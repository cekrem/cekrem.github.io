+++
title = "Hejlsberg: 'Who's Going to Make the AI?'"
description = "The creator of C# and TypeScript (not to mention TurboPascal and Delphi!) on vibe coding, fundamentals, and what AI is never going to do."
tags = ["ai", "llm", "coding", "craft", "typescript", "vibe-coding"]
date = 2026-05-30
draft = false
+++

Sajjaad Khader sat down with Anders Hejlsberg the other day. Yes, _that_ Anders Hejlsberg: the man behind Turbo Pascal, Delphi, C#, and TypeScript. The chat is twelve minutes long (or probably a lot longer as it's quite aggressively edited), and Sajjaad opens with the question every channel seems contractually obligated to ask in 2026: [will AI replace software engineers?](https://www.youtube.com/watch?v=CPrePbvbbic)

Hejlsberg's answer was about as gentle as you'd expect from a man who has spent fifty years building the foundations everyone else takes for granted:

> "No. Who's going to make the AI?"

That's it. That's the whole answer. The rest of the interview is just Hejlsberg, very politely, explaining what he means.

## The pyramid doesn't disappear

His argument is structural rather than sentimental. He isn't making a "humans have souls" case. He's pointing at the thing the hype crowd keeps glossing over:

> "Who's going to make the programming languages that the AI expresses itself [in]? Who's going to write the frameworks that the AI talks [to]? [...] Someone has to design the CPU, the operating systems."

AI doesn't run on vibes. It runs on stacks. Stacks that someone, someone who understands how a hash table works and why, has to keep designing, debugging, and reasoning about. The pyramid of abstractions narrows as you go up, but the bottom doesn't vanish. If anything it grows. More AI means more language tooling, more compilers. None of that comes from prompting.

This is roughly the argument I've been making for a while now from [the old gym](/posts/coding-as-craft-going-back-to-the-old-gym/), just delivered by a guy whose CV could fit on a postage stamp because the entries read "designed Pascal", "designed Delphi", "designed C#", "designed TypeScript".

## On vibe coding

When Sajjaad asks what he makes of vibe coding, Hejlsberg doesn't sneer. He just punctures it:

> "For a lot of stuff that is rote, how many times can you write this to-do list app? AI in its training set has seen [it] a gazillion times, so it can riff over that. [...] But when it comes down to business logic or you got to invent something, that's how this industry makes progress."

AI is great at the parts that have already been written a million times. That's a feature, not a victory. The part where the industry actually moves forward, the part where _your_ specific business problem gets a _new_ solution, is exactly the part the model has never seen. (And then, since these things are trained to always produce an answer, you get something that looks like a solution but isn't. We've [seen this movie before](/posts/llms-corrupt-your-documents/).)

His exact verdict on vibe coding: "that doesn't really bring a lot to the table anyway." That's Hejlsberg-polite for "no."

## The mistake beginners make

When asked what beginners get wrong most often, his answer should be framed on every CS classroom wall:

> "Not spending enough time learning the basic principles [...]. What is a variable really? And what is an array? And what is a data structure? And how do pointers work? Once you grok that, then it doesn't really matter what language you're in. [...] If you don't get that deeper understanding, then you're sort of thinking at that veneer syntactic level of what do I have to write, but you're not really understanding why you're writing it."

"Veneer syntactic level" is the perfect phrase for what vibe coding actually produces. You move tokens around. The compiler accepts it. The tests, if you wrote any, pass. Done. Until they aren't.

The whole reason I keep banging the [theory-building drum](/posts/programming-as-theory-building-naur/) is that veneer-level interaction with a codebase is precisely what happens when the theory dies. You don't build the model in your head, so you don't actually understand what you're shipping. Hejlsberg is describing the same disease from the other end of the career arc: as the thing juniors absolutely have to avoid catching.

## The grunt work is fine

Let me be clear, because Hejlsberg is too:

> "AI is an accelerator [...] it's going to remove a lot of grunt work that we don't need to do anymore [...]. But it'll allow us to focus more on the creative side, because AI is not going to innovate. It's not going to like _bing_, have this crazy idea I had in the shower this morning."

That's the same line I've been walking in [Claude Code: Game Changer or Just Hype?](/posts/claude-code-game-changer-or-just-hype/) and when I [signed the no-AI-in-Node.js-core petition](/posts/no-ai-in-nodejs-core/). AI for the boring parts: fine, good, please. AI for the parts that make you a better engineer, or that constitute your actual contribution to a codebase that millions depend on: no.

He even names the boring parts explicitly later in the interview: "the grunt work of writing a test for a pull request, that doesn't really bring a lot to the table anyway. So, yeah, hand that off." Hand that off. Keep the rest.

## So go learn pointers

The most subversive line in the whole interview, in a year where every other Twitter influencer is telling juniors that learning fundamentals is a waste of time, is this:

> "[A CS degree?] Oh, I definitely think so. [...] like the history of programming and like we've talked about here, like what is a programming language, what are the principles of programming, what is data structures, what are databases, what are operating systems."

Coming from a guy who could have made the case for "just ship stuff and use the AI", that's a lot.

Software Engineering is still a craft, not a problem solved by LLMs. I, for one, am thankful for that!
