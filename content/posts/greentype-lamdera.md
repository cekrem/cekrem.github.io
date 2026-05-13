+++
title = "GreenType: a beautifully coded terrible idea"
description = "Or: an afternoon with Lamdera"
tags = ["elm", "lamdera", "fullstack", "side project", "functional programming"]
date = "2026-05-13"
draft = false
+++

I built [a keyboard](https://greentype.lamdera.app) that does basically nothing (except cool thock sounds), and it was super fun.

When you start typing, you and everyone else on the page hears a Cherry MX Blue sample (a different sound per key, because I went further down that rabbit hole than I should have). A trail of recent keystrokes fades across the screen. A global counter ticks up. That's the app.

Someone in the Elm Slack called it "a beautifully coded terrible idea," which feels about right.

(Disclaimer, btw: that JavaScript part with the audio-equivalent of a sprite containing multiple samples was mostly Claude. Because _I_ wanted to spend as much time in Lamdera land as possible!)

## So why bother?

I wanted to try [Lamdera](https://lamdera.com). The TL;DR is it's Elm, but fullstack -- meaning the backend is also Elm, and the backend and frontend share the same types (like, literally they import types from the same file!). A message from frontend to backend is just a value. As Elon said: Let that sink in.

Quite refreshing after all these years of, well, the normal approach with all the usual friction of frontend/backend coms.

So, ie: A `KeyPressed` value on the frontend turns into a `ToBackend` message the compiler insists the backend handle. The broadcast comes back as a `ToFrontend` message the compiler insists the frontend handle. End to end, fully typed _all the way_. Not only that: if/when you change your model(s) the data survives across deploys via _migrations_ (also Elm!) the compiler walks you through (and yells at you about if you skip them). I mean... What's not to like, and why haven't I tried Lamdera for real before?!

## It works, `lamdera deploy` was all it took

[Try it](https://greentype.lamdera.app). If you're lucky someone else tries it at the same time and you can have a quite alternative version of an online chat. [Source is here](https://github.com/cekrem/greentype) if you want to see how much of an actual app it isn't.

I don't think I have a real takeaway other than: Lamdera is as weirdly nice as people say. _Please_, go waste an afternoon on it!
