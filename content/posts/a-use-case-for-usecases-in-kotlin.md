+++
title = "A Use Case for `UseCase`s in Kotlin"
description = "archaic remnants or useful abstractions?"
date = "2025-01-31"
tags = ["vipps", "vipps mobilepay", "android", "kotlin", "clean architecture", "architecture"]
draft = false
+++

## My First Encounter with a Kotlin `UseCase`

One of my responsibilities as an Android Developer in Vipps (Mobilepay) was to do tech interviews. After a while, I also made the tech assignments and changed the recruitment process a bit. But in the earlier days, we used a standard "build X using Y", where "Y" was modern Android tools (preferably Compose), and "X" was some non-descript hello world-ish app that did something I can't for the life of me remember. During one of the tech task evaluations we did prior to an interview, I encountered a strange animal completely unknown to me. A `UseCase` class, with an `operator fun invoke()` method.

It looked something like this:

```kotlin
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

Never had I ever (remember, I started my Kotlin/Java days @ Vipps, and they simply don't do that; it's also a no Go – pun intended).

This `UseCase` was then used like this:

```kotlin
val getProfile = GetProfileUseCase(someInjectedProfileRepo)

getProfile(userId)
```

## What my betters told me

...was that this whole UseCase layer (and especially the way the operator function was used!) was overengineering at its worst, and that the consept in general reeked of ye old Java from back when people didn't know any better. I was curious, but sadly not curious enough to do my own research back then. I made a mental note to check if the candidate was the over-engineering type in the actual interview (which, to my pleasant surprise, he really wasn't, and he got the job), and thought very little of it.

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

Bonus advice: if what your betters tell you seems off, make sure to do your own research and thinking as well; at the end of the day no-one shares your `git blame`.

## Just kidding, I wasn't done!

One might claim that simply using a service class is more convenient (KISS and all that). And I agree, it might be. However, there are reasons why use cases in the application layer is superior to just using a service class. Here are some key architectural benefits of the UseCase pattern:

## 1. Single Responsibility Principle

- A UseCase represents a single business use case/user story
- A service class typically groups related operations, potentially violating SRP
- When you have `MyService.getProfile()`, `MyService.updateProfile()`, `MyService.deleteProfile()`, you're bundling multiple responsibilities

## 2. Clean Architecture Boundaries

- UseCases explicitly represent application-specific business rules as a distinct architectural layer
- Services tend to become "catch-all" classes that blur the lines between use cases, domain logic, and infrastructure concerns
- This distinction is crucial for maintaining the Dependency Rule in Clean Architecture

## 3. Business Intent

```kotlin
// UseCase approach - clear business intent
class GetUserProfileUseCase(private val repository: ProfileRepository)
class UpdateUserProfileUseCase(private val repository: ProfileRepository)
class ValidateUserProfileUseCase(private val repository: ProfileRepository)

// Service approach - less clear business organization
class UserService(private val repository: ProfileRepository) {
    fun getProfile(id: String): Profile
    fun updateProfile(profile: Profile)
    fun validateProfile(profile: Profile)
}
```

## 4. Composition Over Inheritance

- UseCases are highly composable - you can combine them to create more complex use cases

```kotlin
class GetValidatedProfileUseCase(
    private val getProfile: GetUserProfileUseCase,
    private val validateProfile: ValidateUserProfileUseCase
)
```

## 5. Testing and Mocking

- While both approaches are testable, UseCases provide a more focused testing surface
- Each use case test covers exactly one business scenario
- Service tests often need more complex setup due to shared dependencies

## 6. The `invoke` Operator

- Again, it's not just syntactic sugar - it makes the UseCase behave like a first-class function
- This enables functional composition and makes the code more expressive:

```kotlin
val getProfile = GetProfileUseCase(repo)
val validateProfile = ValidateProfileUseCase(validator)
val profiles = userIds.map(getProfile).filter(validateProfile)
```

## 7. Package by Component?

- UseCases naturally support packaging by component as they represent discrete business capabilities
- Services often end up as cross-cutting concerns that make clean component boundaries harder to maintain

The service class approach isn't wrong - it's just solving a different problem. If you're building a simple CRUD application, services might be sufficient. But if you're building a complex domain with distinct business rules, UseCases provide better architectural boundaries, clearer business intent, and more maintainable code organization.

Architecture is about making it clear what the application does by looking at the structure of the code. A well-named UseCase like `GetValidatedProfileUseCase` immediately tells you what business capability it provides, while `UserService.getValidatedProfile()` hides this intent inside a more generic container.

## Update: Friendly Disclaimer and Reminder

If you're looking for a comprehensive guide to software architecture, this is not it. The purpose of my recent posts about software architecture is to explore some some principles in a practical way, principles I've previously been too quick to dismiss or too lazy to apply. I'm neither claiming mastery of these concepts, nor am I suggesting that these principles should be rigidly applied in every situation. I'm not even proposing that my brief examples are the best way to implement or even explain these principles. Rather, I'm documenting my attempts to bridge classical software engineering principles with contemporary development practices. In fact, I have yet to decide for my self how close to "Clean Architecture" I want to get in the end vs how pragmatic I want to be. But for now I'm (mostly) enjoying the learning and exploration. Keep that in mind before you harass me, Uncle Bob or anyone else on Reddit about it 😅

And to all of you who have disagreed with me in a meaningful and respectful way, thank you. It's been a great learning experience for me.

Thanks :)
