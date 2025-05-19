+++
title = "A Use Case for  Port Boundaries in Frontend Development"
description = "Learn how Elm's architectural discipline—and a few ideas from Clean Architecture—can reshape how we think about frontend boundaries."
date = "2025-05-19"
tags = ["clean architecture", "architecture", "elm", "react", "frontend", "software design"]
draft = false
+++

In the Elm ecosystem, the browser is treated like an I/O device. DOM events, JavaScript interop, and even network requests are kept outside the core logic. Rather than allowing side effects to permeate the codebase, Elm channels them through strictly typed boundaries known as _ports_.

This architectural stance is both radical and liberating. It allows you to build user interfaces where logic remains pure, testable, and robust, even as surrounding technologies evolve.

You might not be writing Elm, but the core idea is portable: **treat your UI runtime as a detail**. What if React—or your TypeScript frontend—adopted this philosophy? What if we stopped treating our framework as the foundation and started treating it as just another dependency?

---

## Your App Is Not Your Framework

Too many frontend projects blur the lines between business logic and UI behavior. It’s common to model domain concepts directly inside React components and tie state management logic to hooks, lifecycle events, or global stores.

Over time, this creates tight coupling to the framework. Refactoring becomes risky. Testing core logic without a UI becomes difficult. And your _business model_ becomes tangled with the frontend library of the month.

You might discover, months in, that half your app is unusable outside a browser—or that important state transitions are buried deep inside components.

![michael-scott-in-chains](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExbWJocXQ3cnB5NG00OWV1aWZldmtvdjQxZmJxY3hiMndxcHJtZDNmYyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/SDGNkoOsb8alDk66ZN/giphy.gif)

According to Uncle Bob, you should _date_ your framework, not _marry_ it—and in theory, React isn’t even a framework, but a library. As Martin Fowler and others have pointed out, the key distinction lies in _inversion of control_: with a library, _your code_ calls into it; with a framework, _it_ calls into your code. This subtle but important difference affects how much architectural ownership you retain. As [thoroughly explained and discussed here](https://stackoverflow.com/questions/3057526/framework-vs-toolkit-vs-library), libraries are called by your code, while frameworks call your code.

By designing your application to live independently of its framework, you dramatically increase its adaptability and longevity.

## What Elm Gets Right

Elm enforces a clean separation of concerns from the start:

- UI updates are modeled as **pure functions**
- State transitions are explicit, driven by **messages**
- Side effects are expressed as **commands**, executed by the runtime
- External interactions (e.g. JavaScript, local storage, sockets) go through **ports** with typed boundaries

This structure makes Elm code surprisingly easy to reason about. Most files don’t even “know” the DOM exists. You test your business logic just as you would in a backend service.

Elm doesn’t just allow this separation—it _requires_ it. That’s what gives Elm applications such strong architectural integrity.

And if a new JS feature becomes available, you can use it—just on the _outside_ of the port, treating it as implementation detail, not core logic.

## Applying the Same Mindset in React/TypeScript

You don’t need to rewrite your app in Elm to benefit from this philosophy. Even in a conventional React/TypeScript stack, you can adopt many of the same patterns:

1. **Keep domain logic in plain TypeScript modules.** Avoid JSX or DOM references.
2. **Model UI state as a consequence of business state.** Eliminate redundant local flags.
3. **Define ports explicitly.** Side-effecting utilities like `copyToClipboard()` should live at the boundary.
4. **Test your logic in isolation.** Leave UI interactions for the adapter layer.
5. **Establish clear boundaries.** Name and document them like external APIs.

In small apps, this might feel overengineered. But as complexity grows, the benefits compound. Debugging becomes easier. You can test without mocking every hook. You can reason clearly about behavior.

## A Boundary Buys You Freedom

When your domain logic is independent of the DOM, you unlock powerful benefits:

- Share logic across platforms (web, native, CLI)
- Run simulation tests without UI scaffolding
- Swap out rendering libraries (React, Svelte, server-driven UI)
- Move logic into backend tasks or scheduled jobs

You also improve onboarding: new developers can focus on logic before touching the view layer.

A clear boundary keeps your app flexible, portable—and maintainable.

## The STDIN/STDOUT Analogy

In _[Clean Architecture](https://amzn.to/4iAc8o1)_, Uncle Bob recounts working on a payroll system whose logic was tightly coupled to its user interface and low-level I/O libraries. Initially, the system read data from punch cards and output to line printers. But as hardware evolved—magnetic tapes, then disk storage, then terminals—each shift in technology would have required major rewrites of the business logic.

To solve this, he redesigned the system to treat `STDIN` and `STDOUT` as abstraction boundaries. All input flowed through `STDIN`, all output through `STDOUT`. With this design, only the code that handled the I/O had to change when new hardware was introduced. The core logic remained untouched.

That insight—treating delivery mechanisms as pluggable interfaces—**is just as applicable to frontend development today**. Browsers change, frameworks evolve, APIs deprecate. But if your business logic communicates with the runtime through clean ports, your application can stay stable through it all.

_— Source: [Clean Architecture](https://amzn.to/4iAc8o1), Robert C. Martin (2017)_

## Ports Are More Than Just Interop

Elm uses the word _port_ to describe any bridge between core logic and the outside world. That linguistic choice matters.

If we start treating the DOM, browser APIs, and even JavaScript runtimes as _ports_—not as our app—we’re more careful about where side effects live. We build a clean kernel of logic and wrap it in infrastructure.

Imagine treating the clipboard, URL bar, `localStorage`, or `window.location` as I/O devices rather than global state. The benefits are the same: modularity, testability, confidence.

This mindset isn’t exclusive to Elm. It belongs in every serious frontend codebase. And adopting it doesn’t mean switching languages—just shifting how we define and respect our boundaries.
