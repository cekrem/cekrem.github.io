---
title: "The Elm Architecture vs React's useReducer, or 'Same Loop, Different Guarantees'"
date: 2025-09-18
description: "A practical comparison of The Elm Architecture and React's useReducer: how they map conceptually, where they differ in guarantees, and what to watch out for when scaling apps."
tags: ["elm", "react", "usereducer", "architecture", "state-management"]
draft: true
---

I love how often smart engineers arrive at the same shape of solution from different directions. The Elm Architecture (TEA) and React's `useReducer` are a great example: two ecosystems, one mental model.

But this isn't a "which one is better" piece.

Instead, this is a side‑by‑side look at the same loop expressed in two worlds—what maps neatly, what absolutely doesn't, and how the guarantees you get change the way you structure code at scale.

## The Loop We All Build

At heart, both TEA and `useReducer` revolve around a simple loop:

1. A message/action happens
2. You compute a new state
3. You render that state
4. You perform effects that cause more messages/actions

In Elm, this loop is explicit and enforced. In React, it's conventional and flexible.

### Elm

```elm
module Counter exposing (Model, Msg(..), init, update, view, subscriptions)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)

type alias Model =
    { count : Int }

type Msg
    = Increment
    | Decrement

init : () -> ( Model, Cmd Msg )
init _ =
    ( { count = 0 }, Cmd.none )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }, Cmd.none )

        Decrement ->
            ( { model | count = model.count - 1 }, Cmd.none )

view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (String.fromInt model.count) ]
        , button [ onClick Increment ] [ text "+" ]
        ]

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none
```

### React with useReducer

```jsx
import { useReducer } from "react";

const initialState = { count: 0 };

const Action = {
  Increment: { type: "Increment" },
  Decrement: { type: "Decrement" },
};

const reducer = (state, action) => {
  switch (action.type) {
    case "Increment":
      return { ...state, count: state.count + 1 };
    case "Decrement":
      return { ...state, count: state.count - 1 };
    default:
      return state;
  }
};

export const Counter = () => {
  const [state, dispatch] = useReducer(reducer, initialState);

  return (
    <div>
      <button onClick={() => dispatch(Action.Decrement)}>-</button>
      <div>{state.count}</div>
      <button onClick={() => dispatch(Action.Increment)}>+</button>
    </div>
  );
};
```

Same idea. Different enforcement.

## Effects: `Cmd` vs `useEffect`

Effects are where the similarities carry you 80% of the way and then the last 20% decides your production story.

- **Elm `Cmd Msg`**: declarative, described in pure code, executed by the runtime, results come back as `Msg` via the same update loop.
- **React `useEffect`**: imperative side‑effects run after render; you orchestrate async work yourself and call `dispatch` when ready.

### Elm: fetch on click

```elm
type Msg
    = Fetch
    | Fetched (Result Http.Error String)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fetch ->
            ( model
            , Http.get
                { url = "/api/greeting"
                , expect = Http.expectString Fetched
                }
            )

        Fetched (Ok txt) ->
            ( { model | greeting = txt }, Cmd.none )

        Fetched (Err _) ->
            ( { model | greeting = "Oops" }, Cmd.none )
```

No mutation leaks, no forgotten cleanup. The runtime guarantees ordering and cancellation semantics.

### React: fetch on click

```jsx
const reducer = (state, action) => {
  switch (action.type) {
    case "Fetch":
      return { ...state, loading: true };
    case "Fetched":
      return { ...state, loading: false, greeting: action.payload };
    case "FetchFailed":
      return { ...state, loading: false, error: true };
    default:
      return state;
  }
};

const fetchGreeting = async (dispatch, signal) => {
  try {
    const res = await fetch("/api/greeting", { signal });
    const txt = await res.text();
    dispatch({ type: "Fetched", payload: txt });
  } catch (e) {
    if (e.name !== "AbortError") dispatch({ type: "FetchFailed" });
  }
};

export const Greeting = () => {
  const [state, dispatch] = useReducer(reducer, {
    loading: false,
    greeting: "",
    error: false,
  });

  useEffect(() => {
    if (!state.loading) return;
    const controller = new AbortController();
    fetchGreeting(dispatch, controller.signal);
    return () => controller.abort();
  }, [state.loading]);

  return (
    <button onClick={() => dispatch({ type: "Fetch" })}>
      {state.loading ? "Loading..." : state.greeting || "Load"}
    </button>
  );
};
```

It works well—but the discipline is on you. Cleanup, idempotency, and avoiding render‑effect feedback loops are not enforced by the framework.

## Where They Map 1:1

- **Model/State**: Elm `Model` ↔ React reducer state.
- **Msg/Action**: Elm `Msg` union ↔ React action objects.
- **Update/Reducer**: Pure function, input is message/action and old state; output is new state.
- **View**: Elm `Html Msg` ↔ React JSX with `dispatch` passed through.

If you stick to those, `useReducer` feels very Elm‑ish.

## Where Guarantees Diverge

- **Type system**: Elm's `Msg` is an exhaustive union with compiler‑enforced handling. React needs TypeScript and discipline; you can still forget cases or widen to `any`.
- **Side‑effects**: Elm turns effects into data (`Cmd`) processed by the runtime. React executes effects directly in `useEffect`, making ordering, cancellation and concurrency your responsibility.
- **Global invariants**: Elm prevents invalid states by construction ("make impossible states impossible"). React can emulate via types and state modeling, but nothing stops you from sprinkling additional `useState` that bypasses your reducer.
- **Refactoring safety**: Elm's compiler becomes your pair programmer. In React, the compiler helps if you invest in strict TypeScript and ESLint rules.
- **Debugging/time travel**: Elm debugger is built‑in. React has excellent devtools but time travel depends on external tooling and reducer purity.

## Scaling the Codebase

Both approaches scale, but the pressure points differ.

- **Elm**

  - Break large modules into feature modules with their own `Model/Msg/update/view` and compose.
  - Use the pattern championed by Richard Feldman (see the `elm-spa-example`) to keep message routing explicit.
  - JSON decoding/encoding is explicit; friction up‑front, fewer surprises later.

- **React**
  - Co‑locate reducers per feature; lift them into context providers when shared.
  - Guard against reducer bypass: prefer reducer‑only state for domain data, `useState` only for purely local UI details.
  - Encapsulate effects in custom hooks that dispatch actions, mirroring Elm `Cmd` modules.

## Common Foot‑guns (and How to Avoid Them)

- **Effect leaks**

  - Elm: runtime handles cancellation; your job is to model messages.
  - React: always return a cleanup from `useEffect`, and use `AbortController` for fetch.

- **Invalid states**

  - Elm: encode impossible states in types (e.g., `type RemoteData a = NotAsked | Loading | Success a | Failure`).
  - React: mirror that with discriminated unions in TypeScript and a single reducer.

- **Reducer escape hatches**
  - Elm: not possible; all state changes flow through `update`.
  - React: avoid mixing `useState` that mutates the same domain; route through `dispatch`.

## Choosing for a Project

- **Choose Elm when** you want strong guarantees, explicitness by default, and a runtime that enforces the architecture. The learning curve is front‑loaded; the payoff is in refactoring safety and fewer production surprises.

- **Choose React + useReducer when** you need to integrate with a large React ecosystem, want flexibility, and are willing to enforce constraints via conventions, TypeScript, and linting.

Both can yield beautiful, maintainable systems if you design with the loop in mind and treat effects as first‑class concerns.

## A Handy Mapping Table

- **Elm `Model`**: React reducer state
- **Elm `Msg`**: React action (prefer discriminated unions in TS)
- **Elm `update`**: React reducer function
- **Elm `Cmd`**: React `useEffect` + async function that dispatches
- **Elm `subscriptions`**: React event sources (intervals, websockets) wrapped in `useEffect`
- **Elm ports**: Boundary to JS world ↔ React imperative escape hatches (but keep them at the edges)

## Closing Thought

Same loop. Different guarantees. If you adopt Elm's discipline inside React—single reducer per domain, discriminated unions, effects as data‑producers that funnel back through `dispatch`—you get most of TEA's clarity. If you adopt React's pragmatism inside Elm—clear module boundaries and small, composable features—you get most of the ergonomics people love about React.

Either way, design for change. Future‑you will thank present‑you.

---

_Further reading: Richard Feldman's `elm-spa-example` for project organization, and the React docs on `useReducer` and `useEffect` for effect modeling._
