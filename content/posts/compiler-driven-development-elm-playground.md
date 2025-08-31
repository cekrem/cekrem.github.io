+++
title = "Compiler-Driven Development: Building an Elm Playground That Compiles in the Browser"
description = "How I built an interactive Elm workshop environment using Guida's in-browser compiler after server-side compilation hit memory limits"
tags = ["elm", "compiler", "guida", "workshop", "frontend", "functional programming", "in-browser compilation"]
date = "2025-08-31"
draft = false
+++

Sometimes the best solutions emerge from the ashes of failed approaches. This is the story of how I built [elm-playground](https://elm-playground.render.com) – an interactive Elm environment for teaching "compiler-driven development" – and how hitting memory limits forced me to discover something even better than my original plan.

## The Mission: Teaching Compiler-Driven Development

I've been planning to host an Elm workshop at [Ensō](https://enso.no) with a specific theme: "Compiler-driven development." The idea is to showcase how Elm's famously friendly compiler can guide your development process, catching errors before they become runtime surprises and helping you write better code through its helpful error messages.

But explaining the magic of compiler-driven development requires more than slides – it needs hands-on experience. I wanted workshop participants to feel the difference between "debugging by guessing" and "being guided by the compiler." That meant building an interactive playground where people could write Elm code and immediately see compilation results.

Granted, setting up Elm locally is not hard by any stretch of the word. But no setup is better than little setup!

## The Obvious Initial Approach

My initial plan was textbook simple:

1. Build a frontend with a code editor
2. Set up a backend that receives code via POST requests
3. Run `elm make` on the server
4. Return compilation results to the frontend

I even had it working! The Go backend would create temporary directories, write the submitted code to `Main.elm`, run the compiler, and return either success (with the compiled JavaScript) or failure (with error messages).

```go
// The original backend approach (simplified)
func compileHandler(w http.ResponseWriter, r *http.Request) {
    tmpDir := createTempDir()
    writeCodeToFile(tmpDir, requestBody.Code)
    defer removeTmpDir()

    cmd := exec.Command("elm", "make", "src/Main.elm", "--output=main.js")
    cmd.Dir = tmpDir

    output, err := cmd.Run()
    // Handle success/error cases...
}
```

It worked perfectly on my local machine. It worked perfectly in development. But the moment I deployed to production on Render.com's free tier...

```
failed
43b72b0
Ran out of memory (used over 512MB) while running your code.
```

## The Memory Problem

No matter what I tried, `elm make` consistently exceeded the 512MB memory limit. I attempted several optimizations:

- **Pre-warming `elm-stuff`**: Reusing compiled dependencies between requests
- **Symlinking instead of copying**: Reducing disk I/O overhead
- **Switching from Go to Node.js**, using the existing node-elm-compiler package: Using lighter runtime abstractions
- **Constraining `elm make`**: Looking for memory limit flags (spoiler: they don't exist)

Nothing worked. The Elm compiler, while excellent at its job, simply requires more memory than a free hosting tier provides for even simple programs. (_Allegedly_, that is – locally I could never reproduce this high memory consumption! But how and why that is is a different post.)

## Discovery: The Elm Community Has Solutions

Frustrated but not defeated, I turned to the Elm community Slack. The response was immediate and enlightening – several people had already solved this exact problem in different ways:

- One suggested [Ellie](https://ellie-app.com/new), the established Elm playground
- Others mentioned [elmrepl.de](https://elmrepl.de) and [elm-repl-worker](https://pithub.github.io/elm-repl-worker/eager-tea.html)
- Not least: [@deciojf](https://github.com/deciojf) introduced me to the [Guida/Try](https://guida-lang.org/try) PoC – a similar project using [Guida](https://guida-lang.org/), a port of the Elm compiler written in Elm itself

While Ellie would have worked, I wanted something I could customize and brand for our workshop. And Guida? That was intriguing.

## Enter Guida: Elm Compiling Elm

[Guida](https://guida-lang.org/) is a remarkable project – it's literally the Elm compiler ported to Elm, which means it can run in the browser via JavaScript. No server required, no memory limits, no deployment complexity.

The architecture is beautifully simple:

```elm
-- (The actual code has more to it, but the following is a simplified illustration)

-- Instead of HTTP requests to a backend:
type Msg
    = CompileCode String
    | CompilationComplete (Result Error String)

-- Guida handles compilation directly in the browser, using ports to pass source / compiled js:
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CompileCode sourceCode ->
            ( { model | status = Compiling }
            , sendSourceCodeToPortCmd sourceCode
            )

        CompilationComplete result ->
            case result of
                Ok compiledJs ->
                    ( { model | status = Success compiledJs }, Cmd.none )

                Err error ->
                    ( { model | status = Error error }, Cmd.none )
```

## The Journey to Working Solution

Getting Guida integrated wasn't without challenges, though. Initially I hit CORS issues while the browser fetched Elm packages. Apparently, <https://package.elm-lang.org> doesn't expect browsers to do any package fetching at all, so I needed to set up a proxy as an intermediate layer. And the errors I got from the compiler once I'd solved the CORS/Proxy issue were not pretty-printed text but rather JSON that needed massaging. These issues were luckily less of a "black box" than the weird memory stuff on cheap cloud hosting.

[@deciojf](https://github.com/deciojf), Guida's creator, pointed me to [`elm/project-metadata-utils`](https://package.elm-lang.org/packages/elm/project-metadata-utils/latest/) for proper error message decoding. I ended up borrowing his `viewError` function.

With some blood, sweat, tears and greatinsights from the awesome Elm community, I finally had a working solution. The final architecture is refreshingly simple:

1. **Pure frontend application** built with Elm
2. **Guida integration** for in-browser compilation
3. **No backend** required beyond static file hosting, and [a proxy](https://github.com/ensolabs/elm-playground/blob/master/index.cjs#L13) to Make Things Work™ when fetching Elm dependencies.
4. **Proper error formatting** using Elm's own error decoders

## The Final Result

[Elm Playground](https://elm-playground.render.com) now provides exactly what I wanted for the workshop:

- **Interactive code editing** with syntax highlighting
- **Real-time compilation** without server round-trips
- **Friendly error messages** formatted just like the CLI compiler
- **Zero infrastructure overhead** – just static files

More importantly, it perfectly demonstrates compiler-driven development. Workshop participants can:

1. Write invalid Elm code and see helpful error messages
2. Fix errors guided by compiler suggestions
3. Experience the confidence that comes with "if it compiles, it works"
4. Understand why Elm developers love their compiler

The final two exercises don't work yet, because they have additional package dependencies not found in the deault `elm.json` file in Guida. But I'm quite confident I'll be able to solve that quite quickly 🤓

## Why This Solution is Better

The journey from server-side to client-side compilation turned out to be more than just a workaround – it's actually superior in several ways:

### 1. **Instant Feedback**

No network latency means compilation results appear immediately. This makes the compiler-driven development cycle feel natural and responsive.

### 2. **Scalable by Default**

Since compilation happens on the user's machine, the playground can handle unlimited concurrent users without additional infrastructure.

### 3. **Offline Capable**

Once loaded, the playground works without internet connectivity – perfect for workshop environments with unreliable WiFi.

### 4. **Lower Operating Costs**

Static file hosting is essentially free compared to maintaining server-side compilation infrastructure.

### 5. **Better Privacy**

Code never leaves the user's browser, addressing any potential concerns about code privacy.

## The Meta-Experience

There's something delightfully meta about this solution. The workshop is about compiler-driven development, and the tool we're using to teach it exemplifies the principle perfectly:

- **Elm code compiling Elm code** in the browser
- **Type safety** throughout the compilation pipeline
- **Impossible states** made impossible by Guida's architecture
- **Helpful errors** at every layer

It's Elm all the way down, and it works beautifully.

## Lessons Learned

Building elm-playground taught me several valuable lessons:

### 1. **Constraints Drive Innovation**

The 512MB memory limit felt like a showstopper, but it forced me to discover a fundamentally better solution.

### 2. **Community Knowledge is Invaluable**

The Elm community's willingness to share experiences and solutions was crucial to success. (Good luck having GPT-whatever giving you advice is these scenarios...)

### 3. **In-Browser Compilation is Powerful**

Tools like Guida open up new possibilities for educational and development environments.

### 4. **Simple Solutions Scale**

The final architecture is much simpler than the original server-side approach, yet more capable.

## Looking Forward

Elm Playground is just the beginning. The success of in-browser compilation opens up interesting possibilities:

- **Multi-file projects** with proper module structure
- **Package installation** and dependency management
- **Interactive tutorials** with progressive skill building
- **Code sharing** and collaborative editing
- **Integration with other tools** in the Elm ecosystem

The foundation is solid, and the community is active. I'm excited to see where this goes.

Bonus: I was also invited to collaborate on [Guida](https://github.com/guida-lang/compiler), and I think I just might 🤓

## Try It Yourself

[Elm Playground](https://elm-playground.render.com) is live and ready for exploration. Whether you're teaching Elm, learning compiler-driven development, or just curious about in-browser compilation, I encourage you to give it a try.

The source code is available on [GitHub](https://github.com/ensolabs/elm-playground), and contributions are welcome. Special thanks to [@deciojf](https://github.com/deciojf) and the Guida project for making this possible.

## Conclusion

Sometimes the best engineering solutions come from embracing constraints rather than fighting them. What started as a simple backend compilation service evolved into something much more interesting: a demonstration of Elm's potential for meta-programming and self-hosting.

The elm-playground project proves that compiler-driven development isn't just a teaching concept – it's a practical approach that can lead to elegant, efficient solutions. And when your playground for teaching compiler-driven development is itself an example of compiler-driven development working beautifully... well, that's just good teaching.

At the time of writing this project has already been forked by my betters, as it turns out to be quite interesting in more ways than expected.

I'm glad I didn't give up!
