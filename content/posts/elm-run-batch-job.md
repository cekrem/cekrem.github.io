+++
title = "A batch job, in The Elm Architecture"
description = "Last time I built an 80-line native fetch with elm-run. This time I'm pushing it at real scale: a long-running batch where each item is a little railway-oriented state machine -- and the same Elm domain runs in the browser, on backend, and in the batch."
tags = ["elm", "elm-run", "native", "batch", "lamdera", "railway oriented programming", "functional programming"]
date = "2026-06-24"
draft = false
+++

At the end of my [native Elm post](/posts/native-elm/) I said I hoped my next `elm-run` project would be a REST API, or maybe replacing some small existing app. I lied a little. I went the other direction and grabbed something much bigger: a real batch job, inside a real (and fairly large) application I'm actually building. The fetch PoC was 80 lines of the most ordinary Elm imaginable. This one isn't a toy, and that's the whole point -- Damir (who's building elm-run) needs someone leaning on it at scale and reporting back what creaks, so that's what I've been doing.

Quick confession before anything else: the batch isn't fast yet. It works, it's correct, the types are lovely, but "production-grade throughput" it is not (but closer than one might think!). I'll get there (or elm-run will, rather). What I want to talk about isn't the speed. It's the _shape_.

## I've done the CLI thing before

This isn't my first batch-ish rodeo in Elm. Back in February I wrote [blog-bot](/posts/blog-bot/), a little Bluesky poster that runs daily on GitHub Actions, using [elm-pages](https://elm-pages.com/) Script mode. That was genuinely great. `BackendTask` chained five steps together, the compiler caught my mistakes, and I deployed the whole thing in a handful of commits.

But elm-pages Script is a _pipeline_ shape. You compose tasks, you `andThen` your way to the end, Node runs underneath. Perfect for "read RSS, transform, post, done." What it is _not_ is The Elm Architecture. There's no `Model`, no `update`, no long-lived loop with effects flowing in and out over time. For a fire-and-forget pipeline you don't miss that. For a job that has to babysit a few hundred things, each one drifting through several states at its own pace, some of them failing halfway and needing a nudge -- you miss it a lot.

That's the difference native Elm gave me. Not "Elm can run a script" (elm-pages already does that, and quite beautifully at that). It's "Elm can run _the loop_ -- `init`, `update`, `subscriptions` -- against the OS instead of the browser." Same loop I've written a hundred times for widgets. Now it's doing back-office work.

## Each item is a tiny state machine

A batch over a list of things is really a list of little lifecycles, and a lifecycle is exactly what a union type is _for_. So instead of a record with a `status : String` and a pile of nullable fields (the shape every untyped worker eventually rots into), each item is this:

```elm
type Item
    = Queued Input
    | Submitted Ref
    | Processing Ref Partial
    | Finished Ref Result
    | Failed Item Http.Error
```

That's not _like_ railway-oriented programming. It _is_ railway-oriented programming, just with more stations on the track. Scott Wlaschin's `Result` -- the two-state success/failure railway everyone draws -- is the degenerate case of this. Add intermediate stops and you've got the same track, longer. (I've written about [parse, don't validate](/posts/parse-dont-validate-typescript/) before; this is the same instinct pointed at a _process_ instead of a value.)

And the transitions are functions whose types won't let you cheat. The step that turns a `Submitted` into a `Processing` simply cannot be handed a `Queued`. You can't fetch a result for something you never submitted, because the function that fetches results asks for a `Ref`, and a `Queued` item hasn't got one yet. I didn't write a single guard for any of that. It's a product of the shape. The illegal _orderings_ became unrepresentable, not just the illegal values.

## A failure that remembers where it was standing

Look at that last branch again:

```elm
    | Failed Item Http.Error
```

`Failed` carries the whole previous `Item`. Not an error code floating in the void -- the actual last-good state the item was in when the HTTP call gave up. Which means rewinding a failure is comically boring:

```elm
rewind : Item -> Item
rewind item =
    case item of
        Failed previous _ ->
            previous

        _ ->
            item
```

A thrown exception is amnesiac. It knows _that_ it failed, never _where you were standing_ when it did. So you restart from the depot and re-run the three expensive calls that already succeeded. Here the failure is a checkpoint with a return address. Retry isn't "start over and pray it's idempotent" -- it's "resume from the siding you parked on." The type literally hands you back the state from just before things went sideways.

In a request/response handler you can almost get away without this. One request dies, the user hits refresh, nobody notices. In a batch over a few hundred items, item 287 _will_ fail, and "the job crashed at 64%" is a disaster while "283 finished, 4 parked, here they are" is a Tuesday. Batch is precisely where the difference between an exception and a checkpoint stops being academic.

Kicking the whole list off is the same TEA reflex too -- map your inputs into pending items, batch the commands:

```elm
start : Config -> List Input -> ( Dict Id Item, Cmd Msg )
start config inputs =
    let
        pending =
            inputs |> List.map (\input -> ( idOf input, Queued input ))

        cmds =
            pending
                |> List.map (\( id, item ) -> step config (GotStep id) item)
                |> Cmd.batch
    in
    ( Dict.fromList pending, cmds )
```

Then `update` catches each `GotStep id newItem`, drops it back into the `Dict`, and fires the next `step` for that one item. Hundreds of independent little railways, all advancing through the one `update` function, results trickling back as messages. It's the testimonials-widget loop I [started small with years ago](/posts/starting-small-with-elm-a-widget-approach/), except now it's grinding through a backlog instead of rendering a carousel.

## Why this matters more for a batch than a frontend

Batch jobs are where reliability goes to die in most stacks. Not because the work is hard -- because nobody ever invested in types there. The frontend gets the nice treatment because users _see_ it. The worker gets a bash script that calls a Python script that shells out to `psql`, with a `try/except: pass` someone added at 2am and retry logic that's about 60% finished. The most safety-hungry workload running on the least safety.

So the win isn't that elm-run is magic. It's that the batch is suddenly a first-class citizen, written in the same language with the same exhaustive `case` matching as the part of the app I actually took seriously. An unhandled variant in a UI is a stuck spinner -- annoying, visible, recoverable. An unhandled variant in a batch is a silent skip on row 40,000 that nobody notices until reconciliation a month later. Exhaustiveness pays off most exactly where there's no human watching the screen.

And refactoring stops being terrifying. Change the shape of a step and the compiler walks me through every place that produces or consumes it, the retry and the rewind included. `update` is a total function from `(state, message)` to new state, so I can feed it a recorded sequence of messages and assert the final state -- replay a failure, test resume-from-checkpoint -- without touching IO at all. Refactoring a stateful imperative worker, by contrast, is mostly staring at it and hoping it still resumes correctly. (This is the testing posture I went on about in the [book's testing chapter](/posts/elm-book-testing-strategies/), now applied to a cron job.)

## The actually exciting part: one domain with three runtimes

Imagine this (if you can):

The same Elm types -- the same encoders, decoders, the same domain logic -- run in three places now. There's a [Lamdera](https://lamdera.com/) frontend _AND_ backend, which I [fell for hard a few weeks back](/posts/greentype-lamdera/) precisely because frontend and backend already share their types (a message _is_ a value, the compiler insists both ends handle it). And now there's a native batch binary, courtesy of elm-run, importing the very same domain modules.

What this deletes is a whole _category_ of bug. "We shipped a backend change, the API shape drifted, and three weeks later the nightly batch started silently writing garbage" -- that's not one incident, that's a recurring shape of incident every untyped boundary pays rent on forever. When the decoder is _literally the same value_ referenced from all three, the drift can't happen. There's no spec that the client and the worker are each "supposed to" match off different branches. There's a function. They call it. The compiler refuses to build if they disagree.

Granted, this only buys you anything if the three contexts genuinely share a domain. If your batch's world is mostly unrelated to your frontend's, sharing types just couples three things that wanted to be separate. In my case they're the same app wearing different hats, so it's the real deal. Your mileage, as always, may vary.

## Where it's at

Same honesty as last time: elm-run is young, and I'm out here as the large-scale guinea pig, filing the rough edges I hit back to Damir. The batch isn't necessarily world-class fast. Yet. Bits of it are held together with the programmatic equivalent of duct tape ¯\\_(ツ)_/¯. None of that is the interesting part.

The interesting part is older than this beta, and it's the same bet I keep coming back to: Elm never let you reach past the runtime. Turns out it's the only reason a `Cmd` written for a browser widget can retarget to a native binary chewing through a backlog -- without changing a line. A `Cmd` was always a _description_ of an effect, never the effect itself. Damir just wrote a new runtime to perform those descriptions against the OS. My code doesn't know. My `update` doesn't know. The domain that powers a button click is, right now, the same domain grinding through a few hundred jobs, and the same domain a Lamdera backend leans on in between.

That still feels slightly illegal to me, in the best possible way.

If you want to play along, you can learn more at [elm-run.dev](https://elm-run.dev) (sign up for the beta at [elm-run.dev/beta](https://elm-run.dev/beta)). Go write a batch job. Make batch jobs great again!
