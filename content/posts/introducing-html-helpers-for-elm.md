+++
title = "Introducing HTML Helpers for Elm"
description = "A small utility package to make working with HTML in Elm more convenient"
tags = ["elm", "html", "functional programming", "frontend", "open source"]
date = "2025-05-06"
draft = false
+++

As I continue to build more Elm applications, I find myself creating small utility functions to overcome common pain points. I'm a big fan of abstracting away repetitive patterns into reusable, well-named functions. Today, I'm happy to announce the release of my first public Elm package: [html-helpers](https://package.elm-lang.org/packages/cekrem/html-helpers/latest/).

## What's the Problem?

Elm's HTML API is quite straightforward - you create HTML elements as functions, pass them attributes and children, and compose them together. But a few cases come up repeatedly that can be awkward:

1. **Conditional rendering**: Showing or hiding multiple elements based on some condition often leads to boilerplate code
2. **Empty elements**: You end up writing `text ""` a lot when you need to render nothing
3. **Wrapping elements**: When a function returns a list of HTML nodes, but the caller needs a single node

These aren't major issues, but they're little friction points that come up repeatedly.

## Enter html-helpers

The package contains just three simple functions (for now), but each addresses a common pain point when working with HTML in Elm:

### 1. `contentList`: Conditional rendering made easy

The most obvious usecase is similar to that of `Attributes.classList`, but for content rather than classes:

```elm
viewAnimals : Animal -> Animal -> Animal -> Html msg
viewAnimals dog cat mouse =
    Html.section [ Attributes.id "animals" ] <|
        contentList
            [ ( Html.text dog.name, dog.visible ) -- dog will be rendered if dog.visible is True
            , ( Html.text cat.name, cat.visible ) -- etc
            , ( Html.text mouse.name, mouse.visible ) -- etc
            ]
```

This is much cleaner than the alternatives:

```elm
-- Without contentList, using List.filter and List.map
Html.section [ Attributes.id "animals" ] <|
    ([ ( Html.text dog.name, dog.visible )
     , ( Html.text cat.name, cat.visible )
     , ( Html.text mouse.name, mouse.visible )
     ]
        |> List.filter Tuple.second
        |> List.map Tuple.first
    )

-- Or using List.concat and if expressions
Html.section [ Attributes.id "animals" ] <|
    List.concat
        [ if dog.visible then [ Html.text dog.name ] else []
        , if cat.visible then [ Html.text cat.name ] else []
        , if mouse.visible then [ Html.text mouse.name ] else []
        ]
```

### 2. `wrapToSingleNode`: Working with lists of nodes

Sometimes you have a function that returns a list of HTML elements, but you need to return a single node. The common pattern is to wrap them in a `div`, but that adds an extra DOM element that might affect your styling.

`wrapToSingleNode` uses the following logic:

- If the list is empty, return `nothing`
- If the list contains only one element, simply return that element
- If the list contains multiple elements, wrap them with a plain div with `display: contents`

Using `display: contents` means the wrapper div doesn't create a new box in the layout - its children are treated as if they were direct children of the wrapper's parent.

```elm
view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "My App" ]
        , -- This function returns a list of nodes
          viewItems model.items
            |> wrapToSingleNode
        , footer [] [ text "Footer" ]
        ]

viewItems : List Item -> List (Html Msg)
viewItems items =
    List.map viewItem items
```

### 3. `nothing`: A clearer way to express emptiness

This is just a convenience function that replaces the common pattern of `text ""` with a more semantically clear name:

```elm
viewMaybe : Maybe String -> Html msg
viewMaybe maybeStr =
    case maybeStr of
        Just str ->
            p [] [ text str ]

        Nothing ->
            nothing -- Clearer than text ""
```

## How to Use the Package

Install the package using elm's package manager:

```
elm install cekrem/html-helpers
```

Then import the functions you need:

```elm
import HtmlHelpers exposing (contentList, wrapToSingleNode, nothing)
```

## The Road to 1.0

This is a small package focused on solving specific pain points. I'd like to gather feedback from the community before potentially adding a few more helper functions. If you find these helpers useful, or if you have ideas for other HTML helpers that would be valuable, please let me know!

## Why Create a Package?

You might wonder why these simple functions warrant publication as a package. There are a few reasons:

1. **Reusability**: I found myself copying these functions between projects
2. **Documentation**: Publishing forces me to properly document the code
3. **Community**: Other Elm developers might find them useful too
4. **Learning**: The process of creating and publishing a package was a learning experience

The Elm ecosystem values small, focused packages that do one thing well. Even with just three functions, this package can make your Elm code a little cleaner and more expressive.

## Final Thoughts

I hope you find these helpers useful in your Elm projects. The package is open source under the BSD-3-Clause license, and contributions are welcome. Check it out at [package.elm-lang.org/packages/cekrem/html-helpers/latest/](https://package.elm-lang.org/packages/cekrem/html-helpers/latest/).

For those interested in the implementation details, the source is available on [GitHub](https://github.com/cekrem/html-helpers).
