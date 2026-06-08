+++
title = "Native Elm (the real kind this time)"
description = "elm-run compiles Elm to actual native binaries. And The Elm Architecture shines bright as ever! I built a simple `fetch` to try it out."
tags = ["elm", "native", "cli", "functional programming", "elm-run", "experiment"]
date = "2026-06-08"
draft = false
+++

Back in December I [hacked Elm onto a Node.js backend](/posts/elm-on-the-backend-with-nodejs/) and got a little carried away calling it "Elm on the backend." It wasn't, really. Node did all the actual work -- opened the socket, parsed the HTTP, wrote the response -- and Elm sat in the middle shuffling opaque values between ports. A fun trick, and I still think the passport-through-Elm bit is neat. But the whole time, there was a JavaScript runtime underneath holding the thing up.

So when I saw [elm-run](https://elm-run.dev) on the Elm Discourse -- "run native Elm on your server and your terminal, yes native" -- that was a different beast entirely!

`elm-run` takes the _unmodified_ Elm compiler, runs it down through its own optimizer, and produces actual bytecode that a native runtime executes (or, if you ask it nicely, a true ELF/Mach-O/PE binary, the way a C compiler would). There is neither Node nor JavaScript runtime hiding in its basement. Just Elm.

I had to try it on something, and for no reason in particular I ended up with a native Elm app that fetches a URL and print the body. Super simple, but (and this is an important point) still async! Here's `Fetch.elm`, the first thing I wrote, with a few comments added so you can follow along.

## It's just TEA

```elm
module Fetch exposing (main)

import Capabilities exposing (Console)
import Cli exposing (Env)
import Http


-- init/update/subscriptions, just like we're used to
-- The only new thing is the type: Cli.Program, not Browser.element.
-- And no `view` -- this command-line tool doesn't render anything.
main : Cli.Program Model Msg
main =
    Cli.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        }
```

It's The Elm Architecture! For real! The exact loop 🤤

I've heard people call TEA "a frontend pattern" for years but ie TEA is actually a contract that says _your code never performs effects, it describes them, and the runtime performs them for you_. In the browser, that runtime happens to talk to the DOM and `XMLHttpRequest` (and possibly ports). Swap out what the runtime talks to -- point it at the OS kernel and libcurl (or whatever) instead -- and your program really doesn't change at all. The browser was in fact an implementation detail the whole time. (Though, to be fair: the main thing your average Elm apps does is render DOM stuff, so... But _in principle_!)

## The Model of a CLI app

```elm
-- The whole lifecycle of the program, as a type.
-- We're either still Running (and we're holding the environment
-- the OS gave us, including stdout/stderr); or we're Done
-- (and `Done` carries an exit code).
type Model
    = Done Int
    | Running { env : Env }


type Msg
    = GotResponse (Result Http.Error String)
```

(And just to clarify, `Env` here is not your environment _variables_, but rather the entire context your program runs in, including its `stdout`/`stdin` etc.)

A CLI program _has_ a lifecycle -- it runs, then it finishes with a result -- and most languages leave that implicit, scattered across `return` statements and a `sys.exit()` buried somewhere mid-function. Here it's two states and a number. `Done 0` is success, `Done 1` is failure. The exit code is just data. And notice the `env` only lives in the `Running` arm: once you're `Done`, you've structurally handed back your capabilities. You _can't_ fire one more HTTP request from a finished program, because the finished state carries nothing to do it with. I didn't write a single guard for that, it's a product of its shape.

Damir, who's building elm-run, put a name on this: pre-phase, working phase, post-phase. There's a point at the very start where the model doesn't exist yet, because you haven't met the requirements to build it (you literally can't construct it without them). Then there's the working model, the part that does the job. And then there's the point where the model stops mattering because you're on your way out the door. `Running` is the working phase. `Done` is the post-phase -- nothing left to compute, just a number to hand back to the shell.

## Our old friend `Http.get`

```elm
-- No Flags to see here. We get an Env instead: argv, env vars, and whatever
-- capabilities the runtime decided to hand us (stdout, stderr...).
-- At the OS boundary it's strings all the way down, so the URL
-- shows up as a plain String in env.args.
init : Env -> ( Model, Cmd Msg )
init env =
    case env.args of
        [ url ] ->
            ( Running { env = env }
            , Http.get { url = url, expect = Http.expectString GotResponse }
            )

        _ ->
            fail env "invalid number of arguments (needs exactly one)"
```

That `Http.get` is the same one you write in every Elm web app, character for character. Same `expectString`, same `GotResponse` wrapping a `Result`. Only now there's no `fetch` and no browser anywhere near it -- the `Cmd` bottoms out in libcurl (I guess?), natively. If you've written a single Elm app you already know how to do native HTTP, which is sort of the whole point. It's boring, and boring is exactly what I was hoping for.

The one genuinely new bit is small: no `Flags`. A browser will happily hand you a structured JSON blob to decode into a custom type. The operating system won't. A process gets argv, environment variables, and some file descriptors -- strings and handles, that's the whole menu. So elm-run swaps `Flags` for `Env`, and I read the URL straight out of `env.args` by pattern-matching `[ url ]`. It feels less magical than browser flags, and it should.

In the browser, `init` is usually a formality. You decode a tiny Flags object (or you don't), and the interesting stuff happens later, when someone clicks something. Native Elm front-loads all of it. What arguments did I get? Which capabilities did the runtime actually hand me? Can I even build a working model, or do I have to give up before I start? Damir put it well when we were chatting: **the browser is a super-cozy environment**. It really is. You get a small, safe room and someone else worries about the weather. Out here in Native land you're outside.

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Running { env } ->
            case msg of
                GotResponse (Ok body) ->
                    success env body

                GotResponse (Err err) ->
                    fail env (httpErrorToString err)

        Done exitCode ->
            ( model
            , Cli.exit exitCode
            )
```

I actually went back and forth on that `Done` branch, the one that does nothing but call `Cli.exit`. Exiting, as I see it, is an effect (a side effect, if you want to be old-fashioned about it), and some functional-purist corner of my brain really wants `Cli.exit` to live in exactly _one place_. So that's how I left it. `success` and `fail` don't exit. They simply set the model to `Done` with a code, and **the single `Done` branch is the only spot that pulls the trigger**. The code is data first, and an effect only at the very end.

The other school of thought is the C one, where bailing out has its own name (`die`) and just exits on the spot, straight from `init`, or elsewhere within an update case branch, or never bothering `update` at all. You can run a whole CLI program that way and never once reach the update loop. It's procedural, and honestly fine -- we kicked it around for a while and neither of us landed on a One True Answer. But personally I like threading it through the model like the above. The model says what happened; `update` does the leaving. (Your mileage may vary, of course.)

In other words, this is how we start the process of exiting this program:

```elm
-- Each helper asks for exactly the capability it uses, and no more.
-- success can write to stdout. fail can write to stderr.
-- Both return a `Done` model that makes `update` call `Cli.exit code`

success : { a | stdout : Console } -> String -> ( Model, Cmd msg )
success env output =
    ( Done 0, Cli.println env.stdout output )


fail : { a | stderr : Console } -> String -> ( Model, Cmd msg )
fail env output =
    ( Done 1, Cli.println env.stderr output )
```

And the error handling is the `Http.Error` union you already know, exhaustively matched because the compiler still won't let me skip a case:

```elm
-- The exact same Http.Error you handle in browser Elm. The compiler
-- still makes you cover every branch -- except now "NetworkError"
-- means a real socket gave up, not a mocked-out browser request.
httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.BadUrl url ->
            "Bad url: " ++ url

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus code ->
            "Status code: " ++ String.fromInt code

        Http.BadBody body ->
            "Bad body: " ++ body
```

## You can't call home if nobody gave you a phone

In basically every language I've used, _every_ function can reach the network, because the network is a global. `import requests` and you're off. The only defense against a sketchy dependency is reading its code and hoping. `elm-run` does it differently, and when you run a program, the runtime tells you up front what it wants:

```
./tool

This program requires capabilities not currently granted:

  - http                 (add --allow-http)
```

You download what claims to be a file-formatting tool and the runtime mentions it also wants to make HTTP calls? You can just say no. The call silently no-ops and the tool formats your files anyway. This is the Deno permission model, except reached through Elm's type system instead of a flag parser. The type signature tells you exactly what a function can touch: `success` writes to stdout and that's the whole list, and you can read it straight off the types without trusting a word of the implementation.

## Running it

The whole workflow is one command:

```
run --allow-http cli/Fetch.elm https://learnelm.dev
```

No `package.json`, no `node_modules`, no bundler config, no `tsc`. `run` walks up the tree to find your `elm.json`, calls the real Elm compiler, optimizes, and executes. Want a standalone binary? `run make -o fetch cli/Fetch.elm` and now `./fetch` works on its own.

The trick that makes `./fetch` Just Work is sneaky and I love it: the _type of your `main`_ selects the runtime. `main : Cli.Program Model Msg` gets the CLI host. A `Worker.Program` would get the web-server host (which packs an actual HTTP/2 server with TLS -- you could front it like Nginx, apparently). The compiler reads the type, embeds it, and writes a shebang into the binary -- the same `#!/usr/bin/env` line you'd put at the top of a bash script -- so the OS loader picks the right runtime for you. The type system chooses your host. Very Elm.

## Is this production-ready?

Not quite. It's 0.2.0.

I want to be straight about this, because the elm-run docs are refreshingly straight about it themselves. The _type-level_ guarantee is real and airtight today: inside your Elm code, you genuinely cannot call an effect you weren't granted. But the _OS-level_ enforcement is young and the authors say so plainly. The bytecode isn't cryptographically signed yet, so a determined attacker could edit a `.bc` file and inject trust flags. The filesystem sandbox doesn't survive a spawned process -- if your program has the `Process` capability and shells out to some non-elm-run binary, that child walks right out of the sandbox. The game engine (GPU, 60Hz TEA loop) builds daily but won't ship for months. Even the "host" concept the authors now call a bit of a kludge they're planning to tear out.

So where does that leave it? The developer experience is already good today. The security and the bigger ambitions are mostly promises the runtime is still growing into (signed bytecode, the locked-down distribution, that game engine that builds every night but won't ship for months).

None of that is what I find exciting, though. The exciting part is older than this beta. Elm forbade arbitrary JavaScript and routed every effect through the runtime, and for years some people treated that as an annoying limitation to work around. Turns out it was a bet. Because the language never let you reach past the runtime, the _same source_ can retarget from "JavaScript in a browser" to "bytecode hitting libcurl" without touching a line. And if you spent those years cleverly bypassing Elm's no-JavaScript rule to sneak in native code, congratulations: you've quietly locked yourself _out_ of native Elm. The thing that used to feel like a straitjacket is the only reason any of this compiles.

I built a working HTTP client in about 30 lines of the most ordinary Elm imaginable, and it ran as a native binary with no JavaScript in sight. My Node experiment was a clever workaround that needed JavaScript to exist at all. This needed nothing. Different beast, better beast.

Hopefully my next project with `elm-run` will be a REST API of some sort; perhaps I can even replace some small existing app with it already?

If you want learn more, check out [elm-run.dev](https://elm-run.dev), or sign up @ [elm-run.dev/beta](https://elm-run.dev/beta).
