+++
title = "LLMs Corrupt Your Documents (and the Theory Dies Twice)"
description = "Microsoft Research put numbers on it. 25% degradation over 20 interactions. No plateau."
date = 2026-04-24
author = "Christian Ekrem"
tags = ["ai", "craft", "llm", "programming", "delegation", "trust", "programming-as-theory-building"]
draft = false
+++

This week a friend sent me a paper with a title that made me laugh out loud: ["LLMs Corrupt Your Documents When You Delegate."](https://arxiv.org/html/2604.15597v1) By Philippe Laban, Tobias Schnabel, and Jennifer Neville at Microsoft Research. Not "LLMs _might_ corrupt" or "LLMs _occasionally_ introduce errors." Just the blunt statement of fact.

I appreciated that, and the veteran reader of my blog might guess already that I'm not very surprised.

## The numbers

The researchers built something called the DELEGATE-52 benchmark. Fifty-two documents across different domains, handed to nineteen different models (including "frontier" ones like Gemini 3.1 Pro, Claude 4.6 Opus, and GPT-5.4). Each model gets a document and a series of editing instructions. Twenty interactions. Just twenty. And by the end?

About 25% of the document content was degraded. For the top tier models. The ones we're supposed to trust, remember?

Average it across all nineteen models and you're looking at 50% degradation by the time the simulation ends. Half the document, silently corrupted.

They extended the experiment to 100 interactions. No plateau. The line just keeps going down. "Monotonic decline", is how they put it (how's that for a general AI revolution subtitle?). The longer you work with it, the worse things get. The damage compounds.

And here's the _extra_ kicker: short-term performance doesn't predict long-term reliability. Two models that looked nearly identical after two interactions (91.5% vs 91.1%) diverged wildly over time (48.3% vs 64.1%). So "it works on my machine" is even less reassuring than usual. The demo always looks fine. It's the twentieth, fiftieth, hundredth interaction where things fall apart -- and by then, who's still checking?

## The only domain that works

Out of all the domains they tested, only Python code showed what they called "majority readiness." Seventeen out of nineteen models hit 98% or above. Python! The most structured and mechanically verifiable domain in the whole set.

Everything else? Documents, prose, data, less structured formats? Corrupted.

Think about what that means. LLMs can handle the thing that already has a compiler checking its work. The thing where "correct" has a mechanical definition -- where there's a machine-readable spec the output can be verified against. The moment you move into territory where correctness requires _understanding_ -- where you need to know what the document is trying to say, not just whether it parses -- the models fall apart. Unstructured text has no spec. The corruption is invisible by design.

This tracks perfectly with what I've been saying about [AI excelling at the boring parts](/posts/coding-as-craft-going-back-to-the-old-gym/). Boilerplate generation, data formatting, repetitive scaffolding, test setup. The stuff with clear structure and tight constraints. The moment you need judgment, taste, or domain knowledge, you're on your own. (Or worse: you _think_ you're not on your own, because the output looks right.)

## Silent corruption

The really nasty part is _how_ these errors happen. They're sparse but severe. The model doesn't turn your document into gibberish. It makes small, confident(!) changes that look fine on a quick scan. A detail shifted. A qualification dropped. A meaning subtly altered. A sentence reordered so the emphasis lands differently. You'd have to read the whole thing carefully, comparing against the original, to catch it.

And nobody does that. That's the whole point of delegating.

So the errors accumulate. And they don't just stack -- they _interact_. An early corruption changes the context, which shifts subsequent outputs, which compounds further. It's the document equivalent of allowing nulls everywhere and wondering why things explode three layers deep. Twenty interactions in, a quarter of your document is wrong, and you probably don't know it. You're working with a corrupted version of your own work, making decisions based on text that no longer says what you think it says.

If this doesn't terrify you, I don't think you've worked with documents that matter.

## The theory dies twice

This connects to something I keep coming back to. [Peter Naur argued in 1985](/posts/programming-as-theory-building-naur/) that a program is not its source code. It's the theory -- the mental model of how and why the system works -- held by the people who built it. When those people leave, or when they never built that understanding in the first place, the theory dies and you're left with an artifact nobody truly comprehends.

What this paper shows is something worse. When you delegate document maintenance to an LLM, the theory dies _twice_. First: you didn't build the understanding, because you delegated instead of engaging with the material. Second: the LLM silently corrupted the artifact itself. So now you have neither the mental model _nor_ an accurate written representation of it.

You've lost both the map and the territory as it were.

I wrote about [reflexive AI usage](/posts/coding-as-craft-going-back-to-the-old-gym/) being like a diagnosis I don't want next to my name. This paper is the lab work confirming the diagnosis. The damage is measurable, and it gets worse over time.

## The agentic irony

The researchers also tested whether giving models tool use capabilities (web search, code execution, that sort of thing) would help. The "agentic" setup that everyone is so excited about.

But lo and behold: It made things worse. Six percent additional degradation.

"Better tooling" made it worse!

The models with the most capabilities introduced _more_ errors, not fewer. They had more ways to confidently do the wrong thing.

I'm reminded of what happened with the [19,000-line PR to Node.js](/posts/no-ai-in-nodejs-core/). More capability, more output, more surface area for silent errors that nobody has the bandwidth to catch. The scale is the problem, and giving agents more tools just increases the scale.

They also found that distractor context -- irrelevant documents sitting in the context window alongside the one you're working on -- made things worse too. And the effect compounded over time. So the more realistic the setup (long conversations, multiple files, the way people actually use these tools in practice), the worse the results.

## Staying in the old gym

What struck me reading this paper is that it takes a philosophical argument and gives it teeth. I can say [coding is a craft](/posts/coding-as-craft-going-back-to-the-old-gym/) and that outsourcing your thinking to an LLM robs you of growth. I can point to Naur and say the theory matters more than the code. But somebody will always come back with "yeah but it's faster" or "yeah but the output is fine."

Now there's a benchmark showing the output is, after thorough scrutiny, explicitly _not_ fine. It degrades silently, over time, without plateau.

So what do you do? Same thing I've been saying. You stay engaged with your own material. You write your own documents, maintain your own code, read your own diffs carefully, build your own understanding. When you delegate to an LLM, you delegate the grunt work with tight constraints and clear verification. You don't hand over the things that require judgment and then assume they'll come back intact.

The old gym is uncomfortable. It's slower. There's no AI sitting next to you telling you everything you write is brilliant. But the work that comes out of it is yours, and it doesn't degrade when nobody's looking.

That's worth something. Actually, it's worth quite a lot.
