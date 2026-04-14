+++
title = "Effect Without Effect-TS: Algebraic Thinking in Plain TypeScript"
description = "The ideas behind Effect-TS are 40 years old. You can use most of them today, in plain TypeScript, without adopting a framework."
tags = ["typescript", "functional-programming", "type-safety", "error-handling", "domain-modeling"]
date = 2026-04-14
draft = false
+++

A lot of people are reaching for [Effect-TS](https://effect.website).

Every few months you'll be three functions deep in some TypeScript service, squinting at a `try/catch` that swallows four different kinds of failure into one `catch (err)`, and you'll think: "Effect would fix this." Then you look at the API surface, the generator syntax, the layers and services and fibers, and you quietly close the tab. Not because it's bad (not at all; it's genuinely impressive software.) But it requires some investment, and you're just not quite sure...

But what if the _ideas_ behind it don't require the framework, and you can use most of them with what TypeScript gives you out of the box?

If you read my [parse-don't-validate post](/posts/parse-dont-validate-typescript/), you already used one of those ideas. The `Parsed<T>` type that returns either a value or an error? That's typed errors as values. You were doing algebraic thinking without knowing it. (I was too, for years, before I learned what to call it.)

This post takes that thread and pulls it further. Same principle ("make the type system carry the proof") applied to operations instead of data.

## The function that lies to you

Here's a signup function we've written in some form at, well, every company we've worked at:

```typescript
async function signupUser(email: string, password: string): Promise<User> {
  if (!isValidEmail(email)) {
    throw new Error("Invalid email");
  }

  const existing = await db.findUserByEmail(email);
  if (existing) {
    throw new Error("Email already registered");
  }

  const user = await db.createUser({
    email,
    passwordHash: await hash(password),
  });

  await emailService.sendWelcome(user.email);
  await analytics.track("user_signed_up", { userId: user.id });

  return user;
}
```

The return type says `Promise<User>`. That's a lie. This function can fail in at least four ways (bad email, duplicate, database down, email service timeout), calls a database, sends an email, tracks analytics. None of that is in the signature. The caller has to wrap it in `try/catch` and guess:

```typescript
try {
  const user = await signupUser(email, password);
  res.json({ ok: true, user });
} catch (err) {
  // What kind of error? Validation? DB? Email service?
  // No idea. The type system forgot.
  res.status(400).json({ error: (err as Error).message });
}
```

Same problem as [the parse-don't-validate post](/posts/parse-dont-validate-typescript/), one level up. A `string` pretending to be an email was a lie. A `Promise<User>` pretending to always succeed is the same lie.

## Idea 1: honest errors

You know this part from the parse-don't-validate post, so I'll go fast.

Instead of throwing, return the error as a value. Make each failure a variant in a discriminated union:

```typescript
type SignupError =
  | { _tag: "InvalidEmail" }
  | { _tag: "EmailTaken"; email: string }
  | { _tag: "DbError"; cause: unknown }
  | { _tag: "EmailServiceDown" };

type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
```

(I'm using `_tag` instead of `kind` here -- convention I picked up from the Effect community, and it avoids collisions with domain fields named `kind`. Use whatever you want, property name is not the point.)

Now the signup function returns `Promise<Result<User, SignupError>>`. The caller switches on `error._tag` and the compiler checks exhaustiveness -- _if_ you add the `assertNever` trick:

```typescript
function assertNever(x: never): never {
  throw new Error(`Unexpected: ${JSON.stringify(x)}`);
}

// at the call site:
if (!result.ok) {
  switch (result.error._tag) {
    case "InvalidEmail":
      return res.status(400).json({ error: "Bad email" });
    case "EmailTaken":
      return res.status(409).json({ error: "Already registered" });
    case "DbError":
      return res.status(500).json({ error: "Try again later" });
    case "EmailServiceDown":
      return res
        .status(202)
        .json({ message: "Signed up, welcome email delayed" });
    default:
      assertNever(result.error);
  }
}
```

Add a fifth error variant next month and the compiler flags every `switch` that doesn't handle it. In Elm this would just be a compile error you can't ignore. In TypeScript you need the `assertNever` dance, which is less elegant but does the job.

One thing that might bite you, though: TypeScript sometimes infers `string` instead of the literal `"InvalidEmail"` for `_tag`. If that happens, use constructor functions:

```typescript
const invalidEmail = (): SignupError => ({ _tag: "InvalidEmail" });
const emailTaken = (email: string): SignupError => ({
  _tag: "EmailTaken",
  email,
});
```

Or just `as const` the object. Either way, you need the literal types for narrowing to work.

This is idea 1, and you've already been doing it if you followed the parse-don't-validate series. The new part starts now. Lo and behold:

## Idea 2: honest _dependencies_

The return type of our signup function is now `Promise<Result<User, SignupError>>`. Better -- the error channel is visible. But the function still secretly depends on a database, an email service, and an analytics client, all hiding behind module-level imports. The function's _real_ inputs aren't just `email` and `password`. They're also "a database that's up" and "an email service that works." The type signature doesn't mention any of them.

In [Why TypeScript Won't Save You](/posts/why-typescript-wont-save-you/), I talked about the gap between what the type system sees and what actually happens at runtime. Hidden dependencies live in exactly that gap.

The fix is the simplest idea in this whole post, and I almost feel dumb writing it out: put the dependencies in the function signature.

```typescript
type SignupDeps = {
  readonly findUserByEmail: (
    email: string,
  ) => Promise<Result<User | null, DbError>>;
  readonly createUser: (
    input: CreateUserInput,
  ) => Promise<Result<User, DbError>>;
  readonly sendWelcomeEmail: (
    email: string,
  ) => Promise<Result<void, EmailError>>;
  readonly trackEvent: (
    name: string,
    props: Record<string, string>,
  ) => Promise<void>;
};
```

Now the function takes its dependencies as the first argument:

```typescript
async function signupUser(
  deps: SignupDeps,
  email: string,
  password: string,
): Promise<Result<User, SignupError>> {
  const parsed = parseEmail(email);
  if (!parsed.ok) return { ok: false, error: { _tag: "InvalidEmail" } };

  const existing = await deps.findUserByEmail(parsed.value);
  if (!existing.ok)
    return { ok: false, error: { _tag: "DbError", cause: existing.error } };
  if (existing.value)
    return { ok: false, error: { _tag: "EmailTaken", email } };

  const created = await deps.createUser({
    email: parsed.value,
    passwordHash: await hash(password),
  });
  if (!created.ok)
    return { ok: false, error: { _tag: "DbError", cause: created.error } };

  const welcomed = await deps.sendWelcomeEmail(parsed.value);
  if (!welcomed.ok) {
    // Non-fatal: user is created, email just didn't send
    // (log it, retry later, whatever)
  }

  await deps.trackEvent("user_signed_up", { userId: created.value.id });

  return { ok: true, value: created.value };
}
```

Read the signature: `signupUser(deps: SignupDeps, email: string, password: string): Promise<Result<User, SignupError>>`. That's the whole story. What it needs, what it takes, what it returns, how it can fail. No ambient imports, no hidden capabilities. If you read that line and nothing else, you know what this function does.

(If you've read Scott Wlaschin's _Domain Modeling Made Functional_, you'll recognize this -- he passes dependencies as function parameters and then partially applies them. In F# the currying makes it natural. In TypeScript it's a bit more explicit, but the principle is identical. You could use lodash functional or rambda or something to support currying, btw.)

The payoff shows up immediately in tests:

```typescript
const fakeUser: User = { id: "1", email: "test@example.com" };

const result = await signupUser(
  {
    findUserByEmail: async () => ({ ok: true, value: null }),
    createUser: async () => ({ ok: true, value: fakeUser }),
    sendWelcomeEmail: async () => ({ ok: true, value: undefined }),
    trackEvent: async () => {},
  },
  "test@example.com",
  "password123",
);

expect(result).toEqual({ ok: true, value: fakeUser });
```

No mocking library needed! And no `jest.spyOn(db, 'findUserByEmail')`. Just... functions. The dependencies are in the type, so TypeScript tells you exactly what to provide. If you forget one, it's a compile _error_, not a runtime "what happened now, and what does that exception really mean?".

And in production, you wire it (once!) at the edge:

```typescript
const prodDeps: SignupDeps = {
  findUserByEmail: postgresUserRepo.findByEmail,
  createUser: postgresUserRepo.create,
  sendWelcomeEmail: sendgridClient.sendWelcome,
  trackEvent: segmentClient.track,
};

router.post("/signup", async (req, res) => {
  const result = await signupUser(prodDeps, req.body.email, req.body.password);
  // handle result...
});
```

This is dependency injection, without all the `@Injectable()`. We usually use tools (not just Effect) to handle much of this, but it's a good thing to at least know how to do it without all the magic tricks! Just a type and a function parameter. The "infrastructure layer" from [Clean Architecture](/posts/clean-architecture-and-plugins-in-go/) is literally just the `prodDeps` object.

I already covered this pattern in Elm and F# in [the impossible-states post](/posts/making-impossible-states-impossible-with-functional-dependency-injection/). Turns out it works fine in TypeScript too, it's just more verbose (and way less common!).

## Idea 3: composition (and where it gets ugly)

Look at the `signupUser` body again. See all those early returns?

```typescript
const existing = await deps.findUserByEmail(parsed.value);
if (!existing.ok) return { ok: false, error: { _tag: "DbError", cause: existing.error } };

const created = await deps.createUser({ ... });
if (!created.ok) return { ok: false, error: { _tag: "DbError", cause: created.error } };

const welcomed = await deps.sendWelcomeEmail(parsed.value);
if (!welcomed.ok) { ... }
```

If you read the parse-don't-validate post, you've seen this before -- the `parseUser` function had the same shape. Check result, bail on error, continue on success, repeat. It works. It's also six lines of plumbing for every two lines of logic.

You can clean this up with a small helper:

```typescript
async function andThen<T, U, E1, E2>(
  result: Promise<Result<T, E1>>,
  f: (value: T) => Promise<Result<U, E2>>,
): Promise<Result<U, E1 | E2>> {
  const r = await result;
  if (!r.ok) return r;
  return f(r.value);
}
```

This is `flatMap` for async results. If the previous step failed, skip everything. If it succeeded, run the next step. The error types union automatically. (In F# this would be `Result.bind` inside an `async` computation expression. In Elm it's `Result.andThen`. Same idea, different syntax.)

And if you must know, by doing this, you're not far from making a [Monad](/posts/functors-applicatives-monads-elm/#monad-i-have-a-wrapped-value-and-a-function-that-returns-a-wrapped-value), though that scary term doesn't necessarily help us at this point.

For two or three steps, `andThen` cleans things up nicely. Past four or five, the nesting gets painful. You start wishing for something like F#'s computation expressions or Haskell's `do` notation -- a way to write what looks like straight-line code but with the error handling baked in.

And that is, quite honestly, where Effect-TS earns its weight. Its generator-based syntax gives you exactly that:

```typescript
// Effect-TS version (for comparison, not what we're building)
const signupUser = Effect.gen(function* () {
  const email = yield* parseEmail(rawEmail);
  const existing = yield* deps.findUserByEmail(email);
  // ... looks like straight-line code, but errors propagate automatically
});
```

I'm not going to build that in this post. If I started writing combinators on top of combinators I'd end up with a worse version of Effect, and that's not the point.

## Where this breaks down

I want to be honest about the limits, because overselling this stuff is how you end up writing [FP articles you can't finish](/posts/the-fp-article-i-cant-seem-to-finish/).

Result composition past four or five steps gets verbose. The early-return pattern works, it's just a lot of characters for not much meaning. The `andThen` helper takes the edge off but introduces nesting. Past a certain point you're fighting the language. TypeScript doesn't have `do` notation and probably never will.

Error types also multiply across module boundaries. When `signupUser` calls `createOrder` which calls `chargePayment`, each layer has its own error union. You end up manually merging them or writing mapping functions between layers. Fine for two levels. Annoying at five.

And structured concurrency is a different game entirely. "Run these three things in parallel, cancel the rest if one fails, make sure cleanup happens" -- `Promise.allSettled` gives you nothing type-safe. Effect's fiber model is genuinely better here, and I'm not going to pretend otherwise.

These are real limits. The patterns in this post cover maybe 80% of what I need day-to-day. The other 20% is where I keep almost reaching for Effect.

In any case, I'll argue _it's often good to learn to do manually even things a framework can do better automagically_. Often.

## What this actually is

Typed errors are a 10-line `Result` type. Explicit effects are `Promise<Result<T, E>>` instead of `Promise<T>`. Dependency injection is a function parameter. None of this requires a library. You can adopt typed errors tomorrow without touching your DI story. You can inject dependencies without a single `Result` type. They work independently, and they compound when you combine them.

Effect-TS packages all of these (and more) into a coherent system with good ergonomics. That's worth something. But the ideas predate it by decades, and they come from the same tradition as parse-don't-validate.

Reaching for Effect makes sense. But when you choose to go all in that route, I hope you know _why_ it exists -- and that's (IMHO) worth more than the library. `¯\_(ツ)_/¯`
