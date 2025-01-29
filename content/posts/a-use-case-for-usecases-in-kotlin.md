+++
title = "A Use Case for `UseCase`s in Kotlin"
description = "archaic remnants or useful abstractions?"
date = "2025-01-31"
tags = ["vipps", "vipps mobilepay", "android", "kotlin", "clean architecture", "architecture"]
draft = false
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

## What my betters told me

...was that this whole UseCase layer (and especially the way the operator function was used!) was overengineering at its worst, and that the consept in general reeked of ye old Java from back when people didn't know any better. I was curious, but sadly not curious enough to do my own research. I made a mental note to check if the candidate was the over-engineering type in the actual interview (which, oddly, he really wasn't, and he got the job), and thought very little of it.

## But wait!

I'm in [Uncle Bob](https://amzn.to/40SYBRI) land these days. I know he's a somewhat controversial guy, and a lot of people have an issue or to with some opinionated advice in his Clean Code(r) books. Leaving those controveries alone for the moment – this guy has had a significant impact on how we approach software architecture and system design. So, as I'm reading his less controversial work, [Clean Architecture](https://amzn.to/4iAc8o1), this UseCase thing pops up again! And, further more, in many of his talks (I've seen at least two on YouTube last week) he sites [Ivar Jacobson](https://amzn.to/4hcyXNf) in general, and recommends his [Object-Oriented Software Engineering: A Use Case Driven Approach](https://amzn.to/3CuqLZE) (note the subtitle!) in particular.

## The Clean Architecture Perspective

What I've come to realize is that UseCases aren't just some archaic remnant of over-engineered Java applications - they serve a crucial role in Clean Architecture's separation of concerns. In fact, they represent what Uncle Bob calls "application-specific business rules" - the actual behaviors that make your application unique.

Consider our earlier example:

```kotlin
class GetProfileUseCase(private val profileRepository: ProfileRepository) {
    suspend operator fun invoke(userId: String): Profile? {
        val profile = profileRepository.get(userId)

        if (profile.isValid) {
            return profile
        }
        return null
    }
}
```

This UseCase encapsulates a specific business rule: "A user can retrieve a valid profile by ID." It's not just a pass-through to the repository - it enforces validation rules and handles the business logic of what constitutes a retrievable profile.

## Why They Make Sense

1. **Single Responsibility**: Each UseCase represents one specific thing the application can do. This makes the code more maintainable and easier to test.

2. **Independence from Frameworks**: UseCases don't know about Android, Compose, or any other framework. They're pure business logic, which means they're highly portable and reusable.

3. **Dependency Rule**: They help maintain Clean Architecture's dependency rule - outer layers (UI, frameworks) depend on inner layers (UseCases, Entities), never the other way around.

4. **Testability**: Because UseCases are framework-independent and focused on a single responsibility, they're incredibly easy to test:

```kotlin
class GetProfileUseCaseTest {
    @Test
    fun `should return null for invalid profile`() {
        val mockRepo = mockk<ProfileRepository>()
        coEvery { mockRepo.get(any()) } returns Profile(valid = false)

        val useCase = GetProfileUseCase(mockRepo)
        runBlocking {
            assertNull(useCase("userId"))
        }
    }
}
```

## The `invoke` Operator: More Than Syntactic Sugar

That `operator fun invoke()` that initially seemed strange? It's actually a clever use of Kotlin's operator overloading that makes the UseCase feel like a first-class function while maintaining the benefits of a class (like dependency injection and state if needed).

## When to Use UseCases

UseCases make the most sense when:

- You have distinct business rules that need to be enforced
- The operation is more complex than a simple CRUD operation
- You need to combine multiple data sources or operations
- You want to maintain a clean separation between business logic and other layers

## Conclusion

While UseCases might seem like unnecessary abstraction at first glance, they serve a valuable purpose in maintaining clean architecture principles. They're not just about following patterns blindly - they're about creating maintainable, testable code that clearly expresses business intent.

The next time you encounter a UseCase in a codebase (or consider writing one), remember that it's not just Java baggage - it's a powerful tool for encapsulating business logic and maintaining architectural boundaries. Used judiciously, UseCases can make your codebase more maintainable, testable, and clearer in its intentions.

Just don't forget the golden rule of software architecture: everything comes with tradeoffs. UseCases add a layer of abstraction that might be overkill for very simple CRUD operations. As with all architectural decisions, consider your specific needs and context before applying them.
