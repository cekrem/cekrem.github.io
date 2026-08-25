+++
title = '`bun-plugin-elm`: import { Elm } from "./Main.elm" (Made by Hand, btw)'
description = "Last week's two Bun scripts are now a 65-line plugin. In other more AI-related news: it kind of feels like Bun is the wrong horse to bet on."
tags = ["elm", "bun", "elm-watch", "tooling", "simplicity", "ai", "coding-as-craft"]
date = 2026-08-25
draft = false
+++

Last week I [replaced Vite and all its deps and stuff with two Bun scripts](/posts/bun-and-elm-are-friends/) and felt rather pleased with myself. The footnote at the bottom hinted at something even better, and here it is. Lo and behold, the scripts are now a reusable plugin! 🥳

## A bun plugin isn't so hard, really

The main problem to solve is as follows: Bun has no idea what a `.elm` file is. So `build.js` (in my previous iteration, before the plugin) ran `elm make`, waited for it, and only then handed `index.html` to `Bun.build`. And `dev.js` (again, previous iteration) spawned `elm-watch hot` on the side and killed it again when its time had come. A perfect fit for that particular project, yes, but if we're being honest it's quite a bit more reusable than that. The Right™ solution would be a plugin!

Bun plugins are probably a lot more powerful than what I'm doing here, BUT suffice it to say: they have an `onLoad` hook! It gives you a file filter, and for every matching import you return the JavaScript you'd like it to resolve to. That's all [bun-plugin-elm](https://github.com/cekrem/bun-plugin-elm) really does (trimmed a little here):

```typescript
build.onLoad({ filter: /\.elm$/ }, async ({ path }) => {
  const watchMode = !build.config.outdir;
  const output = join(process.cwd(), "elm-stuff/output.js"); // why not just use an already git-ignored dir?
  await rm(output, { force: true });

  const elmMake = Bun.spawn(
    ["bunx", "elm", "make", path, "--optimize", `--output=${output}`],
    { stdout: "inherit", stderr: "inherit" },
  );
  const exitCode = await elmMake.exited;
  if (exitCode > 0 && !watchMode) {
    process.exit(exitCode);
  }

  // on watch mode: write elm-watch.json if missing, spawn `elm-watch hot`
  // {... see full source on github}

  return {
    contents: `export { Elm } from "${output}";`,
    loader: "js",
  };
});
```

Import a `.elm` file, and the plugin runs `elm make` on it and hands Bun a one-liner re-exporting the compiled output. No `outdir` means we're serving rather than building, so the plugin also writes an `elm-watch.json` (unless you have one) and starts `elm-watch hot`, just like `dev.js` used to. And it works!

## Simplicity, vol 2

A mere `bun add --dev bun-plugin-elm` and something like this in your `main.js` is pretty much all you need:

```javascript
import { Elm } from "./Main.elm";

const app = Elm.Main.init({
  node: document.getElementById("elm"),
  flags: {},
});
```

Given the above, any `Bun.build` call with `plugins: [elmPlugin]` Just Works™. For dev, `Bun.serve({whateverConfig})` (or plain `bun public/index.html`) picks the plugin up after adding this to `bunfig.toml`:

```toml
[serve.static]
plugins = ["bun-plugin-elm"]
```

## The sad part

Bun [joined Anthropic](https://bun.com/blog/bun-joins-anthropic) in December. I honestly didn't catch that. What's more, in July, Jarred Sumner published [Rewriting Bun in Rust](https://bun.com/blog/bun-in-rust): 535,496 lines of Zig ported to Rust in eleven days by up to 64 Claude agents, ~$165,000 worth of tokens, he said, with basically one engineer supervising. The result is called Bun 1.4.

Yikes.

So there I was, praising Bun for letting me keep everything hand written and readable. The irony of it all kind of sucks, to be honest.

[Naur would ask what happened to the theory](/posts/programming-as-theory-building-naur/). _Whatever understanding of that codebase lived in the heads of the people who wrote the Zig, they're not the ones who wrote the Rust_! [A bit like nodejs...](/posts/no-ai-in-nodejs-core/)

Well. I'm still using Bun, for now. I just finished deleting a bundler; I'm not shopping for a new one just yet. But it did make me want to label my own stuff.

## "Made by hand, btw"

So the plugin repo got a badge, with an `AI_DISCLOSURE.md` behind it, and I think my other repos are getting the same as I touch them:

[![no ai, I like coding](/images/no-ai.png)](https://github.com/cekrem/bun-plugin-elm/blob/master/AI_DISCLOSURE.md)
