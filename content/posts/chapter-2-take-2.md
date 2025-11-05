---
title: "Chapter 2, Take 2: Why I Changed Course"
date: 2025-10-30T00:00:00+02:00
slug: "chapter-2-take-2"
description: "Rewriting Chapter 2 to focus on discipline by construction over side‑by‑side comparisons, and how early reader feedback shaped the new approach."
tags: ["elm", "react", "functional-programming", "writing", "book-notes"]
aliases: ["/posts/elm-architecture-vs-react-side-by-side"]
draft: false
---

I’m rewriting Chapter 2 of my upcoming book, [An Elm Primer for React Developers](https://leanpub.com/elm-for-react-devs).

Not because the original was "wrong"", but because the frame was off. I started by putting Elm and React side by side, trying to show “the Elm way” next to “the React way.” It felt tidy. It also pushed me into an awkward corner: either I write React the way I used to (which would undercut credibility with seasoned React developers), or I write the best React I can with everything I’ve learned from years in Elm (which would quietly disprove half my own argument). That tension is the point of this rewrite.

This chapter is about what React developers can learn from Elm—not about arguing that Elm is better than React.

### Early Access, Real Feedback

Opening drafts early was the best decision I’ve made on this project. Readers called out places where I was “winning” with Elm by quietly applying discipline I had learned in Elm back into the React examples—making the comparison feel stacked. Others asked sharper questions: “Is the goal to prove Elm beats React, or to teach people to think functionally?” That feedback changed Chapter 2.

The new approach acknowledges something simple and important: a disciplined React app can be excellent. With care, you can avoid the traps. But that’s the rub—React (and more broadly JS/TS) gives you a lot of rope: escape hatches, caveats, and footguns you can manage if you’re careful. Elm removes those options by design. The difference isn’t outcome—disciplined teams can produce great results in both. The difference is slope: how easy is it to slip when you’re tired, rushed, onboarding, or juggling complexity?

### Why Not Side‑by‑Side?

Side‑by‑side examples encourage a “who did it better?” posture. That’s not the useful question. The useful question is: which environment makes it harder to accidentally do the wrong thing?

React gives you choices: mutable vs. immutable patterns, implicit vs. explicit effects, runtime vs. compile‑time checks, types that are tight vs. types that leak `any` or `unknown`, escape hatches like `as` casts, optional chaining that masks branches you should handle, dependency arrays that let stale closures creep in. These are not React’s “fault”; they’re the nature of a flexible ecosystem designed to work for many teams and constraints.

Elm, by contrast, constrains you. Mutation is off the table. Side effects must be explicit. All branches must be handled. The compiler won’t let you move on until you’ve made your intent precise. You can’t “just ship it” with a maybe‑it’s‑fine type hole; the compiler blocks the door until you’ve resolved the ambiguity.

So instead of “React vs. Elm,” the rewrite is “discipline by convention vs. discipline by construction.”

### What the New Chapter Does

- Clarifies the goal: teach functional discipline in a way that sticks, not win a framework duel.
- Shows realistic paths to success in React—and why the slope is steeper.
- Highlights the unique advantage of Elm: it removes entire categories of mistakes up front.
- Uses examples targeted at common pains React developers feel, then shows how Elm removes the sharp edges.

### The Nuance That Matters

- The point isn’t that a “perfect” Elm app is better than a “perfect” React app. If you’re deliberate and thoughtful in React, you can build something just as robust.
- The point is that Elm makes sloppy patterns a non‑option. Many things that are “easy mistakes” in JS/TS simply cannot compile in Elm.
- In React, being disciplined is a choice you must repeatedly make. In Elm, it’s the default you must actively opt out of (which you can’t, most of the time).

That difference is what gives Elm its teaching power. You’re not memorizing rules; you’re building muscle memory under constraints that align with functional principles. Once learned, those habits transfer back to React and JS/TS.

### Why I’m Writing It This Way Now

- Honesty: I don’t want to “win” via strawmen or outdated React. You deserve the best version of both worlds.
- Practicality: You shouldn’t have to memorize guardrails to avoid common pitfalls. Elm bakes the guardrails in.
- Transfer: The discipline you learn in Elm is portable. You’ll use it in React, TypeScript, Rust—anywhere.

So, without more fuzz: Here is the _new_ Chapter 2! Enjoy 🤓

---

## The New Chapter 2

In the last chapter, we explored _why_ Elm's constraints enable freedom from bugs. We talked about immutability, exhaustive checking, and compile-time guarantees. Now let's see what those principles look like in actual code.

**Note**: All code examples from this book are available at [github.com/cekrem/elm-primer-code-examples](https://github.com/cekrem/elm-primer-code-examples), where you can browse, download, and run them locally.

If you've been using React for a while, you're familiar with the constant sense of making architectural decisions. Should this be a hook or a reducer? Do I need context here? Should I memoize this callback? Every feature brings a small avalanche of choices, and while that flexibility is powerful, it can also be exhausting.

Elm takes a radically different approach: it gives you exactly one architecture. Not one _recommended_ architecture, but literally one. Every Elm application—whether it's a simple widget or a 100,000-line production codebase—follows the same pattern. The Elm Architecture (TEA) is built into the language itself.

This might sound limiting at first. But consider: when there's only one way to do things, you spend less time making decisions and more time solving actual problems. The cognitive load drops dramatically. And surprisingly, this single pattern scales beautifully.

> **Elm Hook**
>
> React hooks like useState, useReducer, useEffect, useMemo, and useCallback solve problems that don't exist in Elm. [The Elm Architecture](https://guide.elm-lang.org/architecture/) handles state, effects, and optimization by design. Keep reading to see how!

## The Recipe: Four Simple Ingredients

Every Elm application is built from exactly four pieces. Think of them as ingredients in a recipe—each one has a specific purpose, and when combined, they create something greater than their parts.

Here's the complete recipe:

1. **Model** - What data does your app need?
2. **Msg** - What events can happen?
3. **update** - How does your state change?
4. **view** - How do you display your state?

That's it. No hooks, no context, no effects management, no memoization. Just these four pieces. Let's look at each one in isolation before we put them together.

> **A Note Before We Begin**
>
> This chapter shows complete code examples to illustrate the architectural patterns. Don't worry about setting up Elm or typing this yourself yet—that's what Chapter 3 is for. Right now, just focus on understanding the patterns. Think of this as a guided tour before you get hands-on. You'll be writing Elm code yourself very soon.

## Ingredient 1: Model - Your State Shape

The `Model` defines _all_ the state in your application. In React terms, it's like combining all your `useState` and `useReducer` state into a single data structure.

Here's the simplest possible model:

```elm
type alias Model =
    { count : Int
    }
```

This is a type alias that says "Model is a record with one field: count, which is an Int." No null, no undefined—just an integer.

**In React, you might write:**

```typescript
interface Model {
  count: number;
}
```

Similar, right? But there's a key difference: in Elm, this type is enforced _everywhere_. You can't accidentally set `count` to a string or forget to initialize it, nor can you typecast it as anything else. The compiler checks every usage.

Here's a slightly more interesting model:

```elm
type alias Model =
    { count : Int
    , history : List Int
    }
```

Now we're tracking both the current count and its history. Still just a data structure—no logic, no methods, just pure data.

**What you'd recognize from React:** This is like defining your component's state shape, but for your entire application. Similar to how Redux has a single state tree, or how you might structure a `useReducer` state object.

## Ingredient 2: Msg - Things That Can Happen

In React, when a button is clicked, you call a function that directly updates state. In Elm, you create a _message_ that describes what happened.

```elm
type Msg
    = Increment
    | Decrement
```

This isn't a string or an enum—it's a union type. `Msg` can be _exactly_ one of these values: `Increment` or `Decrement`. Nothing else.

Messages can carry data too:

```elm
type Msg
    = Increment
    | Decrement
    | SetCount Int
```

Now `SetCount` carries an integer. When you create a `SetCount` message, you _must_ provide a number. The type system enforces this.

Here's a more interesting example:

```elm
type Msg
    = Increment
    | Decrement
    | Undo
    | Reset
```

We've added `Undo` and `Reset` messages. Notice how each message is a distinct value—you can't confuse them or misspell them. The compiler knows exactly what messages exist in your application.

**What you'd recognize from React:** If you've used Redux or `useReducer`, you've seen action types. Messages are similar, but they're compiler-checked union types instead of string constants. You can't dispatch a message that doesn't exist.

## Ingredient 3: update - How State Changes

The `update` function is where all your business logic lives. It takes a message and the current model, and returns a new model.

```elm
update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            { model | count = model.count + 1 }

        Decrement ->
            { model | count = model.count - 1 }
```

Read that type signature: "update takes a Msg and a Model, and returns a Model." It's a pure function—same inputs always give same outputs.

The `case` expression does pattern matching on the message. If it's `Increment`, create a new model with count increased by 1. The `{ model | count = ... }` syntax means "create a new record that's a copy of model, but with count changed."

This isn't mutation—it's creating a new value. The old model is unchanged.

**What you'd recognize from React:** This is exactly like a reducer in `useReducer` or Redux:

```typescript
function reducer(state: Model, action: Msg): Model {
  switch (action.type) {
    case "INCREMENT":
      return { ...state, count: state.count + 1 };
    case "DECREMENT":
      return { ...state, count: state.count - 1 };
  }
}
```

Same pattern! But again, in Elm the compiler forces you to handle _all_ cases. Miss one, and your code won't compile. And though even React beginners know better than to mutate state within a reducer by now, it's still _possible_, and can lead to all manner of undefined behavior; In Elm it's impossible to mutate.

## Ingredient 4: view - Rendering Your State

The `view` function takes your model and returns HTML. It's a pure function—just data in, HTML out.

```elm
view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (String.fromInt model.count) ]
        , button [ onClick Increment ] [ text "+" ]
        ]
```

The type signature says "view takes a Model and returns Html that can produce Msg values." When you click the button, it creates an `Increment` or `Decrement` message.

**What you'd recognize from React:** This is your component's render function:

```typescript
function Counter({ count, onIncrement, onDecrement }) {
  return (
    <div>
      <button onClick={onDecrement}>-</button>
      <div>{count}</div>
      <button onClick={onIncrement}>+</button>
    </div>
  );
}
```

The difference? Elm's `view` is guaranteed to be pure. No side effects, no direct state updates. Just: model goes in, HTML comes out.

## Putting It All Together: Counter with Undo

Now let's combine these four ingredients into a complete application. We'll build a counter that tracks its history and supports undo.

Here's the full code (also available in the book's code repository at [02_counter_undo](https://github.com/cekrem/elm-primer-code-examples/tree/main/02_counter_undo)):

```elm

module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


-- MODEL


type alias Model =
    { count : Int
    , history : List Int
    }


init : Model
init =
    { count = 0
    , history = []
    }


-- MSG


type Msg
    = Increment
    | Decrement
    | Undo
    | Reset


-- UPDATE


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            { count = model.count + 1
            , history = model.count :: model.history
            }

        Decrement ->
            { count = model.count - 1
            , history = model.count :: model.history
            }

        Undo ->
            case model.history of
                [] ->
                    model

                previousCount :: rest ->
                    { count = previousCount
                    , history = rest
                    }

        Reset ->
            init


-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ button [ onClick Decrement ] [ text "-" ]
            , div [] [ text (String.fromInt model.count) ]
            , button [ onClick Increment ] [ text "+" ]
            ]
        , div []
            [ button [ onClick Undo ] [ text "Undo" ]
            , button [ onClick Reset ] [ text "Reset" ]
            ]
        , div [] [ text ("History: " ++ String.fromInt (List.length model.history) ++ " items") ]
        ]


-- MAIN


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }
```

We store the current count and a list of previous counts. When you increment or decrement, we save the old value before changing it.

### Messages Describe All Possible Actions

```elm
type Msg
    = Increment
    | Decrement
    | Undo
    | Reset
```

Four things can happen in this app. Nothing else. The compiler knows this.

### Update Handles Each Case Explicitly

```elm
update : Msg -> Model -> Model
update msg model =
    -- you can "case match" on a union type like `Msg`:
    case msg of
        Increment ->
            { count = model.count + 1
            , history = model.count :: model.history
            }

        Decrement ->
            { count = model.count - 1
            , history = model.count :: model.history
            }

        Undo ->
            -- ...and you can case match on a list,
            -- handling empty lists differently than non-empty ones:
            case model.history of
                -- If there's no history:
                [] ->
                    model

                -- If there's at least one entry (`previousCount`):
                previousCount :: rest ->
                    { count = previousCount
                    , history = rest
                    }

        Reset ->
            init


```

Notice the `Undo` case: we pattern match on the history. If it's empty, do nothing. If it has items, extract the previous count and the rest of the list. This is exhaustive—we handle both possibilities.

The `::` operator prepends an item to a list. So `model.count :: model.history` means "create a new list with the current count at the front, followed by the existing history."

### View Renders Based on Model

```elm
view : Model -> Html Msg
view model =
    div []
        [ div []
            [ button [ onClick Decrement ] [ text "-" ]
            , div [] [ text (String.fromInt model.count) ]
            , button [ onClick Increment ] [ text "+" ]
            ]
        , div []
            [ button [ onClick Undo ] [ text "Undo" ]
            , button [ onClick Reset ] [ text "Reset" ]
            ]
        , div [] [ text ("History: " ++ String.fromInt (List.length model.history) ++ " items") ]
        ]
```

Pure function. Model goes in, HTML comes out. No hooks, no effects, no memoization needed.

## The Elm Runtime Loop

Here's what happens when you run this application:

1. Elm calls `init` to get the initial model: `{ count = 0, history = [] }`
2. Elm calls `view` with that model to generate HTML
3. Elm renders the HTML to the page
4. User clicks the "+" button
5. The button's `onClick Increment` creates an `Increment` message
6. Elm calls `update Increment model`
7. `update` returns a new model: `{ count = 1, history = [0] }`
8. Elm calls `view` again with the new model
9. Elm efficiently updates only the changed parts of the DOM
10. Back to step 4, waiting for the next interaction

You never write this loop yourself. You just provide three pure functions (`init`, `update`, `view`), and Elm handles the rest.

## What React Developers Already Know

If you've used React for a while, TEA will feel familiar:

**useState → Model**
Instead of spreading state across multiple hooks, you define one data structure.

**useReducer → update**
If you've used reducers, you already understand `update`. Same pattern: take current state and an action, return new state. The difference is that Elm's pattern matching makes it impossible to miss a case.

**Props and callbacks → Msg**
Instead of passing callbacks down through props, you dispatch messages. Events flow up as messages, not function calls.

**Redux → TEA**
Redux was literally inspired by Elm. Dan Abramov saw TEA and brought those ideas to React. The difference? Redux is a library you add on top of React. TEA is built into Elm—you can't _not_ use it.

## What Makes TEA Different

Here's what you get that React doesn't provide by default:

**One way to do things**
No debate about hooks vs reducers vs context. Every Elm app uses TEA. This removes cognitive load—you don't spend time choosing patterns.

**Impossible to forget a case**
Add a new message? The compiler tells you every place you need to handle it. Can't forget, can't miss one.

**No scattered logic**
All business logic lives in `update`. No logic in event handlers, no side effects in render, no effects synchronizing state. One place, clear flow.

**Pure functions everywhere**
`update` and `view` are pure functions—same inputs always give same outputs. This makes testing trivial and reasoning straightforward.

**Type-safe messages**
You can't dispatch a message that doesn't exist. You can't forget to include data a message needs. The types enforce correctness.

## The Price of Explicitness

TEA is more explicit than React. You write out every case. You define your messages up front. You can't just add an inline handler that updates state directly.

This explicitness trades verbosity for safety. The counter example above is about 80 lines. In React with hooks, you might do it in 40 lines.

But here's the thing: as your application grows, that explicitness scales beautifully. The 80-line Elm app uses the same patterns as a 100,000-line Elm app. There's no complexity cliff, no point where you need to refactor to Redux or introduce new patterns.

In [The Pragmatic Programmer](https://amzn.to/3Lk4wtr), Andy Hunt and Dave Thomas argue that good design is whatever makes your code **Easy To Change**. TEA is incredibly easy to change because:

1. The compiler guides you through every change
2. All state changes flow through one function
3. Pure functions are trivial to test
4. Pattern matching forces explicit handling

You write more code up front, but you spend less time debugging, refactoring, and hunting down edge cases.

## What You Just Learned (The FP Hiding in Plain Sight)

As you explored The Elm Architecture, you learned core functional programming concepts without realizing it:

**Pure functions**
Both `update` and `view` are pure—same inputs always give same outputs. No hidden state, no side effects.

**Immutability**
You never mutate the model. You always create new values. The `{ model | count = ... }` syntax creates a new record.

**Algebraic data types**
The `Msg` type is a union type (also called a sum type). It says "a Msg is one of these options, and nothing else."

**Pattern matching**
The `case` expression destructures data and forces you to handle all possibilities. The compiler checks exhaustiveness.

**Explicit state transitions**
State doesn't change in random places. It flows through one function: `update`. This makes state changes predictable and testable.

These are the same concepts you'd learn in Haskell, F#, OCaml, or Clojure. But you learned them by building a working UI, not by studying academic papers.

## What's Next

In this chapter, you learned The Elm Architecture: the four ingredients that every Elm application uses. You saw how Model, Msg, update, and view work together to create reliable, predictable applications.

But we've only scratched the surface. The counter example used `Browser.sandbox`, which can't talk to the outside world. No HTTP requests, no random numbers, no JavaScript interop – or in Elm terms: No `Cmd`s (commands). That's coming in later chapters.

In Chapter 3, you'll build your first Elm app and experience the compiler-driven workflow firsthand. You'll set up your environment, write code, and see how the compiler guides you to working solutions.

The theory is helpful, but the real learning happens when you write Elm yourself.

---

That's better, right? Thanks to everyone who read the early drafts and told me where it rang false or felt slanted. That feedback made this rewrite necessary—and better.

If you’ve got more thoughts, I’m still listening.
