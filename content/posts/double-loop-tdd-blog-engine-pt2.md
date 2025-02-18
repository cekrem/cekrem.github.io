+++
title = "Double Loop TDD: Building My Blog Engine the Right Way (part 2)"
description = "How I'm using Double Loop TDD to build my blog engine"
tags = ["tdd", "kotlin", "clean architecture", "testing", "blog engine"]
date = "2025-02-18"
draft = false
+++

## From Hugo to Kotlin: The Journey Continues

In my [previous post](/posts/replacing-hugo-with-kotlin-clean-architecture), embarked on a bold and ambitious journey to replace Hugo with a custom Kotlin-based blog engine built using Clean Architecture principles (to the letter!). Today, I want to dive deeper into the development process, specifically how I'm using **Double Loop TDD** to ensure the quality and maintainability of the system. Again, I'm trying to go all-in, basically to see how far is too far, and to learn and explore.

## What is Double Loop TDD?

[Double Loop TDD](https://khalilstemmler.com/articles/test-driven-development/introduction-to-tdd/#Double-Loop-TDD) is an approach that combines two testing cycles:

1. **Outer Loop (Acceptance Tests)**: High-level tests that verify the system's behavior from the user's perspective
2. **Inner Loop (Unit Tests)**: Low-level tests that verify the implementation details of individual components

The key idea is to write an acceptance test first, watch it fail, then use unit tests to drive the implementation that makes the acceptance test pass. The unit tests will traverse the layers of the clean architecture, starting from the domain layer and working their way down to the nitty-gritty infrastructure layer, until they all - along with the acceptance test - pass. When done, you'll ideally have a system that is both robust and easy to maintain (or that's the plan, at least). With 100% test coverage, of course.

!["Double Loop TDD Illustration"](https://khalilstemmler.com/img/blog/tdd/intro/double-loop-tdd.svg)

> Image borrowed from [khalilstemmler.com](https://khalilstemmler.com/), in return I guess it's only fair I recommend his [Solid Book](https://solidbook.io/)

## The Current State of the Blog Engine

The source code for this project can be found [here](https://github.com/cekrem/clean-blog/tree/v0.2). Please note that I'm right in the middle of development as I'm writing this, so this project is by no means finished. Here's where I'm at in the development process:

1. **Acceptance Tests**: I've written the `ServeMarkdownBlogPostFeatureTest` that verifies the end-to-end behavior of serving markdown posts as HTML
2. **Domain Layer**: Complete with tests
3. **Application Layer**: Complete with tests
4. **Interface Adapter Layer**: This layer is quite thin, abstract and empty for now, nothing really to test. I'm thinking about moving the controller to this layer, and return a generic type rather than using the ktor-specific `call.respond()` that put it in the infrastructure layer in the first place. WIP indeed!
5. **Infrastructure Layer**: Markdown parsing is working, but HTML transformation needs work, or in more general terms: the input device (markdown to domain model) is working, but the output device (domain model to HTML) is not working yet.

I'm coming to like this approach more than I'd planned. It's forcing me to think about the system in a more holistic way, and to consider the interactions between the layers. Strangely it's also forcing me to focus more on the individual components, and testing them in isolation (which wouldn't even be possible without this die-hard Clean Architecture setup).

## The Acceptance Test in Action

Here's a snippet of the acceptance test that's driving the development:

```kotlin
class ServeMarkdownBlogPostFeatureTest : FeatureAcceptanceTest() {
    @Test
    fun `should convert and serve markdown blog posts as properly formatted HTML pages`() =
        runTest {
            TestFixtures.blogPosts.forEach { post ->
                // Given a blog post exists
                testApplication.givenBlogPost(
                    slug = post,
                    content = TestFixtures.readMarkdownPost(post),
                )

                // When requesting the blog post
                val response = testClient.get("${testApplication.baseUrl}/posts/$post")

                // Then it should return properly formatted HTML
                assertEquals(HttpStatusCode.OK, response.status)
                assertEquals(
                    ContentType.Text.Html.withCharset(Charsets.UTF_8),
                    response.contentType(),
                )
                assertEquals(TestFixtures.readHtmlFixture(post), response.bodyAsText())
            }
        }
}
```

The test uses markdown and HTML fixtures to verify that this markdown:

```markdown
---
title: Hello, World!
description: This is the description
---

## Basic content

This is my first blog post. Welcome to my blog!
```

will be transformed into this HTML:

```html
<!doctype html>
<html>
  <head>
    <title>Hello, World!</title>
    <meta charset="utf-8" />
    <meta content="This is the description" name="description" />
  </head>
  <body>
    <h1>Hello, World!</h1>
    <h2>Basic content</h2>
    <p>This is my first blog post. Welcome to my blog!</p>
  </body>
</html>
```

(The actual fixtures contain a bit more complex content, I simplified it a bit in this post to avoid spamming with long code blocks.)

For now, it's not nearly there. But I'm getting closer, one unit test at a time. Which is a lot better than just coding blindly until it happens to work (good luck refactoring the mess you've made without breaking stuff with that approach).

## Next Steps

0. (**Get layers in order?** Try again to move the controller to the adapter layer, it probably belongs there)
1. **Write Unit Remaining Unit Tests**: Let's get 100% coverage on that infra layer too!
2. **Implement Transformation**: Make the output device (domain model to HTML) work
3. **Refactor**: Clean up the code while keeping all tests passing
4. **Extend Features**: Add support for more markdown elements and custom templates

## Lessons Learned So Far

1. **Acceptance Tests are Powerful**: Having clear acceptance criteria makes it easier to focus development efforts
2. **Layered Testing Works**: Testing at different levels (acceptance, unit) provides confidence in the system
3. **Using Double Loop TDD makes testing efforts a lot more structured and predictable**: Both progress and path becomes very transparent and measurable
4. **Infrastructure is Tricky**: The infrastructure layer often requires more attention than expected – it's a great idea to keep it in its own layer. Clean architecture makes sense!

Stay tuned for the next post where I'll share how I tackled the HTML transformation challenge and the lessons learned along the way! Or how I gave up on it all and went back to Hugo, haha. We'll see.

> **Pro tip**: When working with Double Loop TDD, focus on one failing unit test at a time. It's tempting to try to solve everything at once, but incremental progress leads to better results.
