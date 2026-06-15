+++
title = "Explaining Functional Programming to Non-Programmers (It's Just Excel)"
description = "A colleague asked whether functional programming means writing the code yourself instead of letting Claude do it. The real answer was sitting in a spreadsheet the whole time — and the man who co-created Haskell agrees."
date = 2026-06-15
author = "Christian Ekrem"
tags = ["functional-programming", "excel", "programming", "elm", "software-engineering", "teaching"]
draft = false
+++

A few days ago someone at work asked me what I actually do. Not my job title — they had that — but what _functional programming_ is. I started in on the usual mumble about pure functions and immutability, watched their eyes begin the slow slide toward the exit, and then they rescued both of us with a guess:

"Functional programming... does that mean you write the code yourself, instead of having Claude do it? Is that the thing?"

Well, yes. But also no; that has _nothing_ to do with it really.

And later that day I saw a feature inside the client's document management software where you could click a button to sync the document's metadata title/subtitle with what was actually visible _within_ that document. I tried to explain that **in a more functional paradigm, the title within the document would be calculated based on the metadata rather than having a procedure mutate it in place**.

Didn't quite succeed with that explanation, I think, though it's more helpful than the Claude question.

But I've been asked some version of this enough times now that I've at least stopped reaching for monads and category theory, which is roughly like answering "what's a car?" by opening the hood. But let's do better. Lo and behold, I've discovered a tool that every non-technical person I work with understands better than I do. Most of them could run circles around me in it. They probably have it open right now.

"**You already know functional programming. You've just been calling it Excel.**"

## The man who built Haskell agrees

Simon Peyton Jones — one of the principal designers of Haskell, the language that functional programmers light candles to — has said it plainly. In [an oral-history interview](https://archivesit.org.uk/interviews/simon-peyton-jones/) he describes spending years on Excel "because it is the world's most widely used functional programming language."

He'd know. Back in 2003 he co-wrote a paper at Microsoft Research with the unglamorous title [_A User-Centred Approach to Functions in Excel_](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/07/excel.pdf) (ICFP '03, if you want the PDF — it's a good read). The whole premise is that the spreadsheet is already a functional language, used daily by hundreds of millions of people who would never describe themselves as programmers and would be mildly offended if you did.

Microsoft eventually leaned all the way into it. When they shipped the `LAMBDA` function in [late 2020](https://www.microsoft.com/en-us/research/blog/lambda-the-ultimatae-excel-worksheet-function/), the research team — Andy Gordon and, yes, Peyton Jones again — noted that the Excel formula language had become _Turing-complete_. You can now, in principle, compute anything in it. They called these "functional programming features," in the same breath as calling Excel "the world's most widely used programming language." Felienne Hermans, a researcher who has spent a career studying spreadsheets, gave a whole talk titled ["Pure Functional Programming in Excel"](https://www.youtube.com/watch?v=0yKf8TrLUOw). (Bloomberg [reckons](https://www.bloomberg.com/features/2025-microsoft-excel-ai-software/) Excel has somewhere on the order of a billion users. Haskell, last I checked, does not.)

So when I tell a non-programmer "you already do this," I'm not being nice. I'm being literal. Here's the proof, in three parts.

## One: every cell is a little function

Click on a cell. Either someone typed a value straight into it — `1337`, a name, a date — or there's a formula, something like `=A1+B1`.

That formula does exactly one thing. It looks at A1, looks at B1, hands you back the sum. That's it. It doesn't matter what time of day you open the sheet, who's logged in, or which cells you happened to click first. Same inputs, same answer, every single time. And if you ever wonder where a number came from, you click it and the formula bar tells you, all of it, no secrets. **The grid never lies.**

That property has an intimidating name — "referential transparency" — and a very simple meaning: a cell's value depends only on what you can see flowing into it, and nothing else. There is no hidden "it depends." This is the first thing functional programmers chase, and most of us spend our careers trying to make ordinary code behave as honestly as a column of `=A1+B1`.

## Two: no cell reaches across the grid

Cell C1 cannot reach over and change A1.

A formula computes _its own_ value out of other cells. It never mutates them. There is simply no way to write something in B7 that means "give me the total, and also, while you're in there, set A1 to zero and bump C4 by three." Causation points one direction only: a cell sits _downstream_ of the cells it reads, never upstream. **No cell reaches across the grid and meddles with another.**

Compare that to how most software is written. In an ordinary program, almost any line can change almost any value, anywhere, at any time. Some function buried four files away flips a flag you forgot existed, and three weeks later you're staring at a bug that makes no sense. That entire category of misery — _spooky action at a distance_ — is impossible in the grid by construction. Not just discouraged, but rather impossible. You couldn't do it if you tried.

When I write [Elm](/posts/why-i-hope-i-get-to-write-a-lot-of-elm-code-in-2025/) all day and gush about never getting a runtime error, this is most of what I'm gushing about. The language won't let one part of the program secretly knife another in the back. Just like Excel.

## Three: the messy stuff lives in the menus

"But hang on," the sharp ones say. "Spreadsheets _do_ things. They save. They print. They pull live data."

They do — and look at _how_. None of that happens inside a cell. It happens when **you** click Save. When **you** click Print. When **you** hit refresh on the data connection. The grid itself stays pure; all the messy, real-world, touches-the-outside-world stuff is walled off behind deliberate, you-pressed-the-button actions in the menus. Click Ops _outside_ the grid is the only way to interact with the outside word.

We call it "managing side effects," and it sounds like an apology a pharmacist makes. All it really means is this: keep the calculating part separate from the part that talks to the world, and make the second part explicit. Excel does this so naturally you never noticed it was a design decision.

You _do_ notice when someone breaks it. We've all met the cursed spreadsheet — the one held together by VBA macros nobody understands, where opening the file silently emails three people and overwrites a cell on a tab you forgot was there. That sheet is feared precisely because it smuggled side effects _into_ the grid, where they don't belong. The moment a cell can reach out and change the world without you asking, you've lost the thing that made spreadsheets trustworthy in the first place. There's a whole career's worth of software-engineering wisdom hiding in why that one workbook gives everyone the cold sweats.

## So, do I write the code myself instead of letting Claude do it?

Back to the question that started all this.

Mostly, yes. There are exceptions (pun not intended), and I've written at length about those (and why they are few). But that was never the actual distinction, and I think the question is interesting precisely because of how it _misses_. Functional programming isn't a posture about whose fingers hit the keys. You can have an AI generate functional code or imperative code. You can also hand-craft, lovingly, by yourself, a tangled mess of mutation and hidden state that would make the cursed spreadsheet blush.

The point was never the typing. The point is the _discipline_ — the same three rules the grid enforces. Every value honestly traceable to its inputs. Nothing reaching across to mutate anything else. The world-touching stuff kept explicit and to the side. Code with those properties is code you can trust the way you trust a spreadsheet that just recalculated four thousand cells without you checking a single one. (Whether a human or a model produced it is a [separate conversation](/posts/programming-as-theory-building-naur/), and an important one — just not _this_ one.)

When functional programmers reach for words like "pure," "immutable," and "monads," all the scary vocabulary I've spent years [trying to demystify](/posts/functors-applicatives-monads-elm/), we are, mostly, trying to hold onto the feeling of a spreadsheet when the program grows too big to fit on a screen. That's the whole job. A spreadsheet keeps itself honest for free because you can see the entire thing. Take that same honesty and try to stretch it across a million lines of code you _can't_ see all at once, and you need rules to do it. Functional programming is those rules. We're not building cathedrals. We're trying to keep a billion-row grid from lying to us.

## Try it on someone

Next time a non-programmer asks what functional programming is, don't reach for monads. (Please, do not reach for monads.) Open a spreadsheet. Type a number in one cell, a formula in the next, and then change the number. Watch the formula update on its own.

That little flinch — the grid keeping itself consistent without anyone telling it to — is the entire religion. Everything else we do is just trying to keep that flinch alive in programs too large to see. The world's most popular functional programming language has been sitting on your colleague's second monitor this whole time. They were functional programmers before either of us knew the word.

---

### Further reading

- Simon Peyton Jones, Alan Blackwell & Margaret Burnett, [_A User-Centred Approach to Functions in Excel_](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/07/excel.pdf) (ICFP 2003) — the original "Excel is a functional language" paper, from a co-designer of Haskell.
- Microsoft Research, [_LAMBDA: The ultimate Excel worksheet function_](https://www.microsoft.com/en-us/research/blog/lambda-the-ultimatae-excel-worksheet-function/) — the announcement that made the formula language Turing-complete.
- Felienne Hermans, [_Pure Functional Programming in Excel_](https://www.youtube.com/watch?v=0yKf8TrLUOw) (GOTO 2016) — a whole talk on exactly this premise.
- And if you want the developer-facing version of the same ideas: my posts on [functors, applicatives and monads in Elm](/posts/functors-applicatives-monads-elm/) and [why I keep writing Elm](/posts/why-i-hope-i-get-to-write-a-lot-of-elm-code-in-2025/).
