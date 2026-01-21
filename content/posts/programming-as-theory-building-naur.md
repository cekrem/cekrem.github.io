+++
title = "Programming as Theory Building: Why Senior Developers Are More Valuable Than Ever"
description = "Peter Naur's 1985 theory of programming explains why experience matters more in the age of AI-generated code"
date = 2025-06-26
author = "Christian Ekrem"
tags = ["programming", "software-engineering", "theory", "llm", "ai", "craft", "programming-as-theory-building"]
draft = false
+++

*Update: I've written a follow-up exploring how AI degrades the institutions where theory-building happens: [Part II: When Institutions Crumble](/posts/programming-as-theory-building-part-ii/)*

---

In 1985, computer scientist Peter Naur wrote a prescient essay called ["Programming as Theory Building"](https://pages.cs.wisc.edu/~remzi/Naur.pdf) that feels more relevant today than ever. As we watch junior developers reflexively accept LLM-generated code they don't understand, and see codebases balloon with theoretically orphaned implementations, Naur's central thesis becomes crystal clear: **a program is not its source code**.

## The Theory Behind the Code

Naur argues that programming is fundamentally about building a theory—a **shared mental model** of how a system works, why it works that way, and how it should evolve. The source code is merely a written representation of this theory, and like all representations, it's lossy. Critical knowledge about intent, design decisions, trade-offs, and the reasoning behind architectural choices exists only in the minds of the people who built the system.

When those people leave, the theory dies with them. The code remains, but the _program_—the living, breathing system with its context and rationale—is gone.

## The Theory-Loss Crisis

Today's development landscape has created a perfect storm for what I call "theory-less" code:

**Reflexive AI Usage** has become the norm. Developers instinctively reach for LLM-generated solutions without the cognitive struggle that builds understanding. As [I've written before](/posts/coding-as-craft-going-back-to-the-old-gym/), this "reflexive AI usage" robs us of growth opportunities—the moments when we're stuck, step away, wrestle with the problem, and finally achieve that rewiring "aha!" moment that makes us permanently better engineers.

**Domain-Blind Code Generation** represents an even more extreme case. LLM-generated code isn't just theory-less—it's **nobody's theory**. It emerges from statistical patterns without understanding the business domain, the system's conceptual model, or the nuanced trade-offs that domain experts have encoded into the architecture. The code might pass tests, but it exists in a theoretical and domain vacuum. With no `git blame` pointing to a human being at a nearby desk, I'm at a severe disadvantage trying to discern the how and more importantly the _why_ of the code.

**The Integration Problem**: When developers accept AI-generated code without deep understanding, they're not just copy-pasting syntax—they're importing foreign architectural decisions into their system (that's in the _best_ case scenario where the code 1) works and 2) doesn't do anything absurdly dangerous!). These decisions may contradict the domain model, violate established patterns, or introduce subtle inconsistencies that won't surface until the system is under stress.

The result? Codebases that work initially but become increasingly incoherent as they grow. Systems where the code no longer reflects the domain language. Technical debt that compounds because nobody understands the theoretical foundations that once gave the system its integrity.

This crisis isn't new, mind you. I remember that poor trainee at a previous company who logged into production and ran `rm -rf /` because StackOverflow told him it would fix his symlink issues.

But the scale of it all is what's exploded! The developer population doubles roughly every five years, meaning at any moment, half of all developers have less than five years of experience. (If you include all the yolo vibe coders out there, the numbers are even scarier!) Now arm those inexperienced developers with AI tools that generate entire functions instantly, and you get a perfect storm: more juniors than ever, with more powerful copy-paste tools than ever, operating with less understanding than ever.

The trainee lost in StackOverflow at least had to search, read, and manually type his destructive command. Today's developer accepts AI-generated functions with a keystroke, importing architectural decisions they've never examined (let alone downright dangerous code).

## Why Senior Developers Are More Valuable Than Ever

This brings us to why experienced developers have become critically important:

**Domain Theory Builders**: Senior developers don't just write code—they construct and maintain the theoretical framework that connects business domains to software architecture. They understand not just _what_ the code does, but _why_ it exists, how it models the business domain, and how it should evolve as understanding deepens. They're the ones who ensure the code speaks the language of the domain experts.

**Architectural Theory Guardians**: When junior developers or LLMs produce code, senior developers serve as the critical bridge between raw implementation and coherent system design. They can evaluate whether new code aligns with or violates the system's theoretical foundation—not just technically, but conceptually. They understand the difference between code that works and code that belongs.

**Intentional AI Collaborators**: Senior developers practice what I call "intentional collaboration" with AI rather than reflexive usage. They understand everything they integrate, challenge AI's assumptions, and ensure that generated code serves the system's theoretical coherence rather than undermining it. If they use AI, it's for the boring parts while preserving the craft elements that require human judgment. (If you're stuck in a language where you, say, need to hand craft twenty-something factories doing the exact same thing but for different services or props, this would be a fair thing to outsource to Claude Code or whatever.)

**Theory Teachers and Craft Mentors**: Perhaps most importantly, senior developers transfer both theory and craft to others. They mentor junior developers not just in syntax or patterns, but in the deeper understanding that transforms scattered code into coherent programs. They teach the art of wrestling with problems, the value of cognitive struggle, and the discipline of understanding before implementing.

## The Irreplaceable Human Element

Naur's essay reminds us that programming is fundamentally a human intellectual activity. The real product of programming isn't the code—it's the theory, the understanding, the mental model that gives the system coherence. While LLMs can generate syntactically correct code, they cannot participate in theory building. They cannot understand business context, make thoughtful trade-offs, or maintain the conceptual integrity that separates good software from mere working code.

While good documentation, [Architectural Decision Records](https://adr.github.io), and clean, legible code **help**, all written words—whether inside or outside our codebase—ultimately fail to capture all that our programs **are**, **do**, and **mean**.

The most successful teams will be those that recognize this fundamental distinction: LLMs might be useful for truly mechanical tasks (generating boilerplate, writing basic tests, creating those twenty-something nearly-identical factories), but the core work of programming—the theory building that transforms business requirements into coherent software models—must remain a deeply human activity.

## Preserving the Theory

Organizations serious about software quality must invest in theory preservation:

- **Documentation that captures intent**, not just implementation
- **Knowledge sharing practices** that transfer mental models, not just procedures
- **Code review processes** that evaluate theoretical consistency, not just correctness
- **Mentorship programs** that develop theory-building skills in junior developers

## The Craft of Theory Building

Peter Naur understood something in 1985 that we're rediscovering today: programs are human constructs that require human understanding to thrive. As we navigate an era of abundant code generation, the developers who can build, maintain, and transfer the theories that make code meaningful become our most valuable assets.

This isn't about rejecting AI or clinging to outdated practices. It's about preserving the essential human elements: domain understanding, architectural coherence, and the craft of building systems that not only work but make sense. It's about maintaining the ability to wrestle with problems, to understand deeply before implementing, and to ensure our code reflects the rich mental models that make software systems truly maintainable.

The question isn't whether LLMs can write code—they obviously can. The question is whether we can maintain the human theoretical frameworks that transform that scattered code into coherent, domain-aware, lasting programs.

In a world pushing for reflexive AI usage, senior developers who practice intentional collaboration (if any!) with AI while preserving the craft of programming become the guardians of software quality. They're the ones who ensure that our systems remain comprehensible to humans, true to their domains, and built upon solid theoretical foundations.

When the dust of this Null-Stack Vibe Bonanza has settled, they'll once again be looking for senior developers.

---

*Continue reading: [Part II: When Institutions Crumble](/posts/programming-as-theory-building-part-ii/)*
