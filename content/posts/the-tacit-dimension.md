+++
title = "The Tacit Dimension: Why Your Best Engineers Can't Tell You What They Know"
description = "In 1966, Michael Polanyi explained why some knowledge resists being written down. Sixty years later, that's the knowledge AI cannot touch — and the knowledge your senior engineers carry in their bones."
date = 2026-05-19
author = "Christian Ekrem"
tags = ["programming", "software-engineering", "theory", "llm", "ai", "craft", "polanyi", "tacit-knowledge", "programming-as-theory-building"]
draft = false
+++

In 1966, a Hungarian chemist named Michael Polanyi published a short book called [_The Tacit Dimension_](https://www.amazon.com/Tacit-Dimension-Michael-Polanyi/dp/0226672980). Its central claim is seven words long, and it is the thing the AI coding industry needs you to forget:

**We can know more than we can tell.**

Polanyi was a working scientist before he became a philosopher, and the question that bothered him was simple. How does an old chemist look at an apparatus and know it's going to fail, before the symptoms appear? How does a surgeon's hand find the right pressure without anyone teaching the exact weight? How does an experienced researcher recognise a promising line of work _before_ they can say what's promising about it?

His answer: most of what experts know cannot be put into words. Not won't — _can't_. It is structurally tacit. It lives in the body, in the practice, in the cumulative pattern-recognition of having done a thing for a long time. You can't extract it. You can't transcribe it. You can apprentice yourself to someone who has it and slowly, over years, absorb some. That's roughly the only way.

This is the part of programming knowledge that AI is structurally locked out of. Not because the models are too small, or the training corpora too narrow, or the architectures too primitive. **Because the knowledge isn't there to be trained on, and by Polanyi's definition cannot be put there.**

## What Can't Be Told

If you've been writing software for more than a few years, you already know this in your bones. You've had the experience: someone shows you a PR, you skim it, you say "this isn't right" before you can explain _what_ isn't right. Maybe ten minutes later, after you've sat with it, you can produce a defensible critique. "The dependency direction is wrong." "This is going to fight the existing error-handling pattern." But the _recognition_ came first, in a flash, before the explanation.

That's tacit knowledge at work. Your eyes have been over ten thousand PRs. You're picking up on a constellation of features — naming choices, indentation patterns, where exceptions get caught, the implicit contract a function seems to expect, the way the author tends to handle nulls. You can recognise a constellation in milliseconds. You can articulate one in maybe ten minutes, and even then incompletely.

(My favourite version of this is the senior dev who looks at a new design and says "I don't like it, but I can't tell you why yet. Give me an hour." That hour is their doing the slow, painful work of _making the tacit explicit_. Often they come back with a single sharp question that unpicks the whole thing. Sometimes they can't articulate it ever, and they have to settle for "trust me, this is going to bite us." If you've worked with someone like this, you know the value. If you haven't, I'm sorry — they're becoming rare.)

## The Articulation Era

We're living in what I want to call the **Articulation Era**. A period of software development where the only knowledge that counts is the kind you can write down. Documentation, ADRs, runbooks, READMEs, comments, type annotations, test names. The explicit dimension. Anything that isn't on the page doesn't exist.

The AI industry didn't invent this bias, but it has _operationalised_ it ruthlessly. An LLM is a maximum-articulation machine. It was trained on text; code, comments, docs, Stack Overflow answers, blog posts. Every sentence in its training corpus is, by definition, _something somebody wrote down_. So when you ask it to generate code, what comes back is the average of all the explicit knowledge that's ever been recorded about that kind of problem.

What never makes it in, though:

- The unwritten convention that "we never throw exceptions across this module boundary, even though the type signatures allow it."
- The shared team understanding that "the `User` type is for the public-facing API; for internal flows we use `Account`."
- The fact that the senior who built the auth system three years ago designed it for a specific failure mode the docs don't mention (and that nobody has hit since, because of the design).
- The half-conscious smell that a particular function "wants to be split in two," even though no current line of it is, strictly speaking, wrong.

None of this is in the training data. None of it _can_ be in the training data, because it was never written down. The tacit dimension is structurally absent.

This is not a problem more training or better models can fix. Rather, it's a problem the entire production process of AI excludes by construction.

## Three Failure Modes You Can Already See

Once you have the frame, three specific failure modes start showing up everywhere in AI-assisted codebases. They compound.

**Articulation Bias** is the systematic preference, baked into AI tooling, for the kind of knowledge that _can_ be written down. An AI assistant is happy to consult your README and your type definitions. It cannot consult the seventeen tribal conventions your team has accumulated over four years. So it generates code that adheres to the articulated rules and quietly violates the unarticulated ones. The PR passes review by the bot. It fails review by the human who's been there since the beginning.

**The Fluency Mask** is what happens when AI's verbal fluency about code gets mistaken for understanding of code. Ask an LLM why a certain pattern is used in your codebase and you'll get a confident, articulate, plausible explanation. That explanation is generated from a thousand similar-looking codebases on GitHub. It has no relationship to _your_ codebase's actual reasons. The fluency is real. The "knowing" isn't. (This is, by the way, why "explain this code to me" is one of the most misleading uses of AI assistance. The explanations are always plausible. They are almost never grounded.)

**Tacit Bankruptcy** is the long-term consequence, and one that _should_ make team leads nervous at that. A codebase that ran on tacit knowledge — held by its team, transmitted through working together — slowly spends down that knowledge when AI starts doing the writing. The original carriers retire or move teams. No new carriers are forming, because juniors are being apprenticed to an AI assistant instead of to a senior. After a few years, the team has the code, the docs, the tests, and none(!) of the tacit knowledge that made the system make sense. The codebase keeps running. Nobody knows why.

Walk into any team that fully embraced AI assistance two years ago and ask the senior who's still there what's changed about the kind of questions they get from juniors. I propose they'll tell you in unison that the questions have flattened. The "why does this work this way" line of inquiry has dried up, because the juniors aren't _reading_ the code anymore. They're prompting against it.

## A Small Story (Slightly Anonymised)

A guy I worked with a while back, much smarter than me, once spent an entire afternoon refusing to merge a PR that, on paper, was correct. The change worked. The tests passed. CI was green. He couldn't articulate what was wrong. He kept saying "I just don't believe this code."

Eventually he asked the author to walk him through the reasoning, line by line, out loud. Maybe forty minutes in, the author said something offhand: "well, this assumes the queue is FIFO, but I think that's safe." It wasn't safe. The queue was FIFO in development and best-effort-FIFO in production, and the difference was buried in a runbook nobody had looked at in two years. My colleague had smelled it from the diff. He couldn't explain _why_ up front, but luckily his persistence (and frankly his good reputation as someone one should listen to when it comes to software engineering) made him too hard to dismiss. He just "didn't believe the code".

That afternoon cost a few hours of two engineers' time. It probably saved a months-long incident.

That kind of work is impossible for an AI. It's also impossible to _prompt_ an AI into doing, because the input my colleague used — a constellation of subtle features, a year-long history of similar bugs, a half-conscious memory of "where pain has come from before" — isn't anywhere it can be fed in. It lived in him. He'd built it the slow way, over a decade.

This is what the AI-coding pitch never confronts. Yes, generate code faster, sure. But the _catching_ — the eye that says no — comes from somewhere AI cannot reach.

## The Seniors Who Matter Most Right Now

If you're a senior engineer reading this, here is what I think you actually are, in 2026, more than at any point in the last twenty years:

**A tacit knowledge carrier.** You hold the unwritten understanding of your systems. The conventions, the design intuitions, the half-memories of why this isn't structured the other way. Your value isn't your typing speed. It never was. It's the catalogue of pattern-recognition you built over a decade of doing the work.

**An apprentice-maker.** The only known way tacit knowledge gets transferred is by working alongside someone who has it. Bootcamps can't do this. Courses can't do this. AI tutors definitely can't do this. _You_ can. And right now, you're the rate-limiting step on whether the next generation of engineers picks up any of it. The work has to happen in pair sessions, in code reviews where you push back and explain (or fail to explain), in the slow process of letting a junior watch you make a decision.

**A tacit translator.** Sometimes you can take a piece of tacit knowledge and pull it partway into the explicit. When you write an ADR that captures a constraint you'd previously only _felt_, you're doing translation work. Most translations are partial — you can describe the symptom but not the underlying judgment that recognised the symptom. That's fine. Partial is better than nothing, and over time the partial translations stack up into something a team can lean on.

**A pattern guardian.** You're the one who can look at a PR and say "this fits us" or "this doesn't." That sentence is mostly tacit. It is also the single most important sentence in code review. Without it, a codebase loses its shape — loses, in Polanyi's terms, its accumulated tacit dimension. A codebase that has lost its shape will still compile. It will still pass tests. It will not be navigable by anyone who joins after the shape was lost.

In a world hellbent on automating the articulable, the value of the people who carry the inarticulable has actually _gone up_. Quietly, but a lot.

## Where Polanyi Meets Naur

I argued in [the original theory-building post](/posts/programming-as-theory-building-naur/) that a program is not its source code — it's the theory the team holds about the system. [Part II](/posts/programming-as-theory-building-part-ii/) extended that: the theory lives not in individuals but in the institution.

Polanyi tells us _why_ the theory has to live there and can't be reduced to the artifacts. It lives in the tacit dimension, which is the part of knowing that _cannot in principle be made fully explicit_. Naur called it "theory." MacIntyre would call it "practice." Aristotle called it phronesis. Polanyi called it the tacit dimension. They are all pointing at the same thing: the kind of knowing you only get from doing, the kind that cannot be transmitted by writing it down.

That's the part AI is structurally unable to learn from, train on, or generate. Not because of any current limitation that is bound to go away in the next iteration of your favorite model. Because _if it could be put into the training data, it wouldn't be tacit anymore_.

Read that sentence again. It's the crux. AI is good at exactly the knowledge that _can_ be written down. The most important knowledge — the kind that lets a senior _smell_ something fishy in a diff — _can't_ be written down. So no amount of AI improvement closes the gap. The gap is part of the definition.

(As the veteran reader knows, this connects to [the diagnostic I sketched in Architecture by Autocomplete](/posts/architecture-by-autocomplete/). Primitive obsession in AI-generated code isn't just a typing problem — it's evidence that the model is reaching for the average of all explicit code it's seen. The domain types your senior would have invented live in the tacit dimension. They're not in the corpus, and never will be.)

## What to Do

If you take Polanyi seriously, a few things follow:

- **Re-elevate apprenticeship.** Working at the shoulder of someone who has the tacit knowledge is the only known transmission mechanism. Pair programming, code review where the senior explains in voice (or admits they can't), walking through bugs together — these aren't quaint. They're the only mechanism we have. Burn them and you burn the wire.
- **Distinguish articulated from tacit work.** Some of the work is genuinely articulable: write the docs, write the ADRs, capture what you can. But don't pretend the articulation captures everything. The remainder isn't an oversight. It's the irreducible part.
- **Resist the fluency mask.** When AI produces a confident explanation of code, treat it the way you'd treat a confident explanation from a stranger who's never worked on your team. The fluency in and by itself is no evidence of grounding.
- **Pay seniors to teach, not just to ship.** A senior who spends two hours pairing with a junior is doing the most important work on the team that week. If your incentive structure doesn't reflect that, your incentive structure is bankrupting your tacit capital, one sprint at a time.

## In Polanyi's Own Words

I'll leave you with one of my favorite lines from Polanyi. He's writing about scientific discovery, but you can read it as a description of a senior engineer reading a tricky PR (that Gemini Flash GPT whatever approved instantly):

> _We start by an act of personal commitment, recognising in some pattern the promise of a hidden meaning. We pursue it without being able to say what we are looking for, and we know we have arrived without being able to say what we have found._

If that doesn't describe the experience of debugging a hard problem, I don't know what does. And it is exactly the thing AI cannot do, can never do, and is steadily making us forget we used to do ourselves.

The Articulation Era will pass — these things always do. When it does, the developers who quietly kept the tacit dimension alive, by mentoring and reviewing and refusing to outsource the work that mattered, will be the ones the next generation of teams desperately needs.

We can know more than we can tell. Make sure your team still has people who know.
