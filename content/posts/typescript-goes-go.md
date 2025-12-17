+++
title = "TypeScript Goes Go: What Does This Mean for Us?"
date = "2025-12-17"
description = "Microsoft is rewriting the TypeScript compiler in Go. A 10x speedup sounds great, but what does it actually mean for day-to-day web development?"
tags = ["typescript", "go", "performance", "tooling", "web-development"]
draft = false
+++

Anders Hejlsberg announced that Microsoft is porting TypeScript to Go. Yes, _that_ Go. Not Rust (which everyone expected), not C++ (which would be reasonable), but Go.

I'll admit my first reaction was a grin. Go is one of those languages I genuinely enjoy working with - simple, pragmatic, fast. My second reaction was "wait, 10x faster?" And my third was "okay, this makes a lot of sense actually."

## The Numbers

Let's start with what matters. According to the [official announcement](https://devblogs.microsoft.com/typescript/typescript-native-port/), we're looking at:

| Codebase              | Current | Native | Speedup |
| --------------------- | ------- | ------ | ------- |
| VS Code (1.5M LOC)    | 77.8s   | 7.5s   | 10.4x   |
| Playwright (356K LOC) | 11.1s   | 1.1s   | 10.1x   |
| TypeORM (270K LOC)    | 17.5s   | 1.3s   | 13.5x   |

Editor startup for VS Code's codebase drops from 9.6 seconds to 1.2 seconds. Memory usage is roughly halved. These aren't minor improvements - they're the difference between "go get coffee" and "already done."

For those of us who've sat through multi-minute TypeScript builds on larger codebases, this is genuinely exciting. I've worked on projects where `tsc --noEmit` was basically a meditation practice.

## Why Go?

This is where it gets interesting. The JavaScript/TypeScript ecosystem has seen a wave of performance-focused tooling rewritten in systems languages - esbuild (Go), SWC (Rust), oxc (Rust). So why did they choose Go?

I think it's actually a great choice:

1. **Go's garbage collector** plays nicely with the kind of memory allocation patterns a compiler needs - and frees the team from manual memory management headaches
2. **Structural similarity** to the existing TypeScript codebase makes the port more straightforward (ironically, TypeScript to Go is a more direct translation than TypeScript to Rust would be)
3. **Simplicity and readability** - Go's philosophy of "one obvious way to do things" makes for maintainable code, which matters when you're building something this critical
4. **The team knows Go well** - an underrated reason to choose any technology, honestly

Nothing against Rust - it's a fantastic language. But Go's pragmatic approach feels very aligned with TypeScript's own philosophy. Both languages prioritize developer productivity and "just working" over theoretical purity.

The internet predictably had opinions about this choice. But I've learned to be suspicious of the "you should have used X" crowd. The TypeScript team has been maintaining one of the most successful language tools for over a decade. They probably know what they're doing. ¯\\_(ツ)_/¯

## The Versioning Story

Here's how the transition works:

- **TypeScript 6.x** - The current JS-based compiler, continuing to receive updates
- **TypeScript 7.0** - The new Go-based "native" compiler

The plan is to maintain TypeScript 6 until TypeScript 7 reaches maturity. So you're not being forced off a cliff. If your project depends on specific APIs or configurations that aren't ready in TypeScript 7, you can stick with 6 for a while.

They're also moving to LSP (Language Server Protocol), which has been on the wishlist forever. This should make TypeScript play nicer with editors beyond VS Code.

(Codenames, if you're curious: "Strada" for the original TypeScript and "Corsa" for the Go port. Both Italian car terms. Microsoft loves a theme.)

## What This Actually Means for You

Let's let the rubber hit the road: for most of us, this changes nothing about how we write code. TypeScript will still be TypeScript. Your `interface User { name: string }` isn't going anywhere. The type system works the same way.

What changes is the _experience_:

- **Faster CI builds** - Those 10x improvements translate directly to shorter pipelines
- **Snappier editors** - Autocomplete and type checking that actually keeps up with your typing
- **Larger projects become viable** - Monorepos that currently crawl might actually work

The TypeScript team specifically mentions that features "once considered out of reach" are now possible. Instant error listings across entire projects. More advanced refactorings. Deeper analysis that was previously too expensive to compute.

## The Elephant in the Room: AI Tooling

Here's a bit buried in the announcement that caught my attention:

> "This new foundation goes beyond today's developer experience and will enable the next generation of AI tools to enhance development."

AI coding assistants need fast, low-latency access to semantic information. When your Copilot or Claude or whatever needs to understand your codebase to suggest meaningful completions, a 10x faster type checker makes a real difference.

I'm not sure how I feel about optimizing for AI. But I also can't pretend that AI-assisted coding isn't becoming a significant part of how software gets written. (I've [written before](/posts/claude-code-game-changer-or-just-hype/) about trying to stay head instead of tail in that relationship.)

## My Take

I think this is good news:

1. **Faster tools make developers happier** - this is just true
2. **Go is a solid choice** - pragmatic, fast, maintainable
3. **The migration path is sane** - they're not breaking everything overnight
4. **It shows investment in TypeScript's future** - Microsoft could have let it stagnate

Will it save TypeScript from its fundamental limitations? No. [TypeScript still won't save you](/posts/why-typescript-wont-save-you/) from bad architecture, missing validation, or the escape hatches that let lies into your type system. A faster compiler doesn't make `as unknown as User` any safer.

But a faster compiler does make the development experience better. And in a world where we're competing with "just use JavaScript" and "try this other language," a snappier TypeScript is a meaningful improvement.

## When Can You Try It?

Timeline from the original March announcement:

- **Mid-2025**: Preview of native `tsc` for command-line typechecking
- **End of 2025**: Feature-complete project builds and language service

We're now past that mid-2025 milestone, so early previews should already be available. For widespread production use, 2026 seems realistic.

The code is already available on GitHub under the same license as TypeScript. You can build and run it today if you're curious (and don't mind incomplete features). Check the TypeScript blog post for the repo link and build instructions.

## Final Thoughts

Over a decade ago, TypeScript was a weird Microsoft experiment that most of us ignored. Now it's arguably the default choice for serious JavaScript development. The team clearly isn't resting on that success.

Will rewriting the compiler in Go be remembered as a brilliant move or a strange detour? I genuinely don't know. But I'm cautiously optimistic. Faster tools are almost always better tools, and the TypeScript team has earned some trust.

Now if you'll excuse me, I'm going to go write some Elm. ;)
