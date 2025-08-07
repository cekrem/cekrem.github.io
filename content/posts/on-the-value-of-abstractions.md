---
title: "On the Value of Abstractions"
date: 2025-08-07
draft: false
description: "A reflection on why starting with abstractions—even simple ones—pays off in real-world development."
tags: [architecture, kotlin, elm, software-design]
---

Most of my day-to-day work is in Elm. The combination of a functional language and the Elm Architecture makes many architectural decisions almost invisible (I talk more about that [in this blog post](/posts/why-i-hope-i-get-to-write-a-lot-of-elm-code-in-2025/#the-elm-architecture-vs-clean-architecture)). You get a clear separation of concerns, and the language nudges you toward good design by default.

But my work isn’t limited to Elm. I frequently find myself building features that span both frontend and backend—writing new endpoints, and sometimes even designing new database tables. When I step outside the Elm world, I’m reminded that architecture is something I have to be intentional about again.

This post isn’t about which code goes in which layer, or about specific design patterns. Instead, I want to zoom in on a deceptively simple choice: should you just implement the thing you need, or should you start by carving out an abstraction?

I’ll argue that starting with an abstraction pays off, even when it feels like extra work.

Let’s take a concrete example. Suppose I need a `SearchCacheRepository`—something to store and retrieve cached search results. I could just write a class that does what I need, jumping straight to creating the appropriate tables (and indices) and call it a day. But instead, I find myself reaching for an interface:

```kotlin
@ImplementedBy(SearchCacheInMemoryImpl::class)
interface SearchCacheRepository {
    val cacheTimeout: Duration

    suspend fun getCachedSearch(
        userID: Int,
        searchId: String,
    ): Either<CacheError, CachedSearch>
}
```

And then, I’ll write a quick in-memory implementation:

```kotlin
@Singleton
class SearchCacheInMemoryImpl : SearchCacheRepository {
    override val cacheTimeout = 10.seconds
    // Implementation using hashMap follows
}
```

Later, when I need to actually persist things, I can add a SQL-backed implementation:

```kotlin
@Singleton
class SearchCacheSqlImpl
@Inject
constructor(
    private val dbProvider: DatasourceProvider,
    override val cacheTimeout: Duration
) : SearchCacheRepository {
    // Implementation using Postgres or whatever follows
}
```

## Why Bother With the Abstraction?

It’s tempting to see this as unnecessary overhead—why not just write the code you need, and refactor later if you really need to swap implementations? But in practice, I’ve found that starting with an abstraction has a few big benefits:

- **Clarity of intent:** By defining the interface first, I’m forced to think about what functionality I actually need. I can even start calling the methods from the consumer side before I’ve implemented them, which is a great way to see if the API feels right in practice.
- **Faster iteration:** The in-memory implementation is useless in production, but it’s incredibly convenient for local development and testing. I can get the rest of the system working, run both manual and automated tests, and only worry about the “real” implementation when I’m ready.
- **Parallel development:** If the task is split between multiple developers, I can hand off the SQL implementation to someone else, without breaking the contract between the backend and frontend, or between the controller/route and the repository. Everyone can work in parallel, with confidence that things will fit together.
- **Easy swapping:** When the time comes to switch from the in-memory version to the real thing, it’s just a matter of wiring up the new implementation. No need to touch the rest of the codebase.
- **Bonus point:** It’s actually more common than you’d think that YAGNI (You Ain’t Gonna Need It) comes into play where you don’t expect it. Like starting out with a file-based storage and finding it’s actually sufficient for your needs for years and years before you actually need that enterprise cluster-solar-elastic-cosmic db thing Azure has been trying to sell you.

## When You _Don’t_ Need an Abstraction

Of course, not every bit of code needs an interface or extra layer. Sometimes, a direct implementation is the right call. For example:

- One-off scripts or migrations
- Truly trivial logic that’s unlikely to change
- Internal code with only one consumer
- Quick prototypes or spikes
- When speed of delivery is more important than flexibility

This isn’t an exhaustive list, but the point is: be intentional. Reach for abstractions when they solve a real problem, not just out of habit.

Be _very_ careful with those last two, though; you never know when your prototype is thrown into production and you (or some other sorry soul) will have to maintain it.

## Conclusion

In my experience, the small up-front cost of defining an abstraction often pays for itself many times over. It’s not just about future-proofing or testability (though those are nice side effects)—it’s about making it easier to think, to iterate, and to collaborate. Even if you’re the only developer on the project, your future self will thank you.

And if you’re coming from Elm, where the architecture is almost invisible, it’s worth remembering that a little bit of explicit structure can go a long way—especially in languages where the compiler isn’t holding your hand quite as tightly.
