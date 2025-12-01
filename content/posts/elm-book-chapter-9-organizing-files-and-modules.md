+++
title = "Organizing Files and Modules in Elm: Building an Advent Calendar"
description = "Unlearning JavaScript pain-driven file splitting habits, and building an Advent Calendar with Elm"
date = "2025-12-01"
tags = ["elm", "react", "functional programming", "book", "architecture", "tasks", "file organization"]
draft = false
+++

We're officially in Part III of the book now, where we shift from systematic concept exploration to building real applications. This chapter asks you to unlearn something you probably picked up from years of JavaScript development: the instinct to split code into multiple files at arbitrary line counts.

As usual, [the book can be found and bought @ leanpub](https://leanpub.com/elm-for-react-devs).

(And as usual, the formatting is slightly more adequate in the actual book than on this Hugo blog, but we'll make do.)

---

# Chapter 9: Organizing Files and Modules

We're changing gears now. In Parts I and II, we explored Elm's fundamentals systematically—one concept at a time, building up from pure functions to side effects to structured data. That approach served us well for learning the language itself.

But real applications don't grow that way. Real applications start with a vague idea, evolve through iteration, and accumulate features as you discover what you actually need. They require techniques and patterns as you encounter problems, not in alphabetical order.

So in Part III, we'll build real applications and introduce concepts as we need them. We'll learn about `Task`s when we need to work with time. We'll explore modules when our data structures demand their own space. We'll discover patterns as they emerge naturally from the problems we're solving.

This chapter, in particular, asks you to unlearn something. Something you probably picked up from years of JavaScript development, internalized through pain and production incidents, and now follow almost instinctively.

We're going to question when—and why—you should split your code into multiple files.

## Moving Beyond the Single-File Approach?

So far, we've been dealing with relatively small apps that will fit in a single file regardless of language or programming paradigm. But what happens when we scale our Elm apps and create more complex things?

In JavaScript workflows, there are certain practices around organizing code. I propose that quite a few of these have very little to do with good architecture, and much to do with trying to mitigate one of two major pain points:

### JavaScript Pain Point I: "Sneaky Mutations"

As we've addressed thoroughly already, JavaScript is quite dynamic and extremely liberal. As our files increase in length, the cognitive load required for something as trivial as _avoiding unintentional mutations_ increases exponentially. All it takes is a misplaced (and innocent-looking!) `const sortedArray = oldArray.sort()`<sub><sup>\*</sup></sub> to create a bit of undefined behavior.

A common rule of thumb to mitigate is this:

> Prefer shorter files (so you can double-check everything whenever making a change)

After all, if your files are shorter, skimming through them to look for foxes in the garden is a more realistic endeavor. Right?

### JavaScript Pain Point II: Refactoring is Hard and Quite Dangerous

Given the above premise, it follows that having an iterative approach to organizing code, components, modules and directories is _unsafe_; large refactors, we've learned, equals being quite screwed quite fast. So we need to be very mindful even before we know for certain just exactly we're building, how portable it needs to be and what it will interact with. YAGNI (the "You Ain't Gonna Need It"-principle) is out the window, and so, I guess, is agile development...?

Sadly, but not without reason, we internalize the following principle as well:

> Get Architecture Right From The Start (because refactoring might actually kill you)

Anyone who's deployed any substantial JavaScript project to production after a large "Noop" refactor can empathize, and will nod a tired head in agreement. The pain and the fear is real!

## Elm is Different

As we're not writing a JavaScript application, I have some good news for you: There is a better way! Let's address the principles and underlying pain points right away:

- Chance of sneaky mutations in Elm: 0%
- Refactoring in Elm is _cheap_, _safe_ and _reliable_

This makes growing an Elm codebase fundamentally different. There are reasons for splitting up files, but line count isn't really one of them. And there are reasons to think about architecture early, but you can also make large-scale changes as you go. Good architecture tends to emerge naturally from any sane Elm application unless you deliberately work against it.

So rather than splitting at a certain arbitrary code length threshold, we can discover other and more relevant points where a split makes sense. We can split around data structures, and delegate complexity surrounding each structure to its own file (with the added bonus point of only exporting what we need, and keeping implementation details hidden from consumers).

In fact this is Evan's main advice on this:

> Build modules around data structures. Do not worry about file length.
>
> – Evan Czaplicki, Creator of Elm

Quite the paradigm shift. And honestly? It's liberating. You model your app according to its actual structure, not your fear of forgetting something. You're not limited by how much you can hold in your head at once. You build architecture like playing Super Mario—eager, experimental, knowing that if you die you can simply try again.

This is a good time to practice some more, and see how this plays out in a growing application.

## Let's Build an Advent Calendar App

To help us unlearn some of these pain point-based habits regarding code organization and file splitting, let's create a slightly more useful application.

At the time of writing, November is rapidly coming to an end, and I feel like making a new Advent Calendar for my wife. And as we all know, Elm is ~~the best tool for the job, and a lot more cozy and romantic than anything physical you can hang on the wall~~ very fun to write, so let's simply code one!

## Basic Advent Calendar Spec

- a header with a title, perhaps with the current year to make it feel up to date?
- 24 slots, each with something fun/nice inside (not sure what yet)
- slots should be impossible to open early! This is important!
- Nice-to-have: animated snow falling?

Hopefully we'll learn that 1) keeping this entire app in one file is _fine_, because we don't have to worry about tricky refactoring or sneaky mutations, and 2) splitting it into multiple files might make sense _for other reasons_, reasons we will get back to shortly.

<sub><sup>\*: Array.prototype.sort() actually sorts in place, _in addition to_ returning the sorted array</sup></sub>

[...] Read the rest of this chapter in [the book @ leanpub](https://leanpub.com/elm-for-react-devs)

---

## The actual Advent Calendar app

And here it is! [The actual Advent Calendar for 2025 - cekrem.github.io/advent](https://cekrem.github.io/advent/) the rest of this chapter walks through the implementation step by step, including working with Tasks for date/time handling.
