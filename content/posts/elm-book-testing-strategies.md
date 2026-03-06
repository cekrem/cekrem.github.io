+++
title = "An Elm Primer: Testing Strategies"
description = "TDD, fuzz testing, and why you write fewer tests in Elm but catch more bugs"
date = "2026-03-06"
tags = ["elm", "react", "functional programming", "book", "testing", "tdd"]
draft = false
+++

This chapter might be the most freeing one in the book. If you've spent real time writing React tests, you know the ritual: mocks, cleanup, async wrappers, `act()` warnings. In Elm, testing is just calling pure functions and checking the output.

Believe it or not, [the book](https://leanpub.com/elm-for-react-devs) is actually closing in on being finished. We're in Part IV now (Production Readiness), and the finish line is genuinely in sight. If you want to follow along for the final stretch, remember to subscribe.

(And as usual, the formatting is slightly more adequate in the actual book than on this Hugo blog, but we'll make do.)

---

# Chapter 15: Testing Strategies

> **Elm Hook**
>
> React testing demands mocks, async wrappers, and cleanup rituals just to verify basic behavior. In Elm, most of your code is pure functions: data in, data out, nothing else to account for. The result is fewer tests that catch more bugs, plus a fuzz testing framework built right into the standard tooling.

If you've tested React applications seriously, you know the overhead. `jest.mock()` for modules, `act()` for state updates, `waitFor()` for async operations, `cleanup()` after each test. You're spending real effort managing the test environment before you even get to the thing you want to verify. That overhead exists because React components have side effects: they touch the DOM, fire network requests, schedule timers, read from context. Your tests need to control all of it.

Elm doesn't have that problem. Your `update` function is a pure function. Your view is a pure function. Your decoders, validators, helpers: all pure functions. Testing a pure function means calling it with some input and checking the output. No setup, no teardown, no mocking.

Testing still matters in Elm. But you spend your time on things the type system can't express: business logic, edge cases, domain-specific properties. You stop testing what the compiler already guarantees.

## From Jest to elm-test

If you've used Jest, elm-test will feel immediately familiar. Install it and initialize a test directory:

```
npx elm-test init
```

This creates a `tests/` directory with a sample test file. Here's the smallest meaningful test in both frameworks, side by side.

Jest:

```javascript
describe("Math", () => {
  it("adds numbers", () => {
    expect(1 + 1).toEqual(2);
  });
});
```

elm-test:

```elm
suite : Test
suite =
    describe "Math"
        [ test "adds numbers" <|
            \_ ->
                (1 + 1)
                    |> Expect.equal 2
        ]
```

The structure maps almost one-to-one. `describe` groups tests. `test` defines a single case. `Expect.equal` is the assertion. The main syntactic difference is the `\_ ->` lambda. elm-test passes each test function a unit value, which you ignore.

Run tests with `npx elm-test`. You'll get output in your terminal within a second or two, even for hundreds of tests.[^elm-test-rs] No browser startup, no DOM rendering, no waiting for React to mount. Just functions being called and results being checked.

For the tightest feedback loop, run in watch mode:

```
npx elm-test --watch
```

This re-runs your tests every time you save a file. If you're used to Jest's watch mode, same idea. The difference is that elm-test reruns are near-instant, so you get red-or-green feedback almost before your fingers leave the keyboard.

That speed matters more than you might think. When the feedback loop is fast enough, writing tests _first_ stops being a chore and starts being a tool for thinking.

[^elm-test-rs]: For even faster runs, look at `elm-test-rs`, a Rust-based test runner that's significantly quicker on large test suites. Same test format, faster execution.

## TDD Where It Shines

Test-driven development has a complicated reputation. Practiced dogmatically across an entire codebase, it can feel like overhead. But there's one place where TDD consistently earns its keep: **recursive functions**.

Recursion is hard to get right in your head all at once. You need a base case, a recursive step, and confidence that the two work together for inputs of any size. TDD turns that into a series of small, concrete steps: start with the simplest possible input, write a test, make it pass, then move to the next level of complexity. Each test constrains the implementation a little more, until the recursive structure emerges naturally.

Let's build a function test-first. We want `group`: given a list, it groups consecutive equal elements together.

```elm
group [ 1, 1, 2, 3, 3, 3, 2, 2 ]
--> [ [ 1, 1 ], [ 2 ], [ 3, 3, 3 ], [ 2, 2 ] ]
```

This is a real utility. You'd reach for it when grouping messages by sender, runs of identical log entries, or streaks in time-series data. It's also recursive, which makes it a perfect candidate for building incrementally.[^lovdata-recursive]

[^lovdata-recursive]: The Lovdata codebase (125,000 lines of Elm) includes a similar pattern: converting between flat message lists and recursive tree structures for AI chat histories. The production tests use the same progressive approach shown here: base cases first, then structural properties verified with fuzz testing. The version in this chapter is simplified, but the technique scales.

### Round 1: The Empty List

Start with the simplest possible input.

```elm
module GroupTests exposing (suite)

import Expect
import Group exposing (group)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "group"
        [ test "empty list gives empty groups" <|
            \_ ->
                group []
                    |> Expect.equal []
        ]
```

The implementation to pass this test is trivial:

```elm
module Group exposing (group)

group : List a -> List (List a)
group list =
    []
```

Ignoring the input entirely. That's fine. We only have one test, and it only demands `[]`. Run `npx elm-test`, see green. Move on.

### Round 2: A Single Element

```elm
, test "single element gives one group" <|
    \_ ->
        group [ 1 ]
            |> Expect.equal [ [ 1 ] ]
```

Red. Our implementation returns `[]` for everything. Fix:

```elm
group : List a -> List (List a)
group list =
    case list of
        [] ->
            []

        first :: _ ->
            [ [ first ] ]
```

We pattern-match on the list and wrap the first element. We're still ignoring the rest of the list, but the tests don't demand more yet. Green.

### Round 3: Two Different Elements

```elm
, test "different elements form separate groups" <|
    \_ ->
        group [ 1, 2 ]
            |> Expect.equal [ [ 1 ], [ 2 ] ]
```

Red. We return `[ [ 1 ] ]` and drop the `2`. Now we need the recursive step:

```elm
group list =
    case list of
        [] ->
            []

        first :: rest ->
            [ first ] :: group rest
```

Each element becomes its own single-element group, and we recurse on the rest. This passes all three tests. But it treats every element as a separate group, which isn't what we want.

### Round 4: Consecutive Equal Elements

Here's the test that forces the real logic:

```elm
, test "consecutive equal elements are grouped together" <|
    \_ ->
        group [ 1, 1 ]
            |> Expect.equal [ [ 1, 1 ] ]
```

Red. We get `[ [ 1 ], [ 1 ] ]`. Now we need to look at the result of the recursive call and decide: does the current element belong with the first group, or does it start a new one?

```elm
group list =
    case list of
        [] ->
            []

        first :: rest ->
            case group rest of
                (next :: others) :: groups ->
                    if first == next then
                        (first :: next :: others) :: groups

                    else
                        [ first ] :: (next :: others) :: groups

                _ ->
                    [ [ first ] ]
```

Read this carefully. After recursing on the rest, we peek at the first group in the result. If its head element equals `first`, we prepend `first` into that group. If it doesn't, we start a new group. The catch-all `_` handles the base case where the recursive result is empty.

Green. And now the satisfying part:

### Round 5: The Full Test

```elm
, test "mixed sequence groups correctly" <|
    \_ ->
        group [ 1, 1, 2, 3, 3, 3, 2, 2 ]
            |> Expect.equal
                [ [ 1, 1 ]
                , [ 2 ]
                , [ 3, 3, 3 ]
                , [ 2, 2 ]
                ]
```

No code changes needed. It passes immediately.

That's the TDD payoff with recursion. Each test forced a small, comprehensible change. The recursive structure emerged from the tests rather than being designed upfront. And because each step was verified before moving to the next, we caught mistakes early, before the recursive logic got tangled.

The final test suite, with `describe` blocks organizing the progression:

```elm
suite : Test
suite =
    describe "group"
        [ describe "base cases"
            [ test "empty list gives empty groups" <|
                \_ ->
                    group []
                        |> Expect.equal []
            , test "single element gives one group" <|
                \_ ->
                    group [ 1 ]
                        |> Expect.equal [ [ 1 ] ]
            ]
        , describe "grouping behavior"
            [ test "different elements form separate groups" <|
                \_ ->
                    group [ 1, 2 ]
                        |> Expect.equal [ [ 1 ], [ 2 ] ]
            , test "consecutive equal elements are grouped together" <|
                \_ ->
                    group [ 1, 1 ]
                        |> Expect.equal [ [ 1, 1 ] ]
            , test "mixed sequence groups correctly" <|
                \_ ->
                    group [ 1, 1, 2, 3, 3, 3, 2, 2 ]
                        |> Expect.equal
                            [ [ 1, 1 ]
                            , [ 2 ]
                            , [ 3, 3, 3 ]
                            , [ 2, 2 ]
                            ]
            ]
        ]
```

Notice how `describe` nests naturally. "Base cases" and "grouping behavior" are logical categories within the "group" suite. You can nest as deep as you like, though two levels is usually enough. The nesting structure is identical to Jest's `describe`, so there's nothing new to learn.

## Fuzz Testing: Let the Framework Think

Those five tests cover the cases we _thought of_. But what about the cases we didn't? What if there's some combination of inputs that breaks our implementation, an edge case hiding in a sequence we never considered?

Fuzz testing flips the approach. Instead of writing specific input/output pairs, you describe a _property_ that should hold for _any_ input, and the framework generates hundreds of random inputs to test it.

Our `group` function has a clean property: if you flatten the groups back into a single list, you should get the original list back.

```elm
import Fuzz

-- inside the suite:

, describe "properties"
    [ fuzz (Fuzz.list Fuzz.int) "flattening groups recovers the original list" <|
        \randomList ->
            group randomList
                |> List.concat
                |> Expect.equal randomList
    ]
```

`fuzz` replaces `test`. Instead of `\_ ->`, the lambda receives a randomly generated value, in this case a `List Int`. The `Fuzz.list Fuzz.int` argument is a _fuzzer_: a recipe for generating random data. elm-test ships fuzzers for all common types, and they compose. `Fuzz.list` takes any fuzzer and produces lists of random length filled with random values from that fuzzer.

By default, elm-test runs each fuzz test 100 times with different random inputs. That's 100 different lists: empty ones, single-element ones, long ones, lists with all identical elements, lists with alternating values. All generated and checked automatically. If any run fails, elm-test reports the specific input that caused the failure and attempts to _shrink_ it to the smallest failing example.

The property `List.concat (group xs) == xs` is called a _round-trip property_: apply a transformation, then its inverse, and verify you get back to where you started. A function could pass all five of our hand-written tests while still being broken for some edge case we never considered. The round-trip property checks the function's core invariant across a huge range of inputs, including ones we'd never think to write by hand.

Here's another useful property: every group should be non-empty.

```elm
, fuzz (Fuzz.list Fuzz.int) "no group is empty" <|
    \randomList ->
        group randomList
            |> List.all (\g -> not (List.isEmpty g))
            |> Expect.equal True
```

And one more: every element within a group should be the same value.

```elm
, fuzz (Fuzz.list Fuzz.int) "elements within each group are identical" <|
    \randomList ->
        group randomList
            |> List.all (\g ->
                case g of
                    [] ->
                        False

                    first :: rest ->
                        List.all (\x -> x == first) rest
            )
            |> Expect.equal True
```

Three fuzz tests, each checking a different structural property. Together they specify `group` more thoroughly than dozens of hand-written examples could. And they take the same time to run.

Fuzz testing is particularly effective in Elm because purity eliminates false failures. In a framework with side effects, a flaky test might fail because of timing, network state, or shared mutable state. In Elm, if a fuzz test fails, it found a real bug. Every time.

> **Fuzz testing in production**
>
> The Lovdata codebase uses fuzz tests to verify a function that converts between flat and tree-shaped chat histories. One of those tests generates lists of up to a million messages to check that the conversion functions are properly tail-call optimized and don't overflow the stack. If you'd tried to write that test case by hand, you'd still be typing.

## What You Don't Need to Test

Here's a test you might write in a React application:

```javascript
it("handles null user gracefully", () => {
  render(<Profile user={null} />);
  expect(screen.queryByText("Name:")).not.toBeInTheDocument();
});
```

In Elm, this test can't exist, because the scenario can't exist. If `Profile.view` expects a `User`, you can't pass it `Nothing` without the type signature explicitly allowing `Maybe User`. The compiler won't let you compile code that passes invalid data to a function. There's nothing to test.

React developers often write tests for:

- Null and undefined handling. Elm has no null. Values that might be absent use `Maybe`, and the compiler forces you to handle the `Nothing` case.
- Type checking at boundaries. "Does this prop receive the right type?" In Elm, the compiler answers that question for every function call in the entire codebase.
- Exhaustive case coverage. "Did I handle all the enum variants?" Elm's pattern matching is checked at compile time. Miss a case, and the code won't compile.
- State shape consistency. "Is the state object shaped correctly after this update?" Elm's model is typed. If `update` returns something with the wrong shape, it doesn't compile.

None of these need tests in Elm. The compiler is faster, more thorough, and never forgets to run.

What _does_ need testing? Business logic. "Does this function compute the right result?" The compiler knows that your `calculateDiscount` function takes a `Price` and returns a `Price`. It doesn't know whether the discount should be 10% or 15%. That's your job.

Edge cases in domain logic. The compiler can't tell you that your grouping function handles the empty list correctly, or that your date parser does the right thing with leap years. Those are the tests worth writing.

Integration behavior. "When the user clicks submit and the server returns an error, does the form show the error message?" The individual pieces are type-checked, but the _composition_, the way your `update` function threads state through a sequence of messages, is where bugs live. For complex flows, test the update function directly: feed it a `Msg`, check the resulting `Model`.

You end up with fewer tests, but each one tests something the compiler genuinely can't verify. That's the "half the tests, twice the confidence" tradeoff. You're not skipping tests; you're letting the compiler handle the tedious half so you can focus on the interesting half.

## Wrapping Up

Testing in Elm is testing pure functions. No mocks, no cleanup, no async wrappers. Just inputs and outputs. The same purity that makes refactoring safe and state predictable makes tests straightforward to write and fast to run.

When something is tricky to implement, whether it's a recursive algorithm or a complex validation chain, TDD gives you a way to build it up incrementally with instant feedback. When you want confidence beyond what you can enumerate by hand, fuzz testing explores the edges for you.

The compiler handles the rest.

---

This is a chapter from [An Elm Primer for React Developers](https://leanpub.com/elm-for-react-devs), which is nearing completion. Subscribers to my newsletter (old and new alike!) get a discount in their inbox 🤓
