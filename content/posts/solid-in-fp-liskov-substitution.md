+++
title = "SOLID in FP: Liskov Substitution, or The Principle That Was Never About Inheritance"
description = "Revisiting LSP through a functional lens – turns out it was never about what we thought it was about"
tags = ["elm", "functional-programming", "SOLID", "architecture"]
date = 2026-03-02
draft = false
+++

[Last time](/posts/solid-in-fp-open-closed/), I said Liskov Substitution would require "some even heftier reframing." I was bracing myself – LSP is built around inheritance, and Elm doesn't have inheritance. How do you reframe a principle about something that doesn't exist?

Turns out I was worried about the wrong thing entirely.

![How the turntables...](https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExem5pamQ1c3pzdDl5bmt5bTRsd2sweXEzZnFtbzI2MmVqaDNtZjh2cyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/fQorEj8vN8eqkNcy6T/giphy.gif)

## It was never about inheritance

Here's Uncle Bob, who popularized this stuff:

> "People (including me) have made the mistake that this is about inheritance. It is not. It is about sub-typing."

He goes on: all implementations of interfaces are subtypes. All duck-types are subtypes of an _implied_ interface. And his updated definition is refreshingly blunt:

> "A program that uses an interface must not be confused by an implementation of that interface."

Not "subclasses must behave like their parent class." Not anything about `extends` or `override`. Just: if your code expects a thing to work a certain way, every version of that thing better actually work that way. Otherwise, Uncle Bob warns, `if/switch` statements will start proliferating – the calling code starts checking "wait, what did I _actually_ get?" instead of trusting the abstraction.

I'll be honest: when I read this, I felt a bit silly about [my earlier Kotlin post](/posts/liskov-substitution-the-real-meaning-of-inheritance/) on the topic. It's not _wrong_, but I spent the whole thing talking about inheritance hierarchies when the actual principle is broader than that. Live and learn, I guess.

## The violations that can't happen

That Kotlin post used the classic Rectangle/Square example. You know the one – `Square` extends `Rectangle`, setting `width` silently also sets `height`, and suddenly:

```kotlin
rectangle.width = 4
rectangle.height = 5
assert(rectangle.area() == 20) // 💥 Fails for Square!
```

This literally cannot happen in Elm. No mutation. Setting a field returns a new record; the old one stays untouched. There is no mechanism for setting one field to secretly affect another.

And the other greatest hits of LSP violations? Can't throw unexpected exceptions – Elm doesn't have exceptions. Can't return null – Elm doesn't have null. Can't silently ignore methods you inherited – there's nothing to inherit.

## So it's just... free?

The structural stuff, yeah. Pretty much. The part that catches the majority of real-world LSP violations in OOP codebases is handled by the language. You don't need contract tests for it. You don't need discipline. The compiler won't let you ship broken substitutions.

But there's a catch. (There's always a catch.)

**Semantic contracts** are still on you. The type system tells you the _shape_. It can't tell you the _meaning_.

Here's what I mean:

```elm
type alias DiscountStrategy =
    Order -> Float


loyaltyDiscount : DiscountStrategy
loyaltyDiscount order =
    if order.customerYears > 5 then
        0.1

    else
        0.0


seasonalDiscount : DiscountStrategy
seasonalDiscount _ =
    0.15
```

Both compile. Both fit the type. Swap one for the other and the compiler won't blink.

Now someone adds:

```elm
surpriseUpcharge : DiscountStrategy
surpriseUpcharge order =
    -0.2
```

Still compiles. Still a valid `DiscountStrategy`. But any code expecting a value between 0 and 1 is in for a bad time. That's an LSP violation – the implementation "confuses" the caller, exactly what Uncle Bob warned about.

![Kevin's chili. Everything falls apart.](https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExMnhmcHR4Y3F2cHR0cXB3ZXEyZDJxeGV6ZGd0enNpaTd0YmhjamphOCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/g0mCv3FF2XFdDShr8v/giphy.gif)

## Closing the gap: [make illegal states unrepresentable](https://functional-architecture.org/make_illegal_states_unrepresentable/)

But here's the thing – Elm _does_ give you tools to push semantic contracts into the type system. The trick is to stop using `Float` and make a proper type instead:

```elm
module Discount exposing (Discount, fromFloat, toFloat)


type Discount
    = Discount Float


fromFloat : Float -> Maybe Discount
fromFloat value =
    if value >= 0 && value <= 1 then
        Just (Discount value)

    else
        Nothing


toFloat : Discount -> Float
toFloat (Discount value) =
    value
```

Because `Discount` is an opaque type (the constructor isn't exported), the _only_ way to create one is through `fromFloat`. And `fromFloat` returns `Maybe` – you literally can't construct an invalid discount. The semantic contract that was previously just in your head? It's in the type system now.

```elm
type alias DiscountStrategy =
    Order -> Discount
```

`surpriseUpcharge` can't even be written anymore. `Discount.fromFloat -0.2` returns `Nothing`, and the calling code has to deal with that. No discipline required; the compiler handles it.

I've written about this pattern before in [Making Impossible States Impossible](/posts/making-impossible-states-impossible-with-functional-dependency-injection/), and it's one of those things that keeps surprising me with how far you can take it. The more of your domain you encode this way, the smaller the surface area for LSP violations becomes. You're basically trading semantic contracts (which live in documentation and hope) for type-level contracts (which live in the compiler).

## What FP actually gives you

Elm makes most LSP violations structurally impossible. For the semantic stuff that remains, opaque types and smart constructors let you push those contracts into the type system too. You _can_ still mess things up – naming a function `discount` when it's really an upcharge is always possible – but the attack surface is tiny compared to OOP, where you can violate LSP through mutation, exceptions, null, side effects, and inheritance hierarchies seven levels deep.

(And we all know how well documentation and discipline hold up at 11pm on a Thursday.)

---

Up next: Interface Segregation – another principle that sounds very OOP, in a language with neither interfaces nor classes. These keep getting more fun.
