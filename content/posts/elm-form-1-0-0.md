+++
title = "cekrem/elm-form: Type-Safe Forms That Won't Let You Mess Up"
slug = "elm-form"
description = "A new Elm package for building forms with phantom types, validation, and the compiler's blessing"
tags = ["elm", "forms", "functional programming", "frontend", "open source", "phantom types"]
date = "2025-12-03"
draft = false
+++

I just published [cekrem/elm-form](https://package.elm-lang.org/packages/cekrem/elm-form/1.0.0/) – a package for building HTML forms in Elm with type safety, validation, and a clean API. If you've ever written forms in Elm (or any language, really), you know they can get messy fast. This package tries to make them less so, without including too many arbitrary batteries.

## What's the Deal?

Forms are everywhere, and they're usually tedious to build. You need labels, inputs, validation, error handling, accessibility attributes, and somehow it all needs to stay in sync. `elm-form` gives you a declarative way to build forms that handles the boilerplate while keeping things type-safe.

Here's a quick example:

```elm
Form.new [ Attr.class "contact-form" ]
    [ Form.input "name" "Full Name"
        |> Form.withRequired True
        |> Form.withTransformer String.trim
    , Form.input "email" "Email Address"
        |> Form.withType "email"
        |> Form.withRequired True
        |> Form.withValidator emailValidator
    ]
    |> Form.build model.formValues FormChanged FormSubmitted
```

That's it. No manual wiring of `onInput` handlers, no forgetting to add labels, no wondering if you remembered to trim that username field.

And btw, we're simply using a **single `Dict String String` to store all form values**.

![michael-scott-happy](https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExeTZiNnJzeng0bjN5aGIwZXZqenVybHcyMDR5MXQxa2UyOXJiODkzcSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/tlGD7PDy1w8fK/giphy.gif)

## The Phantom Types Thing

The package uses phantom types for stand-alone inputs to help model their state:

```elm
-- This won't compile (good!):
Input.new "Username"
    |> Input.build ""

-- This will compile:
Input.new "Username"
    |> Input.withOnChange UsernameChanged
    |> Input.build ""
```

The compiler literally won't let you render a stand-alone input without either an onChange or a "disabled" prop. It's like having a very pedantic code reviewer who never gets tired of pointing out the same mistake. Except this one is helpful. 😅

(Note: In the complete code example above with a `Form` given a list of `input`s the type checker does the opposite: you're _not_ allowed to manually set an onChange handler per input – the form builder wires things up for you.)

## Validation Without the Headache

Validators in `elm-form` return HTML attributes instead of error messages. This might sound weird at first, but it's actually pretty nice:

```elm
emailValidator : String -> Result (List (Html.Attribute msg)) ()
emailValidator value =
    if String.contains "@" value && String.contains "." value then
        Ok ()
    else
        Err
            [ Attr.class "error"
            , Attr.attribute "aria-invalid" "true"
            ]

-- (btw: don't validate emails like this, I'm just trying to get a point across)
```

This approach keeps the library flexible – you decide how to display errors. Want CSS-based styling? Add a class. Need accessibility? ARIA attributes are right there. The library doesn't make assumptions about your UI.

## Why Another Form Package?

Fair question. There are other form packages in the Elm ecosystem, and they're good. But I wanted something that:

1. Uses phantom types to catch mistakes at compile time
2. Keeps the API simple and composable
3. Handles the common cases without getting in the way
4. Doesn't force specific UI patterns on you
5. Has an even more minimalistic approach, and fewer included batteries

Plus, building packages is a great way to learn. And now I get to use it in my own projects, which is a real win.

## Get Started

```bash
elm install cekrem/elm-form
```

The [README](https://github.com/cekrem/elm-form) has more examples, including login forms, registration forms with multiple validators, and using the lower-level `Input` module directly when you need more control.

Source code is on [GitHub](https://github.com/cekrem/elm-form), and feedback is welcome. If you find bugs or have ideas for improvements, open an issue or PR.

---

## Shameless Plug

If you're enjoying these Elm packages and want to dive deeper into functional programming, check out my book: [An Elm Primer for React Developers](https://leanpub.com/elm-for-react-devs). It's written specifically for React developers who want to learn real functional programming without getting lost in academic theory. Even if you never write production Elm, learning it will make you a better React developer. Promise.

There's a free sample on Leanpub, and I've also published [chapter 2](/posts/chapter-2-take-2/), [chapter 8](/posts/elm-book-missing-chapter-8-ports-interop/) and [half of chapter 9](/posts/elm-book-chapter-9-organizing-files-and-modules/) here on the blog.
