+++
title = "Kotlin's Rich Errors: Native, Typed Errors Without Exceptions"
date = 2025-08-08
draft = false
tags = ["kotlin", "elm", "arrow", "functional-programming", "error-handling", "union-types"]
categories = ["Programming", "Kotlin", "Functional Programming", "Rich Errors"]
+++

At KotlinConf 2025, the Kotlin team showcased progress toward **Rich Errors** with union types. After years of watching languages slowly adopt patterns that Elm has championed since day one, it's exciting to see Kotlin taking this significant step toward more explicit, type-safe error handling. And in a very "native" Kotlin way at that!

I vividly remember this announcement giving my functional heart a pleasant jolt, but I haven't found the time for a write-up until now. Better late than never, though:

## What Are Rich Errors in Kotlin?

Kotlin's Rich Errors feature introduces union types specifically for error handling, allowing functions to return values like `String | Error` - a type that can be either a `String` or an `Error`. This is a fundamental shift away from the traditional try-catch paradigm toward explicit, type-safe error handling.

```kotlin
// Future Kotlin with Rich Errors
fun parseNumber(input: String): Int | ParseError {
    // Returns either an Int or a ParseError
}
```

This approach makes errors part of the type system, forcing developers to handle them explicitly rather than hoping they remember to wrap everything in try-catch blocks.

### How this compares in Kotlin today

Kotlin already ships with `Result<T>` in the standard library, and many teams model error domains with Arrow's `Either<Error, Value>`/`Validated`. Rich Errors make these patterns feel native: the error space becomes part of the function type without wrappers. This reduces the need for `Either`-style constructs for many cases, while Arrow still remains valuable for optics, typed effects, and broader FP utilities.

## Familiar pattern in other ecosystems

If you've used languages or libraries that embrace typed errors, the idea will feel familiar: Elm's `Result` (and to some extent `Maybe`), Rust's `Result<T, E>`, Swift's `Result<Success, Failure>`, or Kotlin's Arrow `Either`. Rich Errors bring this experience directly into Kotlin's type system.

## Why This Matters

### Type Safety Over Runtime Surprises

Traditional exception-based error handling in languages like Java and Kotlin (pre-rich errors) suffers from a fundamental problem: exceptions are invisible in the type system. You can't tell from a function signature whether it throws exceptions or what kinds of exceptions to expect.

```kotlin
// Traditional Kotlin - what exceptions might this throw?
fun parseNumber(input: String): Int {
    return input.toInt() // NumberFormatException? Who knows!
}
```

With union types, errors become explicit:

```kotlin
// Rich Errors Kotlin - crystal clear what can go wrong
fun parseNumber(input: String): Int | ParseError
```

### Performance Benefits

Exception handling has runtime overhead. Creating stack traces, unwinding the call stack, and throwing exceptions all cost CPU cycles. Union-like typed errors are just regular values—no special runtime machinery required.

### Composability

When errors are values, composition and transformation flow naturally. Mapping, flat-mapping, and aggregating error-aware computations become straightforward and explicit, without exceptions jumping across call sites.

## The Road Ahead

Kotlin's Rich Errors feature is under active design and currently experimental; details, syntax, and operator semantics may change. The intent is to cover many use cases currently handled by wrappers like `Either` or `Result`; whether it fully replaces them will depend on the final design and ecosystem adoption. As a built-in construct, it could be more efficient and convenient than library-based solutions. For the latest status, see the official Kotlin page for language features and proposals: [Kotlin language features and proposals](https://kotlinlang.org/docs/kotlin-language-features-and-proposals.html).

## Key benefits

1. **Exhaustiveness enforced**: the compiler keeps success and error paths explicit
2. **Composable control flow**: map/flatMap-style composition without exceptions
3. **Predictability**: fewer hidden control transfers from thrown exceptions
4. **Safer refactors**: changing error types surfaces all impacted call sites

## Looking Forward

For teams already using Arrow or similar libraries, this direction validates your emphasis on typed errors while promising a more idiomatic, built-in experience over time.

The fact that Kotlin is moving in this direction suggests we're approaching a tipping point where explicit error handling becomes the norm rather than the exception (pun intended). And honestly, it's about time.

---

### Further reading

- Official status and proposals: [Kotlin language features and proposals](https://kotlinlang.org/docs/kotlin-language-features-and-proposals.html)
