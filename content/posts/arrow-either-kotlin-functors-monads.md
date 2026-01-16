+++
title = "Arrow's Either: The Kotlin Chapter of our Scary Words Saga"
description = "Taking our functor-applicative-monad tour from Elm to Kotlin, and discovering that Arrow has its own opinions about all this"
date = 2026-01-16
tags = ["kotlin", "functional-programming", "arrow", "tutorial"]
draft = false
+++

## Previously, on "Scary Words"

A few weeks back I wrote about [functors, applicatives, and monads in Elm](/posts/functors-applicatives-monads-elm/) – those three terrifying terms that make developers' eyes glaze over. The punchline was simple: if you've used `map`, `map2`, or `andThen`, you already know these concepts. You just didn't know they had fancy names.

But here's the thing: I spend a lot of my day-to-day in Kotlin, not Elm. And Kotlin has its own functional programming story, largely thanks to a library called [Arrow](https://arrow-kt.io/). So I thought it'd be fun to see how the same concepts translate.

Spoiler: they translate _pretty well_, but Arrow has made some interesting choices along the way.

## Either: The Result Type You Wished You Had

If you're coming from Elm, think of Arrow's `Either<E, A>` as basically `Result<Error, Value>` with a different name. It's a container that holds _either_ a "left" value (conventionally the error) or a "right" value (the success). Yes, "right" as in "correct." Functional programmers love their puns.

(F# decided to put the success type _first_ in their `Result<'T, 'TError>`, completely ruining the pun. Typical.)

```kotlin
import arrow.core.Either
import arrow.core.left
import arrow.core.right

// A successful value
val userName: Either<String, String> = "Christian".right()

// An error
val userAge: Either<String, Int> = "Age cannot be negative".left()
```

Why `Either` instead of Kotlin's built-in `Result`? Well, `Result` is designed primarily for catching exceptions, and it bakes in `Throwable` as the error type. `Either` is more flexible – your "left" can be whatever you want: a string, a sealed class of domain errors, an enum. In practice, this matters _a lot_ for modeling business logic.

## Functor: Yes, It Maps

Remember our definition from the Elm post? A functor is anything you can `map` over. You have a value in a container, you want to apply a function without unwrapping.

```kotlin
// Apply a function to a wrapped value
"hello".right().map { it.uppercase() }  // Either.Right("HELLO")

"oops".left().map { it.uppercase() }    // Either.Left("oops") - untouched!
```

That's it. `Either` is a functor. If the value is `Right`, the function runs. If it's `Left`, nothing happens – the error just passes through. Same pattern as `Maybe.map` in Elm, just with `Right`/`Left` instead of `Just`/`Nothing`.

Arrow also gives you `mapLeft` for when you want to transform the error side:

```kotlin
"oops".left().mapLeft { "Error: $it" }  // Either.Left("Error: oops")
```

Handy for error translation between layers of your app.

## Applicative: Combining Multiple Eithers

Here's where it gets interesting. Remember the applicative problem? You have a function that takes multiple arguments, and multiple wrapped values:

```kotlin
data class User(val name: String, val age: Int, val email: String)

fun validName(name: String): Either<String, String> =
    if (name.isNotBlank()) name.right() else "Name required".left()

fun validAge(age: Int): Either<String, Int> =
    if (age in 1..149) age.right() else "Invalid age".left()

fun validEmail(email: String): Either<String, String> =
    if (email.contains("@")) email.right() else "Invalid email".left()
```

In Elm, you'd use `Result.map3 User validName validAge validEmail`. In Arrow, the idiomatic way is to use `bind()` inside an `either { }` block:

```kotlin
import arrow.core.raise.either

// Short-circuit on first error (like Elm)
fun createUser(name: String, age: Int, email: String): Either<String, User> = either {
    val n = validName(name).bind()
    val a = validAge(age).bind()
    val e = validEmail(email).bind()
    User(n, a, e)
}
```

But wait – what if you want to collect _all_ the errors instead of stopping at the first one? This is where Arrow gets opinionated.

### The Error Accumulation Question

Here's a choice you don't face in Elm: when combining multiple operations that might fail, what happens if _several_ of them fail?

Elm's `Result.map3` short-circuits on the first error. Arrow gives you both options via `zipOrAccumulate`:

```kotlin
// Accumulate: collects ALL errors
fun createUserAccumulating(
    name: String,
    age: Int,
    email: String
): Either<NonEmptyList<String>, User> = either {
    zipOrAccumulate(
        { validName(name).bind() },
        { validAge(age).bind() },
        { validEmail(email).bind() }
    ) { n, a, e -> User(n, a, e) }
}

// If name is blank AND email is invalid:
// Either.Left(NonEmptyList("Name required", "Invalid email"))
```

(Yes, those curly braces around each validation look a bit weird – that's just how Kotlin's lambda syntax works with multiple arguments. You get used to it.)

This is genuinely useful for form validation – you probably want to show all the problems at once, not play whack-a-mole with the user. But it's also a choice you need to _make_, which adds cognitive overhead. Elm sidesteps this entirely by always short-circuiting. Different philosophy.

## Monad: The flatMap/bind Chapter

And now, the M-word. Same scenario as the Elm post: you have a wrapped value, and a function that _returns_ a wrapped value. Without special handling, you'd get `Either<E, Either<E, A>>` – nested containers. Nobody wants that.

In Elm, this is `andThen`. In Arrow, it's `flatMap`:

```kotlin
fun parseAge(str: String): Either<String, Int> =
    str.toIntOrNull()?.right()
        ?: "Not a valid number".left()

fun validateAge(age: Int): Either<String, Int> =
    if (age in 1..149) age.right()
    else "Age must be between 1 and 149".left()

// Chain operations that might fail
fun processAge(input: String): Either<String, Int> =
    parseAge(input).flatMap { validateAge(it) }

processAge("42")   // Either.Right(42)
processAge("abc")  // Either.Left("Not a valid number")
processAge("-5")   // Either.Left("Age must be between 1 and 149")
```

Same pattern as `Result.andThen` in Elm. The nesting problem never materializes because `flatMap` handles the unwrapping.

## The either { } Block: Arrow's Secret Weapon

Here's something Elm _can't_ do (by design): Arrow lets you write imperative-looking code that's actually monadic under the hood. (We actually already saw this above, but let's break it down.)

```kotlin
import arrow.core.raise.either
import arrow.core.raise.zipOrAccumulate

fun createUser(
    nameInput: String,
    ageInput: String,
    emailInput: String
): Either<String, User> = either {
    val name = validateName(nameInput).bind()
    val age = parseAge(ageInput).bind()
    val validAge = validateAge(age).bind()
    val email = validateEmail(emailInput).bind()

    User(name, validAge, email)
}
```

That `bind()` call is basically `andThen` in disguise. If any `bind()` hits a `Left`, the whole block short-circuits and returns that error. But it _reads_ like straight-line imperative code.

Is this cheating? Kinda! It's using Kotlin's coroutine machinery to fake early returns. Elm would never do this – the whole point of Elm is that effects are _always_ explicit in the type signatures, and control flow is _always_ visible.

But honestly? For complex validation chains in Kotlin, this is really nice to write. I've used it plenty. The pragmatist in me wins over the purist here. ¯\\\_(ツ)\_/¯

## So Is Either a "Real" Monad?

Yes! `Either` satisfies the monad laws:

1. **Left identity**: `a.right().flatMap(f)` equals `f(a)`
2. **Right identity**: `m.flatMap { it.right() }` equals `m`
3. **Associativity**: `m.flatMap(f).flatMap(g)` equals `m.flatMap { f(it).flatMap(g) }`

Arrow used to have explicit `Functor`, `Applicative`, and `Monad` type classes (like Haskell), but they removed them in Arrow 1.x. Now it's all just extension functions on the types themselves. Less abstract, more pragmatic – a bit like Elm's philosophy, actually.

The Arrow team's reasoning: Kotlin's type system can't express higher-kinded types elegantly, so the type class approach was always fighting the language. Better to just give you the functions you need directly.

## The Comparison Table

| Concept     | Elm                      | Kotlin/Arrow               | Haskell        |
| ----------- | ------------------------ | -------------------------- | -------------- |
| Functor     | `Result.map`             | `Either.map`               | `fmap` / `<$>` |
| Applicative | `Result.map2`, `map3`... | `zipOrAccumulate`          | `<*>`          |
| Monad       | `Result.andThen`         | `Either.flatMap`, `bind()` | `>>=` (bind)   |

Same patterns, different spellings.

## The Takeaway

If you've used `map`, `flatMap`, and `bind()` on Arrow's `Either`, congratulations – you've been writing functorial, applicative, and monadic code. The scary words are just labels for the patterns you're already using.

Arrow's approach is more flexible than Elm's (error accumulation! imperative syntax!) but that flexibility comes with choices. Elm says "here's the one way to do it." Arrow says "here are several ways, pick what fits."

Neither is wrong. Elm optimizes for simplicity and learnability. Arrow optimizes for power and flexibility in a language (Kotlin) that already embraces multiple paradigms.

The real lesson? These patterns are _universal_. Whether you're writing Elm, Kotlin, Haskell, TypeScript, Rust, or whatever comes next – you'll find functors, applicatives, and monads lurking there, possibly wearing different names.

And now you know them by all their aliases.

---

_If you missed the first part, check out [Functors, Applicatives, and Monads: The Scary Words You Already Understand](/posts/functors-applicatives-monads-elm/) for the Elm perspective. And if you're curious about Arrow, their [official docs](https://arrow-kt.io/learn/typed-errors/working-with-typed-errors/) are surprisingly readable – no category theory degree required._
