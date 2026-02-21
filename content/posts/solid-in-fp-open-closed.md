+++
title = "SOLID in FP: Open-Closed, or Why I Love When Code Won't Compile"
description = "Revisiting OCP through a functional lens – union types give you a different kind of open-closed, enforced by the compiler rather than discipline"
tags = ["elm", "functional-programming", "SOLID", "architecture"]
date = 2026-02-20
draft = false
+++

In [the last post](/posts/solid-in-fp-single-responsibility/), I promised that the Open-Closed Principle would get interesting when reframed through union types and pattern matching. I may have slightly oversold it. But only slightly.

Quick definition: OCP says software entities should be _open for extension, closed for modification._ In the [React version of this](/posts/open-closed-principle-in-react/), the answer was composition — don't modify your `Button`, wrap it in a `PrimaryButton`. Extend from the outside, don't crack open the original. Good advice. The catch: nothing actually stops you from cracking it open. That discipline lives in your head, in code review, in team conventions that erode when deadlines hit.

Elm has a different take.

## The closed side: union types

Say you've got a notification type:

```elm
type Notification
    = Success String
    | Warning String
    | Error String
```

And a view function for it:

```elm
view : Notification -> Html msg
view notification =
    case notification of
        Success message ->
            div [ class "success" ] [ text message ]

        Warning message ->
            div [ class "warning" ] [ text message ]

        Error message ->
            div [ class "error" ] [ text message ]
```

Requirements change (they always do), and now you need an `Info` variant. You add it to the type:

```elm
type Notification
    = Success String
    | Warning String
    | Error String
    | Info String
```

The compiler's response is immediate:

```
Missing patterns! The following are not covered:
    Info _
  in function `view`
```

Not a runtime crash. Not a failing test (if you even wrote one for this, I wouldn't...). A compile error, before anything ships.

Calling this OCP is a stretch, honestly. Technically it's closer to the opposite: adding a variant forces you to modify every pattern match on that type across the codebase. But if you _do_ touch the type, the compiler walks you through every consequence. It finds every `case` expression that needs updating, across the whole codebase. You literally cannot forget one.

## The open side: just write a new function

The "open for extension" half is where Elm gets genuinely nice. Data types and functions are separate. Adding new operations on an existing type never requires touching the type itself:

```elm
-- Original function, untouched
view : Notification -> Html msg
view notification =
    case notification of
        Success message -> div [ class "success" ] [ text message ]
        Warning message -> div [ class "warning" ] [ text message ]
        Error message -> div [ class "error" ] [ text message ]
        Info message -> div [ class "info" ] [ text message ]


-- New operations, no modification needed
icon : Notification -> Html msg
icon notification =
    case notification of
        Success _ -> Icons.checkCircle
        Warning _ -> Icons.alertTriangle
        Error _ -> Icons.xCircle
        Info _ -> Icons.infoCircle


toLogLevel : Notification -> String
toLogLevel notification =
    case notification of
        Success _ -> "info"
        Warning _ -> "warn"
        Error _ -> "error"
        Info _ -> "info"
```

`view` didn't change. The type didn't change. New functions just appeared alongside the old ones. That's the "open" part.

## The trade-off (because there's always one)

Adding new variants is loud. If `Notification` is shared across ten modules and you add `Info`, you get ten compile errors to fix.

OCP in OOP is about preventing accidental breakage: don't touch existing code, because you can't trust yourself to get it right at 11pm. Elm's version of that deal is different. Touch whatever you want, but you can't be incomplete about it.

In OOP, adding a new subtype is quiet — existing code doesn't know or care. Adding new _operations_ is loud — you might have to update an interface and all its implementations. In FP with union types, it's flipped: new operations are free, new variants are loud (but safely loud).

This trade-off has a name — the "expression problem" — and neither approach wins universally. But for typical application code, UIs, domain models, state machines, you add new operations far more often than new variants. And when you do add variants, you really don't want to forget a case handler somewhere. The compiler noise is a feature. One I really love, at that!

## vs. the React approach

In [the React post](/posts/open-closed-principle-in-react/), OCP looked like this:

```tsx
const NotificationBase = ({ message, className }: Props) => (
  <div className={`notification ${className}`}>{message}</div>
);

const SuccessNotification = (props) => (
  <NotificationBase {...props} className="success" />
);

const InfoNotification = (props) => (
  <NotificationBase {...props} className="info" />
);
```

Extending is easy. Forgetting to update the icon map, or the analytics handler, or the toast duration logic when you add a new variant? Also easy. Nothing reminds you.

Compare to the Elm version: add a variant, get compile errors. Fix the errors, you're done. The compiler is the discipline.

I know which one I trust more at 11pm on a Friday.

---

Up next: Liskov Substitution — a principle built around inheritance hierarchies, in a language that doesn't have inheritance. That one's going to require some even heftier reframing.
