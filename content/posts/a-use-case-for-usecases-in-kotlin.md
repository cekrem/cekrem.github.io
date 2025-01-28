+++
title = "A Use Case for `UseCase`s in Kotlin"
description = "archaic remnants or useful abstractions?"
date = "2025-01-31"
tags = ["vipps", "vipps mobilepay", "android", "kotlin", "clean architecture", "architecture"]
draft = true
+++

## My First Impression

One of my responsibilities as an Android Developer in Vipps (Mobilepay) was to do tech interviews. After a while, I also made the tech assignments and changed the recruitment process a bit. But in the earlier days, we used a standard "build X using Y", where "Y" was modern Android tools (preferably Compose), and "X" was some non-descript hello world-ish app that did something I can't for the life of me remember. During one of the tech task evaluations we did prior to an interview, I encountered a strange animal completely unknown to me. A UseCase class, with an `operator fun invoke()` method.

It looked something like this:

```
class GetProfileUseCase(private val profileRepository: ProfileRepository) {
    suspend operator fun invoke(userId: String): Profile? {
        val profile = profileRepository.get(userId)

        // ish; the details don't matter
        if (profile.isValid) {
            return profile
        }

        return null
    }
}
```

Never had I ever (remember, I started my Kotlin/Java days @ Vipps, and they simply don't do that).

This `UseCase` was then used like this:

```
val getProfile = GetProfileUseCase(someInjectedProfileRepo)

getProfile(userId)
```
