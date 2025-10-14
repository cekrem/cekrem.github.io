---
title: "Elm Land, Shared Subscriptions, and the Art of Workarounds"
date: 2025-10-14
description: "When you need to react to Shared model changes in Elm Land - is it a real problem, an architectural flaw, or just a sign you're modeling things wrong?"
tags:
  ["elm", "elm-land", "architecture", "functional-programming", "html-helpers"]
draft: false
---

## The Problem That Shouldn't Exist

Here's a question that comes up occasionally in Elm Land projects: _How do I react when something in the `Shared` model changes?_

It sounds simple enough. You have some global state in `Shared.Model` - maybe feature flags loaded from the backend, authentication status, or some configuration data. Your page needs to _do something_ when that data changes. Not just render differently (that's trivial), but actually perform an effect - fire off a new HTTP request, trigger some side effect locally, or whatever.

And here's where things get interesting: Elm Land doesn't give you a built-in way to do this.

This is either:

1. A legitimate missing feature in Elm Land
2. An architectural flaw in how Elm Land structures applications
3. A sign that you're modeling your state wrong in the first place

Which is it?

## Three Schools of Thought

When this question comes up in the Elm community, you tend to get three different types of responses:

**The Workaround Camp**: "Duplicate the state in your page model and manually diff against `Shared.Model` to detect changes. Or use ports to send messages through JavaScript." Both work, both feel hacky (especially the ports stuff, it gives me the creeps!).

**The Framework Camp**: "This is a known limitation. Elm Land 1.0 will have better support for custom subscriptions - something like a `withOnSharedChange` hook similar to `withOnUrlChange`. But that's not here yet, so in the meantime, don't be afraid to fork the framework and add the hooks you need."

**The Architecture Purist Camp**: "Needing to 'notify' pages of shared state changes is an anti-pattern. Message passing between modules with encapsulated state leads to complexity and tight coupling. The real solution is to model your state differently - use function composition, extensible records, and flatten your state model."

Which camp I'm in is not the point, and I won't tell you (it's the last one, though). But I do like being part of the/a solution, so I found myself being quite the pragmatic when we suddenly faced this issue at my client's.

Lo and behold, the new [`sendMsgWhen`](https://package.elm-lang.org/packages/cekrem/html-helpers/latest/HtmlHelpers#sendMsgWhen) in my `html-helpers` package.

## The new sendMsgWhen helper

Here's how you use it (but, like the box says: I'm not certain you even should...):

```elm
view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Items Page"
    , body =
        [ sendMsgWhen (shared.items /= model.prevSharedItems) SharedItemsChanged
        , viewItems (model.items ++ shared.items)
        ]
    }


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        SharedItemsChanged ->
            ( { model | prevSharedItems = shared.items }, openBannerEffect "New global items, time to celebrate!" )
      -- {...other cases}


```

When there's a diff between `shared.items` and `model.prevSharedItems`, a `SharedItemsChanged` message gets sent, and your `update` function can handle it like any other message - fire off a new HTTP request, update local state, whatever you need.

### How It Works (/destroys the internet, YMMV)

The implementation is extremely hacky:

```elm
sendMsgWhen : Bool -> msg -> Html msg
sendMsgWhen condition msg =
    lazyWhen condition
        (\() ->
            Html.img
                [ Attributes.style "display" "none !important"
                , Attributes.src "data:,"
                , Events.on "load" (Decode.succeed msg)
                , Events.on "error" (Decode.succeed msg)
                ]
                []
        )
```

It creates an invisible `<img>` element with an empty data URL. The browser immediately fires either the `load` or `error` event (depending on how well the browser likes the `"data:,"` part), which we catch and turn into our message. It's using the browser's event loop to dispatch a message during rendering.

![Kelly from the office](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZWhzOGZtdzlwam9zb3J0ajFzeG9kcnVwNG45Mnh1bWN6czQwNXRuciZlcD12MV9naWZzX3NlYXJjaCZjdD1n/IOxeKSBoyhsE8/giphy.gif)

Is it elegant? No. Is it a proper solution? Definitely not. Does it work? Absolutely. I think.

(You can see the [full source on GitHub](https://github.com/cekrem/html-helpers/blob/9371f55bc11b0f3d9edb579bcb002b7010051b4c/src/HtmlHelpers.elm#L436) if you want to judge me further.)

## The Trade-offs

Let's be honest about what this is:

**Pros:**

- No ports required (stays in pure Elm land)
- No manual diffing in `update` that runs on _every_ message
- Explicit about what changes you're tracking
- Works with the current version of Elm Land
- Doesn't require forking Elm Land

**Cons:**

- Relies on browser implementation details
- Feels hacky (because it is, very much so)
- Sends messages from the view layer without user interaction (traditionally a no-no!)
- Could be abused if you're not careful (it's important to remember to update that `model.prevSharedItems` entry!)
- Becomes unnecessary when Elm Land 1.0 adds proper hooks?
- **It's crazy!**

## When Is This Actually Needed?

**Here's the thing I keep coming back to: _How often is this actually even a problem?_**

In most Elm Land apps I've worked on, the `Shared` model contains:

- Current user/auth state
- Global UI state (sidebar open/closed, theme, etc.)
- Maybe some cached data

And pages mostly just _read_ from `Shared.Model` to render things differently. They don't need to _react_ to changes with effects.

There _are_ scenarios where the current limitations are a problem, but it's also somewhat rare. And when it does come up, there are often modeling approaches that avoid the whole problem:

1. **Delay initialization**: Don't initialize the page until critical shared data is loaded
2. **Re-fetch on change**: If the data is cheap to fetch, just re-fetch it every time the view renders with new shared data (this is actually fine for many cases)
3. **Model the waiting**: Make your page model explicitly represent the "waiting for shared data" state

These all feel like workarounds too, in their own way. But they're workarounds that push you toward clearer state modeling, which has value.

## The Bigger Question

What bothers me most about this whole situation is the uncertainty. Is needing to react to `Shared` changes a code smell? Or is it a legitimate pattern that frameworks should support?

I'm inclined to agree with my betters who argue that "message passing between modules with encapsulated state is an anti-pattern" and that we should use function composition and extensible records instead. The classic Richard Feldman approach from [Scaling Elm Apps](https://www.youtube.com/watch?v=DoA4Txr4GUs).

## My Current Take

Here's some pragmatic idealism for you:

1. **Most of the time**, if you feel like you need subscriptions to `Shared` changes, you probably need to rethink your state modeling. The Elm Architecture really is powerful enough to handle most cases cleanly.

2. **Sometimes**, you have a legitimate edge case where shared state changes need to trigger effects, and fighting against that creates more complexity than just handling it directly.

3. **Elm Land 1.0** will probably provide better primitives for this (when it arrives), making both the workarounds and some of the modeling gymnastics unnecessary.

In the meantime, I'm okay (I think?) with pragmatic hacks like `sendMsgWhen` for those rare cases where you really need them. But I'm also treating them as a code smell - a sign that maybe I should look harder at my state modeling before reaching for the workaround.

## The Honest (lack of?) Conclusion

I don't have a clean answer here. This isn't a post where I tell you "the right way" to handle this problem (although you might have noticed I've let slip a few hints that this shouldn't even be an issue if we just model our apps right in the first place!).

If you're hitting this issue in your Elm Land app, here are your options:

1. **Rethink your state model** - Maybe you can avoid the problem entirely with better modeling
2. **Wait for Elm Land 1.0** - If you can afford to wait, proper hooks are coming
3. **Use a workaround** - Ports, manual diffing, or `sendMsgWhen` all work
4. **Fork Elm Land** - Add the hooks you need; the framework is designed to be extensible

Each has trade-offs. Each is valid in different contexts. The "right" choice depends on your specific situation, timeline, and tolerance for hackery.

What I _am_ confident about: this is a great example of how framework constraints push us to think harder about our architecture. Even if Elm Land eventually adds `withOnSharedChange`, the conversation about _whether we should even need it_ is valuable. Let's enjoy it and learn from it, in any case!

Sometimes the best solution is a clever workaround. Sometimes it's better modeling. Sometimes it's both. But if you find yourself inventing an event buss using ports or writing code that looks like an Elmish Angular two-way-binding, you probably need to repent and start over :D

And for the record: I really like Elm land!
