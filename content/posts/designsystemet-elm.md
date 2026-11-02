+++
date = 2026-11-02
title = "Designsystemet, Now in Elm"
description = "We ported the Norwegian public sector's design system to Elm, and you can have it."
tags = ["elm", "open source", "designsystemet", "design systems", "web components", "enso"]
draft = false
+++

[Designsystemet](https://designsystemet.no) is a really good design system. It's Norway's shared toolbox for public sector services: components, guidelines and patterns, open and free for anyone to use. It's also built _together_ by the people who need it, with Digitaliseringsdirektoratet, Mattilsynet, KS Digital, Utdanningsdirektoratet and Brønnøysundregistrene all on its front page. Hence the point of the whole thing: public services that look and behave like they belong to the same country, and fewer teams solving the same dropdown over and over. Or hamburger menus or whatever.

Until now it's been mainly a react thing, though. So at Enso we built the Elm port, so you can start using it in _real_ applications as well :D

Lo and behold: [designsystemet-elm](https://github.com/ensolabs/designsystemet-elm)! Every component is in the [showcase](https://ensolabs.github.io/designsystemet-elm/), which is the best place to start if you'd rather click around than read my blog post (no hard feelings).

```elm
Html.form [ Ds.size Size.sm, Events.onSubmit Save ]
    [ Textfield.new (Ds.label "Navn")
        |> Textfield.withError model.nameError
        |> Textfield.view [ Attr.value model.name, Events.onInput NameChanged ]
    , Button.view [ Attr.type_ "submit" ] [ Html.text "Lagre" ]
    , Button.view [ Button.tertiary, Ds.color Color.danger, Events.onClick Delete ]
        [ Html.text "Slett" ]
    ]
```

That's 41 component modules, one for every non-deprecated component in the React package, with the same markup and the same CSS.

## We reimplemented (almost) nothing

The tempting way to do this is to rewrite the whole thing in Elm from scratch (in a vacuum, as the saying goes), main problem being that then you own every focus bug and popover edge case until the end of time. But it turns out the React package is a surprisingly thin layer. The styling, as one might expect, lives in `@digdir/designsystemet-css`, but add to that: most of the _behavior_ lives in `@digdir/designsystemet-web`, as web components and polyfills. React renders markup and gets out of the way.

Don't mind if we do!

So: Elm renders the same elements, classes and `data-*` attributes as React, and the same CSS and the same web components take it from there. The Elm package ships no JS and no CSS at all.

Is it that easy? Almost. There's one catch!

## One owner per attribute

Elm's virtual DOM diffs against its _previous view_, not against the live DOM. So if Elm and a web component both write the same attribute, they'll quietly overwrite each other, and you'll waste many an afternoon debugging.

The fix is a basic, but hard rule: every attribute has exactly one owner. If `designsystemet-web` manages it, the Elm module never renders it, and each module's docs list which attributes are off limits.

And then there's the one thing left over. A `<dialog>` can only be opened by calling a method (`showModal()`), and that's not something a pure view function can do. The usual Elm answer is a port, but having every app wire up a port to open a dialog felt silly. So the view renders an attribute instead, and a small script watches it and calls the method to match:

```elm
Dialog.new deleteDialog
    |> Dialog.withCloseButton { label = "Lukk dialogvindu" }
    |> Dialog.view [ Dialog.open model.isOpen, Dialog.onClose DialogClosed ]
        [ Html.text "Slette saken?" ]
```

No ports, and from the outside it's just a `Bool` in your model, the way it should be.

Disclaimer: Though I haven't copied a single line of code from there, I learned this (approximate) approach by some clever guys @ Lovdata. Marked my life.

## Rules that React only documents

This is where it gets fun for people like me. The React docs say a form control needs exactly one of `label`, `aria-label` or `aria-labelledby`, but React being React it can't really enforce such rules. In Elm, however: you can't call `Textfield.new` without a `Ds.Label`, so that's no longer something to remember. Icon buttons want `{ label = ... }` for the same reason. A `Dialog.Id` can't be handed to a popover. And a badge can't have a `count` and a `maxCount` that disagree, because there's no such thing:

```elm
type Content
    = Dot
    | Count Int
    | Capped { count : Int, max : Int }
```

[Deja vu?](/posts/making-impossible-states-impossible-with-functional-dependency-injection/). In my defense, it kind of a big deal!

The most controversial change in this port: we removed the Norwegian. React defaults to strings like "Lukk dialogvindu" and "%d tegn igjen", and the Elm package has no default texts at all. Every string is a required argument, so a package made by Norwegians for a Norwegian design system works in any language.

## How do you know it's really 1:1?

You check! The showcase mirrors the official Storybook story for story, and all 271 upstream stories are either ported or skipped with a written reason (5 are skipped, like the two that only exist to simulate `:hover` and `:active` in Storybook). `bun run parity` then opens every Elm story next to its React twin on the live Storybook, diffs the normalized markup and takes a screenshot of both. Elm's types can't tell you that you forgot a `data-*` attribute, but a diff sure can.

And this is actually a fair use case for Claude and friends. I'm fine with having it as a slave for things like this.

**So, this port has used and will keep on using agents _far more_ than my usual approach, as I think it's a rare case of "right tool for the job" (low risk, thin layer, _very clear and confined specs && reqs_ etc). Keeping up with upstream css/web-component changes _should_ be quite automagic too, which is a win. And, full disclosure: another reason is that I find both making and not least maintaining design systems is on the boring end of the spectrum, with the rare exception of solving more complex stuff like dialogs.**

In any case: The port follows React (`1.23.0` mirrors `1.23.0`), but the Elm registry derives its own semver from the API, so the npm package is at 1.23.0 while the Elm package is at 1.0.0. That's confusing, probably, and I'm sorry. More on that in the README.

(Speaking of apologies: if you're using [Bun like me](/posts/bun-plugin-elm/), don't import the CSS. Bun's CSS bundler can't parse `sibling-index()`. The showcase front page has a tested setup that works around it.)

## Go on, then

```
elm install ensolabs/designsystemet-elm
npm install -E @ensolabs/designsystemet-elm@1.23.0 @digdir/designsystemet-css@1.23.0
```

The [README](https://github.com/ensolabs/designsystemet-elm) covers the rest, including Tailwind. It's a community port, not affiliated with or endorsed by Digdir, so if something's broken, blame us and open an issue.

I realize the audience for "Elm in the Norwegian public sector" might fit in a fairly small meeting room. If that's you, though: hi! Do let me know how it goes.

(Fun fact, though: "Vy", the Public Norwegian railway company used to run on Elm!)
