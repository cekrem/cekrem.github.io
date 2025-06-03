+++
title = "Starting Small with Elm: A Widget Approach"
description = "How to introduce Elm incrementally into your existing web applications with a real-world example"
tags = ["elm", "frontend", "functional programming", "architecture", "hugo", "incremental adoption"]
date = "2025-06-03"
draft = false
+++

It's awesome to learn Elm by building a side project, you absolutely should. And maybe you have – perhaps you've built a todo app, explored The Elm Architecture, and fallen in love with the reliability and maintainability that comes with functional programming and strong types.

But come Monday morning, you're back to wrestling with JavaScript bugs, runtime errors, and the nagging feeling that there has to be a better way. The problem isn't that Elm isn't ready for production work – it absolutely is. The problem is convincing your team, your boss, or your organization to take the leap. And when you're thinking about wholesale replacement, your boss's skepticism might be quite healthy. But here's the thing: if you reduce the scope, you can also reduce the risk and buy-in required. Instead of "let's rebuild our entire app in Elm," what if the conversation was "let's try Elm for this one small widget"? Suddenly, the stakes drop dramatically.

> Companies that use Elm in production usually start with a single component. So if you want to use Elm at work, start with a small experiment. Do people think it is nice? Do more! Do people think it sucks? Do less!
>
> – Jason O'Neil, author of [react-elm-components](https://github.com/cultureamp/react-elm-components)

This is exactly what I did on this very blog, as a proof of concept. While my site is built with Hugo (a Go-based static site generator), I've successfully integrated an Elm-powered testimonials carousel that fetches data, manages state, and provides smooth interactions. Let me show you how starting small can turn employer skepticism into genuine enthusiasm.

## The Case for Incremental Adoption

The [official Elm guide on using Elm at work](https://elm-lang.org/news/how-to-use-elm-at-work) makes a compelling case for incremental adoption, but let's be honest – it can be hard to visualize what this looks like in practice. Most examples are either too simple (a counter) or too abstract (theoretical architecture diagrams).

What you need is a real example that shows:

1. **Minimal integration** – How to embed Elm without disrupting your existing setup
2. **Practical scope** – A widget complex enough to be useful but small enough to be manageable
3. **Clear boundaries** – How to handle data flow between Elm and your host application
4. **Gradual migration** – How this approach sets you up for future expansion

## Meet My Testimonials Widget

Before diving into the implementation, let me show you what we're building. On the home page of this blog (if you're on a wide screen), you'll see a testimonials carousel powered entirely by Elm. I also added it to this very page, so you won't have to stop your reading to check it out. This small widget

- Fetches testimonial data from a JSON endpoint
- Displays testimonials in a responsive carousel format
- Handles navigation with smooth transitions
- Only renders on specific pages and screen sizes
- Integrates seamlessly with the existing Hugo-generated markup

The widget replaces what used to be an embedded iframe – a perfect example of incremental improvement rather than a full rewrite.

## The Widget-First Architecture

Here's how the integration works at a high level:

```html
<!-- In your Hugo template (layouts/partials/footer.html) -->
<div id="elm-widget"></div>
<script src="/widget.js"></script>
<script>
  Elm.Main.init({
    node: document.getElementById("elm-widget"),
    flags: window.location.pathname, // passing in pathname to allow routing
  });
</script>
```

The beauty of this approach is its simplicity. Your host application (Hugo, in my case) just needs to:

1. Provide a DOM element for Elm to mount to
2. Compile and include the Elm JavaScript output
3. Initialize the Elm application with any required data (the pathname in this example, because I only show the carousel on certain paths)

That's it. No complex build system integration, no framework-specific adapters, no architectural rewrites.

## The Elm Implementation

Let's examine the actual Elm code that powers this widget. The main application is surprisingly simple:

```elm
module Main exposing (..)

import Browser
import Html exposing (..)
import Testemonials

main : Program String Model Msg
main =
    {-| I'm using Browser.element instead of Browser.application to control
        only _part_ of the DOM with Elm. Browser.sandbox would also often suffice, but
        it doesn't support HTTP requests. -}
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }

{-| For now I either render Testemonials (the carousel) or nothing,
but this could easily grow to view other things on other routes.

Perhaps the "Subscribe" input/form could be Elm?

-}
type Model
    = Testemonials Testemonials.Model
    | None

init : String -> ( Model, Cmd Msg )
init path =
    -- in effect: show testemonials for "/" and "/hire" routes, and for this very post
    if Testemonials.showForPath path then
        Testemonials.init ()
            -- Map the Testemonials specific model and commands to match the Main ones
            |> Tuple.mapBoth Testemonials (Cmd.map TestemonialsMsg)
    else
        ( None, Cmd.none )
```

The key insight here is that our main module acts as a super-simple **router** that decides whether to show the testimonials widget based on the current path. This pattern scales beautifully – as you add more Elm widgets, you can expand this router to handle multiple components.

## The Testimonials Module

The actual testimonials functionality lives in a separate module:

```elm
module Testemonials exposing (Model, Msg, init, showForPath, update, view)

type Model
    = Failure
    | Loading
    | Success (List Testemonial) Int

init : () -> ( Model, Cmd Msg )
init () =
    ( Loading, getTestemonials )

activePaths : Set.Set String
activePaths =
    Set.fromList [ "", "/", "/hire", "/posts/starting-small-with-elm-a-widget-approach" ]

showForPath : String -> Bool
showForPath path =
    activePaths |> Set.member path
```

This demonstrates several important patterns:

1. **Clear state modeling** – The `Model` type explicitly represents the three possible states: loading, error, or success with data
2. **Configuration-driven behavior** – Which pages show testimonials is controlled by data (path in this instance), not scattered conditionals
3. **Pure functions** – The `showForPath` function is completely predictable and testable
4. **Separated concerns** – Data fetching, state management, and rendering are cleanly separated

## Migrating testemonials data?

Like I said, I used to have that iframe (from [(https://testemonials.to)]), and while I'm definitely ditching that I'd like to keep the data I've collected. This is literally how I migrated: I `document.querySelector`ed the element containing all existing testemonials the and sent the `innerHTML` to GPT-4o with instructions to make pretty JSON matching my Elm model. Simple as that. See, I'm not against Automating The Boring Stuff (the actual name of my last AI-related talk @ Ensō), I just [hate letting LLMs have all the fun of the actual coding](https://cekrem.github.io/posts/coding-as-craft-going-back-to-the-old-gym/).

## Handling Data and HTTP

One of Elm's many strengths is how it handles side effects like HTTP requests (`ports` in another way Elm deals with the outside world, read more about that [here](https://cekrem.github.io/posts/a-case-for-port-boundaries-in-frontend/)). Anyway, here's how the testimonials widget fetches data:

```elm
getTestemonials : Cmd Msg
getTestemonials =
    Http.get
        { url = "/testemonials.json"
        , expect = Http.expectJson GotTestemonials testemonialsDecoder
        }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model, msg ) of
        ( _, GotTestemonials (Ok testemonials) ) ->
            ( Success testemonials 0, Cmnd.none)

        ( _, GotTestemonials (Err _) ) ->
            ( Failure, Cmd.none )
```

Compare this to typical JavaScript approaches:

- **No promise chains or async/await complexity** – Commands are values that describe what you want to do
- **Explicit error handling** – The `Result` type forces you to handle both success and failure cases
- **No runtime errors** – If it compiles, the HTTP handling will work as expected
- **Testable** – You can test your update function by passing it messages directly

## Styling Without Conflicts

One challenge with widget-based approaches is styling conflicts. Since this Elm widget lives inside a Hugo site with its own CSS, I needed to avoid dependencies on external stylesheets. The solution? Inline styles with careful encapsulation. Granted, I _have_ started down the rabbit hole of changing the overall styling of this blog, as you may have noticed, but to keep this example clear I gave myself the restraint of not depending on any (subject-to-change!) existing classes:

```elm
testemonialEntry : Bool -> Testemonial -> Html Msg
testemonialEntry visible testemonial =
    let
        conditionalStyles = {- implementation details -}
    in
    Html.div
        ([ Attributes.style "transition-property" "all"
         , Attributes.style "transition-timing-function" "ease-out"
         , Attributes.style "transition-duration" "0.4s"
         , Attributes.style "border-radius" "2rem"
         , Attributes.style "background" "rgba(127,127,127,0.1)"
         -- ... more styles
         ]
            ++ conditionalStyles
        )
        [ -- content ]
```

While not as clean as using a CSS framework, this approach guarantees that the widget won't break the host application's styles (or vice versa). As you grow your Elm usage, you can migrate to more sophisticated styling solutions. If my blog theme were built on Tailwind, this would all be a pretty one-liner, though... 🤤

Doh...

## Responsive Behavior

A fun challenge when commiting to _not_ relying on external CSS is hiding/showing based on screen size. Rather than relying on CSS media queries, my beloved widget uses a CSS `clamp()` function to hide the entire widget on smaller screens.

I bet you haven't seen one of these in the wild, and I don't really think you should try the following at home either:

```elm
hideOnBreakpoint : String -> Html msg -> Html msg
hideOnBreakpoint breakpoint content =
    let
        clampStyle =
            "clamp(10px, calc((100vw - " ++ breakpoint ++ ") * 1000), 10000px)"
    in
    Html.div
        [ Attributes.style "max-width" clampStyle
        , Attributes.style "max-height" clampStyle
        , Attributes.style "overflow" "hidden"
        ]
        [ content ]
    -- And then you simply pipe your content like this `|> hideOnBreakpoint 600px`
```

This might look hacky, ~~but it's actually quite elegant – the widget completely disappears below 600px width, which is exactly what I wanted for this use case~~ and it really is. ¯\\_(ツ)_/¯

## The Build Pipeline

Getting Elm integrated into an existing build pipeline is surprisingly straightforward. In my case, I added these simple npm scripts:

```json
{
  "scripts": {
    "build": "elm make src/Main.elm  --output=static/widget.js --optimize",
    "start": "hugo build -D && concurrently \"http-server ./public\" \"elm-watch hot\""
  }
}
```

For development, `elm-watch` provides hot reloading. For production, the standard `elm make` command outputs a single JavaScript file that Hugo copies to the final site. No complex webpack configurations or framework-specific build tools required.

If you're already using React, you can even use [react-elm-components](https://github.com/cultureamp/react-elm-components) to get a head start!

## Why This Approach Works

Starting with a small widget like this testimonials carousel provides several advantages:

### 1. **Low Risk**

If the Elm widget breaks, it doesn't take down your entire application. The worst-case scenario is a missing testimonials section – hardly catastrophic.

### 2. **Learning by Doing**

You get hands-on experience with Elm's core concepts (Model-View-Update, commands, subscriptions) in a real-world context without the pressure of migrating critical functionality.

### 3. **Clear Success Metrics**

You can easily measure the benefits: Does the widget perform better? Is it more reliable? Is the code easier to understand and modify? The answers become obvious quickly.

### 4. **Foundation for Growth**

Once you have the basic integration working, adding more Elm widgets becomes progressively easier. The build pipeline is established, the team understands the patterns, and the confidence is built.

## What's Next?

Having successfully integrated one Elm widget, I'm already thinking about what could be next. I've done Markdown rendering in Elm before, perhaps I could use Elm for rendering posts and pages as well? Or perhaps I'll replace the share buttons with something homecooked? Whatever small problem you decide to solve with Elm, I'm sure there are other problems equally suited. Speaking of which, [Elm Programming: Solving Complex Problems with Simple Functions](https://elmprogramming.com/function-composition.html) is a _great_ read on that more general topic.

The beauty of this approach is that each step is optional and reversible. You're not making a bet-the-company decision – you're making small, measured investments that compound over time. And you're learning!

## Getting Started Today

If you want to try this approach in your own application, here's a roadmap:

1. **Identify a small widget** in your current application that has interesting state management
2. **Set up a minimal Elm build** that outputs to a single JavaScript file
3. **Create a simple Elm application** that mounts to a DOM element and accepts flags
4. **Implement your widget** using The Elm Architecture
5. **Integrate it** by replacing the existing widget (or even static html or whatever) with your Elm version

Start small, prove the value, and expand from there.

## Conclusion

Elm doesn't have to be an all-or-nothing decision. By starting with small, isolated widgets, you can:

- Gain practical experience with functional programming concepts
- Improve specific parts of your application with better reliability and maintainability
- Build team confidence and expertise gradually
- Create a foundation for larger migrations if and when they make sense

The testimonials widget on this blog is proof that this approach works in practice.

In the case of Elm, the first small step might just be a single widget.

---

_If you're interested in exploring this approach further, check out the [complete source code](https://github.com/cekrem/cekrem.github.io/tree/main/src) for this blog's Elm widgets. The simplicity might surprise you._
