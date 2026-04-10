+++
title = "I Signed the 'No AI in Node.js Core' Petition"
description = "19,000 lines of AI-generated code to Node.js core. No thanks."
tags = ["open source", "ai", "node.js", "software craftsmanship"]
date = 2026-04-10
draft = false
+++

It's Friday, and I just signed [a petition](https://github.com/indutny/no-ai-in-nodejs-core) asking the Node.js TSC to vote no on allowing AI-generated code in Node.js core.

Someone opened a 19,000-line pull request to rewrite Node.js internals, with the disclaimer that "a significant amount of Claude Code tokens" were used to create it. The author reviewed the changes themselves. (That's the claim, anyway. And speaking of (dis)claim(ers): I don't know the author of this PR or the quality of prior contributions, that's beside the point! Probably a brilliant software engineer!)

Nineteen thousand lines. I've reviewed PRs a fraction of that size and still missed things. Reviewing AI output is a different kind of reading than reviewing code a human wrestled with, line by line. When someone writes code, the PR tells a story of decisions made. When an LLM generates it, you're reading _output_. The shape looks right. The story is missing. (I'll leave from the present discussion the absurdity of such a large PR in general, btw. That's just crazy!)

I [use AI for the boring parts](/posts/claude-code-game-changer-or-just-hype/), as much as the next guy. Or probably less than the next guy, but still. Grouping Tailwind classes, catching subtleties that linters miss, reformatting data, proofreading or going over semi-relevant data in search of clues when doing tough debugging. Grunt work. But that's a completely different thing from mass-producing 19k lines of code to a project that runs on millions of servers and calling it your contribution.

Code review on a project like Node.js exists for two reasons: catching bugs, and growing contributors. An LLM learns nothing from review feedback. The hours a maintainer spends reviewing generated code are hours that don't compound. And using these tools costs money (or a beefy GPU). Open source contributions should be reproducible by reviewers without requiring a paid subscription. That's a weird gatekeep to introduce into a project that's been open for over a decade.

[Sign it if you agree.](https://github.com/indutny/no-ai-in-nodejs-core)
