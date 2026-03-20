+++
title = "The FP Article I Can't Seem to Finish"
description = "I've been trying to write a 'why functional programming' piece for over a year. Here's why it keeps falling apart."
tags = ["functional-programming", "fsharp", "elm", "advocacy"]
date = 2026-03-20
draft = false
+++

I've been trying to write an article about why developers should learn functional programming. I have three drafts. In Norwegian, for some reason. None of them are good enough to publish.

I believe the argument. Spent the last year proving it to myself with [an Elm book](https://leanpub.com/elm-for-react-devs), 125,000+ lines of production Elm, [a subtle mindset switch towards F#](/posts/why-i-hope-i-get-to-write-a-lot-of-fsharp-in-2026/), and [a whole SOLID-in-FP blog series](/posts/solid-in-fp-interface-segregation/). But every draft I write sounds like a sales pitch, and I can't make myself hit publish.

## The usual pitch

The standard FP advocacy article goes something like: "You're already using functional concepts! `map`/`filter`/`reduce`, hooks, Redux — all borrowed from FP. But you're doing it through an imperative language. It's like playing tennis with a badminton racket."

I know, because I've written that exact sentence. Twice. In two separate drafts. (Both in Norwegian, so at least the international audience was spared.)

It's _true_. It's also completely unconvincing. When someone is shipping features on a deadline, "you're holding the racket wrong" doesn't help.

## What we oversell

Ian Duncan recently wrote about [what functional programmers get wrong about systems](https://www.iankduncan.com/engineering/2026-02-09-what-functional-programmers-get-wrong-about-systems/), and one point stuck with me: we tend to conflate _program_ correctness with _system_ correctness. We talk about types preventing bugs like that's the whole story, but production isn't one program. It's deployments at different versions talking to each other, database migrations in flight, message queues carrying data whose schema changed two releases ago. The type checker sees none of that.

Types aren't useless — I just need to stop doing what I keep doing in my drafts: presenting compile-time safety like it solves problems it doesn't.

## What actually convinced me

Nobody argued me into functional programming. I just got frustrated enough with the alternative.

I was maintaining a React codebase with `useReducer` everywhere, and the `default` case in every switch statement was silently swallowing bugs. Then I spent a few months in Elm, where the compiler [refuses to let you ignore a case](/posts/solid-in-fp-liskov-substitution/). When I came back to React, I couldn't unsee it — not from some argument I'd read, but from having spent months where the problem just didn't exist.

That's the thing that actually works. Show someone a problem they recognize, then show them what it looks like when the language handles it.

## Show, don't pitch

This F# function handles a result from loading a user:

```fsharp
type LoadResult =
    | Success of User
    | NotFound
    | ServerError of string

let handleResult result =
    match result with
    | Success user -> showProfile user
    | NotFound -> showEmptyState ()
    | ServerError msg -> showError msg
```

If I add a new case — say `| Unauthorized` — the compiler flags every `match` that doesn't handle it. Immediately, before I've even saved the file.

If you've ever shipped a bug because a switch fell through to `default`, you know what I mean.

But here's the part my drafts keep leaving out: exhaustive matching is a property of a single program at a single moment. It doesn't prevent your v2 API from receiving v1 data. It doesn't catch a field whose type stayed `string` but whose meaning changed from cents to dollars. Duncan is right about this, and I need to say so instead of pretending the compiler sees everything.

What exhaustive matching _does_ give you is confidence that within this version, you've considered every case. I'll take that.

## The pitch that isn't a pitch

After a year of failing to write the definitive "why FP" article, I think I know why it never works: you can't talk someone into thinking differently about code. My three Norwegian drafts are proof.

What _has_ worked is way less glamorous. You pair with someone, they hit a familiar bug, and you show them what the same code looks like in F#. Maybe they get curious. Maybe they don't.

The best FP advocacy I've done was actually a pull request where a colleague read the code and asked "wait, where's the error handling?" and I got to say "it's all there — the types just make it look like there isn't any."

I'll probably never finish those Norwegian drafts. But I'll keep writing [F#](/posts/why-i-hope-i-get-to-write-a-lot-of-fsharp-in-2026/) and hoping the code makes a better argument than I can. `¯\_(ツ)_/¯`
