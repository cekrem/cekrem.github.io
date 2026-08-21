+++
title = "Bun and Elm (: r)Are Friends"
description = "I replaced my Vite setup with two small Bun scripts humans can read (that I Humanly™ wrote). Dev server, hot reloading, CORS proxy, production build – the works!"
tags = ["elm", "bun", "elm-watch", "frontend", "tooling", "simplicity"]
date = 2026-08-21
draft = false
+++

I have an Elm app at work that needs exactly one thing from the JavaScript ecosystem: an npm package to piggyback on some A$ure auth thing. And for that one(!) package, I was running Vite with an Elm plugin and a growing pile of config to keep the two on speaking terms. Plus a backlog of `bun audit` warnings, courtesy of said auth thing's dependencies, and/or build tools just bringing their own garbage.

![michael-scott-not-happy](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExY2Fyc2cxazA3NjQ4MjQ5MHRtenFyY2gweW5uanpsbnB6c21tMjZkeCZlcD12MV9naWZzX3NlYXJjaCZjdD1n/jOpLbiGmHR9S0/giphy.gif)

This week I deleted all of it. What's left resembles[^1] [this example repo](https://github.com/cekrem/elm-bun): two small Bun scripts, about eighty lines between them. One runs the dev server, one does the production build (hot reloading is still elm-watch's job). Hand written code that's also quite easy on the eyes; sure beats both the boilerplate jungle and vibe slop alternatives.

## How I got here

It started with an [elm-safe-virtual-dom](https://github.com/lydell/elm-safe-virtual-dom) craving of sorts, actually, Simon Lydell's patched versions of Elm's core rendering packages. They make Elm apps survive Google Translate and DOM-meddling browser extensions (you know the classic crash if you've shipped Elm to real users); NoRedInk [adopted the forks](https://blog.noredink.com/post/800011916366020608/adopting-elm-safe-virtual-dom) and went from thousands of virtual DOM errors a day to zero. I wanted in on this! Someday the Lamdera compiler will install these forks for you (that work is merged but not yet released), and until then, you swap the packages yourself in Elm's package cache. So: point `ELM_HOME` at a folder inside the project, and patch that folder after every install.

(There's more to be said, but the simplified version is that this Just Works™:)

```json
"scripts": {
  "build": "ELM_HOME=elm-home vite build",
  "postinstall": "rm -rf elm-stuff && ELM_HOME=elm-home elm-janitor-apply-patches"
}
```

Like I said: It Works ¯\\\_(ツ)\_/¯

But it left me wondering about the rest of my setup. The Elm plugin, Vite (why did I need that again?) and a couple of workarounds I could no longer explain to myself. When I asked in the Elm Slack whether I could skip the plugin and just reference the compiled Elm output from my HTML, the answer was: sort of. Vite injects code into the JS files it serves even when the script tag says `vite-ignore`. That breaks elm-watch badly enough that even Lydell's own Vite setup needs a custom plugin to cope.

So the one thing Vite still did for me was live reload. And I wanted elm-watch for that anyway. Somewhere in there I started wondering what I still had a bundler _for_ and how and why things always seem to get out of hand in JavaScript (let alone npm!) land.

## The dev server

Bun can [import HTML files](https://bun.com/docs/bundler/html). I assumed that meant strings, but it doesn't: Bun treats the HTML file as an entrypoint and serves everything it references. Which means a dev server can look like this:

```javascript
import index from "./public/index.html";

const API_TARGET = "https://your-cors-sensitive-api.io/api";

const elmWatch = Bun.spawn(["bunx", "elm-watch", "hot"], {
  stdout: null, // don't pollute console when all is a-ok
  stderr: "inherit",
});

// Proxy to dodge CORS hassle from localhost (remove or tweak to your liking)
async function proxyApi(req) {
  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/api/, "") + url.search;
  const headers = new Headers(req.headers);
  headers.delete("host");
  console.log("[api-forward req] →", req.method, path);
  const res = await fetch(API_TARGET + path, {
    method: req.method,
    headers,
    body: req.body,
    redirect: "manual",
  });
  console.log("[api-forward res] ←", res.status, path);
  return res;
}

const server = Bun.serve({
  port: 1337,
  development: {
    hmr: false, // handled by elm-watch
  },
  routes: {
    "/api/*": proxyApi,
    "/*": index,
  },
});

process.on("SIGINT", () => {
  elmWatch.kill();
  process.exit(0);
});

console.log(`dev server running: ${server.url}`);
```

The above has more batteries included than I mostly need, and yet is still _a lot cleaner and terser_!

bun dev.js` and you're up. Wow.

`elm-watch` runs as a child process here, still doing the one job it does better than any bundler plugin: recompiling Elm on change and hot-swapping it in the browser with your app state intact. (Unless your`Model` changed shape, in which case it reloads the page on purpose. Fair enough.) Bun's own HMR is switched off.

The `/api/*` proxy is a bit beside the point for this post, but it was so small that I left it in there; it's not an uncommon requirement after all.

## The build

Production is the other half of the same trick, and simpler stilll:

```javascript
import { rm } from "node:fs/promises";
import tailwind from "bun-plugin-tailwind";

await rm("elm-stuff", { recursive: true, force: true });
await rm("dist", { recursive: true, force: true });

const elmMake = Bun.spawn(
  [
    "bunx",
    "elm",
    "make",
    "src/Main.elm",
    "--optimize",
    "--output=elm-stuff/output.js",
  ],
  { stdout: "inherit", stderr: "inherit" },
);

if ((await elmMake.exited) !== 0) {
  process.exit(1);
}

await Bun.build({
  entrypoints: ["public/index.html"],
  outdir: "dist",
  target: "browser",
  format: "esm",
  minify: true,
  env: "BUN_PUBLIC_*",
  publicPath: process.env.BUN_PUBLIC_BASE_URL || "/",
  plugins: [tailwind], // add/remove as you see fit
});
```

`elm make --optimize` first, then `Bun.build` gets the exact `index.html` the dev server serves and bundles everything it references into `dist/`, minified.

So how does Elm get into the page at all? `index.html` loads `src/main.js`:

```javascript
import { Elm } from "../elm-stuff/output.js";

const app = Elm.Main.init({
  node: document.getElementById("elm"),
  flags: {},
});
```

elm-watch writes `elm-stuff/output.js` during development (an eight-line `elm-watch.json` points it there); `elm make --optimize` writes the same file for production. (And the A$ure auth package from the intro? Imported right here, bundled from node_modules like anything else from ~~gehenna~~ npm-land.)

## YAGNI ftw

[This repo](https://github.com/cekrem/elm-bun/tree/34390b1fa131beee29a9685728d9ecd264019469)[^1] shows you that you can get quite far with excellent results WITHOUT a whole lot of deps. I challenge you to start simple, and only add the bells and whistles (meaning more deps) when and if you _really_ need it.

I've written before about [pragmatic workarounds](/posts/why-you-probably-shouldnt-use-my-elm-land-fork/) when tooling doesn't quite fit. This one was mostly deletion. For the record: Bun still does plenty I haven't read, I'm not saying it's a one trick pony or a minimalism tool (it is, after all, a bundler), but nothing injects itself into elm-watch's output, which is all I need to really care about for now. The minimalism comes from _only_ using Bun.

Using fewer tools means fewer movable parts, less complexity and fewer things that can and/or will break!

All in all: my config is _short_, _makes sense_, and is _WRITTEN_ and _EASILY READ_ by human beings.

I'll be darned, and call me Shirley: that's more than I could say about any build && bundle setup I've had before (involving JavaScript, that is).

[^1]: The astute reader will notice that this link points to a prior commit, and not the `HEAD` of this repo. If you go to `master`, you'll probably see what my next post is about and why that's even easier and cleaner! Turns out I still code faster than I blog, which is mostly a good thing :)
