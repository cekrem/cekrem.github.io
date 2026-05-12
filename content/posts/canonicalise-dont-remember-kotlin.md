+++
title = "Canonicalise, Don't Remember — Smart Constructors in Kotlin"
description = "If you have to remember to call mergeByX() before you pass a value around, you're sowing foot guns. Make the constructor do it once, and let the type carry the promise."
date = 2026-05-12
author = "Christian Ekrem"
tags = ["kotlin", "type-safety", "functional-programming", "domain-modeling", "smart-constructors", "parse-dont-validate"]
draft = false
+++

Story time! What follows is a slightly simplified and transposed-to-another-domain version of what I experienced this week. Ish.

In our app, we had a shopping cart (not really, though, but stay with me), where adding the same product twice should collapse into one line with the quantities summed. A colleague had recently shipped `mergeBySku()` to do exactly that. The "add to cart" code path called it. The "restore the user's cart from the server" code path called it. Then a third construction site landed in the repo (someone's "re-import items from a previous order" feature, or some such) without first making the call to normalise the line items. Then, lo and behold: a support ticket showed a customer's cart with the same product appearing four times.

![Michael Scott: "Fool me once..."](https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExdzZya3p6ZmQxbm9yaG93MXgyM28zZmFqMHJoeWwxNHdvdDExbjl1NyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/2eTVRPLl4WgOrxY0kr/giphy.gif)

We could play blame game all day, or we could investigate why this happened and how to prevent it from doing so again.

Adding `mergeBySku()` to the import path as well was the obvious patch. A true hot-fix one-liner! But "remember to call merge everywhere you make a shopping cart" had already failed once, and I couldn't see why the next reminder would do any better. <sup><sup><sup>(I wonder if some consultants "fix" things this way intentionally to avoid going out of business?)</sup></sup></sup>

**So I wanted a different shape of fix entirely.** The kind that doesn't need a wiki page nobody'd read. Or a thirty-minute "by the way, always remember to merge line items" meeting on a colleague's calendar. The merge has to happen because the code has no other option. That was the bar.

I was kind of looking for [parse-dont-validate](/posts/parse-dont-validate-typescript/), but not quite. More like... Auto-normalize data automagically whether you remember or not? Too long for a t-shirt, though.

The broken code did this: `mergeBySku()` in the add-to-cart pipeline, `mergeBySku()` in the cart-restore service; _no_ `mergeBySku()` in the new import path. The function was free-floating, public, and entirely advisory — anyone who wanted a properly merged cart just had to know to ask for one.

That's a foot gun, if there ever was one. The function wasn't wrong (the function was actually _great_, both in this anecdotal edition and the original it's based on; state of the art superb Kotlin wizardy!). The _type_ was the thing that wasn't quite being as useful as it should be.

## The original setup

A (simplified) cart holds a customer and some line items:

```kotlin
@Serializable
data class Cart(
    val customerId: CustomerId,
    val items: List<LineItem>
)

fun List<LineItem>.mergeBySku(): List<LineItem> = // ...
```

`mergeBySku()` collapses items sharing the same SKU into a single line with summed quantities. Fine in isolation. Bad as a pattern, the moment it has more than one caller.

The add-to-cart pipeline did this:

```kotlin
val cart = Cart(customerId, items.mergeBySku())
```

The cart-restore service did its own thing — a little different, a little worse:

```kotlin
cartStore.load(customerId).map { cart ->
    cart.copy(items = cart.items.mergeBySku())
}
```

Two code paths == two "rememberings". And Every™ future code path is one more chance to forget, in case you missed the first ones.

(Again: not blaming anyone for writing it this way. The first time you need a merged list, the obvious move is the obvious move — you call `mergeBySku()` and move on with your life. The alarm should go off the _second_ time someone writes the same incantation in a different file. It usually doesn't. The shape of the code is what's wrong here, not the people working in it or the implementations themselves.)

## The Point, and The Fix

I had a similar case a couple of weeks ago where we _always_ had to sanitize a search query (from user input) before storing it in our domain model. The hat trick I found then seems to be just what the doctor ordered here too, and possibly the main takeaway in this post:

- A `private constructor` (💡!)
- A smart companion `operator fun invoke` (🤯?)
- A rad `@Annotation` that _limits native `.copy()` availability_ (😵‍💫?!)

Here's what it looks like:

```kotlin
@Serializable
@ConsistentCopyVisibility
data class Cart private constructor(
    val customerId: CustomerId,
    val items: List<LineItem>
) {
    companion object {
        operator fun invoke(
            customerId: CustomerId,
            items: List<LineItem>
        ) = Cart(
            customerId = customerId,
            items = items.mergeBySku()
        )
    }
}

// Btw, you could just as easily have moved this function to the companion as well. YMMV
private fun List<LineItem>.mergeBySku(): List<LineItem> = // ...
```

A few things changed, let's look at them one by one. The primary constructor is now `private`, and the companion `invoke` is now the only way to actually construct this object from the outside. But the cool thing with using an `operator fun invoke` is that `Cart(...)` still works everywhere, and callers won't even notice the difference! And, more importantly: our custom invoke _always_ calls `mergeBySku()`! While we're at it, we're making the merge function private so we don't do double-merging.

The final point is `@ConsistentCopyVisibility`, which basically makes the built in `copy` method private(!). More on that further down.

The cart-restore service promptly collapsed to this, without needing to remember to massage data at all:

```kotlin
suspend fun loadCart(customerId: CustomerId) = cartStore.load(customerId)
```

The defensive re-merge is now gone, because there's nothing left to defend against: a `Cart` is, by construction, in canonical form. If you have one, its items are merged. The service doesn't need to know that SKUs can collide any more than it needs to know how PostgreSQL stores rows.

## This is "parse, don't validate"'s lesser-known cousin

I've [written](/posts/parse-dont-validate-typescript/) [about](/posts/arktype-parse-dont-validate-sequel/) Alexis King's [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) before, and it's a principle worth rehearsing and re-iterating. But like I said this isn't _quite_ that. King's pitch is mostly about _rejecting_ bad input or transforming it to a richer type you can later trust completely — you parse a `string` into an `Email` because some strings aren't emails. The parser's job is to refuse or approve/transpose.

Here, nothing is being rejected. Two lists of items can both be perfectly legitimate, and yet the difference between "raw" and "merged" is the difference between a working feature and a support ticket about phantom duplicates. Nothing is bad. Something is just _uncanonical_.

The slogan, if I want one: **make the canonical form the only form.**

(Scott Wlaschin's framing for this kind of thing: the type is a _promise_. A shape that also commits to something. When the constructor doesn't enforce that commitment, every caller ends up co-authoring the invariants with you, and group projects are the worst place to keep code. I'm stealing the framing.)

When I look at it through that lens, all the `mergeBy`s and `sortBy`s and `trim`s and `lowercase()`s and `distinct()`s I've been sprinkling at call sites for years are the same shape of mistake. A list of items on a `Cart` _means_ the merged list. A trimmed string _means_ the trimmed string. If two values share a type but differ in things I'd happily call equivalences, the type is lying to me.

## Where Kotlin fights back: `data class.copy()`

Back to that badass annotation now:

Kotlin's `data class` generates a `copy()` method that, by default, calls the _primary_ constructor — yes, the private one — directly. So without `@ConsistentCopyVisibility`, this is what you'd see:

```kotlin
val good = Cart(customerId, items)            // merged, via invoke
val sneaky = good.copy(items = newItems)      // NOT merged. Bypassed.
```

That's `copy()` writing fields straight into the private primary constructor. The merge logic lives in `invoke`, which `copy()` doesn't go through. So `copy()` doesn't merge.

`@ConsistentCopyVisibility` (tracked under [KT-11914](https://youtrack.jetbrains.com/issue/KT-11914), if you enjoy archaeology) makes `copy()` inherit the visibility of the primary constructor. Slap it on the class and `copy()` becomes effectively private too — external callers attempting it now get a compile error. The smart constructor is finally the _only_ smart constructor, which is our main goal (canonical form == only form!).

This behavior is [the default from Kotlin 2.1.0 onward](https://kotlinlang.org/docs/whatsnew21.html#improved-data-class-copy-visibility-alignment-with-constructor-visibility), so on a modern toolchain the annotation is belt-and-braces; you can also flip the same flag globally with `-Xconsistent-data-class-copy-visibility`.

Either way, write the annotation. It says what it does, and it survives a Kotlin downgrade without anyone needing to re-explain the constraint. Future-you will be glad to find it sitting at the top of the file.

## Where Kotlin fights back, part 2: `@Serializable`

One last door worth knowing about. By default, kotlinx.serialization deserializes straight into the primary constructor — again, the private one — and skips your companion `invoke` entirely. The bug we just deleted can quietly walk back in through the cache-read door if you let it.

If you control the producer and you're certain data only enters the cache after going through `invoke`, the bytes on disk are already canonical and you're fine. Otherwise: write a custom `KSerializer` (or `@Serializable(with = ...)` plus a surrogate) whose `deserialize` routes through `Cart(...)` instead of the primary constructor. The invariant either lives in the type or it lives in an unwritten promise about your storage layer — and unwritten promises are how we got here in the first place.

Or better yet: put on your big boy pants and use separate DTOs instead of (de-)serializing your domain models directly.

## Aside: `init { require(...) }` vs `invoke`

Some people reach for `init { require(...) }` constantly in Kotlin, and it's a perfectly good tool (though I'm personally not a fan). But regardless of your preference it's a tool for _validation_, not for canonicalisation. `init` runs after the fields are set; you can't _replace_ `items` from inside `init`, you can only inspect it and throw.

So: rejection is `require`. Normalisation is `invoke`. Same conceptual distinction as parse-vs-validate, just at a slightly different layer.

## The architecture argument, briefly

I've been talking about this at the type level, but it lands in the same place architecturally: the cart-restore service had two jobs. It answered "what's this user's cart?" _and_ it patched up the shape of the data it received. Two reasons to change. Every service that ever touched a `Cart` would have inherited that second job — and every one would have reinvented it slightly differently.

**If your domain type can be constructed in an invalid state, every function that consumes it is forced to become a domain expert.** Call that "reuse" if you like; I'd call it poor engineering. It's not cool, and it gets worse as it scales!

The domain type is the right place for the invariant. Not the controller, and definitely not whichever analytics shim ends up touching it next year. Once the type "carries the promise", the rest of the codebase gets to be _stupid_, and services stop being domain experts. Stupid services are great.

## In conclusion

Every time I write "remember to call X before you pass this around", I should reconsider. Reminders don't survive a refactor, much less a second developer. Two months from now I'll even forget myself, with nobody to blame but past-me.

Move the merge into the constructor and the problem just... evaporates. If it's a `Cart`, its items are merged. Done.

(Then go check `copy()`. Then `@Serializable`. Or do the whole thing in Elm with phantom types and call it a day. True story: immediately after solving this, I decided to finally give [Lamdera](https://lamdera.com) a try. Full stack Elm 🤤 That's probably my next blog post.)
