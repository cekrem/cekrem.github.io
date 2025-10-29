+++
title = "The Same App in React and Elm: A Side-by-Side Comparison"
description = "Understanding The Elm Architecture through a practical Hangman game implementation, compared directly to React patterns"
date = "2025-10-29"
tags = ["elm", "react", "functional programming", "typescript", "architecture"]
draft = false
+++

A few weeks ago, I [announced I'm writing a book about Elm for React developers](https://cekrem.github.io/posts/elm-book-announcement/). The response has been encouraging, so here's a full chapter from the book, showing what The Elm Architecture looks like in practice—side-by-side with React.

(The formatting is slightly nicer in the actual book, but Hugo does a decent job as well.)

I've currently finished the introduction (published [here](https://cekrem.github.io/posts/elm-book-announcement/)) and drafted chapters 1-6. I don't plan on adding all, and not in sequence, but some of it will appear on this blog.

What follows is **Chapter 2**, the chapter I'm most uncertain about:

---

**Update**: I'm actually a bit back to the drawing board for this chapter. Early feedback (especially from the React community) has lead me to believe that I'm not successfully getting my message through with a side-by-side comparison like this, and need to rethink my approach. How about that? That makes this very post a lot more useful for me than for the one reading it right now. Sorry about that, and thank you for your feedback – my next iteration will be better.

I'll probably release another chapter (a more finished one) shortly.

---

In the [introduction](https://cekrem.github.io/posts/elm-book-announcement/), we explored _why_ Elm's constraints enable freedom from bugs. We talked about immutability, exhaustive checking, and compile-time guarantees. Now let's see what those principles look like in actual code.

If you've been using React for a while, you're familiar with the constant sense of making architectural decisions. Should this be a hook or a reducer? Do I need context here? Should I memoize this callback? Every feature brings a small avalanche of choices, and while that flexibility is powerful, it can also be exhausting.

Elm takes a radically different approach: it gives you exactly one architecture. Not one _recommended_ architecture, but literally one. Every Elm application—whether it's a simple widget or a 100,000-line production codebase—follows the same pattern. The Elm Architecture (TEA) is built into the language itself.

This might sound limiting at first. But consider: when there's only one way to do things, you spend less time making decisions and more time solving actual problems. You stop debating architecture and start building features. And surprisingly, this single pattern scales beautifully.

Let's see what this looks like in practice.

> **Elm Hook**
>
> React hooks like useState, useReducer, useEffect, useMemo, and useCallback solve problems that don't exist in Elm. [The Elm Architecture](https://guide.elm-lang.org/architecture/) handles state, effects, and optimization by design. Keep reading to see how!

[... Let's get back to just _how_ to see what this looks like in practice, once I've rewritten chapter two ]

🤓
