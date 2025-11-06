+++
title = "Why TypeScript Won't Save You"
date = "2025-11-13"
description = "TypeScript is a fantastic tool, but it won't save you from yourself. Understanding its limits is the first step to writing actually safe code."
tags = ["typescript", "type-safety", "architecture", "elm", "boundaries"]
draft = true
+++

Last week, a colleague showed me some TypeScript code they were particularly proud of. Beautiful interfaces, generic constraints, mapped types - the works. "Look," they said, "the compiler guarantees this is safe."

Then I asked: "What happens when the API returns null instead of an array?"

Silence.

The code compiled perfectly. The types looked great. And it would crash in production the moment the API had a bad day.

This isn't a story about bad developers or bad code. It's about a fundamental misunderstanding of what TypeScript actually gives you - and more importantly, what it doesn't.

## The Illusion of Safety

TypeScript is an incredible tool. It catches countless bugs, makes refactoring safer, and dramatically improves the developer experience. I use it daily and wouldn't go back to plain JavaScript.

But here's what TypeScript won't do: **it won't save you from yourself.**

The problem isn't TypeScript - it's the mindset that treating types as a safety guarantee creates. I see this constantly: developers who stop thinking about edge cases because "the types will catch it," who skip validation because "it's typed," who trust the green checkmark too much.

TypeScript gives you the _feeling_ of safety without the guarantee. And that gap between feeling and reality is where production bugs live.

## Escape Hatches Everywhere

Let me show you what I mean. Here's perfectly valid TypeScript:

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

function getUser(id: number): User {
  const response = fetch(`/api/users/${id}`);
  return response.json() as User; // "Trust me, compiler"
}
```

The compiler is happy. Your IDE shows no errors. But you've just lied to the type system.

That `as User` doesn't make the data a User - it just tells TypeScript to stop checking. The API could return `null`, an error object, or a completely different shape. TypeScript will never know.

And this is just one escape hatch. TypeScript also gives you:

- `any` (the nuclear option)
- `@ts-ignore` (sweep it under the rug)
- `as unknown as T` (the double lie)
- Type assertions that can't be verified

In a large codebase, how do you know someone didn't cheat? You can't. **You're only as safe as your weakest `any`.**

Compare this to Elm, where cheating is literally impossible. There is no escape hatch. If the compiler says it's safe, it actually is. (I explore this in depth in my new book, [An Elm Primer for React Developers](https://leanpub.com/elm-for-react-devs), which shows how Elm's guarantees change the way you think about type safety - even when you're back in TypeScript.)

## The Boundary Problem

Here's the deeper issue: **TypeScript only knows about your code. It knows nothing about the outside world.**

Every time data enters your system - from an API, user input, localStorage, URL parameters - it's untrusted. TypeScript can't verify it. The types you assign are just wishful thinking until you actually validate.

And here's what makes this worse in modern frontend development: **most projects tightly couple framework code with infrastructure concerns.**

Look at a typical React component:

```typescript
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => setUser(data as User)); // ??
  }, [userId]);

  if (!user) return <div>Loading...</div>;

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

This is the norm! Your UI logic, state management, side effects, and data fetching are all tangled together. The component is simultaneously:

- Managing React-specific state and lifecycle
- Fetching data from the network
- Transforming that data (with a type assertion)
- Rendering UI

There's no boundary between safe and unsafe data. The infrastructure concern (fetching) is married to the framework (hooks, effects) and mixed with presentation logic. Everything is volatile, everywhere, all the time.

This isn't just a TypeScript problem - it's an architectural one. But TypeScript makes it worse by giving you the illusion that `data as User` is somehow safe.

In a well-designed system, you want your domain and application layers to work with safe, validated data. Only the infrastructure layer should deal with the messy, untyped reality of the outside world.

### In Elm: Safety by Default

Elm forces this architecture. Here's how you handle API data:

```elm
type alias User =
    { id : Int
    , name : String
    , email : String
    }

userDecoder : Decoder User
userDecoder =
    Decode.map3 User
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "email" Decode.string)

-- This returns Result Error User
-- The compiler forces you to handle both cases
decodeUser : String -> Result Error User
decodeUser json =
    Decode.decodeString userDecoder json
```

Once you have a `User` in your domain layer, it's guaranteed to be valid. The type system won't let invalid data reach your business logic. Your inner layers only work with safe data.

### In TypeScript: Hope and Pray

In TypeScript, there's no such boundary. You can pass unvalidated data anywhere:

```typescript
// Infrastructure layer - gets raw data
async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json(); // ?? Hope it's actually a User
}

// Domain layer - assumes data is safe
function sendWelcomeEmail(user: User) {
  // Will crash if user.email is undefined
  emailService.send(user.email, "Welcome!");
}
```

TypeScript can't tell you that `fetchUser` might not return a real `User`. It can't tell you that your domain layer is working with potentially invalid data. **Everything is volatile, everywhere, all the time.**

You _can_ build proper boundaries in TypeScript - using libraries like Zod or io-ts to validate at the edges:

```typescript
import { z } from "zod";

const UserSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.string().email(),
});

type User = z.infer<typeof UserSchema>;

async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return UserSchema.parse(data); // Actually validates!
}
```

But notice: **you have to remember to do this.** TypeScript won't remind you. It won't fail to compile if you forget. And in a large codebase with dozens of developers, someone will forget.

## Runtime vs Compile-Time

This points to the fundamental difference: **TypeScript disappears at runtime.**

When your code runs in production, all those beautiful types are gone. What's left is JavaScript - dynamic, untyped, perfectly happy to let `undefined` crash your app.

TypeScript is a compile-time tool. It checks your code against itself. But it can't check your code against reality.

Elm's types, on the other hand, are enforced at runtime through the architecture. The decoder doesn't just annotate - it actually validates. The Maybe type doesn't just document that a value might be missing - it forces you to handle that case or your code won't compile.

## The Null/Undefined Trap

Speaking of missing values, let's talk about TypeScript's most persistent problem:

```typescript
interface User {
  id: number;
  name: string;
  email?: string; // Optional
}

function sendEmail(user: User) {
  // TypeScript knows email might be undefined
  // But this still compiles:
  emailService.send(user.email, "Hello!");
}
```

With `strictNullChecks` enabled, TypeScript will warn you. But:

1. Not all projects enable it
2. You can still ignore the warning
3. Optional chaining (`user.email?.toLowerCase()`) hides the problem instead of solving it

In Elm, there is no `null` or `undefined`. If a value might be missing, it's a `Maybe`:

```elm
type alias User =
    { id : Int
    , name : String
    , email : Maybe String
    }

sendEmail : User -> Result Error ()
sendEmail user =
    case user.email of
        Just email ->
            emailService.send email "Hello!"

        Nothing ->
            Err (MissingEmail user.id)
```

You literally cannot access `user.email` without handling both cases. The code won't compile. No escape hatch. No forgetting. No runtime crash.

## The Deeper Problem: Mindset

Here's what really concerns me: **TypeScript creates a false sense of security.**

I see developers who:

- Skip validation because "it's typed"
- Don't test edge cases because "the compiler checked it"
- Trust `as` assertions because they're in a hurry
- Add `any` to make the error go away
- Believe that if it compiles, it works

This is the real danger. Not that TypeScript is bad - it's not. But that we treat it as something it isn't.

TypeScript is a sophisticated linter. It's fantastic at catching typos, refactoring mistakes, and API misuse within your codebase. But it's not a safety guarantee. It's not a substitute for thinking. And it's definitely not the same as real type safety.

## What Actually Saves You

So if TypeScript won't save you, what will?

**Understanding the boundaries.**

In any system - TypeScript, Elm, or anything else - you need to know where unsafe data becomes safe. You need infrastructure layers that validate, and domain layers that assume validity.

In Elm, the language forces this architecture. Decoders at the boundary, pure functions in the core, effects at the edges. You can't cheat.

In TypeScript, you have to build this discipline yourself:

1. **Validate at boundaries** - Use Zod, io-ts, or similar. Don't trust external data.
2. **Create safe types** - Once validated, use branded types or classes that can't be constructed with invalid data.
3. **Ban escape hatches** - Configure ESLint to flag `any`, `as`, and `@ts-ignore`. Make them painful.
4. **Separate concerns** - Keep infrastructure (fetching, parsing) separate from domain logic. Don't mix `useEffect` with business rules.
5. **Test the unhappy paths** - Types won't save you from bad data, but tests can.
6. **Be honest about tradeoffs** - TypeScript is faster to write than Elm. That's a valid choice. Just know what you're giving up.

## The Craft of Type Safety

This brings me back to something I think about a lot: coding as craft. (I wrote about this in [Coding as Craft: Going Back to the Old Gym](/posts/coding-as-craft-going-back-to-the-old-gym/).)

Good craftspeople understand their tools - both their strengths and their limitations. A hammer is great for nails, but you don't use it on screws just because it's the tool in your hand.

TypeScript is a great tool when you understand its limits:

- It catches bugs within your codebase
- It makes refactoring safer
- It documents your intentions
- It improves the developer experience

But it won't:

- Validate external data
- Prevent runtime errors
- Guarantee type safety
- Save you from yourself

Whether you're using TypeScript, Elm, or anything else, the key is understanding what you're actually getting. Tools are fantastic, but they're not a substitute for thinking.

## Learning Real Type Safety

If you want to understand what actual type safety feels like - the kind where "if it compiles, it works" is more than a meme - I'd encourage you to try Elm.

Not necessarily to use it in production (though I do, and love it). But to learn what a language looks like when it takes type safety seriously. When there are no escape hatches. When the compiler actually has your back.

I'm writing about this extensively in [An Elm Primer for React Developers](https://leanpub.com/elm-for-react-devs). The book shows how Elm's approach to type safety, boundaries, and architecture can change how you think about code - even when you're back in TypeScript. Because once you've experienced real type safety, you start building better boundaries in every language.

## The Verdict

TypeScript won't save you. But understanding its limitations might.

Use TypeScript. Enjoy TypeScript. But don't trust it blindly. Validate at boundaries. Test the unhappy paths. Build proper architecture. And remember: the green checkmark means your code is consistent with itself, not that it's correct.

The best code comes from developers who think, not from those who trust the compiler blindly.

---

**What do you think?** I'd love to hear your experiences with TypeScript's limitations - or times when you thought you were safe but weren't. Find me on [Twitter/X](https://twitter.com/cekrem) or subscribe below for more posts about type safety, architecture, and the craft of software development.
