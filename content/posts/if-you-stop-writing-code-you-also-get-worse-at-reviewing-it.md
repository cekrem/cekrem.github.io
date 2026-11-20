+++
title = "If you stop writing code, you also get worse at reviewing it"
description = "Before 2022 10/10 engineers would agree wholeheartedly. Somehow it changed.(?!)"
tags = ["ai", "software craftsmanship", "coding-as-craft"]
date = 2026-11-20
draft = false
+++

Whatever skill you're learning, it won't take long before someone with experience in that particular field tells you to get your hands dirty. It's fine to read "Born to Run", but you won't be running an ultra marathon any time soon if you don't start running. Whether it's muscle memory, technique, physical fitness or problem solving you need to work on to reach your goals, you need to _practice_. **This isn't a controversial statement in _any field at all_, and has never really been.**

Except in software engineering, somehow.

When it comes to software engineering, we somehow lost our way, thinking that _our skills won't stop improving if we stop practicing_. Making such a claim in any other field would be sneered at at best. Imagine John Scofield[^*] saying he stopped practicing his guitar because "he was at a good enough level, musically, to maintain (and even improve!) his expertise" simply by 1) instructing others on how to play (either in ~~vibe~~ general terms, or with a strict ~~spec~~ musical notation), and then 2) listening to what they played and iterating until it sounded good enough for his next record. "My music is better", he would claim, and moreover "actually _playing the guitar_ was never the point anyway, there's more to making music."

Mind you, my point in this post is not to discuss the short term quality of code output (or recorded guitar playing, to continue the proverbial thread), but rather the _skill of the craftsman practicing his craft_ vs the one who doesn't practice at all.

To make another comparison that's arguably closer to software engineering, or at least the "writing and reasoning about code" part of it, let's look at authors in other fields. I have no doubt that reading great prose has the potential to nudge a writer towards better writing of his/her own; in fact it's super important to have creative references to draw upon - no doubt at all. But, imagine an author who 1) stopped writing, and only pursued reading and giving feedback to other writers, and worse yet 2) _mostly read AI generated prose_!? To be perfectly honest, I would expect a quite steady (if not exponential) decline of this author's writing skills.

## "There's more to software engineering than writing code"

Sure. But if we can at least agree that **the code that runs our software is a non-trivial part of it** (though, granted, [not all of it by far: The other parts of developing and maintaining software speak even louder against using generative AI as a significant ~~tool~~ service!](/posts/programming-as-theory-building-naur/)), we should aspire to be proficient in understanding how code works, what good code looks like, what to watch out for and how software architecture plays a vital part in making code Easy To Change.

Simply "reviewing all the code Claude produced" won't quite cut it. And who are you trying to fool, after all; at this point you're not really reading half of it, are you?

So I propose something that used to be a no-brainer: **Keep practicing!**

Which brings me to my next point:

## All engineers(!) need to be good at solving problems

`if` || `while` you can argue that the need for being hands-on on your software's _code_ varies, I propose you _can't_ argue that we're still _solving problems_. And the moment you stop _practicing solving problems_ is the moment you stop getting better at it, just like everything else. Simple as that. This is hardly new, btw: you could always tell who beat Doom using cheat codes and who finished the game the real way! If the end goal is to "beat the game", then by all means cheat; if the end goal is _getting good at it_, then I'd advice you not to. Some lessons are only learned the hard way (trial _and error_), and very few are learned _without effort at all_. Repeated LLM usage for problem solving pounds the following premise into our brain's wiring: If something is hard, tricky or requires effort, you shouldn't even try. And _right there_ goes our learning, craft and joy, right out the window.

> In a world where [people are using AI to summarise books instead of reading them](https://www.reddit.com/r/Bard/comments/1j1g8bo/which_ai_is_best_for_summarizing_books/) and [turning to AI for therapy](https://www.abc.net.au/news/2025-05-19/young-australians-using-ai-bots-for-therapy/105296348), I don't want to keep using it. It feels like such a slippery slope. [As literacy and numeracy rates decline](https://www.ceda.com.au/research-and-policy/research/education/the-state-of-australian-literacy-and-numeracy), **I can't help but question whether encouraging us to rely on AI so heavily is a good idea**.
>
> It makes me wonder: are we still thinking for ourselves at all?
>
> — Em's blog[^*1], emphasis mine.

Please, John Scofield, don't stop playing your guitar!

[^*]: ![John scofield playing at the Moers Festival in 2021 ](https://upload.wikimedia.org/wikipedia/commons/9/99/John_Scofield-8615.jpg)

[^*1]: I'm not sure who Em is, [but their blog](https://em-online.bearblog.dev/blog/) is great!
