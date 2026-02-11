+++
date = 2026-02-11
title = "elm-native – scaffold hybrid mobile apps with Elm, Vite, and Capacitor"
description = "npx elm-native my-app"
tags = ["cli", "elm", "capacitor", "mobile", "npm package"]
draft = true
+++

## Have you ever

- Wanted to write mobile apps in Elm?
- Spent an evening getting Elm, Vite, and Capacitor to play nice together, only to realize you'll forget all the steps by next week?
- Thought "there's gotta be a one-liner for this"?

Well, now there is:

```bash
npx elm-native my-app
```

That gives you a working [Elm](https://elm-lang.org/) + [Vite](https://vite.dev/) + [Capacitor](https://capacitorjs.com/) project with iOS and Android ready to go. [Here it is](https://github.com/cekrem/elm-native).

## What you get

Elm handles all the UI. [Capacitor](https://capacitorjs.com/) wraps it in a native shell. [Vite](https://vite.dev/) compiles Elm via `vite-plugin-elm`. And a tiny JavaScript bridge reads device info and passes it to Elm as flags. Here's that bridge in its entirety:

```javascript
import { Elm } from "./Main.elm";
import { SafeArea } from "capacitor-plugin-safe-area";

async function start() {
  let safeAreaTopInPx = 0;
  try {
    const { insets } = await SafeArea.getSafeAreaInsets();
    safeAreaTopInPx = insets.top;
  } catch (_) {
    // Safe area not available (e.g. browser dev)
  }

  Elm?.Main?.init({
    flags: { safeAreaTopInPx },
  });
}

start();
```

20 lines. That's the entire JavaScript layer. Everything else is Elm. The safe area bit means your content won't hide behind the notch, which is one of those things you don't think about until it bites you.

## The Elm side

The template starts you off with a counter (I know, I know), but it shows the full pattern: flags from native land, standard TEA, inline styles. Replace it with whatever you actually want to build.

```elm
type alias Flags =
    { safeAreaTopInPx : Int
    }

init : Flags -> ( Application, Cmd Msg )
init flags =
    ( { model = { count = 0 }
      , safeAreaTopInPx = flags.safeAreaTopInPx
      }
    , Cmd.none
    )
```

Need camera access or GPS? Install the Capacitor plugin and wire it through [ports](/posts/a-case-for-port-boundaries-in-frontend/). Same patterns we already know from the web.

## The scaffolding

Very much in the [create-elm-live-app](/posts/create-elm-live-app/) spirit: a `"bin"` entry in package.json pointing to a script that copies a template and runs `npm install`. Except this time I also run `npx cap add android` and `npx cap add ios` automatically, so you don't have to touch Capacitor's interactive setup. Non-interactive scaffolding or bust.

```
npm run dev          # Vite dev server
npm run sync         # Build + sync to native projects
npm run open:ios     # Open in Xcode
npm run open:android # Open in Android Studio
```

## Why?

I've been [pushing Elm outside the browser](/posts/elm-on-the-backend-with-nodejs/) lately, and mobile felt like the obvious next step to experiment with (and a more realistic one at that; the nodejs thing is mostly a PoC). There's something nice about the compiler catching my mistakes before they reach my phone. And honestly, after wrestling with various cross-platform setups over the years, having Elm do all the UI while Capacitor handles the native bits is a pretty good deal.

Also: for the first time in a good while, I've got an idea for a small app. Why not Elm?

![Yes? Yes.](/images/michael-scott-yes.gif)

It's version 0.1.0. It's absolutely an MVP. But it generates a working app, on both platforms, from one command. ¯\\\_(ツ)\_/¯

[Check it out on GitHub.](https://github.com/cekrem/elm-native)
