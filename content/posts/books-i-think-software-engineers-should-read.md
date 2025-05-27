---
title: "Books I Think Software Engineers Should Read"
description: "...Because reading potentially makes you smarter 🤓"
tags:
  ["programming", "career", "software engineering", "architecture", "learning"]
date: 2024-12-18
---

What follows is a non-ordered & non-exhaustive list of great programming books that I'd recommend every ambitious software engineer. The language specific ones are obviously not for everyone.

Disclaimer: I have not read all of these from cover to cover. I've read most, but some are on my list of books to read next based on suggestions and/or reviews from people I trust.

## General

- [Deep Work: Rules for Focused Success in a Distracted World](https://amzn.to/4gAOaHa) – Not a programming / software engineering book at all per say, but a _highly_ recommended read regardless. If you read one book on this list, go for this one, for real.
- [Clean Code](https://amzn.to/3VIleoE), [Clean Code*r*](https://amzn.to/3ZZu3Ny) and [Clean Architecture](https://amzn.to/4iAc8o1) — These Uncle Bob classics are great. I'm currently enjoying the architecture one _on audible_, that's a first for me with a software engineering book. Simply great, and truly a pleasant read/listen.
- [The Pragmatic Programmer: Your Journey To Mastery](https://amzn.to/4gjf4Ud) — A classic, and a good one at that!
- [Staff Engineer: Leadership beyond the management track](https://amzn.to/41GYOrQ) — This one I find a tiny bit boring, to be perfectly honest, but still very helpful. Lot's of insight about "all the other stuff" (not coding).
- [The Effective Engineer: How to Leverage Your Efforts In Software Engineering to Make a Disproportionate and Meaningful Impact](https://amzn.to/4gjc9ex) — I haven't read this one yet, but it's been highly recommended to me by trustworthy people. And how about that killer subtitle, ey?

## Elm

- [Elm in Action](https://amzn.to/4kBLTxA) – This is The Book™ on Elm, by Richard Feldman (author of [the Roc Programming language](https://www.roc-lang.org)). It's simply great. The last few chapters are a tiny bit overwhelming if you're new to Elm, but thankfully [Elm Land](https://elm.land) solves much of that stuff for you.
- [The Elm Community](https://elm-lang.org/community) –Not a book at all, I know, but since this is my all time favorite programming community I can't help but mention it anyways. The Slack, the Discourse, Subreddit – it's all great.

## Golang

- [The Go Programming Language](https://amzn.to/4fruZyJ) —
  Kind of obvious, this one. But a great classic! I remember enjoying the chapter about UTF-8 a lot, as well as the generally thorough explanations of how and _why_ Golang behaves.
- [Concurrency in Go: Tools and Techniques for Developers](https://amzn.to/3Bpf4TL) — This is a truly great programming book! Even though Golang is made for concurrency, it's still very possible to mess up. This book shows you how it's done. What's a bit cool (🤓) is that it predates the `context.Context` interface, and as such suggests using a manual "done channel" to enable canceling of coroutines. It shows the author's insight that an exact pattern like that was introduced with the `Context.Done()` method introduced later in the language. For more on that, check out [this git diff](https://github.com/cekrem/goutils/commit/0a511038efd9186cf204d503f7ff37c83b5c5838), on a small golang utility library I started on way back.
- Feel free to skip this one, though: [Learning Functional Programming in Go](https://amzn.to/3P1uq3R) — This book should, IMHO, rather have been a tweet. Something like this: "Go is not really suited for functional programming, I'd advice you not to do it at scale." Fun fact: this book is actually what got me into [Kotlin](#kotlin). All that talk about [tail call optimization](https://stackoverflow.com/questions/310974/what-is-tail-call-optimization) (and how Golang is _not_ doing that...) got me searching for more functional fun outside of Elm, Haskell and Lisp.

## Python

- [Fluent Python: Clear, Concise, and Effective Programming](https://amzn.to/3Dyiyni) — I read this one on my Kindle, actually, before I learned that Kindle's not where programming books really shine. That aside, I have nothing but fond memories from the first edition, and I've heard the updates on the second edition are really worthwhile. If you want to read _one_ Python book, this is it.
- [Automate the Boring Stuff with Python, 2nd Edition: Practical Programming for Total Beginners](https://amzn.to/4gx5tt2) — This one is also cool! While mainly targeting "total beginners", it's also suitable for seasoned programmers who don't usually work in Python, but want to leverage its super fast scripting capabilities to automate stuff.

## Kotlin

- [Functional Programming in Kotlin](https://amzn.to/4gjT1wU) — Functional Programming _and_ Kotlin in the same book title?! No-brainer. This one is great!
- [Kotlin in Action](https://amzn.to/402VYev) — One of two "general Kotlin books" I'd recommend.
- [Mastering Kotlin](https://amzn.to/3ZYEdxN) — The other one :)

## Lisp

- [Land of Lisp: Learn to Program in Lisp, One Game at a Time!](https://amzn.to/4izuO7c) — A bit whimsical, but then again Lisp is _not_, so in sum a semi-serious book. I liked it ¯\\_(ツ)_/¯
- [On Lisp: Advanced Techniques for Common Lisp](https://amzn.to/4gf8sq2) — _The_ Lisp book, by mr. Paul Graham himself. Hats off, hands down.
- [Practical Common Lisp](https://amzn.to/3ZVWUSW) — The other Lisp book, I guess? Great.

## React

- [Advanced React: Deep dives, investigations, performance patterns and techniques](https://amzn.to/4iFXVWq) — I've actually read (or at least skimmed) quite a few books on React — I even started writing one, way back — but this is the only one I think is worth recommending. If you're a complete beginner there are probably other/better options, but given that you're at least semi-familiar with thinking in React, this is The One.

## Rust

- [The Rust Programming Language](https://amzn.to/4gFp7D3) — "The Book", as official as it gets, and quite good at that.
- [Programming Rust](https://amzn.to/400rtXM) — Less official, but a fine resource regardless. The two complement each other (and of course overlap a bit as well).

Warning: I might add more later.
