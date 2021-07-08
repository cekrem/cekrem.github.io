---
title: "create-elm-live-app – the smallest npm package ever?"
description: "Try out Elm without breaking a sweat!"
tags: ["cli", "elm", "npm package"]
date: 2021-07-08
---

## The problem

I've been tinkering a bit with Elm lately. The super-enforced functional and minimal paradigm is very refreshing, and serves as a sort of detox after spending one too many hour stuck in Android's not-so-lovely XML + mutating class world. Setting up a new bare minimum Elm app should be quite simple, but it turns out that there are a few more steps required than one would expect. My first instinct – being a React guy – was to try `yarn create elm-app` (or `npx create-elm-app`), hoping it would do the Elm-equivalent of what `create-react-app` does. Turns out, to my dissapointment, that the end result leaves something to be desired. No proper live-reload out of the box, and a lot of the webpack stuff I was hoping to avoid completely with Elm. Yuck.

## The simplest possible solution (that actually works)

At Vipps we're passionate about simplification, in fact thats pretty much the headline of our company. So – being a Vipps guy – I thought: What's the most minimal, easy, no-nonsense way to solve this? Is it possible – is it _moral?!_ – to just add a `"bin"` entry to an otherwise vanilla package.json, pointing to a basic shell script? Turns out, it is! The following points to a simple (but perhaps not very pretty) [index.sh](https://github.com/cekrem/create-elm-live-app/blob/master/index.sh) – and it works like a charm\*.

```json
// Inside package.json:
"bin": {
    "create-elm-live-app": "index.sh"
},
```

It's [published](https://www.npmjs.com/package/create-elm-live-app). You're welcome :)

\*: Probably not on Windows. ¯\\_(ツ)_/¯
