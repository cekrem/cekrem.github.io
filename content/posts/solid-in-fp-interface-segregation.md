+++
title = "SOLID in FP: Interface Segregation and Dependency Inversion, or The Finale Where Functions Steal the Show"
description = "Revisiting ISP and DIP through a functional lens – turns out they share a punchline"
tags = ["fsharp", "functional-programming", "SOLID", "architecture", "dependency-inversion"]
date = 2026-03-12
draft = false
+++

[Last time](/posts/solid-in-fp-liskov-substitution/), I said Interface Segregation was up next — "another principle that sounds very OOP, in a language with neither interfaces nor classes." I was gearing up for another round of reframing, maybe some clever type-level trick like the opaque types in the LSP post.

Nope. This one basically solved itself.

Also — you might notice the code looks different this time. I recently wrote about [wanting to use more F# in 2026](/posts/why-i-hope-i-get-to-write-a-lot-of-fsharp-in-2026/), and this felt like a natural place to make the switch. Same ML-family DNA, same functional philosophy, just with full .NET backend support. If the concepts _didn't_ transfer directly from Elm, this whole series would be a lot less interesting.

![nothanks](https://media1.tenor.com/m/SbKvGF0njxUAAAAd/nothanks-michael.gif)

## Uncle Bob's definition

ISP in Uncle Bob's words:

> "Clients should not be forced to depend on interfaces they don't use."

The classic example: you've got one big interface with twelve methods, but most clients only need two or three. You change a method that Client A uses, and Client B has to recompile even though it never called that method. You write a mock for testing, and you're stubbing out nine methods you don't care about. Fun times.

I wrote about this [in Go a while back](/posts/interface-segregation-in-practice/), with the usual `UserService` monolith interface:

```go
// The classic fat interface
type UserService interface {
    CreateUser(user User) error
    GetUser(id string) (User, error)
    UpdateUser(user User) error
    DeleteUser(id string) error
    ValidatePassword(password string) bool
    SendWelcomeEmail(user User) error
    GenerateAuthToken(user User) (string, error)
    ResetPassword(email string) error
    UpdateLastLogin(id string) error
}
```

Nine methods. A handler that only reads users still depends on the whole thing. The fix in Go was to split it into `UserReader`, `UserWriter`, `UserAuthenticator`, `UserNotifier` — each with just the methods that belong together. That's solid OOP advice (pun very much intended). Break the fat interface into focused ones.

But here's the thing: that entire problem _starts_ with grouping methods into interfaces. What if you just... didn't?

## Functions are the smallest possible interface

In F#, the equivalent of a "single-method interface" is just a function type:

```fsharp
type GetUser = UserId -> Result<User, UserError>
type SaveUser = User -> Result<unit, UserError>
type SendEmail = EmailAddress -> EmailContent -> Async<Result<unit, EmailError>>
type ValidatePassword = Password -> bool
```

`GetUser` takes a `UserId`, returns a `Result<User, UserError>`. That's the whole contract. No `SendEmail` method lurking next to it that you didn't ask for.

You literally cannot make a function type _fatter_ unless you actively try. One input, one output — that's as segregated as an interface gets. ISP is just... how functions already work.

Compare that to the Go version, where the fix for a fat interface was to split it into four smaller interfaces. In F#, you never had to split anything because you never grouped them in the first place.

## Partial application as natural dependency segregation

But it gets better. Say you have a function that processes an order — it needs to validate the product, check inventory, and calculate pricing:

```fsharp
let processOrder
    (validateProduct: ProductCode -> Result<ValidProduct, ValidationError>)
    (checkInventory: ProductCode -> Async<bool>)
    (calculatePrice: ValidProduct -> CustomerType -> Price)
    (order: UnvalidatedOrder)
    : Async<Result<ProcessedOrder, OrderError>> =
    // implementation
```

Each dependency is a function parameter — exactly the interface that `processOrder` needs, nothing more. No `IOrderService` with fifteen methods, nine of which are irrelevant.

Partial application lets you wire this up cleanly:

```fsharp
// At the composition root, wire up the dependencies
let processOrderForWeb =
    processOrder
        Catalog.validateProduct
        Warehouse.checkInventory
        Pricing.calculate

// Now processOrderForWeb has the signature:
// UnvalidatedOrder -> Async<Result<ProcessedOrder, OrderError>>
```

The consumer of `processOrderForWeb` doesn't even _know_ about product validation, inventory, or pricing. Those dependencies have been baked in. All the caller sees is a function from `UnvalidatedOrder` to `Result`. That's it.

This is exactly the pattern Scott Wlaschin describes in [Domain Modeling Made Functional](https://amzn.to/44B0dQE) — dependencies as function parameters, with the "real" input last so partial application works cleanly. No IoC containers. No interface hierarchies. Just functions.

## What this looks like in practice

I actually have a small project — [blog-bot](https://github.com/cekrem/blog-bot) — that does this for real. It's an F# pipeline that reads blog posts from RSS, transforms them into social media posts, and publishes them. The core pipeline function looks like this:

```fsharp
type Log = string -> unit
type Input = unit -> Async<Result<Post list, PipelineError>>
type Transform = Post -> Async<Result<SocialPost, PipelineError>>
type Output = SocialPost -> Async<Result<PublishedPost, PipelineError>>

type HistoryIO =
    { Read: unit -> Async<Result<Set<PublishedPost>, PipelineError>>
      Write: Set<PublishedPost> -> Async<Result<unit, PipelineError>> }

let run (log: Log) (historyIO: HistoryIO) (input: Input) (transform: Transform) (output: Output) =
    asyncResult {
        let! history = historyIO.Read()
        let! posts = input ()
        let newPosts = filterPublished history posts

        match newPosts with
        | [] ->
            log "No new posts to publish"
            return ()
        | post :: _ ->
            let! socialPost = transform post
            let! published = output socialPost
            do! historyIO.Write(Set.singleton published)
    }
```

Each dependency is a function type. `run` doesn't know or care _how_ posts are fetched, transformed, or published. And at the composition root, everything gets wired up through partial application:

```fsharp
let transform = Transform.Groq.transform (requireEnv "GROQ_API_KEY")
let output = Output.Bluesky.post (requireEnv "BLUESKY_HANDLE") (requireEnv "BLUESKY_PASSWORD")
let input = Input.rss "https://cekrem.github.io/index.xml"

run log history input transform output
```

`Transform.Groq.transform` takes an API key and returns a `Transform` function — the pipeline never sees the key. Same deal with `Output.Bluesky.post`: give it credentials, get back a plain `Output`. Want to swap Bluesky for console output during development? Just pass `Output.console` instead. Same signature, different implementation, zero ceremony.

If you've been following this series, you know where this is heading. Four posts in, and every principle keeps dissolving into the same thing: functions and types doing what OOP needed patterns and discipline for. ISP is the most anticlimactic yet — it's barely even a reframing. It's just how the language works.

## Modules as natural boundaries

In OOP, you'd split a fat service class into focused interfaces. F# has modules instead — and the difference is subtle but nice:

```fsharp
module UserQueries =
    // just reads
    let getById (db: DbConnection) (userId: UserId) : Async<Result<User, QueryError>> =
        // ...

    let search (db: DbConnection) (criteria: SearchCriteria) : Async<Result<User list, QueryError>> =
        // ...

module UserCommands =
    // validates and writes
    let create (db: DbConnection) (userData: UnvalidatedUser) : Async<Result<UserId, ValidationError>> =
        // ...

    let updateEmail (db: DbConnection) (userId: UserId) (newEmail: EmailAddress) : Async<Result<unit, UpdateError>> =
        // ...

module UserNotifications =
    let sendWelcome (sendEmail: SendEmail) (user: User) : Async<Result<unit, EmailError>> =
        // ...
```

Each module groups related functions. But a consumer picks _individual functions_, not entire modules. If your handler needs `getById` and `sendWelcome`, it takes those two function parameters. It doesn't take a `UserQueries` module and a `UserNotifications` module. There's no implicit coupling to the other functions in those modules.

```fsharp
let handleGetUser
    (getUser: UserId -> Async<Result<User, QueryError>>)
    (userId: UserId) =
    // only depends on getUser, nothing else
    getUser userId
```

The handler doesn't know or care that `getUser` came from `UserQueries`. It just needs a function with the right shape. You could swap in a cached version, a mock, a function that reads from a file — anything with the signature `UserId -> Async<Result<User, QueryError>>`.

## The FP version of the problem

Fair warning though: FP isn't totally immune to ISP-like issues. You _can_ create record types that carry too much:

```fsharp
// This is the FP version of a fat interface
type OrderContext = {
    GetUser: UserId -> Async<Result<User, UserError>>
    SaveOrder: Order -> Async<Result<unit, DbError>>
    SendEmail: EmailAddress -> EmailContent -> Async<Result<unit, EmailError>>
    LogEvent: string -> unit
    GetConfig: unit -> AppConfig
    CheckInventory: ProductCode -> Async<bool>
    CalculateShipping: Address -> Weight -> Price
    ValidatePayment: PaymentInfo -> Async<Result<unit, PaymentError>>
}
```

If you pass this to a function that only needs `GetUser` and `SaveOrder`, you've just created a fat interface with extra steps. The function _technically_ has access to `SendEmail`, `CheckInventory`, and everything else. Not great.

The fix? Same as in OOP, but simpler: just take the functions you need as individual parameters instead of bundling them into a record. If you find yourself passing around a record with eight function fields, that's a code smell — the same code smell as a nine-method interface, just wearing a functional hat.

```fsharp
// Better: just take what you need
let placeOrder
    (getUser: UserId -> Async<Result<User, UserError>>)
    (saveOrder: Order -> Async<Result<unit, DbError>>)
    (order: UnvalidatedOrder) =
    // only depends on what it actually uses
```

So yes, you _can_ violate ISP in FP. You just have to go out of your way to do it. The default path — functions as parameters — gives you ISP for free.

![Nailed it](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExN3BkdHQ1OGZhOXhvZGl2ZWd0MzVzb3NqaGN2Y2plbXAxbHBtMGd4OCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYt5jPR6QX5pnqM/giphy.gif)

## Wait — isn't that also Dependency Inversion?

If you've been reading carefully (and if you've read [my earlier post on functional DI](/posts/making-impossible-states-impossible-with-functional-dependency-injection/)), you might be thinking: "That partial application stuff isn't just ISP. That's DIP too."

Yeah. It is.

Uncle Bob's Dependency Inversion Principle:

> "High-level modules should not depend on low-level modules. Both should depend on abstractions."

In OOP, "depend on abstractions" means: create an interface, have the high-level code reference the interface, and inject the concrete implementation at runtime. You need an interface definition, an implementation class, a DI container or factory to wire it up, and lifecycle management to keep it all from leaking. It works, but it's a lot of ceremony for a simple idea.

In F#, a function parameter _is_ an abstraction. When `processOrder` takes `(validateProduct: ProductCode -> Result<ValidProduct, ValidationError>)`, it depends on a function type — not on `Catalog.validateProduct` specifically, not on any module, not on any concrete implementation. The function type is the abstraction.

The concrete implementation gets plugged in at the composition root:

```fsharp
// High-level policy: doesn't know about Groq, Bluesky, or RSS
let run (log: Log) (historyIO: HistoryIO) (input: Input) (transform: Transform) (output: Output) =
    // ...

// Composition root: this is where concrete meets abstract
let transform = Transform.Groq.transform (requireEnv "GROQ_API_KEY")
let output = Output.Bluesky.post (requireEnv "BLUESKY_HANDLE") (requireEnv "BLUESKY_PASSWORD")
let input = Input.rss "https://cekrem.github.io/index.xml"

run log history input transform output
```

That's the blog-bot example from earlier. `run` is the high-level policy — it orchestrates the pipeline. `Transform.Groq.transform` and `Output.Bluesky.post` are low-level details. They never meet inside `run`. The composition root (in `Program.fs`) is the only place that knows about both.

That's dependency inversion. No interface keyword. No IoC container. No abstract class. Just... functions and partial application.

I [wrote about this pattern before](/posts/making-impossible-states-impossible-with-functional-dependency-injection/) with both Elm and F# examples, borrowing directly from Wlaschin's [Domain Modeling Made Functional](https://amzn.to/44B0dQE). His version looks like this:

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

Dependencies first, real input last. Partially apply the dependencies, and the caller gets a clean `UnvalidatedOrder -> Async<Result<ValidatedOrder, ValidationError>>` — no idea what's behind it.

## Why I'm covering both in one post

I was originally planning to give DIP its own post. But writing the ISP section, I kept bumping into the same examples, the same patterns, the same code. The blog-bot `run` function demonstrates ISP (each dependency is a minimal function type) _and_ DIP (the pipeline depends on abstractions, not concretions) simultaneously. They're not the same principle — ISP is about the _size_ of your dependencies, DIP is about the _direction_ — but in FP they share a mechanism.

In OOP, ISP and DIP require different techniques. ISP means splitting fat interfaces into thin ones. DIP means creating abstractions and injecting implementations. Different patterns, different code, different design decisions.

In FP, both are just: take the functions you need as parameters. That's it. The function parameter is already small (ISP) and already abstract (DIP). You'd have to go out of your way to violate either one.

So giving DIP its own post would have meant re-showing the same `processOrder` example with the same partial application pattern and going "look, dependency inversion!" Which... felt a bit silly when it was already right there in the ISP post.

## Noticing a theme yet?

Five principles in, and I keep landing on the same thing. Scott Wlaschin's [Functional Programming Design Patterns](https://fsharpforfunandprofit.com/fppatterns/) talk has that famous slide listing GoF patterns on one side and their FP equivalents on the other: "Functions." "Also functions." I think the same thing happens with SOLID:

- **SRP**: Pure functions can't have hidden side effects — [they naturally do one thing](/posts/solid-in-fp-single-responsibility/).
- **OCP**: Union types and pattern matching flip the expression problem — [the compiler enforces completeness](/posts/solid-in-fp-open-closed/).
- **LSP**: No mutation, no null, no exceptions — [most violations are structurally impossible](/posts/solid-in-fp-liskov-substitution/).
- **ISP**: Function types _are_ single-method interfaces. You can't make them fat.
- **DIP**: Function parameters _are_ abstractions. Partial application _is_ injection.

## What this tells us about SOLID

So... is SOLID useless in FP?

I don't think so. The _thinking_ behind each principle is still valuable. "Don't force consumers to depend on things they don't use." "Depend on abstractions, not concretions." "A module should have one reason to change." These are good ideas regardless of paradigm.

But the _discipline_ that SOLID requires in OOP — the design patterns, the interface hierarchies, the IoC containers, the code review vigilance — a lot of that becomes structural in FP. You don't need to _remember_ ISP when your functions are already small. You don't need a DI framework when partial application exists. The language does the remembering for you.

ISP might be the most anticlimactic of the bunch. Functions are small. DIP might be the most satisfying — watching an entire DI container dissolve into three lines of partial application is genuinely nice. But the deeper point is the same one I've been circling for five posts: these principles are solving OOP problems. When you leave OOP behind, some of those problems tag along and need real thought (SRP, OCP to an extent), and some just evaporate (ISP, most of LSP).

DIP is somewhere in between. The _mechanism_ gets simpler — no interfaces, no containers, no lifecycle management. But the _architectural decision_ doesn't go away. You still need a composition root. You still have to decide what depends on what. That `Program.fs` in blog-bot where all the concrete implementations meet? That's a real design decision, not an accident. Partial application handles the wiring, but _you_ still have to decide where the wiring happens and what plugs into what.

(And we all know how well the discipline-based alternatives hold up at 11pm before a release.)

---

That's all five. When I started this series, I said I had no idea if I'd manage to make all of them compelling. Turns out some were more compelling than others — and a couple basically wrote themselves. I think the honest conclusion is that SOLID in FP is less about applying the principles and more about noticing that you already are.

If you've followed along this far: thanks. And if this made you curious about F#, go read Wlaschin's [Domain Modeling Made Functional](https://amzn.to/44B0dQE). It's the book that made all of this click for me.
