+++
title = "Functors, Applicatives, and Monads: The Scary Words You Already Understand"
description = "Demystifying the most feared terms in functional programming - and how Elm teaches these concepts without ever mentioning them"
date = 2026-01-05
tags = ["elm", "functional-programming", "haskell", "tutorial"]
draft = false
+++

## The Dreaded Three

Happy new year! Good to be back. What better way to kickstart this year than to scare you to death with the three most dreaded words in computer science since `NullPointerException`?

If you've spent any time around functional programming communities, you've encountered _them_. Elodin in The Kingkiller Chronicles claims there are Seven Words to make a woman love you, and there are definitely three words that make junior developers' eyes glaze over. The concepts that spawn a thousand Medium articles with titles like "Monads Explained with Burritos" (not kidding). The triforce of functional programming jargon: **Functors**, **Applicatives**, and **Monads**.

These terms have acquired an almost mythical status. They're spoken of in hushed tones, accompanied by warnings about category theory and abstract algebra. People act like you need a mathematics PhD just to understand what's happening when you chain some operations together.

Here's the thing, though: if you've written any Elm code at all, you already _use_ these concepts daily. You just don't call them by their scary names.

Lo and behold, this might be the day where you finally Get It. Read on!

## What's Actually Going On

Let me let you in on a secret: these three concepts are just patterns for working with "wrapped" values. That's it. Values in containers. Values in boxes. Whatever mental image helps you.

Think about `Maybe` in Elm. It's a container that might hold a value, or might be empty:

```elm
-- A value in a "maybe there, maybe not" container
userName : Maybe String
userName = Just "Christian"

-- An empty container
userAge : Maybe Int
userAge = Nothing
```

The scary words are just names for different ways of working with these containers.

And if you've written JavaScript? You've used these too. `[1,2,3].map(x => x * 2)` is functor territory. `fetch().then(res => res.json()).then(data => ...)` is monadic chaining – `then` flattens nested Promises just like `andThen` flattens nested Maybes. The patterns are everywhere; only the vocabulary changes.

## Functor: "I Have a Function and a Wrapped Value"

A Functor is anything that can be "mapped over." You have a value in a container, and you want to apply a function to it without unwrapping it first.

In Elm, you do this constantly:

```elm
-- Apply a function to a wrapped value
Maybe.map String.toUpper (Just "hello")  -- Just "HELLO"
Maybe.map String.toUpper Nothing         -- Nothing

List.map String.toUpper ["hello", "world"]  -- ["HELLO", "WORLD"]
```

That's it. That's functors. If you can `map` over it, it's a functor.

In Haskell, there's a generic `fmap` that works on _any_ functor:

```haskell
-- Haskell: one function to rule them all
fmap toUpper (Just "hello")   -- Just "HELLO"
fmap toUpper ["hello"]        -- ["HELLO"]
```

Elm doesn't have this. In Elm, you explicitly say _which_ container you're mapping over: `Maybe.map`, `List.map`, `Result.map`, and so on. More typing, but also more clarity about what's actually happening.

## Applicative: "I Have a Wrapped Function and a Wrapped Value"

Things get more interesting when both your function _and_ your value are wrapped. What if you have a `Maybe (String -> String)` and a `Maybe String`? How do you apply one to the other?

This is what Applicatives solve. In Haskell, you'd use `<*>`:

```haskell
-- Haskell: apply a wrapped function to a wrapped value
Just toUpper <*> Just "hello"  -- Just "HELLO"
Nothing <*> Just "hello"       -- Nothing
```

Elm doesn't expose this directly, but you use it all the time through `map2`, `map3`, etc:

```elm
-- Elm: combining multiple Maybe values
validateUser : Maybe String -> Maybe Int -> Maybe User
validateUser maybeName maybeAge =
    Maybe.map2 User maybeName maybeAge
```

Here's the mental model: `map2` is applying a function that takes 2 arguments to 2 wrapped values. If any of them is `Nothing`, the whole thing fails.

You can actually construct `<*>` yourself in Elm if you want:

```elm
-- Elm's equivalent of applicative apply
applicative : Maybe a -> Maybe (a -> b) -> Maybe b
applicative =
    Maybe.map2 (|>)

-- Usage (a bit unusual looking, but it works!)
Just String.toUpper
    |> applicative (Just "hello")  -- Just "HELLO"
```

Not that you'd ever write code like this in practice – `map2` is usually much clearer. But it shows that the concept is there, just with different syntax.

## Monad: "I Have a Value, and a Function That Returns a Wrapped Value"

Now for the big one. The M-word. The concept that has launched countless terrible tutorials.

A Monad handles this situation: you have a wrapped value, and you want to apply a function that _itself_ returns a wrapped value. Without special handling, you'd end up with `Maybe (Maybe a)` – a wrapped wrapped value. Nobody wants that.

Literally nobody!
![Wrapped wrapped wrapped](https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExbDd1NjBqeHZybjdqNXFvNjc4NnF2aXRzZjF4eW9zb3h6aTR1d3RmdyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/9oF7EAvaFUOEU/giphy.gif)

In Elm, this is `andThen`:

```elm
-- A function that returns a Maybe
parseAge : String -> Maybe Int
parseAge str =
    String.toInt str
        |> Maybe.andThen (\n -> if n > 0 then Just n else Nothing)

-- Chain operations that might fail
getUserAge : Maybe String -> Maybe Int
getUserAge maybeAgeString =
    maybeAgeString
        |> Maybe.andThen parseAge
```

If `maybeAgeString` is `Nothing`, the whole chain short-circuits. If `parseAge` returns `Nothing`, same thing. The "wrapped wrapped value" problem never materializes because `andThen` handles the unwrapping for you.

In Haskell, this is the famous `>>=` (pronounced "bind"):

```haskell
-- Haskell: the monad bind operator
Just "42" >>= parseAge  -- Just 42
Nothing >>= parseAge    -- Nothing
```

Again, same concept, different syntax.

## Why Elm Doesn't Use These Terms

Here's what I find fascinating: Elm deliberately avoids the category theory vocabulary entirely. The official Elm guide never mentions functors, applicatives, or monads. Not once.

Instead, you just learn that `Maybe.map` transforms values in a `Maybe`, that `Maybe.map2` combines two `Maybe` values, and that `Maybe.andThen` chains operations that might fail. Practical, concrete, no scary words required.

And honestly? It works beautifully. I've introduced Elm to developers who had zero FP background, and they picked up these patterns in hours. The concepts aren't hard – it's the terminology that creates the barrier.

## The Haskell Type Class Advantage (And Why Elm Says No Thanks)

In Haskell, `Functor`, `Applicative`, and `Monad` are type classes – interfaces that let you write generic code:

```haskell
-- Haskell: this works on ANY functor
doubleInContext :: (Functor f) => f Int -> f Int
doubleInContext = fmap (* 2)

-- Works on Maybe
doubleInContext (Just 5)  -- Just 10

-- Works on List
doubleInContext [1, 2, 3]  -- [2, 4, 6]

-- Works on Either
doubleInContext (Right 5)  -- Right 10
```

This is powerful. One function, infinite containers.

Elm explicitly rejects this approach. Every container gets its own `map`, `map2`, `andThen`. No generics. No user-defined type classes. Want to map over a `Maybe`? `Maybe.map`. A `List`? `List.map`. A `Result`? `Result.map`.

(Technically, Elm _does_ have a few built-in type classes like `comparable` and `number` – that's how `List.sort` works on both `List Int` and `List String`. But you can't define your own, and `Functor` isn't one of them.)

Why? The Elm philosophy values explicitness over abstraction. When you read `Maybe.map`, you know _exactly_ what container you're working with. There's no wondering "wait, which functor instance is this using?" The code is more verbose but harder to misread.

Is this the right trade-off? Depends on who you ask. But it does mean Elm code tends to be readable by anyone who knows the language, without requiring deep type system knowledge.

## The Practical Pipeline

Let me show you what this looks like in real Elm code. Say you're parsing JSON for a user:

```elm
type alias User =
    { name : String
    , age : Int
    , email : String
    }

-- Using applicatives (map3) to combine multiple decodings
userDecoder : Decoder User
userDecoder =
    Json.Decode.map3 User
        (field "name" string)
        (field "age" int)
        (field "email" string)
```

That `map3` is applicative functor stuff. You're applying a 3-argument function (`User`) to three wrapped values (the decoders). If any decoding fails, the whole thing fails.

Or consider form validation with monadic chaining:

```elm
validateEmail : String -> Result String String
validateEmail input =
    if String.contains "@" input then
        Ok input
    else
        Err "Invalid email"

validateAge : String -> Result String Int
validateAge input =
    String.toInt input
        |> Result.fromMaybe "Age must be a number"
        |> Result.andThen (\n ->
            if n > 0 && n < 150 then
                Ok n
            else
                Err "Age must be between 1 and 149"
        )
```

That `Result.andThen` is monadic bind. You're chaining operations where each step might fail, and the failure automatically propagates.

## The Takeaway

Look, I get it. "Functor," "Applicative," and "Monad" sound intimidating. They come from category theory, they have mathematical definitions, and some explanations make them seem impossibly abstract.

But the _concepts_ are simple:

- **Functor**: Apply a function to a wrapped value (`map`)
- **Applicative**: Combine multiple wrapped values with a function (`map2`, `map3`, etc.)
- **Monad**: Chain operations that return wrapped values (`andThen`)

(Am I oversimplifying? A little, yes. There are laws these structures must satisfy, edge cases worth knowing, and nuances I've glossed over. But here's the thing: it's much easier to learn the details once the overview isn't intimidating and foggy. Start with the intuition, then fill in the formalism as needed.)

You've been using these patterns all along. Elm just had the good sense not to scare you with the vocabulary.

And maybe that's the real lesson here: sometimes the barrier to understanding isn't the concept – it's the name we gave it. Strip away the academic terminology, and you're left with practical patterns for handling values that might not exist, operations that might fail, and side effects that need managing.

Next time someone starts going on about the monad laws or the functor hierarchy, you can smile and nod, knowing that it's really just `map` and `andThen` wearing a fancy hat.

---

_If you want to go deeper, [Adit Bhargava's illustrated guide](https://www.adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html) is genuinely excellent and way more visual than this post. And if you want the real mathematical definitions, [the Haskell wiki](https://www.haskell.org/tutorial/monads.html) has you covered – though you absolutely don't need it to write good functional code._
