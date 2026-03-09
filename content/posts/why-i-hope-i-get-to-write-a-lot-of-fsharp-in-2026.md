+++
title = "Why I Hope I Get to Write a Lot of F# in 2026"
description = "The FP language that does what Elm does, but on the backend, with full .NET support"
tags = ["fsharp", "functional programming", "enterprise", "elm", "domain modeling", "clean architecture"]
date = "2026-03-09"
draft = false
+++

A year ago I wrote about [why I hoped to write a lot of Elm code in 2025](/posts/why-i-hope-i-get-to-write-a-lot-of-elm-code-in-2025/). Then I went and wrote [an entire book about it](https://leanpub.com/elm-for-react-devs). I spent the year [demystifying monads](/posts/functors-applicatives-monads-elm/), exploring [SOLID through an FP lens](/posts/solid-in-fp-single-responsibility/), arguing that [TypeScript won't save you](/posts/why-typescript-wont-save-you/), and building real production software in Elm at [Lovdata](https://lovdata.no) (125,000+ lines of it).

So you might expect this year's post to double down on Elm. Instead, I want to make a different argument: **for enterprise projects, I think F# is the right functional language.**

I'm not leaving Elm. Elm is still the best way to learn functional programming — I literally [wrote the book on that](https://leanpub.com/elm-for-react-devs). But learning FP and shipping enterprise software are different problems, and I've been thinking about what fills the gap.

## The Question I Kept Bumping Into

Writing the Elm book forced me to think carefully about what makes functional programming valuable. Not just the syntax or the patterns, but the deeper stuff: immutability as a default, types that model your domain accurately, [making impossible states impossible](/posts/making-impossible-states-impossible-with-functional-dependency-injection/), the compiler catching mistakes before your users do.

These ideas aren't unique to Elm. They come from the ML family of languages — and they transfer. I said so explicitly in the book: the FP fundamentals you learn in Elm "apply directly to Haskell, F#, OCaml, Clojure."

But then the follow-up question hit me: _if I'm building an enterprise backend — or a full-stack application for a team that needs to maintain it for the next five years — which language do I actually pick?_

That's where F# comes in. And the more I look at it, the more I think Scott Wlaschin was right all along.

## Scott Wlaschin's Enterprise Filter

If you haven't read Wlaschin's ["Why F# is the best enterprise language"](https://fsharpforfunandprofit.com/posts/fsharp-is-the-best-enterprise-language/), you should. His argument isn't about what's _cool_ — it's about what survives a cold, pragmatic enterprise filter:

Enterprise software is a **cost center**. It's business-centric, not technology-centric. Projects live 5+ years with team rotation. Management is risk-averse. You need static typing, garbage collection, a backed ecosystem, cross-platform support, and code that's maintainable even after the original team has moved on.

When you run modern languages through that filter, most of them fall out (I'm paraphrasing Wlaschin here, but not by much):

- **Python/Ruby/PHP** — Maintainability goes out the window when you have more than 10K LoC
- **Haskell** — "No gradual migration path — you are thrown in the deep end"
- **Scala** — "Too many different ways of doing things"
- **Elm/PureScript** — Frontend only, for now (Though projects like [Lamdera](https://lamdera.com/) are challenging that! And of course, if your project _is_ frontend only then this might be an excellent choice.)
- **Go** — Weak domain modeling with types
- **Rust/C++** — Unnecessary complexity if you don't need bare-metal performance
- **C#/Java** — Adequate, but inferior defaults and weaker algebraic data type support

Three languages survive: **F# on .NET**, **Kotlin on JVM**, and **TypeScript on Node**.

All three are reasonable. But F# has something the others don't.

## What F# Gets Right

### Immutability as a True Default

I've [written before](/posts/why-i-hope-i-get-to-write-a-lot-of-elm-code-in-2025/) about how Elm _requires_ immutability where React merely _recommends_ it. F# sits closer to Elm on this spectrum than most people realize.

In F#, values are immutable by default. You have to explicitly opt into mutation with `mutable` — and it looks ugly enough that you think twice:

```fsharp
let name = "Christian"    // immutable
// name <- "Chris"        // compiler error

let mutable counter = 0   // you asked for it
counter <- counter + 1    // works, but stands out
```

Kotlin has `val` vs `var`, which is decent. But F# goes further — even collections and records are immutable by default. The language pushes you toward the right thing whether you planned for it or not. In Elm mutability is impossible, and I love that, but as F# has full .Net interop a need for pragmatic solutions make sense.

### Low-Ceremony Domain Modeling

This is where F# really shines, and where Wlaschin's ["Domain Modeling Made Functional"](https://amzn.to/44B0dQE) really clicked for me. I've already explored these patterns in Elm in [my impossible-states post](/posts/making-impossible-states-impossible-with-functional-dependency-injection/) — F# just does it with less ceremony and full backend support.

```fsharp
// Domain types that read like a specification
type EmailAddress = EmailAddress of string
type OrderId = OrderId of int

type OrderStatus =
    | Draft
    | Placed of placedDate: DateTime
    | Shipped of shippedDate: DateTime * trackingNumber: string
    | Delivered of deliveredDate: DateTime
    | Cancelled of reason: string

// Can't create an order that's both shipped AND cancelled.
// Can't have a shipped order without a tracking number.
// The compiler enforces all of this.
```

If you've read my [SOLID in FP](/posts/solid-in-fp-single-responsibility/) series, this should look familiar. Same philosophy. Discriminated unions, exhaustive pattern matching, rich types that _mean_ something. The difference is that F# gives you this with full .NET backend support, not just in the browser.

Want to handle all order states? The compiler makes you:

```fsharp
let describeOrder order =
    match order with
    | Draft -> "Not yet placed"
    | Placed (date) -> $"Placed on {date}"
    | Shipped (date, tracking) -> $"Shipped on {date}, tracking: {tracking}"
    | Delivered (date) -> $"Delivered on {date}"
    | Cancelled reason -> $"Cancelled: {reason}"
    // Forget a case? Compiler error.
```

I wrote in my Elm post that "the compiler is your unforgiving architecture mentor." In F#, the compiler is still your mentor — but now it speaks .NET.

### Parse, Don't Validate

One of my favorite principles (from [Alexis King](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/), and one I explored in [my impossible-states post](/posts/making-impossible-states-impossible-with-functional-dependency-injection/)) works beautifully in F#:

```fsharp
type Email = private Email of string

module Email =
    let create (input: string) =
        if input.Contains("@") then Ok (Email input)
        else Error "Invalid email"

    let value (Email e) = e

// Once you have an Email, it's guaranteed valid.
// The private constructor prevents cheating.
```

Same idea as [Elm's opaque types](/posts/solid-in-fp-liskov-substitution/). Once data enters your domain layer, it's been parsed and validated. The rest of your system works with values that are _already_ guaranteed to be correct. And since everything is immutable, they can't be corrupted later.

I argued in [Why TypeScript Won't Save You](/posts/why-typescript-wont-save-you/) that "you're only as safe as your weakest `any`." F# doesn't have an `any`. No escape hatches. No `as unknown as Whatever`. If the types say it's valid, it's valid.

### Functional Dependency Injection

I already showed this pattern with both Elm and F# code in my [impossible-states post](/posts/making-impossible-states-impossible-with-functional-dependency-injection/), so I'll keep this brief. The idea — straight from Wlaschin — is that you inject dependencies as function parameters and use partial application to wire things up:

```fsharp
type CheckProductCodeExists = ProductCode -> bool
type CheckAddressExists = Address -> Async<Result<CheckedAddress, AddressError>>

let validateOrder
    (checkProduct: CheckProductCodeExists)
    (checkAddress: CheckAddressExists)
    (unvalidatedOrder: UnvalidatedOrder)
    : Async<Result<ValidatedOrder, ValidationError>> =
    // implementation
```

Dependencies first, input second, output last. Partially apply the dependencies, and you get a clean function with the right signature. **Dependency inversion without interfaces**, without IoC containers, without lifecycle management. Just functions.

## Why Not Kotlin? Why Not TypeScript?

Fair question. I work in Kotlin daily and I've written about [Arrow's Either](/posts/arrow-either-kotlin-functors-monads/) and [rich error types](/posts/kotlin-rich-errors-elm-union-types/). Kotlin is a good language. Arrow is genuinely nice. But Kotlin is functional-_capable_, not functional-_first_. You're always one team member away from someone reaching for mutable state and inheritance hierarchies because the language lets them.

Same story with TypeScript, only worse. I've [made my case](/posts/why-typescript-wont-save-you/) that TypeScript's type system provides the _feeling_ of safety without the guarantee. The escape hatches are everywhere. `any`, `as`, `@ts-ignore` — you're only as safe as the least disciplined person on your team.

F# is different. The defaults are right. Immutable. Functional. Exhaustive. You _can_ write imperative code if you really need to (it's .NET, after all), but the language makes the functional path the path of least resistance.

As I wrote in my very first Elm post: what various "best practices" encourage the driven developer to strive for, is a mandatory part of the language. That was true for Elm. It's true for F# too.

## The Enterprise Reality

Here's what seals it for me: F# isn't just a nice language in a vacuum. It runs on .NET — the most widely deployed enterprise runtime there is.

That means:

- **Azure, AWS, GCP** — first-class support
- **NuGet** — massive package ecosystem
- **Entity Framework, Dapper** — database tooling that works
- **ASP.NET** — battle-tested web framework
- **C# interop** — you can introduce F# project-by-project into an existing C# codebase

That last point is huge. Unlike Haskell (where you're "thrown in the deep end"), F# lets you do a gradual migration. Start with one service. Prove the value. Expand. Your existing .NET infrastructure, your CI/CD pipelines, your monitoring — it all keeps working.

Jet.com did exactly this. They built 700+ cloud-based microservices in F# and scaled from 30,000 to 2.5 million customers in three months. (Walmart later acquired them for $3.3 billion, so it apparently worked out.) The interesting part: they didn't _plan_ a microservice architecture. They just wrote idiomatic functional code and woke up one day realizing they'd naturally built one.

And they're not alone. Financial institutions, insurance companies, and tech companies around the world use F# in production. Simon Cousins, who built business-critical systems at a UK power company, put it bluntly: "I have now delivered three business critical projects written in F#. I am still waiting for the first bug to come in."

Sure, that's quite a claim. But when your language enforces immutability, exhaustive pattern matching, and proper domain modeling, certain categories of bugs just... don't happen.

## The Challenges

I wouldn't be giving you the full picture if I didn't list the problems. (I did this for Elm too. It's only fair.)

- **Adoption is low.** F# hovers around 1% on Stack Overflow surveys. Most .NET shops write C#.
- Hiring is harder — you won't find as many F# developers as C# or TypeScript developers.
- The community is smaller. Fewer blog posts, fewer Stack Overflow answers, fewer tutorials.
- And selling it to management? "Let's use this language nobody's heard of" is a hard pitch, even when the arguments are solid.

A developer running an F# SaaS for 5+ years summarized it honestly: "If you can choose F# — do it. But you probably won't be able to."

These are real constraints. But they're all _social_ constraints, not _technical_ ones. Nobody says "F# can't handle this" — they say "we can't find F# developers." The language and ecosystem are solid; it's adoption that's the problem.

(Sound familiar? Elm has the exact same problem, except with an even smaller ecosystem.)

## Elm for Learning, F# for Shipping

Here's how I think about it now.

Elm is still the shortest path to understanding functional programming. No lazy evaluation complexities, no scary jargon, no escape hatches. A compiler so helpful it puts most AI tools to shame. If you're a React developer (or any developer, really) who wants to _get_ FP — [start with Elm](https://leanpub.com/elm-for-react-devs). I'm not backing down from that.

But when the question is "what do I ship enterprise software in?" — when I need backend support, database access, cloud deployment, a hiring pipeline, and a runtime that'll be around in ten years — that's where F# comes in. It takes everything Elm taught me about type safety, domain modeling, and functional architecture, and puts it in a runtime my team already uses.

I'm not leaving Elm behind. I'm taking what Elm taught me forward.

And again: for an isolated _frontend_ project, Elm is still my go to, hands down.

## What's Next

I'm still finishing the Elm book (it's close!). I'm still writing Elm at Lovdata. And I'm still going to argue that Elm is the best FP learning path at every opportunity. And I still prefer Elm for all things frontend.

But this year, I want to go deeper with F#. Build something real. See how Wlaschin's domain modeling patterns hold up when the deadline hits and you need to ship fast rather than fancy. My bet is they'll hold up just fine — because the language won't let me cut the corners I'd be tempted to cut in a less opinionated language.

I've spent years arguing that the compiler should be your strictest collaborator. F# is the first language where I feel that's true _and_ where I can ship it on Monday morning without a fight. It won't _think_ for you — no language can. But it'll make sure your thinking is reflected accurately in the code, and that the compiler keeps it that way.

That's all I ask of a language, really.

## Resources

- [F# for Fun and Profit](https://fsharpforfunandprofit.com/) — Scott Wlaschin's site. Start here.
- [Domain Modeling Made Functional](https://amzn.to/44B0dQE) — The book that connects FP and DDD in a way I haven't seen anywhere else
- [Why F# is the best enterprise language](https://fsharpforfunandprofit.com/posts/fsharp-is-the-best-enterprise-language/) — The article that started this train of thought
- [The SAFE Stack](https://safe-stack.github.io/) — Full-stack F# (server, client via Fable, cloud via Azure)
- [An Elm Primer for React Developers](https://leanpub.com/elm-for-react-devs) — My book, if you want to start the FP journey from the beginning
