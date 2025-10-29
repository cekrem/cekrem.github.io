+++
title = "The Same App in React and Elm: A Side-by-Side Comparison"
description = "Understanding The Elm Architecture through a practical Hangman game implementation, compared directly to React patterns"
date = "2025-10-29"
tags = ["elm", "react", "functional programming", "typescript", "architecture"]
draft = false
+++

A few weeks ago, I [announced I'm writing a book about Elm for React developers](https://cekrem.github.io/posts/elm-book-announcement/). The response has been encouraging, so here's a full chapter from the book, showing what The Elm Architecture looks like in practice—side-by-side with React.

(The formatting is slightly nicer in the actual book, but Hugo does a decent job as well.)

I've currently finished the introduction (published [here](https://cekrem.github.io/posts/elm-book-announcement/)) and chapters 1-6. I don't plan on adding all, and not in sequence, but some of it will appear on this blog.

What follows is **Chapter 2**:

---

In the [introduction](https://cekrem.github.io/posts/elm-book-announcement/), we explored _why_ Elm's constraints enable freedom from bugs. We talked about immutability, exhaustive checking, and compile-time guarantees. Now let's see what those principles look like in actual code.

If you've been using React for a while, you're familiar with the constant sense of making architectural decisions. Should this be a hook or a reducer? Do I need context here? Should I memoize this callback? Every feature brings a small avalanche of choices, and while that flexibility is powerful, it can also be exhausting.

Elm takes a radically different approach: it gives you exactly one architecture. Not one _recommended_ architecture, but literally one. Every Elm application—whether it's a simple widget or a 100,000-line production codebase—follows the same pattern. The Elm Architecture (TEA) is built into the language itself.

This might sound limiting at first. But consider: when there's only one way to do things, you spend less time making decisions and more time solving actual problems. You stop debating architecture and start building features. And surprisingly, this single pattern scales beautifully.

Let's see what this looks like in practice.

> **Elm Hook**
>
> React hooks like useState, useReducer, useEffect, useMemo, and useCallback solve problems that don't exist in Elm. [The Elm Architecture](https://guide.elm-lang.org/architecture/) handles state, effects, and optimization by design. Keep reading to see how!

## A Tale of Two Hangman Games

To understand the difference between React patterns and The Elm Architecture, we're going to build the same application twice: a simple Hangman game. The requirements are straightforward:

- Display a word with blanks for unguessed letters
- Show a clickable alphabet for guessing
- Track remaining attempts
- Show win/lose states
- Allow starting a new game

This is simple enough to understand fully, but complex enough to expose the real differences between React and Elm approaches.

> **A Note Before We Begin**
>
> This post shows complete code examples to illustrate the architectural differences. Don't worry about setting up Elm or typing this yourself yet—that's what Chapter 3 is for (available in the [book on Leanpub](https://leanpub.com/elm-for-react-devs)). Right now, just focus on understanding the patterns. Think of this as a guided tour before you get hands-on.

## The React Version: Clean and Minimal

Here's a well-written React implementation using hooks and TypeScript (about 90 lines total). This represents _good_ React code—minimal state, computed derived values, no premature optimization:

```typescript
import { useState } from "react";

const MAX_LIVES = 6;

type GameStatus = "playing" | "won" | "lost";

interface HangmanProps {
  initialWord?: string;
}

const Hangman = ({ initialWord = "FUNCTIONAL" }: HangmanProps) => {
  const [wordToGuess] = useState(initialWord);
  const [guessedLetters, setGuessedLetters] = useState<Set<string>>(new Set());

  // Compute derived state
  const wrongGuesses = Array.from(guessedLetters).filter(
    (letter) => !wordToGuess.includes(letter)
  ).length;

  const livesRemaining = MAX_LIVES - wrongGuesses;

  const hasWon = wordToGuess
    .split("")
    .every((char) => guessedLetters.has(char));
  const hasLost = livesRemaining <= 0;
  const gameStatus: GameStatus = hasWon ? "won" : hasLost ? "lost" : "playing";

  const displayWord = wordToGuess
    .split("")
    .map((char) => (guessedLetters.has(char) ? char : "_"))
    .join(" ");

  const handleGuess = (letter: string) => {
    if (gameStatus !== "playing" || guessedLetters.has(letter)) return;
    setGuessedLetters(new Set([...guessedLetters, letter]));
  };

  const handleNewGame = () => {
    setGuessedLetters(new Set());
  };

  const alphabet = Array.from({ length: 26 }, (_, i) =>
    String.fromCharCode(65 + i)
  );

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: "1rem",
      }}
    >
      <h1>Hangman</h1>

      {gameStatus === "won" && <div>🎉 You Won!</div>}
      {gameStatus === "lost" && (
        <div>😞 Game Over! The word was: {wordToGuess}</div>
      )}

      <div>{displayWord}</div>
      <div>Lives remaining: {livesRemaining}</div>

      <div>
        {alphabet.map((letter) => {
          const isGuessed = guessedLetters.has(letter);
          const isDisabled = isGuessed || gameStatus !== "playing";

          return (
            <button
              key={letter}
              onClick={() => handleGuess(letter)}
              disabled={isDisabled}
            >
              {letter}
            </button>
          );
        })}
      </div>

      <button onClick={handleNewGame}>New Game</button>
    </div>
  );
};

export default Hangman;
```

If you're an experienced React developer, you might appreciate the design here: only two pieces of state (`wordToGuess` and `guessedLetters`), everything else derived on-demand. No `useEffect` for state synchronization, no defensive `useMemo`. Clean and straightforward.

But even this well-designed version has inherent complexity:

1. **Scattered game logic**: Win/loss conditions computed inline, state guards in event handlers, derived values throughout the component
2. **Recomputation on every render**: Five computed values (`wrongGuesses`, `livesRemaining`, `hasWon`, `hasLost`, `gameStatus`, `displayWord`) recalculate even when nothing changed
3. **Manual state guards**: `if (gameStatus !== 'playing') return;` must be remembered in the right places
4. **No protection against invalid state**: Nothing prevents adding non-alphabet characters to `guessedLetters`, or setting impossible game states
5. **Logic coupled to rendering**: Game rules live inside the component, making them harder to test and reuse

None of these are dealbreakers. This is genuinely good React code. But it's still _complexity_, and with complexity comes cognitive load. You have to think about where logic lives, what recomputes when, and which guards you need.

> **A Note on Real-World React Code**
>
> The version above represents well-thought-out React—minimal state, no premature optimization. But in my experience reviewing production codebases, this isn't always what you encounter. More often, you'll see:
>
> - `useEffect` synchronizing derived state (checking win conditions in an effect rather than computing them)
> - Defensive `useMemo` and `useCallback` "just in case" it's needed later
> - Multiple pieces of state that could be derived (separate `livesRemaining` and `gameStatus` states)
> - `useReducer` for anything beyond trivial state (which is closer to Elm, but more verbose)
>
> These patterns emerge naturally as teams grow, deadlines loom, and developers take the "safe" route of explicit state management. The simplified version here required deliberate design decisions. Even so, the architectural differences we're about to explore apply equally to both the optimized and the typical React patterns.

## The Elm Version: Model, Msg, Update, View

Now let's see the same game in Elm.

> **Elm's Syntax: A Quick Primer**
>
> In addition to the differences in architecture and level of constraints, Elm's syntax undeniably looks different from JavaScript. No curly braces, no parentheses around function arguments, no commas between parameters. It takes some getting used to, but it's surprisingly clean once you see the pattern.
>
> Here's how it works:
>
> ```elm
> -- Define a function
> add : Int -> Int -> Int
> add x y = x + y
>
> -- Call it (no parentheses, no commas)
> sum = add 1 2  -- 3
> ```
>
> In JavaScript, this would be: `const add = (x, y) => x + y`
>
> Same idea, different notation. But not quite same after all, there's a trick: Elm functions only ever take one argument. When you write `add x y`, you're really calling `add` with `x`, which returns a new function that takes `y`. This is called currying, and it enables partial application:
>
> ```elm
> add10 = add 10
> result = add10 5  -- 15
> ```
>
> You can create specialized functions by leaving off arguments. We'll put this to use in a later chapter; for now, read `f x y z` as "call `f` with `x`, then `y`, then `z`."
>
> There are other things that might look foreign too—like the pipe operator `|>` you'll see in the code below—but we'll cover those as we go.
>
> **Bottom line for now: Don't let the syntax trip you up; focus on the patterns.**

Here's the Hangman game in Elm. Read through once to get a feel, then we'll break down each section:

```elm
module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Set exposing (Set)



-- MAIN


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init defaultOptions
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { wordToGuess : String
    , guessedLetters : Set Char
    , gameStatus : GameStatus
    }


type GameStatus
    = Playing Int -- This simple Int represents livesRemaining
    | Won
    | Lost


type alias Options =
    { word : String
    , lives : Int
    }


defaultOptions : Options
defaultOptions =
    { word = "FUNCTIONAL"
    , lives = 6
    }


init : Options -> Model
init { word, lives } =
    { wordToGuess = word |> String.toUpper
    , guessedLetters = Set.empty
    , gameStatus = Playing lives
    }



-- UPDATE


type Msg
    = GuessLetter Char
    | NewGame


update : Msg -> Model -> Model
update msg model =
    case ( msg, model.gameStatus ) of
        -- NewGame msg resets game, always
        ( NewGame, _ ) ->
            init defaultOptions

        -- GuessLetter is handled when in `Playing` state
        ( GuessLetter letter, Playing currentLives ) ->
            -- Already guessed this letter? Do nothing
            if model.guessedLetters |> Set.member letter then
                model

            else
                -- New letter guessed? Handle game logic
                let
                    newGuessedLetters =
                        model.guessedLetters |> Set.insert letter

                    isCorrectGuess =
                        model.wordToGuess |> String.contains (letter |> String.fromChar)

                    livesRemaining =
                        if isCorrectGuess then
                            currentLives

                        else
                            currentLives - 1

                    newGameStatus =
                        if
                            model.wordToGuess
                                |> String.toList
                                |> List.all (\correctChar -> newGuessedLetters |> Set.member correctChar)
                        then
                            Won

                        else if livesRemaining <= 0 then
                            Lost

                        else
                            Playing livesRemaining
                in
                { model
                    | guessedLetters = newGuessedLetters
                    , gameStatus = newGameStatus
                }

        -- GuessLetter is a noop when already won
        ( GuessLetter _, Won ) ->
            model

        -- GuessLetter is a noop when already lost
        ( GuessLetter _, Lost ) ->
            model



-- VIEW


view : Model -> Html Msg
view model =
    Html.div
        [ Attr.style "display" "flex"
        , Attr.style "flex-direction" "column"
        , Attr.style "align-items" "center"
        , Attr.style "gap" "1rem"
        ]
        [ Html.h1 [] [ Html.text "Hangman" ]
        , viewGameStatus model
        , viewWord model
        , viewLivesRemaining model
        , viewAlphabet model
        , Html.button [ Events.onClick NewGame ] [ Html.text "New Game" ]
        ]


viewGameStatus : Model -> Html Msg
viewGameStatus model =
    case model.gameStatus of
        Playing _ ->
            Html.text ""

        Won ->
            Html.div [] [ Html.text "🎉 You Won!" ]

        Lost ->
            Html.div [] [ Html.text ("😞 Game Over! The word was: " ++ model.wordToGuess) ]


viewWord : Model -> Html Msg
viewWord model =
    let
        displayWord =
            model.wordToGuess
                |> String.toList
                |> List.map
                    (\char ->
                        if model.guessedLetters |> Set.member char then
                            char

                        else
                            '_'
                    )
                |> List.intersperse ' '
                |> String.fromList
    in
    Html.div [] [ Html.text displayWord ]


viewLivesRemaining : Model -> Html Msg
viewLivesRemaining model =
    case model.gameStatus of
        Playing lives ->
            Html.div [] [ Html.text ("Lives remaining: " ++ String.fromInt lives) ]

        _ ->
            Html.text ""


viewAlphabet : Model -> Html Msg
viewAlphabet model =
    let
        isDisabled letter =
            (model.guessedLetters |> Set.member letter)
                || (case model.gameStatus of
                        Playing _ ->
                            False

                        _ ->
                            True
                   )
    in
    Html.div []
        (List.range 65 90
            |> List.map Char.fromCode
            |> List.map
                (\letter ->
                    Html.button
                        [ Events.onClick (GuessLetter letter)
                        , Attr.disabled (isDisabled letter)
                        ]
                        [ Html.text (String.fromChar letter) ]
                )
        )
```

The Elm version is about a hundred lines longer than the React version, but let's see what those extra lines buy us:

## Breaking Down The Elm Architecture

Let's look at the four key sections of any Elm application:

### 1. The Model: Your Single Source of Truth

```elm
type alias Model =
    { wordToGuess : String
    , guessedLetters : Set Char
    , gameStatus : GameStatus
    }


type GameStatus
    = Playing Int  -- Int is livesRemaining
    | Won
    | Lost
```

The `Model` is a type alias that describes _all_ the state in your application. There's no spreading state across multiple hooks—it's all in one place. And look at that `GameStatus` type: it's not a string literal like React's `'playing' | 'won' | 'lost'`, it's a proper union type. The compiler knows _exactly_ what values are possible.

But here's the clever part: notice how `Playing` carries an `Int` while `Won` and `Lost` don't? This is **making impossible states impossible**. In the React version, we had separate state variables for `gameStatus` and `livesRemaining`, which meant these invalid states were technically representable:

- `gameStatus = 'playing'` with `livesRemaining = 0` (should be lost)
- `gameStatus = 'lost'` with `livesRemaining = 5` (contradictory)
- `gameStatus = 'won'` with `livesRemaining = -1` (nonsensical)

In Elm, we've encoded the business rule directly in the type: only playing games have lives remaining. Won and lost games are finished—they don't need a life count. The type system prevents these contradictions from ever being expressed in code. You can't accidentally create them, and you can't forget to check for them.

We could of course go even further and make a fully computational game state. Something like this would be a valid approach:

```elm
type alias Model =
    { wordToGuess : String
    , guessedLetters : Set Char
    , livesRemaining : Int
    }

gameStatus : Model -> GameStatus
gameStatus model =
    if wordIsComplete model then
        Won
    else if model.livesRemaining <= 0 then
        Lost
    else
        Playing model.livesRemaining
```

In this alternative design, we'd store `livesRemaining` in the model but compute the game status on demand. Either way, you're still using The Elm Architecture—these are design choices within the architecture, not different architectures. The key insight is that Elm gives you type-safe tools to prevent invalid states, whether through smart type design or computed properties.

### 2. Messages: Things That Can Happen

```elm
type Msg
    = GuessLetter Char
    | NewGame
```

Instead of event handlers that directly manipulate state, Elm uses messages. A message is a value that represents something that happened in your UI. When a user clicks a letter button, you don't immediately update state—you create a `GuessLetter 'A'` message.

### 3. Update: The State Transition Function

```elm
update : Msg -> Model -> Model
update msg model =
    case ( msg, model.gameStatus ) of
        ( NewGame, _ ) ->
            init defaultOptions

        ( GuessLetter letter, Playing currentLives ) ->
            -- handle the guess, extract current lives...

        ( GuessLetter _, Won ) ->
            model

        ( GuessLetter _, Lost ) ->
            model
```

This is where all your business logic lives. The `update` function takes the current state and a message, and returns the new state. It's a pure function—no side effects, no hidden mutations. Notice how we pattern match on _both_ the message _and_ the game status? When the game is `Playing`, we extract the `currentLives` right in the pattern match. This makes it impossible to forget to handle a case. If you add a new `GameStatus` value, the compiler will force you to handle it everywhere.

This pattern matching replaces all those manual guards in the React version. You can't accidentally handle a guess when the game is over—the types won't let you.

> **💡 If This Looks Familiar...**
>
> Remember how React has evolved toward functional patterns? Redux was directly inspired by The Elm Architecture. Dan Abramov saw how Elm handled state updates and brought those ideas to React. The difference? In Redux, immutability and pure reducers are conventions you have to maintain. In Elm, they're enforced by the compiler. You already know this pattern; Elm just makes it impossible to break.

### 4. View: Rendering Your Model

```elm
view : Model -> Html Msg
view model =
    Html.div []
        [ Html.h1 [] [ Html.text "Hangman" ]
        , viewGameStatus model
        , viewWord model
        , viewLivesRemaining model
        , viewAlphabet model
        , Html.button [ Events.onClick NewGame ] [ Html.text "New Game" ]
        ]
```

The view is also a pure function. It takes your model and returns HTML. No hooks, no effects, no memoization. Just `Model` → `Html`. When your model changes, Elm automatically re-renders efficiently.

> **How The Elm Runtime Works**
>
> Here's what happens when you run an Elm application:
>
> 1. The Elm runtime calls your `init` function to get the initial model
> 2. It calls `view` with that model to generate HTML
> 3. It renders the HTML to the page
> 4. It waits for user interactions (clicks, key presses, etc.)
> 5. When a user interaction occurs, it creates a `Msg`
> 6. It calls your `update` function with the message and current model
> 7. `update` returns a new model
> 8. It calls `view` again with the new model
> 9. It efficiently updates only the changed parts of the DOM
> 10. Back to step 4
>
> You never write this loop yourself. You just provide the three pure functions (`init`, `update`, `view`), and Elm handles the rest. No `useEffect` to manage, no lifecycle methods, no manual DOM updates.

## What Did We Gain?

Let's compare what we had to think about in each version:

**React version:**

- Multiple computed values recalculating on every render
- Game logic scattered across inline computations and event handlers
- Manual guards to prevent invalid actions (`if (gameStatus !== 'playing')`)
- No compile-time protection against invalid state (wrong letters in `guessedLetters`, contradictory game states)
- Testing requires mounting the component or extracting logic to separate functions

**Elm version:**

- One immutable model that changes atomically
- All game logic centralized in the `update` function
- Pattern matching that forces handling all cases
- Impossible states prevented by the type system
- Pure functions that are trivial to test in isolation

The Elm version is more explicit—you write out every case. But that explicitness comes with safety. You can't forget to handle a state. You can't mutate data accidentally. You can't represent impossible states. The compiler has your back.

## Computed State vs Centralized Logic

Look back at the React code. We compute game status inline on every render:

```typescript
const hasWon = wordToGuess
  .split("")
  .every((char) => guessedLetters.has(char));
const hasLost = livesRemaining <= 0;
const gameStatus: GameStatus = hasWon ? "won" : hasLost ? "lost" : "playing";
```

This is fine for a small component, but as your app grows, this pattern leads to game logic scattered throughout your components. Testing requires either mounting the component or extracting these computations to separate utility functions.

In Elm, this logic lives in the `update` function, right where state changes happen:

```elm
newGameStatus =
    if
        model.wordToGuess
            |> String.toList
            |> List.all (\correctChar -> newGuessedLetters |> Set.member correctChar)
    then
        Won
    else if livesRemaining <= 0 then
        Lost
    else
        Playing livesRemaining
```

When you guess a letter, we check the win condition _right there_ and return a new model with the updated status. No effects, no dependency arrays. Just pure logic. And notice how `Playing` carries the `livesRemaining` value—our type structure keeps the data right where it belongs.

## Union Types vs String Literals

TypeScript gives you string literal union types:

```typescript
type GameStatus = "playing" | "won" | "lost";
```

This is better than plain JavaScript, but it's still just strings at runtime. You can accidentally compare to the wrong string, or forget a case in your conditionals.

Elm's union types are compiler-enforced:

```elm
type GameStatus
    = Playing
    | Won
    | Lost
```

These aren't strings—they're distinct values. The compiler forces exhaustive pattern matching. If you add a fourth state, every `case` statement in your codebase will fail to compile until you handle it. You literally cannot forget a case.

## The Price of Simplicity

Let's be honest: the Elm version is longer. About 210 lines vs React + TypeScript's 111. Some of that is Elm's more explicit syntax (type annotations, `case` statements), and some is Elm's use of whitespace for structure.

But length isn't the right metric. In _The Pragmatic Programmer_, Andy Hunt and Dave Thomas argue that the overarching architectural principle should be ETC: **Easy To Change**. Good design, they say, is _whatever makes your code easier to change in the future_.

So the real question isn't "which is shorter?" but "which is easier to change without breaking?"

Consider what happens when you need to add a new feature—say, a "Pause" game state:

**In React with TypeScript**, you'd need to:

- Add `'paused'` to your type (TypeScript will catch some usage, but not all)
- Update every conditional that checks game status
- Make sure all `useEffect` dependencies are still correct
- Hunt down every place that sets game status
- Hope you didn't miss any edge cases (TypeScript won't help with logic bugs)

**In Elm**, you'd:

- Add `Paused` to the `GameStatus` union type
- Watch the compiler tell you _exactly_ which `case` statements are now incomplete
- Handle each case one by one, guided by compiler errors
- Compile, and you're done—if it compiles, it works. The compiler is your to-do list.

The Elm version is more explicit, yes. But that explicitness makes change safer. In React with TypeScript, you can still call `setGameStatus('won')` from anywhere, forget to check game status before handling a guess, get dependency arrays wrong, or accidentally mutate state. None of these are possible in Elm—the compiler prevents them, even as the code evolves over time.

## What This Means for Real Applications

This Hangman game is small—a few hundred lines. But The Elm Architecture scales. Whether you're building a game, a dashboard, or a full SPA, you're still using `Model`, `Msg`, `update`, and `view`. The pattern doesn't change.

At Lovdata, we have about 125,000 lines of Elm in production. It's all The Elm Architecture. And it works. New team members don't need to learn six different ways to manage state or debate whether to use Context or Redux. There's one way, and it's the same in every file.

I remember reviewing a junior developer's PR last month—their first Elm feature. The code was good. Not "good for a beginner," just _good_. Because the compiler guided them to the right patterns. They couldn't make the mistakes that would've been easy in React. **That** is what "reliability by design" means in practice.

## The Three Functions That Replace All Hooks

Remember the Elm Hook from the start of this post?

> _In React, you reach for `useState`, `useReducer`, `useEffect`, `useMemo`, `useCallback`, and more. In Elm, three functions—`init`, `update`, and `view`—replace all of them._

Here's how:

- **`init`** replaces: `useState` initial values, constructor logic, initialization
- **`update`** replaces: `useState` setters, `useReducer`, event handlers, state transition logic
- **`view`** replaces: the component render function (with automatic optimization)

You don't need `useCallback` because there are no closures to worry about. You don't need `useRef` because you can't mutate anyway. You don't need `useMemo` because Elm's virtual DOM efficiently handles recomputation. You don't need `useEffect` for state synchronization because state transitions are explicit and centralized. You don't need `useContext` because... well, that's covered in later chapters of the book.

## The FP Concepts You Just Learned

As you explored The Elm Architecture, you encountered core functional programming concepts:

- **Pure functions**: `update` and `view` are pure—same inputs always give same outputs
- **Immutability**: Data never changes; you always create new values
- **Explicit state transitions**: State flows through one function, not scattered mutations
- **Algebraic data types**: Union types and pattern matching for bulletproof modeling

These patterns transfer directly to Haskell, F#, OCaml, Clojure, and better JavaScript. You're learning production FP by building real UIs.

## What's Next

This comparison barely scratches the surface. How do you handle HTTP requests in Elm? What about complex forms with validation? How do you integrate Elm into an existing React codebase? These questions (and many more) are covered in the book.

If you found this interesting and want to go deeper:

- Check out the book on [Leanpub](https://leanpub.com/elm-for-react-devs) for early access to all chapters
- Subscribe to my newsletter below for updates when new chapters are published here
- Try mentally walking through adding features to both versions—maybe a "Pause" game state, or a hint button

The complete code examples shown above work as-is. To actually run them, you'll need to set up your development environment—which is what Chapter 3 covers in the book.

For now, just sit with this: what would it be like to build an application where the compiler catches state bugs _before_ they reach production? Where there's no debate about architecture because there's only one way? Where your tests don't need to mock state updates because update functions are just pure functions?

That's the promise of The Elm Architecture.

---

**All code examples from this series are available at [github.com/cekrem/elm-primer-code-examples](https://github.com/cekrem/elm-primer-code-examples)**, where you can browse, download, and run them locally.
