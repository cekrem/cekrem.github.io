+++
title = "If You're Running Claude Code, PLEASE Run It in a Box"
description = "I occasionally use Claude Code for genuinely tedious tasks. I always run it sandboxed. Here's why and how."
date = 2026-05-18
author = "Christian Ekrem"
tags = ["ai", "claude", "tools", "security", "workflow", "craft"]
draft = false
+++

Let's talk about Claude Code for a minute. I'm not going to tell you yet again ([[1]](/posts/programming-as-theory-building-naur), [[2]](/posts/architecture-by-autocomplete), [[3]](/posts/llms-corrupt-your-documents), [[4]](/posts/im-taking-a-three-week-llm-fast)) why you _shouldn't_, but rather _how_ you should use it, if you must. In other words: this post assumes you've already thought about the craft side, and focuses on not blowing up your production {insert whatever} in the process.

But just to summarize the why and why not of Claude Code (or whatever latest fancy tool), here's where I actually think it shines:

I have a really nice (and also quite dumb and non-complex) skill called `tidy-tailwind`. Before:

```elm
button
    [ class "bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 font-medium text-sm flex items-center gap-2 disabled:opacity-50 md:px-6 md:py-3 border border-blue-600 shadow-sm"
    ]
    [ text "Submit" ]
```

After:

```elm
button
    [ class "flex items-center gap-2"
    , class "px-4 py-2 md:px-6 md:py-3"
    , class "font-medium text-sm"
    , class "text-white"
    , class "bg-blue-500 hover:bg-blue-600"
    , class "border border-blue-600 rounded"
    , class "shadow-sm"
    , class "disabled:opacity-50"
    ]
    [ text "Submit" ]
```

Takes seconds, costs nothing to verify, and I genuinely do not learn anything from doing that by hand. So I don't. It's nice! And it doesn't make me stupid, though arguably less adept at, I don't know, creating `vim` macros?

I'll also occasionally connect it to a Figma MCP server and ask "does the gap on this card match the design?" (Almost always, btw: "not quite." Which is the whole point.) Switching windows and squinting at spacing values is exactly the kind of thing I want to outsource to something that doesn't mind doing it. I'm not on this earth to become a Figma layers investigator expert! Arguably, again, I would learn things from doing this to all manually. But I'm an engineer, preferably dealing with code, not with clicking through Figma layers.

And, yes, occasionally -- very occasionally -- I'll run Claude over a chunk of code before or after I do my own review. It catches things sometimes. But I still do the review, and a human still signs off. That last one's not negotiable.

Bottom line: I want the common denominator for all my LLM usage to be that it frees up _more time for me to write code and do engineering_, not to outsource those very things.

OK, back to the point: whatever your LLM usage scope may be, please pause for a moment with me and think about _how_ you use it.

## Why it needs a box

In case you forgot, Claude Code runs shell commands. It reads your environment variables(!), your filesystem, your git config -- credentials baked in. And each command informs the next; you give it a goal, not a script, and it figures out the steps. [The Railway agent](https://www.theregister.com/2026/04/27/cursoropus_agent_snuffs_out_pocketos/) had a goal, found a token, and acted on it. Confidently. Without checking what it was actually deleting.

[Replit did something similar last summer](https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/): AI agent, active code freeze, production database gone, 1,200+ companies affected. The agent called it "a catastrophic error in judgment." There's also a [Claude Code GitHub issue](https://github.com/anthropics/claude-code/issues/11237) where someone's agent ran `git reset --hard`, fetched stale data from remote, and silently overwrote eight hours of work. No prompt or warning, just that telltale LLM self-confidence.

I won't even mention how [29 million secrets were leaked in public GitHub commits in 2025](https://www.helpnetsecurity.com/2026/04/14/gitguardian-ai-agents-credentials-leak/) -- up 34% year over year, with AI tools ingesting `.env` files for context flagged as a significant driver. Won't mention at all.

## Bottom line: Don't be stupid, just do this

What you need is to simply use Docker's `sbx` (`brew install docker/tap/sbx`):

```bash
sbx run claude
```

The [sbx docs](https://docs.docker.com/reference/cli/sbx/) cover the setup, but TL;DR by default this spawns a safe sandbox that can't `git push` or read files outside of your project. **What an extreme improvement right from the start that is!**

![michael-scott-prison-mike](https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHF4OGtjanJ6YTVybTk3a3R6amR6bTQ4anV2aHFyN2Y4bXRscTFtaiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/niC0LL8nmXnWp0d7Sn/giphy.gif)

And get this: inside the sandbox (/prison), you can actually just let it run without that annoying halt asking for permission to `cat` a file or whatever. Claude Code auto-approves everything by default -- full kamikaze mode with no confirmation prompts. On my host machine that would be terrifying (I mean, even without the dangerous flags it does crazy stuff!). Inside `sbx` it's fine, because it has neither my `git` credentials nor any path to anything outside my working directory. Worst case something goes sideways, I close it and `git stash`. Containable blast radius: √.

In other words: Sandboxing makes it _faster_, not just safer. Took me a while to realize that.

(Btw, someone replied that Claude Code has its own sandbox mode that we should rather use. Allow me to simply answer with this wonderful screenshot from a fellow Elm developer:
![Claude's "sandbox"](/images/sandbox_much.jpg)

Suffice it to say I prefer the _real_ sandbox.)

---

The same nine seconds that the rogue agent spent blowing up a production db would be better spent on doing `cp -r ~/.claude/skills .claude/skills && sbx run claude` instead of `claude`. And since you're a developer, I bet you could (without asking an LLM for help) find some way to `alias` it too.
