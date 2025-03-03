+++
title = "Why I Hope I Get to Write a Lot of Elm Code in 2025"
description = "A deep dive into the functional programming language that still has much to teach us"
tags = ["elm", "frontend", "functional programming", "architecture", "clean architecture"]
date = "2025-03-04"
draft = false
+++

In a world dominated by React, Vue, and Svelte, it might seem strange to highlight Elm – a niche language that has existed since 2012 but has had fewer releases since then than React has in a year. But right now, when frontend development is becoming increasingly complex, and clients are doing heavy lifting that previously belonged on the other side of an API call, it's worth taking a closer look at what Elm does right.

## What is Elm?

Elm is a functional programming language specifically designed for web applications. Here are the key differences from modern JavaScript frameworks:

- **No runtime errors** – When the code compiles, it can run without unexpected crashes
- **Complete handling of all possible states** – The compiler helps you with all edge cases
- **Predictable architecture** – [The Elm Architecture](https://guide.elm-lang.org/architecture/) (TEA) provides a clear structure that scales well
- **Automatic version handling** – The compiler detects breaking changes

### React vs. Elm: Same Direction, Different Approach

It's fascinating to see how React has evolved in recent years:

- React introduced hooks to handle state more functionally
- Redux (inspired by Elm) became standard for complex state management
- TypeScript (strong typing) became almost mandatory for serious projects
- React Server Components isolate side effects on the server side

**But there's an important difference:** React _recommends_ functional programming and immutability, while Elm _requires_ it. In React, you can still mutate variables and state, mix paradigms, and create runtime errors. In Elm, it's simply impossible.

As a senior React developer recently told me: "Good React code in 2025 looks suspiciously like Elm code from 2015."

## When Constraints Give Freedom

Ironically, Elm's strict constraints give us several advantages:

- **Simpler debugging**: When data never changes, you don't have to wonder "who or what changed this value?"

  ```javascript
  // In JavaScript, this can happen:
  let user = { name: "Ada" };
  someFunction(user); // user can be changed here
  console.log(user.name); // What's the name now? Impossible to know without reading someFunction
  ```

  In Elm, this is impossible - you get a compile-time error if you try to mutate:

  ```elm
  -- In Elm:
  user = { name = "Ada" }

  -- This doesn't compile:
  user.name = "Grace"  -- ERROR: Elm doesn't have variable mutation.

  -- The right way in Elm:
  updatedUser = { user | name = "Grace" }  -- Creates a new copy with changed name
  ```

- **Predictable code**: Pure functions + immutable data = same input always gives same output
- **Safer refactoring**: The compiler finds all places that need to be updated
- **Less mental load**: You don't need to keep the entire state history in your head

## SOLID by Default

The Elm Architecture (TEA) is a simple but powerful model for building web applications. It consists of three main parts:

1. **Model** - The application's state
2. **Update** - How the state changes in response to events
3. **View** - How the state is displayed in the user interface

![The Elm Architecture Diagram](https://guide.elm-lang.org/architecture/buttons.svg)
_Image source: [Elm Guide](https://guide.elm-lang.org/architecture/)_

This pattern enforces [SOLID principles](https://en.wikipedia.org/wiki/SOLID) – whether you want to or not:

1. **Single Responsibility** – Elm forces you to separate View, Update, and Model
2. **Open/Closed** – New functionality is added by extending the Msg type with new variants
3. **Liskov Substitution** – Automatically fulfilled through Elm's type system and union types
4. **Interface Segregation** – Elm encourages small, focused modules and types
5. **Dependency Inversion** – All communication goes through messages (Msg) and abstractions

Where other languages offer SOLID as "best practices" you can follow if you're disciplined, they are a mandatory part of Elm's DNA. The compiler is your unforgiving architecture mentor.

## The Elm Architecture vs. Clean Architecture

Clean Architecture (CA) is about organizing code so that business logic is independent of frameworks and UI. How does TEA fit in here?

### 1. Separates UI from Logic

- Just like CA, TEA has a clear separation between the presentation layer (**View**) and domain logic (**Model + Update**)
- This means you can change the UI without changing the domain logic

### 2. Structuring Business Logic

- TEA doesn't have an explicit "use case layer" as CA recommends
- But the **Update function** can be seen as an _interactor_ in CA, where it takes in an event and determines a state change

### 3. Independence from External Systems

- In Clean Architecture, business logic should be **independent** of databases, UI, or third-party APIs
- TEA ensures this by using **Cmd** for side effects, so API calls and similar are outside the core architecture

### 4. Simple Testing

- Both architectures promote **testable code**
- TEA's pure functional approach makes it easy to unit test the **Update function** without thinking about external dependencies

## When Should You Consider Elm?

Elm is particularly well-suited when:

1. You're building a complex frontend application
2. Robustness and maintainability are critical
3. You have the opportunity to train your team
4. You're starting a new project from scratch

## The Challenges

Let's be honest about the challenges too:

- Steep learning curve for developers used to imperative programming
- Smaller ecosystem than React/Vue
- Fewer developers available
- Can be difficult to "sell" to decision-makers

## Conclusion

Elm's relevance in 2025 lies not in market share, but as an architectural compass. Many of its principles are found in:

- [React Server Components](https://react.dev/blog/2023/03/22/react-labs-what-we-have-been-working-on-march-2023#react-server-components)' isolation of effects
- TypeScript's increasingly strict type system
- The growth of compile-time tools like [tRPC](https://trpc.io/) and [Zod](https://zod.dev/)

Again: what various "best practices" encourage the driven developer to strive for, is a mandatory part of Elm. Sure, you can (and should!) write functional React with good architecture, strong types, and isolated side effects; with Elm, you simply aren't allowed to do anything else.

## Resources to Get Started

- [Elm Guide](https://guide.elm-lang.org/) – The official guide
- [Elm in Action](https://amzn.to/41z14kq) – An excellent book for learning how Elm works in larger applications (I'm reading this right now, and I love it!)
- [Elm Community](https://elm-lang.org/community) – An unusually helpful and open community
- [elm-spa](https://www.elm-spa.dev/) – For building Single Page Applications
- [Elm Land](https://elm.land/) – New meta-framework (2024)
