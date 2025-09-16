+++
title = "HTML Helpers 2.0.0 for Elm: Stable conditionals and attributes"
slug = "html-helpers-2-0-0-for-elm"
description = "2.0.0 adds and documents the canonical helpers for clean conditionals and attribute composition, for both single nodes and lists"
tags = ["elm", "html", "functional programming", "frontend", "open source"]
date = "2025-09-16"
draft = false
+++

Back in May, I introduced a tiny Elm package of HTML utilities focused on reducing boilerplate and improving readability. Since then, I’ve been using it in a few projects and gathering feedback. Today I’m releasing version 2.0.0, which finalizes the core API: concise conditionals for single elements and attribute utilities—as well as the 1.x stuff for lists.

If you want to skim the exact changes from 1.3.2 to 2.0.0, here’s the comparison: [1.3.2..2.0.0](https://github.com/cekrem/html-helpers/compare/1.3.2..2.0.0).

## What’s new in 2.0.0

- **Single-node conditionals**: `when`, `unless`, plus `lazyWhen`, `lazyUnless`
- **Attribute helpers**: `attributeIf`, `attributesIf`, `noAttribute`
- Still there and useful: `contentList`, `lazyContentList`, `maybeContentList`, `wrapToSingleNode`, `nothing`, `hideOnBreakpoint`

The goal remains the same: make the most common conditional and “nothing here” patterns feel effortless and obvious at the call site—without changing how you structure your views.

## Embarrassing side note: whatever happened to 1.4.0?

Well, I dislike using AI for _coding_ as I've written about at length on this blog (I do NeoVim without copilot or any other evil!), but sometimes I experiment with having an agent solve menial and dull tasks like rebasing or merging a git stash back in when my branch is outdated. That's what I tried today, right before lunch – bad idea. A rename got lost in the 'auto merge these' operation, and I ended up with duplicates in 1.4.0. Sorry! But an excellent point to my ongoing argument and tirade against using agents in the first place, non-critical as this operation was! Lesson learned: Just don't.

In other words: 2.0.0 is only a breaking change because of my earlier git conflict resolution screwup, so unless you happened to update in the tiny space between 1.4.0 and 2.0.0 there are no _actual_ breaking changes. Only new and nice stuff 🤤

## Quick examples

### 1) Single-node conditionals

```elm
import Html as H exposing (Html)
import Html.Attributes as A
import HtmlHelpers exposing (when, unless, lazyWhen, lazyUnless, nothing)

view : { isLoggedIn : Bool, isLoading : Bool } -> Html msg
view model =
    H.div []
        [ when model.isLoggedIn <| H.p [] [ H.text "Welcome back!" ]
        , unless model.isLoading <| H.button [ A.class "btn" ] [ H.text "Refresh" ]
        , lazyWhen model.isLoggedIn <| H.img [ A.src "/images/avatar.png", A.alt "Avatar" ] []
        , lazyUnless model.isLoading <| H.div [ A.class "ready" ] [ H.text "Ready" ]
        ]
```

These read well at the call site and remove the “if-then-else returning `nothing`” boilerplate.

### 2) Attributes without branching noise

```elm
import Html as H
import Html.Attributes as A
import HtmlHelpers exposing (attributeIf, attributesIf)

viewButton : { canSubmit : Bool, isPrimary : Bool } -> H.Html msg
viewButton model =
    H.button
        [ attributeIf (not model.canSubmit) (A.disabled True)
        , A.class "btn"
        ]
        [ H.text "Submit" ]

viewCard : { isActive : Bool } -> H.Html msg
viewCard model =
    H.div
        (attributesIf model.isActive [ A.class "card active", A.tabindex 0 ])
        [ H.text "Content" ]
```

`attributeIf` and `attributesIf` keep attribute lists linear and readable.

## Install / upgrade

```
elm install cekrem/html-helpers
```

Then import what you need:

```elm
import HtmlHelpers exposing (when, unless, attributeIf, attributesIf)
```

Source code: [github.com/cekrem/html-helpers](https://github.com/cekrem/html-helpers). Feedback is welcome—if you have ideas for additional helpers that keep view code tidy, open an issue or PR!
