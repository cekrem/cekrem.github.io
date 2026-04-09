+++
title = "ArkType: The Parse-Don't-Validate Sequel I Didn't Know I Needed"
description = "Reviewing ArkType after writing about branded types and parsing in TypeScript. Turns out someone built the thing I was hand-rolling."
tags = ["typescript", "type-safety", "functional-programming", "parsing", "domain-modeling", "arktype"]
date = 2026-04-09
draft = false
+++

Two days ago I published a post about [parsing instead of validating in TypeScript](/posts/parse-dont-validate-typescript/). I hand-rolled branded types with `unique symbol`, wrote `Parsed<T>` result types, and stitched together parsers with early returns. It worked. It was also kind of ugly, and I said so at the time.

Then someone in the Reddit comments linked me to [ArkType](https://arktype.io).

I'd heard the name before but never actually sat down with it. After a few hours of poking around I have opinions. Some of them are strong. A couple might even be wrong (I haven't used this in production yet, so grain of salt and all that). But I think ArkType is doing something interesting for TypeScript, and it lands squarely on the parse-don't-validate thread I've been pulling at.

## Quick recap (or: go read the other post)

The short version of [the previous post](/posts/parse-dont-validate-typescript/): a validator checks data and throws away what it learned. A parser checks data and _encodes_ what it learned in the type. Branded types let you fake nominal typing in TypeScript's structural system, and the parser is the one trusted boundary where you're allowed to `as Brand` your way past the compiler.

The long version has code examples. Go read it if you haven't. I'll wait.

The pain point I ended on, though: hand-rolling branded parsers in TypeScript is verbose, repetitive, and requires discipline to keep the `as` casts contained. I mentioned Zod as the ergonomic answer, but noted that even Zod doesn't change the _mindset_ problem. You still have to choose to use it.

So where does ArkType fit?

## First contact

ArkType's pitch is "TypeScript's 1:1 validator, optimized from editor to runtime." Let me just show you:

```typescript
import { type } from "arktype";

const User = type({
  name: "string",
  email: "string.email",
  age: "0 <= number.integer <= 150",
});
```

I stared at that for a while. The strings _are_ the types. `"string.email"` isn't a method chain or a function call. It's a string literal that ArkType's compiler parses into both a TypeScript type and a runtime validator. And the range constraint on age? Also a string. `"0 <= number.integer <= 150"`. Reads like a type annotation you'd _wish_ TypeScript had natively.

The TypeScript type falls out automatically:

```typescript
// { name: string; email: string; age: number }
type User = typeof User.infer;
```

No `z.infer<typeof schema>`. No separate type definition to keep in sync. You write the thing once and both sides (compile-time and runtime) agree on what it means.

If you've read Scott Wlaschin's _Domain Modeling Made Functional_, you'll recognize what's happening here: make illegal states unrepresentable. In Elm I'd reach for an opaque type and a smart constructor, and in F# you'd use a single-case discriminated union. TypeScript makes you fight for it, which I spent most of the previous post complaining about. ArkType picks that fight for you. A `string` tells you nothing. An `Email` tells you something. A `type({ email: "string.email" })` tells you something _and_ enforces it at runtime. That's the bit that's hard to get in TypeScript without a library doing the heavy lifting.

## The parsing story

So what does it actually look like when you use this thing?

```typescript
const out = User(rawData);

if (out instanceof type.errors) {
  console.error(out.summary);
  // "email must be an email address (was 'not-an-email')"
  // "age must be at most 150 (was 200)"
  return;
}

// out is fully typed as { name: string; email: string; age: number }
out.name;
```

This _is_ parsing. Raw data goes in, typed data or errors come out. The caller has to handle both branches before touching the result. Same job as my hand-rolled `Parsed<T>` from the previous post.

But I have a gripe.

That error check uses `instanceof`. Not a discriminated union. Not a `kind` field. `instanceof`. I get _why_ they did it (a `Result<T, E>` wrapper means allocating `{ ok: true, data: T }` on every successful validation, and when you're targeting 14-nanosecond validation that allocation actually matters), but it still feels wrong. A discriminated union says "this value is one of two things" in the type itself. `instanceof` says "go check the prototype chain." Those aren't the same thing, and if you've spent any time in Elm or F# you'll feel that friction immediately.

It also means ArkType's output isn't composable with the FP ecosystem (neverthrow, Effect, fp-ts) without wrapping it yourself. You want to pipe the result into a Result-based pipeline? Write an adapter. It works, but it's the kind of thing that makes me sigh quietly. (To be fair, I haven't checked whether someone's already published an adapter package. Probably someone has. The npm ecosystem is nothing if not thorough.)

## Where it gets interesting: morphs

Okay, this is the part that actually got me excited. Morphs are ArkType's version of transforms, and they turn "parse, don't validate" into "parse _and transform_ in one pass":

```typescript
const CreateUser = type({
  name: "string",
  email: "string.email",
  age: "string.numeric.parse",
});
```

That `"string.numeric.parse"` takes a string _input_, validates that it looks numeric, and outputs a `number`. The TypeScript input type is `{ name: string; email: string; age: string }` and the output type is `{ name: string; email: string; age: number }`. One definition, two types, a transformation in between.

And you can chain them:

```typescript
const JsonUser = type("string.json.parse").to({
  name: "string",
  email: "string.email",
  age: "number.integer",
});
```

Raw JSON string in, typed domain object out. The entire pipeline is a single expression that the type system understands end to end. This is the same composition pattern from [the previous post](/posts/parse-dont-validate-typescript/), where small field parsers (`parseEmail`, `parseAge`) combined into `parseUser`. The library just handles the plumbing now.

Clean Architecture draws a hard line between the messy outside world and your domain, and the boundary is where transformation happens. ArkType turns that boundary into something you can actually compose and type-check. You're _parsing into your domain_ at the edge, not just checking that the shape looks right. Where you put the parser is where you draw the line between trusted and untrusted.

(In [Why TypeScript Won't Save You](/posts/why-typescript-wont-save-you/), I argued that TypeScript's biggest weakness is the gap between compile-time and runtime. ArkType's morphs are an attempt to stitch that gap shut, at least at the boundaries where it matters most.)

## The branded type story

Remember the `unique symbol` dance from my previous post?

```typescript
declare const EmailBrand: unique symbol;
type Email = string & { readonly [EmailBrand]: true };
```

ArkType does this:

```typescript
const Email = type("string.email#Email");
```

One line. The `#` operator adds a type-level brand, so a function expecting an `Email` can't accidentally receive a `Username`, even though both are strings at runtime. Same principle as the hand-rolled version, without the ceremony. (Every primitive in your domain is a missed conversation, as I said in the previous post. ArkType just makes that conversation cheaper to have.)

The part that bugs me, though: branded types in ArkType have had some rough edges historically. There were issues with `declaration: true` in tsconfig, and composing branded types across module boundaries isn't as polished as the rest of the API. It's getting better. It works. But if branded types are central to your parse-don't-validate strategy (and they should be), test this carefully in your actual project setup before going all in. I haven't battle-tested it myself yet, so I'm going off docs and issue threads here.

## Automatic union discrimination

This one impressed me. In Zod, if you want efficient union parsing, you have to explicitly tell it which field to discriminate on:

```typescript
// Zod: you do the work
z.discriminatedUnion("type", [
  z.object({ type: z.literal("email"), address: z.string() }),
  z.object({ type: z.literal("sms"), phone: z.string() }),
]);
```

ArkType figures it out:

```typescript
// ArkType: it figures it out
const Contact = type.or(
  { type: "'email'", address: "string" },
  { type: "'sms'", phone: "string" }
);
```

It automatically finds the most efficient discriminant, even across nested paths. ArkType's docs describe this as "set-theoretic," which tracks. The library represents types as sets and reasons about their relationships mathematically. That's what enables things like `User.extends("object")` at runtime, which is a kind of type introspection TypeScript itself can't do.

In Elm, the compiler does this for custom types automatically. Pattern matching on a `Msg` doesn't require you to hint at which field to check first. ArkType brings that same idea to runtime TypeScript, which is pretty cool for a language that doesn't have native algebraic data types. (Whether you _need_ this level of optimization is a different question. For most apps, probably not. But it's nice that the library is thinking about it so you don't have to.)

## The honest tradeoffs

The string DSL is both the best and worst thing about ArkType. It's concise and readable and serializable (you can store schemas as plain strings, which Zod's function chains can't do). But it's also a DSL you have to learn. TypeScript errors inside those strings surface differently than normal TS errors. Your IDE won't rename a field inside `"string.email"`. The learning curve is real, despite the "familiar syntax" marketing.

Bundle size is the other thing. ArkType ships around 42KB minified. Zod is about 13KB minified + gzipped. Valibot is under 9KB with tree-shaking. ArkType includes what amounts to a JIT compiler for type expressions, and it barely tree-shakes. For a server, who cares. For a client-side bundle where you're counting kilobytes, that's a lot of validator.

And the ecosystem is young. Zod has 50+ integrations (tRPC, Drizzle, React Hook Form, you name it). ArkType has maybe five. If you're building on a stack that expects Zod schemas, switching has real friction. (React Hook Form does have an ArkType resolver, so there's that at least.)

Performance, on the other hand, is absurd. ArkType benchmarks at roughly 14 nanoseconds for object validation versus Zod's 281. Twenty times faster. For most apps this honestly doesn't matter. Validation isn't your bottleneck. But for hot paths or high-throughput APIs, it's there if you need it.

## So should you use it?

Depends on what you're optimizing for.

If you read my parse-don't-validate post and thought "yes, but I don't want to hand-roll all that," ArkType is worth a serious look. Parsing, branding, transforms, union discrimination, roughly half the syntax of Zod. And the philosophy runs deeper than any other TypeScript validation library I've tried.

If you're already on Zod and your codebase is humming along, I wouldn't rush to switch. Zod works. The ecosystem is massive. The parse-don't-validate principle survives in any library that returns a result instead of throwing. The principle is bigger than the tool. (And if you're in Elm or F#, you don't need any of this. The language already does it. Sorry, I had to.)

Either way, ArkType is pushing TypeScript closer to what those languages give you by default: types that mean something at runtime, not just at compile time. The gap is still wide. But it's narrowing.

I'm going to try it on a real project and see how it holds up past the hello-world stage. That's where libraries like this either prove themselves or quietly get replaced by a `utils/parse.ts` you wrote yourself.
