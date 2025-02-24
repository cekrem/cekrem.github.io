+++
title = "Refactoring Towards Cleaner Boundaries: Lessons from Building a Markdown Blog Engine"
description = "How the architecture of a Kotlin blog engine evolved"
tags = ["kotlin", "clean architecture", "refactoring", "tdd", "blog engine"]
date = "2025-02-25"
draft = false
+++

In [part 1](/posts/replacing-hugo-with-kotlin-clean-architecture), we laid out our Clean Architecture vision. In [part 2](/posts/double-loop-tdd-blog-engine-pt2), we explored Double Loop TDD. Today, we dive into the **refactoring journey** that emerged from implementing these principles.

The source code at the time of writing is [available on GitHub](https://github.com/cekrem/clean-blog/tree/v0.3).

## The Controller Conundrum

One of the most significant architectural changes in this iteration was moving the `ContentController` from the infrastructure layer to the **interface adapters layer**. This shift better aligns with Clean Architecture principles:

### Before (Infrastructure Layer)

```kotlin
// ... existing code ...
class ContentController(
    private val getContent: GetContentUseCase,
    private val listContents: ListContentsByTypeUseCase,
    private val getListableContentTypes: GetListableContentTypes,
    private val contentPresenter: ContentPresenter,
) {
    suspend fun handleHealthCheck(call: ApplicationCall) {
        call.respondText("OK")
    }
    // ... existing code ...
}
```

### After (Interface Adapters Layer)

```kotlin
class ContentController(
    private val getContent: GetContentUseCase,
    private val listContents: ListContentsByTypeUseCase,
    private val getListableContentTypes: GetListableContentTypes,
    private val contentPresenter: ContentPresenter,
) {
    suspend fun healthCheckResponse() = Response(statusCode = 200, body = "OK")
    // ... existing code ...
}
```

**Why This Matters:**

1. **Separation of Concerns**: The controller now focuses on adapting application output to the web layer, and knows nothing about Ktor or other infrastructure concerns
2. **Testability**: We can test the controller without Ktor dependencies
3. **Flexibility**: The same controller could be reused with different web frameworks

## The DTO Transformation

Another key change was introducing **DTOs (Data Transfer Objects)** for content presentation:

```kotlin
sealed class ContentBlockDto(
    open val blockTypes: Map<String, Boolean> = emptyMap(),
    open val properties: Map<String, Any?> = emptyMap(),
) {
    data class Heading(
        val text: String,
        val level: Int,
    ) : ContentBlockDto(
        blockTypes = mapOf("heading" to true), // this wouldn't make sense in the domain model, but most template renderers benefit greatly from this kind of data
        properties = mapOf("text" to text, "level" to level),
    )
    // ... other DTOs ...
}
```

**Benefits:**

1. **Clear Boundaries**: DTOs prevent domain models from leaking into the infrastructure layer (the presenter now gets a DTO, not a domain model)
2. **Flexibility**: We can change the presentation format without affecting the domain, and we can craft a DTO that's perfect for the specific output format we need rather than a generic domain model
3. **Testability**: DTOs are simple data structures that are easy to test

## The Testing Evolution

The test suite evolved significantly, particularly in the acceptance tests:

```kotlin
class ServeMarkdownBlogPostFeatureTest : FeatureAcceptanceTest() {
    @Test
    fun `should convert and serve markdown blog posts as properly formatted HTML pages`() =
        runTest {
            TestFixtures.blogPosts.forEach { (slug, post) ->
                // Given
                testApplication.givenBlogPost(slug = slug, content = post.markdownInput)

                // When
                val response = testClient.get("${testApplication.baseUrl}/posts/$slug")

                // Then
                assertEquals(post.expectedHtmlOutput.standardizeHtml(),
                           response.bodyAsText().standardizeHtml())
            }
        }
}
```

**Key Improvements:**

1. **Standardized HTML Comparison**: Added `standardizeHtml()` to handle formatting differences
2. **Fixture Management**: Introduced a `Fixture` data class for better test organization

## Lessons Learned

1. **Architecture is Iterative**: Even with a clear vision, the best structure emerges through implementation
2. **Boundaries Matter**: Clear separation between layers pays dividends in maintainability
3. **Testing Drives Design**: Good tests reveal architectural weaknesses and guide improvements

## Next Steps

In part 4, we'll explore how to handle **cross-cutting concerns** like caching and logging while maintaining our clean architecture. We should probably implement more Markdown rendering features as well. Stay tuned!

> **Pro Tip**: When refactoring, focus on one architectural boundary at a time. It's tempting to fix everything at once, but incremental improvements lead to better results.
