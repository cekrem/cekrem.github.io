+++
title = "An Elm Primer: The missing chapter on JavaScript interop"
description = "Let's treat JavaScript and browsers as flaky infrastructure, and act accordingly"
date = "2025-11-18"
tags = ["elm", "react", "functional programming", "book", "typescript", "architecture", "ports and adapters"]
draft = false
+++

I've been having a week off from working with my book, mainly to celebrate the initial completion of parts I and II (out of IV). But it turns out I had a slight `git push` connection error on my private Macbook after adding the last chapter so what I actually published was less than all of part II: chapter 8 on ports and javascript interop was missing.

This serves as a reminder that the outside world is not to be trusted, and that any interaction and side-effect can (and will, from time to time) fail – even something as ordinary as a `git push`. Which happens to be a major theme in the missing chapter, humbly presented to you below.

As usual, [the book can be found and bought @ leanpub](https://leanpub.com/elm-for-react-devs).

(And as usual, the formatting is slightly more adequate in the actual book than on this Hugo blog, but we'll make do.)

---

# Chapter 8: JavaScript Interop: Ports and Flags

<!-- Status: draft complete -->

> > **Elm Hook**
> >
> > Elm treats JavaScript like infrastructure: useful but untrusted. Ports and flags let you tap into the JavaScript ecosystem while keeping Elm's guarantees intact. Your core logic stays pure and safe.

## JavaScript as Infrastructure

Here's something that might surprise you: Elm treats JavaScript—and even the browser itself—as infrastructure. Not as a trusted part of your application, but as an external dependency that needs careful handling.

In React, you freely call browser APIs, import npm packages, and mix third-party code directly into your components. It's all JavaScript, so it all gets the same level of trust. But Elm takes a different view: anything outside the Elm runtime is potentially unreliable. It might throw exceptions. It might return unexpected types. It might fail in ways you can't predict at compile time.

So Elm keeps that world at arm's length. More ceremony and verbosity? Sure. But your app stays clean and pure.

This chapter represents the last foundational piece you need before taking Elm to the next level. You've learned the architecture, built apps with HTTP and JSON, and now you'll see how to bridge the gap between Elm and the wider JavaScript ecosystem. After this, you'll have everything you need to start building real applications and learning by doing. The rest is about scale, patterns, and experience—not new concepts.

## Upgrading Our Build for Manual Bootstrapping

So far, we've been compiling our Elm apps directly to HTML without supplying an input, which by default means that it will be compiled into a self contained `index.html`. This works great for simple apps, but it doesn't give us control over how the app initializes. We can't pass in flags, and we can't set up ports.

For this chapter, we'll compile to JavaScript instead, and create our own `index.html`:

```bash
[npx ]elm make src/Main.elm --output=main.js
```

This gives us a JavaScript module we can bootstrap manually in our HTML. We'll create an `index.html` file that loads `main.js` and initializes our Elm app with whatever setup we need—flags, ports, or both.

Here's the basic pattern:

```html
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Elm App</title>
  </head>
  <body>
    <div id="app"></div>
    <script src="main.js"></script>
    <script>
      const app = Elm.Main.init({
        node: document.getElementById("app"),
        flags: null, // this is where flags go!
      });
    </script>
  </body>
</html>
```

That `Elm.Main.init()` call is where the magic happens. It's our gateway to flags and ports.

## Flags as Program Input

Think of flags like command-line arguments for your Elm app. When you run a CLI program, some can work with or without arguments:

```bash
ls          # works fine
ls -la      # works with flags
```

Others require arguments to function:

```bash
curl        # error: needs a URL
curl https://api.example.com  # works
```

Elm flags work the same way. Your app can accept optional configuration, or it can require certain data to even start.

### A Simple Flag Example

Let's build a greeting app that accepts a username flag. Create a new Elm file:

```elm
module Main exposing (main)

import Browser
import Html exposing (Html, div, h1, text)

type alias Flags =
    { username : String
    }

type alias Model =
    { username : String
    }

init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { username = flags.username }
    , Cmd.none
    )

view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text ("Hello, " ++ model.username ++ "!") ]
        ]

update : msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )

main : Program Flags Model msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
```

Notice three key changes from our previous apps:

1. **`type alias Flags`** defines what data we expect from JavaScript
2. **`init : Flags -> ( Model, Cmd Msg )`** receives flags as its first argument
3. **`main : Program Flags Model Msg`** declares that this program requires flags

Now compile it:

```bash
elm make src/Main.elm --output=main.js
```

And bootstrap it in `index.html`:

```html
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Greeting App</title>
  </head>
  <body>
    <div id="app"></div>
    <script src="main.js"></script>
    <script>
      const app = Elm.Main.init({
        node: document.getElementById("app"),
        flags: {
          username: "Christian",
        },
      });
    </script>
  </body>
</html>
```

If you open `index.html` in your browser, you'll see "Hello, Christian!"

The `flags` object we pass to `Elm.Main.init()` gets validated against our `Flags` type alias. If JavaScript passes the wrong shape—say, `{ name: "Christian" }` instead of `{ username: "Christian" }`—Elm will catch it at runtime and refuse to start the app. You'll see an error in the console explaining exactly what went wrong.

This is Elm's boundary protection in action. JavaScript is untrusted infrastructure, so Elm validates everything that crosses the border.

### Optional Flags

What if you want flags to be optional? Use `Maybe`:

```elm
type alias Flags =
    { username : Maybe String
    }

init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { username = Maybe.withDefault "Guest" flags.username }
    , Cmd.none
    )
```

Now your app works with or without a username:

```javascript
// With username
Elm.Main.init({
  node: document.getElementById("app"),
  flags: { username: "Christian" },
});

// Without username (shows "Guest")
Elm.Main.init({
  node: document.getElementById("app"),
  flags: { username: null },
});
```

These examples use plain data primitives, but flags can also contain complex JSON data (and we learned in the previous chapter how to decode that). In fact, most times for a production app, JSON is what you want.

### Common Flag Patterns

In real applications, flags typically carry:

- **Authentication data**: tokens, user IDs, session info
- **Environment config**: API URLs, feature flags, debug modes
- **Initialization state**: data from localStorage, server-rendered content
- **Browser capabilities**: screen size, timezone, locale

Here's a more realistic flags structure:

```elm
type alias Flags =
    { apiUrl : String
    , userToken : Maybe String
    , features : List String
    , timestamp : Int
    }
```

The key insight: flags are for data that exists _before_ your Elm app starts. Once your app is running, you'll use ports for ongoing communication with JavaScript.

We'll leave flags be for the present, and spend the rest of our chapter on ports.

## Ports for Communicating with JavaScript

If you've ever been exposed to SOLID design principles, Clean Architecture or any form of large scale systems engineering, chances are you've heard of [Ports and Adapters](<https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)>). Whether that's what Evan had in mind when choosing the "port" term is not certain[^portTermOrigin], but there's a lot of overlap in the mental model in any case. A port in both regards supplies _a means for "external devices" to connect to our app in a controlled manner_. Note that even with the immense care Elm takes in approaching communication with JavaScript in a safe way, you're still required to mark modules containing ports with the `port` prefix to signal clearly that they are doing so.

Just as in the Ports and Adapters (or _Hexagonal_ Architecture), ports can be either _inbound_ or _outbound_:

```elm
port module Main exposing (..)

-- Elm → JavaScript: Elm sends a `String`
-- through the JavaScript port
port copyToClipboard : String -> Cmd Msg

-- JavaScript → Elm: JavaScript sends a `Bool` back
-- to indicate whether the operation was successful
port clipboardResult : (Bool -> msg) -> Sub Msg
```

You've probably figured by now that we'll dive into how to send and receive via ports by implementing the last feature to our LGTM Generator: copy quote to clipboard!

## Adding Clipboard Support to the LGTM Generator

Let's complete the LGTM generator by adding real clipboard support using ports. You can find the complete source code for this chapter in the accompanying repo: [github.com/cekrem/elm-primer-code-examples](https://github.com/cekrem/elm-primer-code-examples), but try not to look at it if you're not _completely_ stuck. We'll proceed at a moderate tempo, and introduce new concepts one at a time.

Start by adding this basic `index.html` to your project root:

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>LGTM Generator with ports!</title>
  </head>
  <body>
    <div id="app"></div>
    <script src="main.js"></script>
    <script>
      const app = Elm.Main.init({
        node: document.getElementById("app"),
      });
    </script>
  </body>
</html>
```

Then, as usual, let's get our compiler going: `[npx ]elm-live src/Main.elm -- --debug --output=main.js`. That extra `--` is not a typo, it signals that what follows after it is an argument sent to the underlying `elm make` command and not to `elm-live`. And, as we covered briefly: We need to specify the output to allow bringing our own index file, which in turn is needed for ports (and flags). If your `index.html` is correct, and your Elm source code is unchanged, everything should behave like the previous iteration (with the notable exception of a cool title). We also turned on the time-traveling debugger with `--debug`, so you can easily inspect all messages and model updates.

(Remember to also fire up the backend with `node server.js`, that one hasn't changed and won't change in this chapter.)

### Step one: adding an outbound port (Elm -> JS) carrying a String

The syntax for adding an _outbound_ port is quite straight forward. Let's start by adding the following section below our `-- CMD` one:

```elm
-- PORTS


{-| Outbound port, Elm -> JS
-}
port copyToClipboard : String -> Cmd Msg
```

This does exactly what the box says: it takes a single `String` parameter, and returns a `Cmd Msg`. When we use the special `port` prefix, it tells the compiler that the Elm runtime should set up this port for us (the actual implementation is abstracted).

Our compiler has some concerns, though:

```text
-- UNEXPECTED PORTS --------------- /path-to-your/src/Main.elm

You are declaring ports in a normal module.

1| module Main exposing (main)
   ^^^^^^
Switch this to say port module instead, marking that this module contains port
declarations.

Note: Ports are not a traditional FFI for calling JS functions directly. They
need a different mindset! Read <https://elm-lang.org/0.19.1/ports> to learn the
syntax and how to use it effectively.
```

Elm requires us to mark all modules using ports as such, so go ahead and do that. Your compiler should be satisfied, and we can move on to actually sending data through this port.

### Step two: mapping the `CopyToClipboard` `Msg` to our outbound port

A tiny adjustment in our update function is all we need to hook up to our port:

```elm
        {- ...rest of update -}
        CopyToClipboard ->
            ( model
            , case model.phrase of
                Success { phrase } ->
                    copyToClipboard phrase

                -- `_` is a wildcard meaning
                -- "every other case:
                _ ->
                    Cmd.none
            )
```

Before, we simply ignored the `CopyToClipboard` `Msg`, but now we send the phrase (if we have one; `Loading` and `Error` states won't trigger this!) through our port. You could explicitly handle the `Loading` and `Error` cases of the phrase model, but the point remains the same: we only copy phrases to clipboard, not loaders or error messages.

Our phrases are already clickable, so this should work already:

```elm
view : Model -> Html Msg
view model =
    Html.div []
        [ Html.span
            -- this was already in place:
            [ Events.onClick CopyToClipboard
            ]
            [ viewPhrase model.phrase ]
        {- rest of view -}
```

Feel free to add some extra styling (cursor: pointer?) and the works according to your liking, but our phrases should now 1) Trigger `CopyToClipboard` that will 2) be handled in `update` and mapped to the outbound `copyToClipboard` port that is 3) transformed into an Elm runtime command that sends the accompanying `String` to the outside JavaScript world. That's all there is to sending a message. Now let's try to receive it!

### Step three: receiving messages in JavaScript land

This is when we get to the part where a custom `index.html` is necessary. Let's cut to the chase and see how to subscribe to Elm messages in JavaScript:

```JavaScript
// inside <script /> in index.html

const app = Elm.Main.init({
  node: document.getElementById("app"),
});


// Every `port {name} {Type} Cmd Msg` in Elm gets a
// matching `app.ports[{name}]` with a `subscribe` method:
app.ports.copyToClipboard.subscribe((text) =>
  console.log(`Text to copy: ${text}`),
  /* TODO: Implement clipboard copy */
);
```

If you refresh your browser (`elm-live` doesn't detect `index.html` changes), you should get a console log whenever you click on a phrase (and not if you click while it's loading or when there's an error).

Great success!

As for the actual implementation: Depending on which day of the week you read this, a simple `navigator.clipboard.writeText()` may or may not suffice on modern browsers. Since we're on the wild side of the Elm / JavaScript boundary by now, there are probably 10 different npm packages providing that functionality, with more than half of them containing major security holes that might make your computer explode.

![clipboard npm packages](/images/clipboard_npm.png)

For a "good enough for this app"-solution without any npm dependencies, check out [`index.html` from the example repository](https://github.com/cekrem/elm-primer-code-examples/blob/main/08_lgtm-generator_05-ports/index.html).

### Step four: sending messages from JavaScript to Elm

Though not strictly needed, we could send a message back to our app to signal that the copy to clipboard action succeeded or failed. If nothing else, it's a simple way to show how things work when messages go the other direction.

First, let's add an _inbound_ port to our Elm code. The syntax is different from outbound ports—instead of returning a `Cmd`, inbound ports return a `Sub` (subscription):

```elm
-- PORTS

{-| Outbound port, Elm -> JS -}
port copyToClipboard : String -> Cmd Msg

{-| Inbound port, JS -> Elm -}
port clipboardResult : (Bool -> Msg) -> Sub Msg
```

The type signature `(Bool -> Msg) -> Sub Msg` looks a bit strange at first. What it means is: "JavaScript will send us a `Bool`, and we'll need to turn that into a message." The Elm runtime handles the plumbing, by turning it into a `Sub` (subscription).

Now we need to subscribe to this port. Remember subscriptions? We've been ignoring them with `subscriptions = \_ -> Sub.none`, but now we have a reason to use them:

```elm
subscriptions : Model -> Sub Msg
subscriptions _ =
    clipboardResult ClipboardCopied
```

This tells Elm: "When JavaScript sends a `Bool` through `clipboardResult`, wrap it in a `ClipboardCopied` message and send it through our update function."

Let's add that message to our `Msg` type:

```elm
type Msg
    = GenerateClicked
    | PhraseReceived (Result Http.Error String)
    | CopyToClipboard
    | ClipboardCopied Bool  -- new!
```

And handle it in our update function:

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        {- ...existing cases... -}

        ClipboardCopied success ->
            if success then
                ( { model | clipboardStatus = Just "Copied!" }
                , Cmd.none
                )

            else
                ( { model | clipboardStatus = Just "Copy failed" }
                , Cmd.none
                )
```

Wait—we need a place to store this status. Let's add it to our model:

```elm
type alias Model =
    { phrase : RemoteData Http.Error Phrase
    , clipboardStatus : Maybe String
    }

init : () -> ( Model, Cmd Msg )
init _ =
    ( { phrase = NotAsked
      , clipboardStatus = Nothing
      }
    , Cmd.none
    )
```

And display it in our view (add this somewhere sensible, maybe below the phrase):

```elm
view : Model -> Html Msg
view model =
    Html.div []
        [ Html.span
            [ Events.onClick CopyToClipboard ]
            [ viewPhrase model.phrase ]
        , Html.button
            [ Events.onClick GenerateClicked ]
            [ Html.text "Generate" ]
        , case model.clipboardStatus of
            Just status ->
                Html.div [] [ Html.text status ]

            Nothing ->
                Html.text ""
        ]
```

Now for the JavaScript side. We need to send messages _to_ Elm. Instead of subscribing to a port, we use `send`:

```javascript
const app = Elm.Main.init({
  node: document.getElementById("app"),
});

app.ports.copyToClipboard.subscribe((text) => {
  try {
    /* Insert copy-to-clipboard implementation */
    // Send success back to Elm
    app.ports.clipboardResult.send(true);
  } catch (error) {
    console.error("Failed to copy:", error);
    // Send failure back to Elm
    app.ports.clipboardResult.send(false);
  }
});
```

That's it. Click a phrase, and you should see "Copied!" appear. The flow is:

1. User clicks phrase → `CopyToClipboard` message
2. Elm sends phrase through `copyToClipboard` port
3. JavaScript receives it, copies to clipboard
4. JavaScript sends result through `clipboardResult.send(true)`
5. Elm receives it as `ClipboardCopied True`
6. Update function stores "Copied!" in model
7. View displays the status

One thing you might notice: the "Copied!" message stays there forever. In a real app, you'd probably want to clear it after a few seconds. You could do this with a `Cmd` that sends a `ClearClipboardStatus` message after a delay, but that requires understanding `Process.sleep` and `Task.perform`, which we haven't covered yet. For now, let's keep it simple and just clear the status when the user generates a new phrase:

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GenerateClicked ->
            ( { model
                | phrase = Loading
                , clipboardStatus = Nothing  -- clear status
              }
            , generatePhrase
            )

        {- ...rest of update... -}
```

There you have it: two-way communication between Elm and JavaScript. Elm stays in control of its data flow, JavaScript handles the messy browser API, and the boundary between them is explicit and type-safe.

## What You Just Learned

This chapter covered Elm's approach to JavaScript interop—treating it as useful but untrusted infrastructure. Here's what you now know:

**Flags** are your program's initialization data:

- Pass configuration, tokens, or feature flags at startup
- Validated against your `Flags` type alias—wrong shape means app won't start
- Use `Maybe` for optional flags with sensible defaults
- Think of them like command-line arguments: some apps need them, others work fine without

**Ports** enable two-way communication with JavaScript:

- **Outbound** (`String -> Cmd Msg`): Elm sends data out to JavaScript
- **Inbound** (`(Bool -> msg) -> Sub Msg`): JavaScript sends data back to Elm
- Mark any module using ports with `port module` to make boundaries explicit
- Subscribe to ports in JavaScript using `app.ports.portName.subscribe()`

**Manual bootstrapping** gives you control:

- Compile to JavaScript with `elm make src/Main.elm --output=main.js`
- Create your own `index.html` and initialize with `Elm.Main.init()`
- Pass flags during initialization, set up port subscriptions afterward

The key insight: Elm treats JavaScript like any external system in Clean Architecture—useful for infrastructure concerns (clipboard, localStorage, analytics), but kept at arm's length from your core logic. Your Elm code stays pure, predictable, and safe. The JavaScript world can throw exceptions and misbehave all it wants; your ports are the controlled boundary.

For React developers, this might feel like extra ceremony compared to just importing an npm package. But that ceremony is precisely what keeps your app reliable. You're not avoiding JavaScript—you're just being intentional about where the boundaries are.

With flags and ports in your toolkit, you have everything you need to build real applications. The remaining chapters focus on patterns, scale, and experience—not new fundamental concepts.

[^portTermOrigin]: In [Elm Town 13: History of Ports](https://elm.town/episodes/b06499a6) Evan Czaplicki addresses this, and he says the following: "It's rooted in ideas of concurrency and client/server relationships. If you want to isolate code a way to do it is to create a communication channel so that you can run code that has certain rules and regulations and if all I send is data then I could send it to anyone who can do anything they want with different rules and they can send it back."
