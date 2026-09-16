+++
title = "The Climb Was the Safety Feature"
description = "European playground rules count how hard a platform is to reach as part of its fall protection. AI, however, just hands every developer a ladder, and nobody has recalculated the fall."
date = 2026-09-16
author = "Christian Ekrem"
tags = ["programming", "software-engineering", "theory", "llm", "ai", "craft", "playgrounds", "programming-as-theory-building", "coding-as-craft"]
draft = false
+++

Disclaimer: I'm tired of both reading and writing about AI. But on a trip with my consultancy last weekend, one particular conversation on the topic turned out to bring a new and interesting perspective on to the table; a rule about playgrounds (like, actual ones, not playgrounds for testing out frontend frameworks). So here's some more on the quite worn-out topic of AI usage in coding.

Disclaimer 2 (meta!): I cut a few corners myself on this post, trying to have Claude summarize some things and create metadata etc. I've reverted that, and won't be doing that again, it leaves a bad taste in my mouth.

The standard for playground equipment in Norway and the rest of Europe is EN 1176, which our own [forskrift om sikkerhet ved lekeplassutstyr](https://lovdata.no/dokument/SF/forskrift/1996-07-19-703) from 1996 accepts as proof of compliance, and which [DSB](https://www.dsb.no/produkter-og-forbrukertjenester/produkter/lekeplassutstyr/) will point you to if you ask. Sorry / you're welcome for the very specific and Norwegian reference, btw. Anyway, the relevant part of it is this: it sizes the fall protection on a raised platform by height, which you'd expect, and by _how easy the platform is to reach_, which you might _not_ expect. So, in other words: A deck that a toddler can walk straight up a ramp onto needs a full barrier from 60 centimeters up (to avoid killing toddlers). The same deck, at the same height, reached only by a climbing net, can get away with a guardrail until it's two meters off the ground. The drop is identical. What changed is _who can get up there without help_.

The standard even explains why: a hard ascent "slows down the movement and provides time for intervention." The climb counts as protection, because it buys an adult time to notice.

**The climb was the safety feature.**

Just like in programming. Before AI.

## What the climb was for

Until about three years ago, software had the same rule built in. Perhaps rule isn't the right term, it's more like a natural law. Let me explain. Anyone who shipped a fast, decent-looking, working web app had climbed to get there. They had lost at least one argument with webpack (I've lost several myself!), and they had probably run something destructive in production because a forum told them to (or at the very least stood next to [the poor trainee who did](/posts/programming-as-theory-building-naur/)). The thing is (or used to be, depending on your definition) _most people can't program at all_, let alone deploy something to the internet and make it look good and respond fast. So when you saw such a thing, you could assume that the person behind it knew roughly what they were doing, not because the thing was impressive, but because of what it took to get it up there.

I propose we leaned on that assumption more than we were aware of, and we forgot to calibrate our expectations after coding skills stopped being a requisite for creating code. It's why a portfolio meant something in a job interview, and why "they have a product in production" used to be a sentence with actual information in it.

Now, a fair share of that climb was what Brooks called accident, and [I said so myself last month](/posts/there-is-still-no-silver-bullet/): the webpack fights, the build config, the twentieth factory. The essence, the part where you decide what the system should mean and feel the design push back, was in there too, but you couldn't see it from the outside. What you could see was the accident, and nobody got through the accident without doing the essence along the way. So the accident worked as a sort of proxy. "Impressive" implied "climbed", and "climbed" implied "understood" (or at the very least it implied a certain degree of hands on _experience_). Loosely, and definitely with exceptions, but it did. (Brooks and Polanyi each have their own name for the part you can't see; [earlier](/posts/there-is-still-no-silver-bullet/) [posts](/posts/the-tacit-dimension/), if you haven't read my previous posts on the topic.)

## Now everyone has a ladder(!). Or a Jetpack?

A single prompt can give you a deployed app with auth, a database, a landing page and a dark mode toggle, responding in under a hundred milliseconds. It looks great. But our previous assumptions need a hefty calibration; testing the end product in a browser, or even looking a few minutes at the code, doesn't guarantee a safe climbing to fall ratio.

Nothing about it tells you whether the builder "climbed", and as such: you can have no assumptions as to how experienced or otherwise trustworthy the author of the software is. _"Impressive looking" implies nothing at all anymore_. The "etos" part of the whole deal is untrusted, to say the least. This happened subtly enough that most of the industry is still acting as if it's there. Hiring managers still weigh portfolios, and reviewers still go easy on a PR that looks clean (or has comments with confidence...). "Ladder code" looks exactly like climbed code from the outside.

To be fair, the amount of climbing has decreased these past fifteen years; Rails scaffolding and Firebase both let people ship things they hadn't entirely built much of themselves. What's new is the height. Squarespace never handed anyone a payment integration or a shell with production tokens in its environment. Jetpack mode and full-auto fire: √

(The people on the ladder aren't stupid, btw. Some of them are the best engineers I know, using it to skip a climb they've already done thirty times, in a codebase they know inside out. That's the whole problem from where the reviewer stands: the output from those engineers and the output from someone who has never climbed anything look eerily similar in the PR, so the protection has to be sized for the second case. Or we need new metrics?)

The people making the playground rules were smarter than us about this. Instead of banning ladders they wrote a rule with two variables in it: how easy the ascent, and how far the fall. The easier you make the climb, the more protection you owe at the top. Our industry has spent three years making the ascent easier for everybody and has not, as far as I can tell, _recalculated a single fall_.

## How far is the fall?

Fall height, in software, is roughly equal to blast radius. A to-do app for yourself is thirty centimeters off the ground; fall all you like (a marketing page is maybe knee height?). A thing that moves other people's money, or holds their health data or their credentials, or runs shell commands with a production token in its environment, is the top of the tower, and the ground underneath is exactly as hard as it sounds.

And again, we handed out ladders to all of it at once. The same tool that scaffolds a hobby project will scaffold a payment integration without a flicker of hesitation, and the two outputs look the same. [I've written about what the landing looks like](/posts/if-you-re-running-claude-code-run-it-in-a-box/): an agent that wiped a production database during a code freeze, and another that found a token and deleted the wrong thing with it. The yearly count of secrets leaked on GitHub is up by a third too, with `.env`-slurping agents named as one of the drivers. Those are the incident reports. Nobody has ever fallen off a to-do app.

## So what do we actually do?

I'm not proposing a ban; the playground people didn't need one either. They just made you count both variables. Somehow we should try and do the same.

Match the ladder to the height. Ladders on the low elements? Sure: [tidying Tailwind classes](/posts/if-you-re-running-claude-code-run-it-in-a-box/), turning DOM sludge into JSON, that sort of thing. On the tall elements, the ones with other people's money or credentials underneath, climb. Do engineering! Learn and understand, struggle until you're better. Or at least make SURE somebody on the team has, recently, and that they're the one reviewing.

If you're in the business of handing out ladders anyway, build the barrier, and build it in proportion. A sandbox with no production credentials in it. A compiler that catches the fall before it happens ([parse, don't validate](/posts/parse-dont-validate-typescript/)). Review by someone who has climbed _this_ tower. The standard's logic is the useful part here: the easier the ascent, the more of this you owe, and almost nobody raised the barrier when they handed out the ladders. (Tests written by the same agent that wrote the code are a barrier installed by the toddler, mind you. They count for _something_, I guess. Not for much.)

And stop reading _impressive_ as _competent_. In hiring, in review, and, hardest of all, when your own ladder output looks better than it should. Ask instead how far the fall is and who is standing underneath.

Sure, AI is hardly our only ladder, btw; but I propose it's the most readily available variant. Every reorg and every layoff letter hands whoever is left a ladder onto a tower nobody on the team climbed. But at least then there's hopefully someone (not a machine) to talk to about it!

As a consultant, my whole job consists of walking up to systems I didn't climb, and a good chunk of this post is aimed at myself, a reflection I really hope I won't forget any time soon. I hope I can remember I'm at the bottom when I arrive, not use ladders to pretend otherwise to the people who hired me.

Luckily, I actually like climbing, and have no plans to quit!
