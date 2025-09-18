---
title: "The Discipline of Constraints: What Elm Taught Me About React's useReducer"
date: 2025-09-18
description: "How enforced discipline in one language can teach you better patterns in another - lessons from crossing the Elm/React boundary"
tags: ["elm", "react", "usereducer", "architecture", "functional-programming"]
draft: false
---

## The Accidental Teacher

I've been thinking about discipline lately. Not the "wake up at 5 AM and eat nothing but kale" kind, but the more interesting variety: the kind that comes from working within constraints that make bad choices impossible.

After spending several months deep in Elm land - where the compiler is your strict but helpful mentor - I returned to a React codebase that was enthusiastically using `useReducer` everywhere. The whiplash was immediate and instructive.

You see, both approaches solve the same fundamental problem: managing complex state changes in a predictable way. But experiencing Elm's enforced discipline first made me realize just how much rope React gives you to hang yourself with - and, more importantly, how to avoid doing exactly that.

This isn't another "Elm vs React" post. This is about what happens when you take the lessons from a language that won't let you make mistakes and apply them to one that absolutely will.

## Same Shape, Different Guardrails

The patterns look almost identical at first glance:

```elm path=null start=null
-- Elm: The compiler ensures you handle every case
type Msg
    = LoadUser String
    | UserLoaded (Result Http.Error User)
    | UpdateName String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadUser id ->
            ( { model | loading = True }
            , Http.get { url = "/users/" ++ id, expect = Http.expectJson UserLoaded userDecoder }
            )

        UserLoaded (Ok user) ->
            ( { model | user = Just user, loading = False }, Cmd.none )

        UserLoaded (Err error) ->
            ( { model | error = Just error, loading = False }, Cmd.none )

        UpdateName name ->
            ( { model | user = Maybe.map (\u -> { u | name = name }) model.user }, Cmd.none )
```

```tsx path=null start=null
// React: You can handle every case... or not
type Action =
  | { type: "LOAD_USER"; id: string }
  | { type: "USER_LOADED"; user: User }
  | { type: "USER_FAILED"; error: string }
  | { type: "UPDATE_NAME"; name: string };

const reducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "LOAD_USER":
      return { ...state, loading: true };

    case "USER_LOADED":
      return { ...state, user: action.user, loading: false };

    case "USER_FAILED":
      return { ...state, error: action.error, loading: false };

    case "UPDATE_NAME":
      return {
        ...state,
        user: state.user ? { ...state.user, name: action.name } : state.user,
      };

    default:
      return state; // feel free to forget a case, nobody will tell you (or even know)
  }
};
```

Both follow the same mental model: messages/actions flow in, new state flows out, effects happen on the side. But there's a crucial difference hiding in that innocent-looking `default` case.

## The Tyranny of Choice

In Elm, if you add a new message variant and forget to handle it, your code simply won't compile. The type checker becomes your pair programming partner, gently (but firmly) reminding you about edge cases you've forgotten.

In React with TypeScript, you get some of this safety - the discriminated union helps, and if you're disciplined about your typing, you'll catch missing cases. But the `default` case is an escape hatch that's always available. And escape hatches have a way of being used.

Here's what I learned from going Elm → React: **the `default` case is where discipline goes to die.**

I lost count of how many React reducers I found that looked like this:

```tsx path=null start=null
const reducer = (state: State, action: any) => {
  switch (action.type) {
    case "LOAD_USER":
      return { ...state, loading: true };

    case "USER_LOADED":
      return { ...state, user: action.payload, loading: false };

    // ... a few more cases ...

    default:
      return state; // "Eh, we'll handle the rest later"
  }
};
```

That `any` type crept in because someone needed to add a quick action and didn't want to deal with TypeScript complaints. The `default` case silently swallows unhandled actions. You've gone from a system that forces you to think through every state transition to one that lets you sweep complexity under the rug.

Elm wouldn't have let this slide for a second.

## Effects: The Other Half of the Equation

But the real education came when dealing with side effects. In Elm, effects are data:

```elm path=null start=null
-- Elm: Effects are just data describing what should happen
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadUser id ->
            ( { model | loading = True }
            , Http.get {
                url = "/users/" ++ id
                , expect = Http.expectJson UserLoaded userDecoder
              }
            )
```

The `Cmd` value is a description of an effect to perform. The Elm runtime handles executing it, manages cancellation, and ensures results come back through your update function. You never escape the loop.

In React, effects are... well, effects:

```tsx path=null start=null
const UserProfile = ({ userId }: { userId: string }) => {
  const [state, dispatch] = useReducer(reducer, initialState);

  useEffect(() => {
    dispatch({ type: "LOAD_USER", id: userId });

    const controller = new AbortController();

    fetch(`/users/${userId}`, { signal: controller.signal })
      .then((response) => response.json())
      .then((user) => dispatch({ type: "USER_LOADED", user }))
      .catch((error) => {
        if (error.name !== "AbortError") {
          dispatch({ type: "USER_FAILED", error: error.message });
        }
      });

    return () => controller.abort();
  }, [userId]);

  // ... rest of component
};
```

You're back in the imperative world of manual cleanup, race condition management, and "did I remember to handle the error case?" The reducer gives you a nice pure core, but effects still happen in the messy, error-prone world of `useEffect`.

## The Lesson: Constraints Enable Creativity

What Elm taught me wasn't that React's approach is wrong - it's that discipline is a muscle that needs exercise. When the language forces you to be disciplined, you develop better habits. When it doesn't, you need to bring that discipline yourself.

After using Elm _every day_ at my client's, I found myself writing React code differently:

1. **Never use `any` in action types.** If TypeScript is complaining about your action shape, fix the types, don't silence the compiler.

2. **Never add a default case that just returns state.** If you're not handling an action, be explicit about it - throw an error or add a comment explaining why it's ignored.

3. **Encapsulate effects in custom hooks.** Create hooks that dispatch actions rather than performing effects directly in components.

```tsx path=null start=null
// Instead of mixing effects directly in components
const useFetchUser = (userId: string, dispatch: Dispatch<Action>) => {
  useEffect(() => {
    if (!userId) return;

    dispatch({ type: "LOAD_USER", id: userId });

    const controller = new AbortController();

    fetchUser(userId, controller.signal)
      .then((user) => dispatch({ type: "USER_LOADED", user }))
      .catch((error) => {
        if (error.name !== "AbortError") {
          dispatch({ type: "USER_FAILED", error: error.message });
        }
      });

    return () => controller.abort();
  }, [userId, dispatch]);
};
```

4. **Design invalid states out of existence.** Instead of separate booleans for `loading`, `error`, and `data`, use discriminated unions:

```tsx path=null start=null
type UserState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; user: User }
  | { status: "error"; error: string };
```

This prevents impossible states like `loading: true, error: "Something went wrong"` that can cause confusing UI states.

(More on that in [Making Impossible States Impossible with Functional Dependency Injection](/posts/making-impossible-states-impossible-with-functional-dependency-injection/).)

## The Deeper Pattern

The real insight isn't about Elm vs React - it's about constraint-driven design. Working in a language that makes certain mistakes impossible teaches you to recognize and avoid those same mistakes when they become possible again.

Elm's constraints taught me better patterns for `useReducer`. The compiler's insistence on totality made me more careful about edge cases. The enforced purity of the update function made me think harder about where effects belong.

## Bringing Elm's Discipline to React

If you've never tried Elm but work with `useReducer` (or Redux) regularly, here are some constraints I learned to impose on myself:

- **Exhaustive action handling**: Comment explicitly when you're intentionally ignoring an action.
- **Total state transitions**: Think through what should happen to every piece of state for every action.
- **Effect isolation**: Keep effects in custom hooks that communicate through dispatch.
- **Invalid state elimination**: Use TypeScript's discriminated unions to make impossible states unrepresentable.

You don't need Elm's compiler to enforce these patterns, but experiencing enforced discipline helps you recognize when you're being undisciplined.

(Actually, IMHO you _do_ need Elm's compiler; I'm trying not to sound Elm biased but who am I kidding 😆)

## The Craft Connection

This connects back to something I've been thinking about regarding [coding as craft](/posts/coding-as-craft-going-back-to-the-old-gym/). Master craftsmen often impose constraints on themselves - not because they have to, but because constraints force innovation and build skill.

The discipline I learned from Elm's compiler made me a better React developer. And I'm more mindful with Kotlin and Golang as well, even though most of that stuff isn't functional at all. The constraints didn't limit my creativity; they channeled it in more productive directions.

When you're building state management with `useReducer`, you're not just solving the immediate problem - you're practicing a way of thinking about state, time, and change. The habits you build in one context carry over to others.

The real question isn't "Which approach is better?" It's "What can I learn from this constraint that will make me better when the constraint is removed?"

Sometimes the best teacher is a language that simply won't let you make certain mistakes. Even if you never ship Elm to production, the lessons in discipline are worth the price of admission.

So even if you have no realistic prospect of using Elm (or Haskell, OCaml or any other ambitious functional language) professionally – learning might make you a better developer nonetheless.
