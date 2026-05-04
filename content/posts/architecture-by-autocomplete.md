+++
title = "Architecture by Autocomplete"
description = "AI defaults to primitives because primitives dominate its training data. The gap between that and theorized code is something you can grep for."
date = 2026-05-04
author = "Christian Ekrem"
tags = ["programming", "software-engineering", "theory", "llm", "ai", "craft", "types", "programming-as-theory-building"]
draft = false
+++

There's a specific code smell that shows up in AI-generated code, and once you see it you can't un-see it: primitive obsession all the way down to the domain core. `string` for emails. `string` for IDs. `Map<string, any>` whenever the situation gets hairy. Working code, passing tests, ships fine. And yet a developer who'd actually thought about the domain would not have written a single one of those types that way.

That gap is the post.

This sits alongside my earlier two on [Programming as Theory Building](/posts/programming-as-theory-building-naur/) and [the institutions where theory lives](/posts/programming-as-theory-building-part-ii/). Those were arguments. This one is closer to a diagnostic.

## The Default Reach

When you ask an AI to add a feature, watch what types it grabs. `string` for emails. `string` for IDs. `string` for currency codes. `int` for "amount." `Map<string, any>` whenever the situation gets hairy. `Date` (just `Date`!) for things that have non-trivial timezone semantics in your actual domain.

This isn't a moral failing of the model. It's statistics. The bulk of code on the internet — the code these models trained on — is full of primitives. Tutorials use primitives. Stack Overflow answers use primitives. Bootcamp homework uses primitives. The textbook chapter you read last week almost certainly did too. So when the model spits out "the most likely next token," it spits out what most code looks like. The average.

But theorized code doesn't look average.

## What the Theory Looks Like

Here's roughly what an AI tends to hand you:

```typescript
function confirmOrder(orderId: string, customerEmail: string, total: number) {
  if (!customerEmail.includes("@")) throw new Error("bad email");
  if (total <= 0) throw new Error("bad total");
  // ...
}
```

And here's what someone who's actually thought about the domain writes:

```typescript
type Email = { readonly _tag: "Email"; readonly value: string };
type OrderId = { readonly _tag: "OrderId"; readonly value: string };
type PositiveAmount = {
  readonly _tag: "PositiveAmount";
  readonly value: number;
};

function confirmOrder(
  orderId: OrderId,
  customerEmail: Email,
  total: PositiveAmount,
): Confirmed<Order> {
  // ...
}
```

(In F# or Elm this is a one-liner per type, btw, which is part of why Wlaschin keeps yelling at the rest of us. Different post.)

The second version cost the developer thirty seconds and a handful of keystrokes. What did those keystrokes buy? They froze a piece of theory into a form the compiler enforces. _An email is not a string._ _An order ID and a customer email cannot be transposed by a tired junior at 4am._ _A total is positive by construction, and if it isn't, this code never runs in the first place._

Each of those types is a fragment of the program's theory in Naur's sense, encoded somewhere a future maintainer (human or otherwise) cannot ignore. The first version's theory lives in the head of whoever wrote it. In this case: nobody. The second version's theory lives in the type signature, where my future self can still read it.

## You Can Grep for It

All this is testable, by the way.

Pull up a codebase that's been on heavy AI assistance for six months or so and run something like:

```
rg ": string" --type ts | wc -l
rg ": Map<string" --type ts | wc -l
rg ": any" --type ts | wc -l
```

Then run the same on a codebase where someone has been guarding the gates. The ratio is not subtle. Theorized codebases bristle with little domain types. Vibe codebases are an ocean of `string`.

(The cutoff is fuzzy, mind you. There are good reasons to reach for `string` — at API boundaries, in adapters, when you really do just mean "any sequence of characters." The diagnostic isn't "no primitives anywhere." It's "primitives all the way down to the domain core, where the domain types should have lived.")

## The Numbers Caught Up

For a while this was vibes. Senior devs grumbling at PRs, nobody able to point to a chart.

Then [GitClear's report on 153M lines of code](https://www.gitclear.com/ai_assistant_code_quality_2025_research) put numbers on it. Copy-pasted lines climbed from 8.3% in 2020 to 12.3% in 2024 — and for the first time in the dataset's history, copy/paste exceeded moved (refactored) code within a commit. Code churn (lines reverted or rewritten within two weeks of being authored) is projected to roughly double from its pre-AI baseline. CodeRabbit's [State of AI vs Human Code Generation](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) report — a review of 470 open-source pull requests — found AI-coauthored PRs shipped with about 1.7x more issues overall and 2.74x more XSS vulnerabilities than human-only PRs.

That's what a codebase forgetting its own theory looks like in real time. Primitive obsession is the fingerprint.

## Why the Model Can't Invent the Type

A type like `NonEmptyList<Confirmed<Order>>` is interesting because it encodes what _can't_ happen. The list isn't empty. The order isn't tentative. The compiler will refuse to run code that violates either constraint.

To invent a type like that, you have to model the negative space of the domain. You have to know what shouldn't be representable, where the impossible lives, which transitions a real order can never take. None of that is anywhere in a training corpus, because training data is the record of what _was_ written. It can't be the record of what couldn't have been written.

When a senior dev reaches for a sum type or a smart constructor, that's the theory becoming visible. The compiler now enforces it. A future reader inherits it for free, at compile time, even after the original author has forgotten what they were thinking when they wrote it.

## The Smallest Useful Habit

If you're reviewing AI output and don't know where to start, start with the types. Count the strings. For each one, ask: is this actually a string in the domain, or a domain concept the model flattened to a string because it didn't know any better?

Most of the time the answer is the second one. And most of the time, fixing it costs a single newtype and a smart constructor. Thirty seconds of work. In exchange you lock in a piece of theory that would otherwise have to be re-derived by every future reader of the file.

Including the AI, the next time it edits the file :|
