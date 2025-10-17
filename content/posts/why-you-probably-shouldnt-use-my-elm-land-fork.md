---
title: "Why You Probably Shouldn't Use My Elm Land Fork"
date: 2025-10-17
description: "A pragmatic detour while waiting for the real solution - introducing @cekrem/elm-land and why it exists as a temporary workaround"
tags: ["elm", "elm-land", "architecture", "open-source"]
draft: false
---

## A Pragmatic Fork

In [my previous post](/posts/elm-land-shared-subscriptions-and-the-art-of-workarounds/), I explored the challenge of reacting to `Shared` model changes in Elm Land. I tried a [pretty hacky HTML helper](https://package.elm-lang.org/packages/cekrem/html-helpers/latest/HtmlHelpers#sendMsgWhen) that sends messages from the view layer. It worked, but it felt... wrong. (And to be honest, the previous "solution" wasn't as much a real solution as it was a satirical take on how far one is willing to go to push through framework limitations.)

After considering less satirical alternatives, I settled on the most straightforward approach: to fork Elm Land, add the specific hook we needed, and use it as a vendored dependency. This would tide us over until either Elm Land 1.0 arrives with proper built-in support, or (better yet) until we can refactor our app to not need this at all.

So I did. And you can find it on npm as [`@cekrem/elm-land`](https://www.npmjs.com/package/@cekrem/elm-land).

**But before you go installing it, let me be very clear: you probably shouldn't use it.**

Let me explain.

## What the Fork Does

The fork adds a single new feature to Elm Land's beta: a `withOnSharedMsg` hook that lets pages and layouts react to messages from `Shared`.

Here's how it works (for pages; the type signature for `Layout.withOnSharedMsg` is identical):

```elm
page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
        |> Page.withOnSharedMsg
            (\sharedMsg ->
                case sharedMsg of
                    Shared.Msg.ItemsSaved ->
                        ShowSuccessToast

                    _ ->
                        NoOp
            )
```

When `Shared` processes certain messages, your page can react by returning its own message. In this example, when `Shared.Msg.ItemsSaved` happens, the page receives a `ShowSuccessToast` message that it can handle in its `update` function.

It's explicit, type-safe, and doesn't require hacky HTML tricks or JavaScript ports.

## How It's Implemented

The implementation is surprisingly straightforward - the TL;DR is that in addition to sending `Shared.Msg` through `update` in `Shared` (returning a new `Shared.Model`), it also passes messages through the `withOnSharedMsg` of every page and layout that uses this helper. These "secondary" update handlers in turn transform the `Shared.Msg` into `Page/Layout Msg` (of course leaving the shared _model_ intact).

You can see the [full implementation in the pull request](https://github.com/elm-land/elm-land/pull/205) I submitted to Elm Land. It's about 100 lines of code, most of which is plumbing to thread the new hook through Elm Land's code generation.

## Why I Made This

We hit a real need at my client project. We had moved a lot of state out of individual pages and into `Shared` to avoid refetching the same data across different parts of the app. Our views already reacted to the changed state just fine, but we needed to react to _the moment of change_ - to trigger effects when something in `Shared` changed, like showing a notification when one component deletes an item that another component is displaying. Without a way to react to those point-in-time events, we had a few unpalatable options:

1. Use the `sendMsgWhen` hack from my previous post (never a real option, like I said the whole solution was mainly parodic)
2. Route all changes through JavaScript ports (ah... The idea that woke my satirical mind in the first place – it still gives me the shivers!)
3. Manually diff `Shared.Model` on every update
4. Let go of the shared state mental model completely, accepting duplicated state across components
5. Fork Elm Land and add the hook we need

Option 5 became the clear winner. Ryan (Elm Land's author) explicitly encouraged forking for cases like this - better to unblock your team with a vendored copy than to be bottlenecked by the framework's release schedule.

And that's what this fork is: **a pragmatic workaround for a temporary limitation.**

## Why You Probably Shouldn't Use This

Here are several good reasons not to use `@cekrem/elm-land`:

### 1. You Might Not Need It

As I discussed in my previous post, needing to react to `Shared` changes with effects is actually pretty rare. Most of the time, you can:

- Model your state differently to avoid the issue
- Let your view react to `Shared` naturally (which works great)
- Initialize your page state appropriately

If you're reaching for this hook, first ask: "Am I modeling this correctly?" The answer might be no, and fixing your model might be cleaner than adding a "framework hook".

### 2. It's a Maintenance Burden

This fork needs to stay in sync with Elm Land's beta. Every time there's an upstream change, someone needs to merge it. That someone is probably you if you use this.

For my team, that trade-off is worth it. We have a specific need, a certain timeline, and the expertise to maintain the fork. But if you're just starting with Elm Land, taking on a forked dependency is probably not where you want to begin.

### 3. It's Not the Real Solution

Elm Land 1.0 will have a better, more comprehensive approach to this problem. This fork is explicitly a stopgap measure. When 1.0 arrives, we'll migrate off this fork and onto the official release.

Using this fork means you'll need to migrate later. If you can wait for the real solution, you should.

### 4. It Might Enable Bad Patterns

Having `withOnSharedMsg` available makes it easy to add "just one quick reaction" to a shared message. Then another. And another.

Before you know it, you have a complex web of dependencies between `Shared` and your pages - exactly the kind of coupling that better state modeling would avoid.

The friction of not having this hook is actually useful sometimes. It forces you to think harder about your architecture.

## When You _Might_ Use This

That said, there are valid scenarios where this fork could help:

1. **You have a production deadline** and can't wait for Elm Land 1.0
2. **You've carefully considered your architecture** and determined you really do need this
3. **You have the expertise** to maintain a forked dependency
4. **You have a specific, well-defined use case** (not just "it would be convenient")

If all four of those are true, then sure - `@cekrem/elm-land` might save you some time.

## Most importantly, though

I want to be absolutely clear: **Elm Land is a fantastic framework.**

Ryan has built something genuinely useful that makes Elm development more productive and enjoyable. The beta is already impressive, and everything he's shared about 1.0 sounds even better.

This fork exists not because Elm Land is broken, but because:

1. The beta has known limitations (which Ryan openly acknowledges)
2. 1.0 is still in development
3. Real projects sometimes need solutions now

This fork is a bridge, not a rejection. It's a way to use Elm Land productively today while waiting for the better solution tomorrow.

## Installation (If You Really Want To)

If you've read all the caveats and still want to try it:

```bash
# Global install
npm install -g @cekrem/elm-land

# Project install
npm install --save-dev @cekrem/elm-land
```

Then use `elm-land` commands as normal - the CLI is identical, just with the new `withOnSharedMsg` hook available.

Check out the [package on npm](https://www.npmjs.com/package/@cekrem/elm-land) for the current version and any additional notes.

## The Bigger Lesson

This whole experience reinforces something I've learned about open source: **Good maintainers support pragmatic forks.**

Ryan didn't take offense at the fork. He didn't try to convince me the limitation wasn't real. He encouraged it as a valid solution while being transparent about what's coming in 1.0.

That's how healthy open source projects work. The framework serves the users, not the other way around.

And sometimes serving users means giving them permission to fork when they need something you can't provide yet.

## Looking Forward

When Elm Land 1.0 arrives with its `Effect` and `Subscription` system, we'll migrate off this fork immediately. That system will be more powerful, more flexible, and better integrated with the framework's overall design.

Until then, `@cekrem/elm-land` solves a specific problem for my team. If it helps yours too, great. But don't reach for it without first questioning whether you really need it.

Nine times out of ten, better modeling is the answer. This fork is for the tenth time.

## The Real Takeaway

If there's one thing I want you to get from this post, it's not "use my fork" or even "fork Elm Land when you need to."

It's this: **Framework constraints are usually there for good reasons, but pragmatism has its place too.**

Think hard about your architecture. Model your state carefully. Exhaust the clean solutions first. But if you hit a legitimate limitation that's blocking your team, and you have the expertise to work around it responsibly - don't be afraid to do so.

Just be honest with yourself about whether it's a legitimate limitation or a sign you're modeling things wrong.

(It's probably the latter. But sometimes it's not!)

And for the record, again: I really do like Elm Land.
