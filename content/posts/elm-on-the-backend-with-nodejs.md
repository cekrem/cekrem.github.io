+++
title = "Elm on the Backend with Node.js: An Experiment in Opaque Values"
description = "What happens when you pass a Node.js response handler through Elm without touching it? Surprisingly elegant things."
tags = ["elm", "nodejs", "backend", "functional programming", "ports", "experiment"]
date = "2025-12-19"
draft = false
+++

What if you could write backend logic in Elm? Not "Elm-like" or "inspired by Elm" – actual Elm, with the compiler, the types, the whole package. I've been nerd-sniped by this idea for a while, and last night I finally sat down to build a proof of concept.

**Disclaimer:** This is me experimenting with a concept, not suggesting anyone _should_ do this. If you actually want Elm on the backend, [Lamdera](https://lamdera.com/) does something far more sophisticated – it's a full platform with seamless frontend/backend Elm, automatic persistence, and real deployment story. My thing is... not that. It's just a hack to see what's possible with vanilla Node.js and vanilla Elm, nothing more.

The result? About 150 lines of Elm that handles HTTP routing, plus a 30-line Node.js wrapper. And one genuinely interesting insight about passing opaque values across language boundaries.

## The Architecture (It's Simpler Than You'd Think)

The basic idea is straightforward: Node.js handles the HTTP server stuff (because that's what it's good at), and Elm handles the routing and response logic (because that's what _I_ want it to be good at). They communicate via ports.

```
HTTP Request → Node → port → Elm → port → Node → HTTP Response
```

The Elm side runs as a `Platform.worker` – no DOM, no browser APIs, just pure message processing. Here's the skeleton:

```elm
main : Program () Model Msg
main =
    Platform.worker
        { init = \_ -> ( (), Cmd.none )
        , update = update
        , subscriptions = subscriptions
        }

port request : (Decode.Value -> msg) -> Sub msg
port response : Response -> Cmd msg
```

Simple enough. But here's where it gets interesting.

## The Problem: How Do You Correlate Requests and Responses?

When a request comes into Node and gets sent to Elm, Elm processes it and sends back a response. But how does Node know which response belongs to which request? HTTP is stateless, and we might have multiple requests in flight.

My first attempt was the obvious one: give each request an ID.

```javascript
// The naive approach
const pending = new Map();
let requestId = 0;

app.ports.response.subscribe((data) => {
  const resolve = pending.get(data.id);
  if (resolve) {
    pending.delete(data.id);
    resolve(data);
  }
});

// Later, when a request comes in:
const id = `req-${++requestId}`;
pending.set(id, responseCallback);
app.ports.request.send({ id, method, path, body });
```

It works! But it's also... kind of gross? You've got this stateful `Map` sitting around, manual ID generation, string-based correlation. Very un-Elm-like.

I forgot the excellent advice from Mr. Dwight K. Schrute:

> "Whenever I'm about to do something, I think, 'Would an idiot do that?' And if they would, I do not do that thing."

## The Insight: Just Pass the Response Handler Through

Luckily, there are smart people in the Elm community who gently pointed me towards greener pastures. Here's the thing about Elm's `Json.Decode.Value` and `Json.Encode.Value` types: they're opaque. In other words, Elm doesn't know or care what's inside them. It just carries them around.

So what if we just... passed the Node.js response object _through_ Elm? Like, literally the same JavaScript object, untouched? (I wouldn't dare do it the other way around, btw, but Elm can be trusted not to mutate _anything_.)

Can we really?!

```javascript
// The elegant approach
app.ports.request.send({
  method: request.method,
  path: request.url,
  body,
  responseHandler, // <-- This is the actual Node response object!
  headers: Object.fromEntries(request.headers),
});

app.ports.response.subscribe(({ responseHandler, ...payload }) => {
  responseHandler.writeHead(payload.status);
  responseHandler.end(payload.body);
});
```

And on the Elm side:

```elm
type alias OpaqueResponseHandler =
    Encode.Value  -- The magic ✨

type alias Request =
    { responseHandler : OpaqueResponseHandler
    , method : Method
    , path : String
    , body : String
    }

type alias Response =
    { responseHandler : OpaqueResponseHandler
    , status : Status
    , body : String
    }
```

Elm receives the `responseHandler` as an opaque `Decode.Value`, threads it through all its pure functions, and sends it back out. When it arrives back in JavaScript land, it's _still the same object_. No ID correlation needed. No pending map. No bookkeeping.

The response handler just... travels through Elm like a passport, untouched and unexamined, and comes out the other side ready to use.

## Why This Actually Works

This pattern works because of a few properties:

1. **`Encode.Value` is truly opaque** – Elm can't decode it (and doesn't try to), so the object stays as-is
2. **JavaScript objects are passed by reference** – the same object identity is preserved
3. **Elm's type system keeps us honest** – we can't accidentally try to use the response handler as a string or number

It's type-safe at the Elm/JavaScript boundary without requiring serialization. The object crosses the boundary twice (in and out) but never needs to be understood by Elm.

## The Rest of the Implementation

With the correlation problem elegantly solved, the rest falls into place. The routing is just pattern matching:

```elm
route : Request -> Response
route req =
    case ( req.method, req.path ) of
        ( Get, "/" ) ->
            respond req Success "Welcome!"

        ( Get, "/hello" ) ->
            respond req Success "Hello, Elm backend!"

        ( Post, "/echo" ) ->
            respond req Success req.body

        _ ->
            respond req NotFound "Not found"


respond : Request -> Status -> String -> Response
respond req status body =
    { responseHandler = req.responseHandler
    , status = status
    , body = body
    }
```

And the `Status` type maps to HTTP codes:

```elm
type Status
    = Success       -- 200
    | BadRequest    -- 400
    | NotFound      -- 404
    | InternalError -- 500
```

No stringly-typed status codes. No magic numbers scattered around. Just types.

## Is This Production-Ready?

Haha, no. Absolutely not. This is a proof of concept, a late-night hack, a "what if?" answered. There's no middleware, no streaming, no websockets, no anything beyond the basics.

But that's not really the point. The point is that the pattern _works_, and it's kind of beautiful? The opaque value trick is genuinely useful and could apply to other interop scenarios.

## What I Learned

The biggest takeaway is that `Encode.Value` is more powerful than I gave it credit for. I've always thought of it as "JSON I haven't decoded yet." But it's really "any JavaScript value I want to carry around without examining."

That's a subtle but important distinction. It means you can use Elm's type system to enforce invariants about _how_ values flow through your program, even when you can't (or don't want to) inspect the values themselves.

Also: running Elm as a backend is surprisingly pleasant. The compiler catches mistakes, the types document the API, and the code is trivially testable. Would I use this for a real service? Probably not – there are better tools for that. But for learning, for experimentation, for the joy of seeing something work?

Worth every minute.

---

_The [complete source code](https://github.com/cekrem/elm-node-backend) is on GitHub if you want to poke around. Fair warning: it's about 250 lines total. Sometimes that's all you need._
