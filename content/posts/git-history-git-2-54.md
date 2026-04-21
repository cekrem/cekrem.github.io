+++
title = "git history: the best thing in Git 2.54"
date = "2026-04-21"
description = "Git 2.54 ships an experimental git history command that does less than rebase. That's the whole point."
tags = ["git", "tools", "functional programming"]
draft = false
+++

Git 2.54 dropped yesterday. 137 contributors, 66 of them first-timers. But the thing I keep thinking about is a small experimental command called `git history`.

It does two things. `git history reword <commit>` lets you fix a commit message and rewrites everything downstream. `git history split <commit>` lets you chop a commit into pieces with the same hunk-picker from `git add -p`. Neither operation touches your working tree or index.

## What it refuses to do

Merge commits? Won't touch them. An operation that _might_ cause a conflict? Won't even start.

Compare that to `git rebase -i`, which will happily begin rewriting your history and then strand you mid-conflict at 11pm on a Friday. You just wanted to fix a typo in a commit message. Now you're resolving conflicts in files you didn't write.

`rebase -i` says "start, then maybe fail." `git history` says "only start when completion is guaranteed." If you've spent time around functional programming, the second one should feel familiar -- same instinct behind making impossible states impossible, except somebody applied it to a CLI.

The whole thing runs without touching your working tree, and it builds on the `git replay` machinery under the hood, so scripting it is straightforward. I've been burned enough times by rebases gone sideways that a tool which says "I will only do this if I _know_ it works" feels kind of radical (even though it shouldn't be).

It's still experimental, so the interface might change. I hope the design philosophy sticks around, though.

[Release notes.](https://github.blog/open-source/git/highlights-from-git-2-54/)
