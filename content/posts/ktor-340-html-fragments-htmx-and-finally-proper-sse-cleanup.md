+++
title = "Ktor 3.4.0: HTML Fragments, HTMX, and Finally Proper SSE Cleanup"
date = 2026-01-30
draft = false
tags = ["kotlin", "ktor", "htmx", "server-sent-events", "functional-programming"]
categories = ["Programming", "Kotlin"]
+++

Ktor 3.4.0 just dropped, and while there's a laundry list of new features, a few of them made me genuinely excited. One of them even feels like a direct response to [that SSE post I wrote](/posts/the-subtle-art-of-taming-flows-and-coroutines-in-kotlin/) where we accidentally DDoS'd ourselves. (It's not, of course. But let me have this.)

## HTML Fragments: Ktor Gets HTMX-Friendly

If you've been following the HTMX movement (and if you haven't, you're missing out on some delightfully old-school-yet-modern web development), you know that the whole point is to return HTML fragments from your server, not full pages. Swap out a `<div>`, update a table row, replace a form with a success message. Simple stuff.

The problem was that Ktor's HTML DSL was designed around full documents. You'd write `call.respondHtml { ... }` and get a complete `<!DOCTYPE html>` wrapper whether you wanted it or not. For HTMX partial updates, you'd end up doing awkward workarounds or just sending raw strings.

Ktor 3.4.0 adds `respondHtmlFragment()`:

```kotlin
get("/users/{id}") {
    val user = userService.findById(call.parameters["id"])

    call.respondHtmlFragment {
        div(classes = "user-card") {
            h2 { +user.name }
            p { +user.email }
        }
    }
}
```

No `<html>`, no `<head>`, no `<body>`. Just the fragment. It's a small thing, but it makes HTMX integration feel first-class rather than bolted on.

Between this and the general HTMX renaissance, maybe we'll all be writing server-rendered HTML again in a few years. Full circle, baby.

## cancelCallOnClose: The SSE Fix I Needed Six Months Ago

Remember [my post about accidentally DDoS'ing ourselves with SSE connections](/posts/the-subtle-art-of-taming-flows-and-coroutines-in-kotlin/)? The core issue was that when clients disconnected, the server-side coroutines kept running, accumulating zombie connections until everything fell over.

Ktor 3.4.0 introduces the HTTP Request Lifecycle plugin with a `cancelCallOnClose` option:

```kotlin
install(HttpRequestLifecycle) {
    cancelCallOnClose = true
}
```

When a client disconnects, the coroutine handling that request gets cancelled automatically. Proper cleanup. No more zombie coroutines. No more accidental self-DDoS.

Now, to be clear: this doesn't replace understanding how `return@collect` differs from `cancel()` in Flow collection. You still need to structure your code correctly. But it adds a safety net for the cases where clients just... vanish. Network drops, browser closes, users getting impatient and hitting refresh.

For long-running requests (SSE, file uploads, streaming responses), this is a nice addition. Would've saved us a Friday afternoon of panic, that's for sure.

## OAuth Fallback: Because Auth Always Has Edge Cases

Speaking of things that break in production, OAuth error handling got an upgrade. Previously, if something went wrong during the token exchange (expired tokens, revoked access, network hiccups), `authenticate(optional = true)` didn't help because that only handles _missing_ credentials, not _broken_ ones.

The new `fallback()` function handles actual OAuth failures:

```kotlin
authenticate("oauth") {
    fallback {
        // Token exchange failed, refresh token expired, etc.
        call.respondRedirect("/login?error=session_expired")
    }

    get("/dashboard") {
        // Only reached if OAuth succeeded
        val user = call.principal<OAuthAccessTokenResponse>()
        // ...
    }
}
```

It's a subtle distinction, but if you've ever debugged OAuth flows in production, you know how many ways they can fail that aren't "user didn't log in."

## Other Bits Worth Mentioning

The full release has more than I can cover in depth, but a few other additions caught my eye:

**Zstd compression** — A newer compression algorithm with better ratios than gzip. If you're serving large responses and bandwidth matters, worth a look. At my client's we implemented this manually, but with this update we won't have to.

**API Key Authentication** — A simple built-in provider for service-to-service auth. Nothing fancy, but nice to have without pulling in a library.

**Runtime OpenAPI annotations** — You can now attach OpenAPI metadata directly to routes with `.describe {}`. The Gradle plugin generates this at build time rather than requiring a separate `buildOpenApi` task.

**`call.respondResource()`** — Serve classpath resources the same way you serve files. Handy for bundled assets.

## Conclusion?

Ktor keeps getting better at the things that matter in production: proper resource cleanup, better error handling, and first-class support for modern patterns like HTMX. The `cancelCallOnClose` feature alone would've saved me a very stressful Friday.

If you're running Ktor in production, the 3.4.0 upgrade seems worthwhile. If you're evaluating Kotlin for backend work, Ktor continues to be a solid choice that doesn't try to be everything to everyone.

Sure beats Spring(!). **Flame war mayhem commencing in 3, 2, 1...**

---

Full release notes: [What's New in Ktor 3.4.0](https://ktor.io/docs/whats-new-340.html)
