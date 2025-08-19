---
title: "Making Impossible States Impossible: Type-Safe Domain Modeling with Functional Dependency Injection"
date: 2025-08-18
description: "Learn how to use rich types, phantom types, and partial application to eliminate impossible states and implement Clean Architecture's dependency inversion in a functional way. Discover why the compiler is your best friend for building robust domain models."
tags:
  [
    "functional-programming",
    "clean-architecture",
    "types",
    "elm",
    "fsharp",
    "domain-modeling",
    "dependency-inversion",
  ]
draft: false
---

Most applications don't fail because algorithms are hard—they fail because our models allow states that make no sense in the domain. "User without email but verified", "order that's both shipped and cancelled", "sum < 0", "modal dialog both closed and active". These states should be impossible from the start.

> Among the most time-consuming bugs to track down are the ones where we look at our application state and say "this shouldn't be possible."
>
> - Richard Feldman, elm-conf 2016

This is where typed functional languages (Elm, Haskell, F#, etc.) truly shine. They give us tools to express domain rules directly in the type system itself. The result? The compiler refuses to build when we try to represent an illegal state. In short: **make impossible states impossible**.

If "no runtime exceptions" sounds appealing, then "no impossible state at runtime" must be even better! 🥳

## Rich Types as Living Documentation

An important observation from Scott Wlaschin's "Domain Modeling Made Functional" is that good domain types should be so clear that domain experts (without programming background) can read them and recognize familiar concepts and rules. In other words: well-chosen, rich types function as living documentation—and the compiler enforces them.

This is simultaneously one of the strongest arguments for typed functional languages: they make it natural to express the domain precisely, get fast feedback during compilation, and collaborate more closely with domain experts about the right concepts.

## Parse, Don't Validate

Instead of "validating" data scattered throughout the code, we do one thing before bringing data into the domain layer: we parse raw data into rich, type-safe domain values. From there, the rest of the system works with values that are already guaranteed to be valid. This principle is excellently explained in Alexis King's (Lexi Lambda) ["Parse, don't validate"](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/).

Example in Elm—a non-empty string and an email:

```elm
module Domain exposing (NonEmptyString, Email, nonEmpty, email)

type NonEmptyString
    = NonEmptyString String -- note: constructor not exposed

nonEmpty : String -> Result String NonEmptyString
nonEmpty s =
    if String.length s > 0 then
        Ok (NonEmptyString s)
    else
        Err "Cannot be empty"

type Email
    = Email String

email : String -> Result String Email
email s =
    if String.contains "@" s then
        Ok (Email s)
    else
        Err "Invalid email"
```

The point: After parsing, there are no "empty strings" or "invalid emails" in the domain. They can only exist as errors in boundary code, not in the rest of the system. And since values are immutable, they also can't be "corrupted" accidentally later in the program flow.

## Sum Types: Single Source of Truth for State

Instead of scattered booleans, represent possible state with an explicit union/sum type. This is the core of "Making impossible states impossible":

```elm
type Session
    = Anonymous
    | Authenticated User

-- Impossible to have a "partially logged in" user
```

Another example is asynchronous loading (avoid `isLoading`, `error`, `data` that can contradict each other):

```elm
type RemoteData error value
    = NotAsked
    | Loading
    | Success value
    | Failure error
```

Here each state is mutually exclusive and complete—UI logic becomes both simpler and safer.

## Functional Dependency Injection: Partial Application as Architecture

Now that the domain's state space is constrained by types, we still need to wire in effects without reintroducing illegal states. This is where partial application shines: we keep the core pure and push effects to the edges by injecting them as functions.

Here's where Clean Architecture's Dependency Inversion Principle meets functional programming in a beautiful way. Instead of injecting heavy interfaces and objects, we can inject **functions** as dependencies. As Scott Wlaschin demonstrates in "Domain Modeling Made Functional", partial application becomes the functional equivalent of dependency injection.

Consider this workflow step from the book (F#!):

```fsharp
type ValidateOrder =
    CheckProductCodeExists    // dependency
    -> CheckAddressExists     // dependency
    -> UnvalidatedOrder       // input
    -> Result<ValidatedOrder, ValidationError> // output
```

The key insight: dependencies come first in the parameter order, followed by input, then output. This allows us to use partial application to "inject" our dependencies:

```fsharp
// "Inject" dependencies via partial application
let validateOrderStep =
    validateOrder
        checkProductCodeExists  // injected dependency
        checkAddressExists      // injected dependency
    // Returns: UnvalidatedOrder -> Result<ValidatedOrder, ValidationError>
```

In Elm, we'd do ish this:

```elm
-- Inject dependencies first, then input
type alias CheckProductCodeExists =
    ProductCode -> Result String ()

type alias CheckAddressExists =
    Address -> Result String ()

type alias ValidateOrder =
    CheckProductCodeExists
    -> CheckAddressExists
    -> UnvalidatedOrder
    -> Result String ValidatedOrder

validateOrder : ValidateOrder
validateOrder checkProduct checkAddress unvalidated =
    Debug.todo "implement"

-- "Inject" concrete dependencies via partial application (currying)
validateOrderStep : UnvalidatedOrder -> Result String ValidatedOrder
validateOrderStep =
    validateOrder checkProductCodeExists checkAddressExists
```

This is **dependency inversion without interfaces**! We've inverted the dependency (the function depends on abstractions, not concretions), and we can easily substitute different implementations for testing or different environments.

### Why This Respects Clean Architecture

This approach aligns with dependency inversion in a minimal, practical way:

- **High-level policy stays pure and unaware of infrastructure** (e.g., `ValidateOrder` knows nothing about a database)
- **Both sides depend on function types, not concretes** (e.g., `CheckProductCodeExists`)
- **Abstractions remain stable while implementations vary** (swap different impls for prod/tests)

Unlike traditional OOP DI, we avoid IoC containers, interfaces, and lifecycle management. The type system and partial application do the heavy lifting.

## Phantom Types: Compile-Time Filtering

Phantom types let us "color" values without runtime cost. They're used to separate elements that shouldn't be mixed. Here's an elegant example where "green cars" and "polluting cars" are distinguished using a type parameter:

```elm
type Car fuel
    = ElectricCar
    | HydrogenCar
    | DieselCar

type Green = Green
type Polluting = Polluting

electricCar : Car fuel
electricCar = ElectricCar

dieselCar : Car Polluting
dieselCar = DieselCar

createGreenCarFactory : (data -> List (Car Green)) -> Factory
createGreenCarFactory build =
    -- implementation irrelevant; signature forbids diesel
    Debug.todo "..."
```

The key is that `electricCar` is polymorphic (`Car fuel`) and can therefore behave as "green" when required, while `dieselCar` is locked to `Polluting` and rejected by the compiler where "green" is expected.

### Process Flow as State Machine with Phantom Types

Phantom types also work well for modeling process flows where order must be correct, without creating a maze of intermediate types:

```elm
type Step step
    = Step Order

type Start = Start
type WithTotal = WithTotal
type WithQuantity = WithQuantity
type Done = Done

start : Order -> Step Start

setTotal : Int -> Step Start -> Step WithTotal
adjustQuantityFromTotal : Step WithTotal -> Step Done
setQuantity : Int -> Step Start -> Step WithQuantity
adjustTotalFromQuantity : Step WithQuantity -> Step Done

done : Step Done -> Order

-- Two legal flows
flowPrioritizingTotal : Int -> Order -> Order
flowPrioritizingTotal total order =
    start order
        |> setTotal total
        |> adjustQuantityFromTotal
        |> done

flowPrioritizingQuantity : Int -> Order -> Order
flowPrioritizingQuantity quantity order =
    start order
        |> setQuantity quantity
        |> adjustTotalFromQuantity
        |> done
```

The signatures prevent us from skipping steps or mixing order. This gives the advantage of a state machine—with compiler checking—without explosion of separate intermediate types.

## Another example using Phantom Builders with Extensible Records

Builders can also be type-secured so that necessary steps must be taken in the right order—before a "finished" object can be produced–using "extensible records" (`{ a | whateverTraitOrPropNeededOrGiven : () }`). A big thanks to one of my Elm heroes Jeroen Engels for [introducing this pattern in a very clear way in this video](https://www.youtube.com/watch?v=Trp3tmpMb-o).

```elm
module Button exposing (Button, new, withDisabled, withOnClick, withText, withIcon, toHtml)

type Button constraints msg
    = Button (List (Html.Attribute msg)) (List (Html msg))

-- Start state: we MUST choose an interaction (onClick OR disabled)
new : Button { needsInteractivity : () } msg
new =
    Button [] []

withDisabled :
    Button { c | needsInteractivity : () } msg
    -> Button { c | hasInteractivity : () } msg
withDisabled (Button attrs children) =
    Button (Html.Attributes.disabled True :: attrs) children

withOnClick :
    msg
    -> Button { c | needsInteractivity : () } msg
    -> Button { c | hasInteractivity : () } msg
withOnClick message (Button attrs children) =
    Button (Html.Events.onClick message :: attrs) children

withText :
    String
    -> Button c msg
    -> Button { c | hasTextOrIcon : () } msg
withText str (Button attrs children) =
    Button attrs (Html.text str :: children)

toHtml :
    Button { c | hasInteractivity : (), hasTextOrIcon : () } msg
    -> Html msg
toHtml (Button attrs children) =
    Html.button (List.reverse attrs) (List.reverse children)
```

Simply put, this ensures that a button _either_ has an onclick _or_ is disabled before allowing it to build. No runtime validation, just extensible record with "traits" or props that indicate their process state. The signatures do the work: `toHtml` cannot be called until we've satisfied both requirements. We can choose order freely, and we can add more "markings" later without changing existing users.

## Practical Checklist for "Impossible States"

- Define sum types for states that would otherwise be booleans that can be combined incorrectly
- Create rich domain values (newtypes/aliases) for "important strings" like Email, UUID, NonEmpty, NonNegative, etc.
  - Use "smart constructors" internally and don't expose type constructors
- Parse at boundaries (IO/HTTP/DB)—give the rest of the system safe types
- Use phantom types to distinguish subgroups that shouldn't be mixed
- Think building sequences as types (phantom builder) when order matters
- Apply partial application for functional dependency injection

## Testing and Compiler Assistance

With strong types and rich domain models, the compiler takes much of the burden of ensuring illegal states cannot exist. This reduces the need for manual tests, since many errors are already caught at compile time.

Testing is still important for ensuring logic behaves as expected, but the compiler helps us eliminate a large class of errors that would otherwise be difficult to find and fix. Instead of testing that "user cannot be both logged in and logged out," the type system guarantees this state simply cannot exist.

## When Is This Worth It?

This is especially valuable in systems where robustness, predictability, and maintainability are important. When the consequences of error states are significant—whether for users, business, or security—it pays to model the domain so that illegal states become impossible at compile time.

As they say about writing tests: just do it where you don't want the application to fail...

## Functional Architecture in Practice

The combination of rich types and functional dependency injection gives us a powerful architecture pattern:

1. **Domain layer**: Pure functions with rich types, dependencies as function parameters
2. **Application layer**: Compose domain functions using partial application to inject dependencies
3. **Infrastructure layer**: Implement the actual dependency functions (database access, external APIs, etc.)

This creates a clean separation where the domain layer has no knowledge of infrastructure concerns, yet we avoid the complexity of traditional dependency injection frameworks.

## Conclusion

Typed functional languages make it both possible and natural to move validation from runtime to compile time. With sum types, rich domain values, phantom types, and functional dependency injection, we can achieve models that simply don't let us represent illegal states.

This approach gives us simpler code, safer refactoring, and fewer production errors. As system complexity continues to grow and robustness becomes increasingly critical, techniques for making impossible states impossible become more relevant than ever.

The compiler becomes our most trusted teammate—one that never gets tired, never misses edge cases, and works 24/7 to ensure our domain models stay consistent and correct.

## References

- [Parse, don't validate – Alexis King @ Lexi Lambda](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)
- [Single out elements using phantom types – Jeroen Engels](https://jfmengels.net/single-out-elements-using-phantom-types)
- [Making impossible states impossible (video)](https://www.youtube.com/watch?v=IcgmSRJHu_8)
- [Phantom Builder Pattern (video)](https://www.youtube.com/watch?v=Trp3tmpMb-o&t=377s)
- [Domain Modeling Made Functional – Scott Wlaschin](https://amzn.to/4loKAlq)
- [Elm Patterns – Process flow using phantom types](https://sporto.github.io/elm-patterns/advanced/flow-phantom-types.html)
- [Elm Radio: Phantom Builders (podcast episode)](https://elm-radio.com/episode/phantom-builder/)
