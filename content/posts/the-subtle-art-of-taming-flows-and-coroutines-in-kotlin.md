---
title: "The Subtle Art of Taming Flows and Coroutines in Kotlin, or 'How Not to DDoS Yourself with Server-Sent Events'"
date: 2025-09-08
description: "A tale of how elegant SSE code passed code review, worked perfectly locally and in staging, but nearly brought down our production servers when thousands of users connected simultaneously during a real DDoS attack."
tags:
  [
    "kotlin",
    "ktor",
    "server-sent-events",
    "coroutines",
    "flow",
    "performance",
    "production",
  ]
draft: false
---

I originally wanted to write a post about Server-Sent Events in general, and how delightfully cool they are. SSE provides a clean, standardized way for servers to push real-time updates to web clients over a simple HTTP connection. The [MDN documentation](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events) showcases how straightforward the client-side implementation is, while [Ktor's SSE support](https://ktor.io/docs/server-server-sent-events.html) makes the server-side equally elegant. SSE strikes a perfect balance: simpler than WebSockets when you only need one-way communication, yet more efficient than polling.

But this isn't that post.

Instead, this is a story about how seemingly innocent Flow and coroutine code can bite you in production in the most unexpected ways. It's about the subtle difference between "working" and "working under load." And it's about how a tiny change in flow control can mean the difference between a robust server and an accidental self-DDoS.

**Note: I tell this tale with the explicit permission from my client, but I've intentionally obfuscated some details for obvious reasons.**

## The Setup: A Perfect Storm

Picture this: It's a Friday around lunch-time. Our team has just deployed a beautiful new SSE endpoint for real-time notifications. The code passed code review with flying colors, worked flawlessly in local development, and sailed through our staging environment. We were proud of our clean, idiomatic Kotlin—a textbook example of modern coroutine and Flow usage.

Then we deployed to production.

At the exact same time, a known hacker group decided to launch a DDoS attack against our infrastructure. Thousands of legitimate users were online, each with active SSE connections for real-time updates. The combination of external attack traffic and internal connection management created the perfect storm.

Our servers didn't just struggle—they started consuming resources at an alarming rate. Memory usage spiked, CPU utilization maxed out, and we were essentially DDoS'ing ourselves from the inside while fighting off the external attack.

## The Puzzle: Two Approaches, One Problem

Here's the code that went to production. Can you spot which approach will leak resources under load?

### Approach A: Collect & Return

```kotlin
routing {
    sse("/events") {
        val sessionId = call.sessionId()
        val eventFlow: Flow<Pair<String, Boolean> = merge(someGlobalEventFlow, someClientSpecificEventFlow(sessionId))
            .map { event -> Pair(event, checkIfClientIsAuthenticated(sessionId)) }

        // Approach A: collect && return
        eventFlow.collect { (event, clientIsAuthenticated) ->
            // if the client is not authenticated, return from function to stop collecting events
            if (!clientIsAuthenticated) {
                sendLoggedOutEvent()
                return@collect
            }

            // try to send the event to the client, returning true if the client is still connected
            val clientIsConnected = trySendEvent(event)
            if (!clientIsConnected) {
                return@collect
            }
        }

        // home free: no longer trying to send events to this user
        close()
    }
}
```

### Approach B: Collect & Cancel

```kotlin
routing {
    sse("/events") {
        val sessionId = call.sessionId()
        val eventFlow: Flow<Pair<String, Boolean> = merge(someGlobalEventFlow, someClientSpecificEventFlow(sessionId))
            .map { event -> Pair(event, checkIfClientIsAuthenticated(sessionId)) }

        // Approach B: collect && cancel
        try {
            eventFlow.collect { (event, clientIsAuthenticated) ->
                // if the client is not authenticated, cancel the flow to stop collecting events
                if (!clientIsAuthenticated) {
                    sendLoggedOutEvent()
                    cancel(IntentionalCloseException)
                }

                // try to send the event to the client, returning true if the client is still connected
                val clientIsConnected = trySendEvent(event)
                if (!clientIsConnected) {
                    cancel(IntentionalCloseException)
                }
            }
        } catch (e: IntentionalCloseException) {
            // do nothing, we've cancelled the flow intentionally
        } finally {
            // home free: no longer trying to send events to this user
            close()
        }
    }
}
```

Both approaches look reasonable at first glance. Both handle authentication checking and client disconnection. Both compile cleanly and work perfectly with a handful of concurrent connections.

But only one of them will behave correctly under production load.

## The Difference: A Tale of Two Control Flows

The critical difference lies in how each approach handles early termination of the Flow collection.

### Approach A: The Resource Leak

```kotlin
if (!clientIsAuthenticated) {
    return@collect  // This only skips the current emission!
}
```

Here's the subtle trap: `return@collect` doesn't stop the collection—it only skips processing the current emission. The `collect` block continues waiting for the next emission from the Flow. This means:

1. The coroutine keeps running
2. The SSE connection remains open
3. The Flow continues producing events
4. `close()` is never reached
5. Resources accumulate with each "disconnected" client

So while the `return@collect` _appears_ to be the coroutine equivalent of a `break` within a regular loop, it's actually more similar to a `continue`. Precicely what we _don't_ want!

Under normal conditions with a few dozen connections, this might go unnoticed (and it sure did!). But when thousands of connections are established during a DDoS attack and then clients become unauthenticated or disconnect, those zombie collectors pile up quickly. Very quickly!

### Approach B: Clean Termination

```kotlin
if (!clientIsAuthenticated) {
    cancel(IntentionalCloseException)  // This cancels the collecting coroutine; think `break` within a loop
}
```

The `cancel()` call throws a `IntentionalCloseException`, which:

1. Terminates the collecting coroutine
2. Exits the `collect` block
3. Triggers the `finally` block
4. Calls `close()` to clean up the SSE connection
5. Properly releases all associated resources

The `try-catch-finally` structure ensures that when we intentionally cancel the operation, cleanup happens correctly.

(You could also use some variation of `transformWhile` or `takeWhile` before the collect instead of canceling with an exception, which is what we ended up doing. But try/catch/finally was easier to explain.)

## The Production Reality

During our incident, Approach A created a cascading resource leak. Every time a client disconnected or became unauthenticated (which happened frequently during the DDoS), we accumulated:

- An active coroutine waiting for the next Flow emission
- An open SSE connection consuming server resources
- Memory allocated for the Flow processing pipeline
- Background tasks polling for authentication status

With thousands of connections being established and "abandoned" in this way, our servers quickly became overwhelmed—not just by the external attack, but by our own leaked resources.

## The Fix and Lessons Learned

The fix was embarrassingly simple: replace `return@collect` with `cancel(...)` and add proper exception handling. But the lessons were profound:

### 1. Load Testing Reveals Truth

Code that works with 10 concurrent connections might fail catastrophically with 10,000. Our staging environment, optimized for cost over scale, simply couldn't reproduce the production load patterns.

### 2. Resource Management Is Critical

In languages with garbage collection, it's easy to forget about resource leaks. But when dealing with network connections, coroutines, and flows, explicit cleanup becomes crucial.

### 3. Control Flow Matters

The difference between "skip this iteration" and "stop collecting" is subtle in code (and in this case _very_ easy to miss!) but massive in production impact. Understanding the exact semantics of coroutine cancellation is essential for robust server applications.

### 4. Timing Is Everything

Our code worked perfectly—until it didn't. The combination of high load and external pressure revealed edge cases that never appeared under normal conditions.

## Best Practices for SSE and Flow Management

1. **Always use explicit cancellation** when you need to terminate Flow collection early
2. **Implement proper cleanup** in `finally` blocks or using `use` functions
3. **Test under realistic load** with tools that can simulate thousands of concurrent connections
4. **Monitor resource usage** in production to catch accumulation patterns early
5. **Understand coroutine lifecycle** and how cancellation propagates through your system

## A Happy Ending

After deploying the fix, our servers stabilized even under the continued DDoS attack. The external attackers were eventually blocked, but more importantly, we learned that our internal code was resilient under extreme load.

The corrected approach handles thousands of SSE connections gracefully, properly cleaning up resources when clients disconnect, and maintaining predictable memory usage even under attack conditions.

## Conclusion

Server-Sent Events are indeed a powerful and elegant technology for real-time web applications. Kotlin's coroutines and Flow provide beautiful abstractions for handling asynchronous streams. But excellence, as always, is in the details.

The difference between `return@collect` and `cancel(...)` might seem trivial, but in production systems serving thousands of users, these subtleties become the difference between stability and catastrophic failure.

Sometimes the most dangerous bugs are the ones that hide in plain sight, looking perfectly reasonable until the moment they're not.

Remember: when dealing with flows and coroutines, always clean up your resources. Your production servers will thank you.

---

_Special thanks to the DDoS attackers for providing the load testing we apparently needed. Your service is not requested, but occasionally educational._
