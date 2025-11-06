+++
title = "Why TypeScript Won't Save You"
date = "2025-11-06"
description = "TypeScript is a fantastic tool, but it won't save you from yourself. Understanding its limits is the first step to writing actually safe code."
tags = ["typescript", "type-safety", "architecture", "elm", "boundaries"]
draft = false
+++

TypeScript won't save you from yourself.

I know this sounds harsh, especially if you've invested years mastering generics, conditional types, and mapped types. But the green checkmark from the TypeScript compiler means your code is consistent with itself - not that it's correct.

This isn't an attack on TypeScript, but rather a proverbial sledgehammer to the belief that types equal type safety.

The problem isn't the tool. It's the mindset. I see it constantly: developers who stop thinking about edge cases because "the types will catch it," who skip validation because "it's typed," who trust the compiler too much.

TypeScript gives you the _feeling_ of safety without the guarantee. And that gap - between feeling and reality, between compile-time and runtime, between your code and the world - is where production bugs live.

## The Illusion of Safety

TypeScript is an incredible tool. It catches countless bugs, makes refactoring safer, and dramatically improves the developer experience. I use it daily and wouldn't go back to plain JavaScript for critical production code.

But it won't protect you from the outside world. And the language itself makes this worse by providing escape hatches everywhere.

## On Escape Hatches

Let me show you what I mean. Here's perfectly valid TypeScript:

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

async function getUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return await response.json();
}

const firstUser = await getUser(1);

// what happens now?
console.log(`Greetings, ${firstUser.name}!`);
```

The compiler is happy. Your IDE shows no errors (it even suggests the `User` properties as you type inside that console.log). But you've just lied to the type system.

Without writing any `as User` (or the dirtier `as unknown as User`), you've convinced TypeScript that a function that can return _anything_ (including nothing) always returns a `User`. The API could return `null`, an error object, or a completely different shape. TypeScript will never know.

Implicit casting by return types is just one escape hatch. TypeScript also gives you:

- `any` (the nuclear option)
- `@ts-ignore` (sweep it under the rug)
- `as unknown as T` (the double lie that always works)
- Type assertions that can't be verified

In a large codebase, how do you know someone didn't cheat? You can't. **You're only as safe as your weakest `any`.**

Compare this to Elm, where cheating is literally impossible. There is no escape hatch. If the compiler says it's safe, it actually is.

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

There's no boundary between safe and unsafe data. The infrastructure concern (fetching) is married to the framework (hooks, effects) and mixed with presentation logic.

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

### In TypeScript: No Boundaries

In TypeScript, there's no such enforcement. You can pass unvalidated data anywhere:

```typescript
// Infrastructure layer - gets raw data
async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return await response.json(); // ?? Hope it's actually a User
}

// Domain layer - assumes data is safe
function sendWelcomeEmail(user: User) {
  // Will crash if user is null, or an int or whatever
  emailService.send(user.email, "Welcome!");
}
```

TypeScript can't tell you that `fetchUser` might not return a real `User`. It can't tell you that your domain layer is working with potentially invalid data.

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

(You could (and should?) also consider [Effect](https://effect.website) for a more holistic approach, but that's a blog post of its own.)

## Runtime vs Compile-Time

This points to the fundamental difference: **TypeScript disappears at runtime** and is **blissfully ignorant of many things at compile-time**.

When your code runs in production, all those beautiful types are gone. What's left is JavaScript - dynamic, untyped, perfectly happy to let `undefined` crash your app.

TypeScript is a compile-time tool. It checks your code against itself. But it can't check your code against reality. And unless you tell it to, it doesn't know or care about architectural layers or the difference between your domain and the dangerous outside world.

Elm's types, on the other hand, are enforced consistently, end to end, through the architecture. The decoder doesn't just annotate - it actually validates. The Maybe type doesn't just document that a value might be missing - it forces you to handle that case or your code won't compile.

## The Deeper Problem: Mindset

**TypeScript creates a false sense of security.**

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

1. **Validate (or better yet _parse_) at boundaries** - Use Zod, io-ts, or Effect or similar. Don't trust external data.
2. **Create safe types** - Once validated, use branded types or classes that can't be constructed with invalid data.
3. **Ban escape hatches** - Configure your setup to flag `any`, `as`, and `@ts-ignore`. Make them painful.
4. **Separate concerns** - Keep infrastructure (fetching, parsing) separate from domain logic. Don't mix `useEffect` with business rules.
5. **Test the unhappy paths** - Types won't save you from bad data, but tests can.

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
- **Protect you from bad data**

Whether you're using TypeScript, Elm, or anything else, the key is understanding what you're actually getting. Tools are fantastic, but they're not a substitute for thinking. And (more on that in a later post): **we need solid engineering and architecture on our frontends, not just typings**.

## Learning Real Type Safety

If you want to understand what actual type safety feels like - the kind where "if it compiles, it works" is more than a meme - try Elm. There are other equally type safe (and functional) languages out there, but as I argue often: Elm provides the shortest and most direct path, especially if you're familiar with the frontend domain (and React in particular).

Not necessarily for production (though I do, and love it). But to learn what a language looks like when it takes type safety seriously. When there are no escape hatches. When the compiler actually has your back. Once you've experienced real type safety, you start building better boundaries in every language.

(I explore this extensively in [An Elm Primer for React Developers](https://leanpub.com/elm-for-react-devs) - how Elm's guarantees change the way you think about boundaries and architecture, even when you're back in TypeScript.)

## The Verdict

TypeScript won't save you. But understanding its limitations might.

Use TypeScript. Enjoy TypeScript. But don't trust it blindly. Validate at boundaries. Test the unhappy paths. Build proper architecture. And remember: the green checkmark means your code is consistent with itself, not that it's **correct**.

The best code comes from developers who think. From engineers and architects, people honing their craft. Not from framework-, and/or hype junkies with smooth typings and tight couplings.
