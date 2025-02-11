+++
title = "Replacing Hugo with a Custom Kotlin Blog Engine"
description = "A Clean Architecture adventure in potential over-engineering"
date = "2025-02-11"
tags = ["kotlin", "clean architecture", "blog", "ktor", "TDD"]
draft = false
+++

## Let's make a blog engine, ey?

Don't get me wrong - [Hugo](https://gohugo.io/) (the stuff that I'm currently using to drive this site) is great. It's blazing fast, feature-rich, and battle-tested. But as a developer who's been diving deep into Clean Architecture lately (as you might have noticed from my [recent](/posts/clean-architecture-and-plugins-in-go) [posts](/posts/interface-segregation-in-practice)), I've been itching to apply these principles to a real project. And what better way to learn than by potentially over-engineering my own blog engine?

## The Plan

Rather than just throwing together another quick web app, I'm attempting to build this the "right" way:

1. Following Clean Architecture principles to the letter
2. Using Test-Driven Development (TDD)
3. Keeping the codebase screaming its intent

## The Architecture

Following Uncle Bob's Clean Architecture principles, I've structured the project into clear layers:

```
src/main/kotlin/io/github/cekrem/
├── domain/                     # Core business entities and rules
│   └── model/                  # Content, ContentBlock, ContentType, etc.
├── application/               # Application-specific business rules
│   ├── config/               # Blog configuration (title, description, url, menu items etc)
│   ├── gateway/              # Port interfaces (ContentSource)
│   ├── parser/              # Content parsing interfaces
│   └── usecase/             # Application use cases
├── adapter/                  # Interface adapters
│   └── presenter/           # Presentation interfaces
└── infrastructure/          # External frameworks and tools
    ├── contentsource/       # File, Mock, and RSS implementations
    ├── factory/             # Dependency injection
    ├── parser/              # Markdown parsing implementation
    └── web/                 # Ktor setup, routes, and templates
```

### Domain Layer

The domain models are pure Kotlin data classes, representing the core concepts:

```kotlin
data class Content(
    val path: String,
    val title: String,
    val blocks: List<ContentBlock>,
    val type: ContentType,
    val metadata: Metadata,
    val publishedAt: LocalDateTime? = null,
    val updatedAt: LocalDateTime? = null,
    val slug: String = path.split("/").last(),
)
```

### Application Layer

The application layer contains use cases that orchestrate the domain logic. I'm using the `UseCase` interface pattern I discussed in [A Use Case for UseCases in Kotlin](/posts/a-use-case-for-usecases-in-kotlin):

```kotlin
interface UseCase<in I, out O> {
    suspend operator fun invoke(input: I): O
}

class GetContentUseCase(
    private val contentSource: ContentSource
) : UseCase<String, Content?> {
    override suspend fun invoke(input: String): Content? =
        contentSource.getByPath(input)
}
```

### Interface Adapters Layer

The adapters layer converts data between the formats most convenient for the use cases and external agencies. For this blog engine, the main adapter is the content presenter:

```kotlin
interface ContentPresenter {
    fun presentContent(content: Content): Any

    fun presentContentList(contents: List<ContentSummary>): Any
}
```

This layer ensures that our domain and application layers remain clean and independent of any presentation concerns. The `Any` return type provides maximum flexibility - implementations can return HTML strings, view models, or any other format needed by the infrastructure layer. This approach perfectly aligns with the Clean Architecture's dependency rule while keeping our options open for different presentation formats.

### Infrastructure Layer

The infrastructure layer handles the technical details of web serving (using Ktor), content storage, and template rendering:

```kotlin
fun startServer(
    getContent: GetContentUseCase,
    listContents: ListContentsByTypeUseCase,
    getListableContentTypes: GetListableContentTypes,
    contentPresenter: ContentPresenter,
    config: ServerConfig,
) {
    embeddedServer(Netty, port = config.port) {
        // ... Ktor setup
    }.start(wait = true)
}
```

## Why This Matters

1. **Separation of Concerns**: The domain logic knows nothing about Ktor, Mustache templates, or markdown parsing. It's pure business rules.

2. **Testability**: Each layer can be tested in isolation. The use cases don't need a web server to be tested.

3. **Flexibility**: Want to switch from Mustache to another template engine? Just create a new presenter implementation. Need to change how content is stored? The `ContentSource` interface makes that easy.

## Current Status

So far I've only got the basic scaffolding in place. The next steps are:

0. Add failing tests for everything; TDD for the win!
1. Implement the markdown parser
2. Add proper template rendering
3. Add RSS feed generation
4. (Implement beyond MVP features as needed)

## Is This Over-Engineering?

Probably! But that's not necessarily a bad thing when the goal is learning. As [The Pragmatic Programmer](https://amzn.to/4gjf4Ud) reminds us, sometimes you need to go too far to find out where "too far" actually is. I'd rather go to far now and learn from it.

The real test will be whether this ends up being more maintainable and adaptable than Hugo for my specific needs. At worst, I'll have learned a lot about Clean Architecture in practice. At best, I'll have a blog engine that perfectly fits my needs and is a joy to extend.

## Next Steps

I'll be documenting this journey as I go. The next post will likely focus on implementing the markdown parser while maintaining our clean architecture principles. But I'll write some failing tests first, and do go full TDD Stay tuned!

> "Architecture is about making it clear what the application does by looking at the structure of the code." - Uncle Bob

Check out Uncle Bob's [Clean Architecture](https://amzn.to/4gjf4Ud) book if you haven't already. It's a great read and a good reminder of what we're trying to achieve.

The code is available on [GitHub](https://github.com/cekrem/clean-blog/tree/v0.1) if you want to follow along or contribute. Just remember - this is very much a work in progress!

## Disclaimer

I can't promise I'll add to this project weekly, there are other things I'd like to write about as well. Stay tuned in any case!
