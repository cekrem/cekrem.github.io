---
title: "Clean Architecture: A Practical Example of Dependency Inversion in Go using Plugins"
description: "Let's make Dependency Inversion and other SOLID principles Great Again™"
tags: ["go", "golang", "architecture", "SOLID", "plugin"]
date: 2025-01-07
---

## Introduction

I've lately enjoyed revisiting the [SOLID Design Principles](//en.wikipedia.org/wiki/SOLID). In the world of software architecture, few principles have stood the test of time like these. I find the "Dependency Inversion Principle" particularly interesting, as it's one of the few that are either forgotten in modern applications, or drowned in so much over-engineering that the cost/benefit equation is offset anyways.

**Note:** Clean Architecture encompasses _far more_ than individual SOLID principles - including concentric dependency circles, strict boundary rules, and comprehensive architectural patterns - but we need to start somewhere. This article kicks off a series exploring some of these principles, starting with DIP, which I've found to be particularly neglected on projects that I've contributed to lately.

> The Dependency Inversion Principle states:
>
> 1. High-level modules should not import anything from low-level modules. Both should depend on abstractions (e.g., interfaces).
> 2. Abstractions should not depend on details. Details (concrete implementations) should depend on abstractions.

Today, let's explore how Go's plugin system enables these principles.

The complete code for this article can be found at [github.com/cekrem/go-transform](https://github.com/cekrem/go-transform).

Also, kudos to Uncle Bob for reminding me about the importance of good **software architecture** in his classic [Clean Architecture](https://amzn.to/4iAc8o1)! Without it, we'll all be building firmware (my paraphrased summary).

## Understanding the Landscape

While many languages implement modularity through external dependencies (like DLLs in C# or JARs in Java), Go takes pride in its ability to compile into a single, self-contained executable. This approach brings several advantages:

- Simplified deployment and versioning
- Elimination of dependency conflicts
- Reduced operational complexity

Honestly, it's one of the things I enjoy when working with Go! However, there are scenarios where a plugin architecture becomes valuable - particularly when you need to:

- Add functionality without recompiling the core application
- Allow third-party extensions
- Isolate different components for better maintainability

Go provides a built-in solution for these cases through its `plugin` package. While less commonly known than other language's module systems, it offers a clean and pragmatic approach to extensible architecture that aligns well with Go's philosophy of simplicity. And congrats for great and simple naming. "Plugin" – it is what it is.

## Clean Architecture in Practice

Let's examine a proof-of-concept project that demonstrates some of these principles. The project implements a simple transformation pipeline where plugins can modify input data. Let's make the Dependency Inversion Principle (DIP) the centerpiece of our system.

### The Core Domain

At the heart of our system lies the transformer interface:

```go
// Transformer defines the interface for data transformation operations.
type Transformer interface {
    // Transform processes the input bytes and returns transformed bytes or an error.
    Transform(input []byte) ([]byte, error)
}

// Plugin defines the interface for plugin implementations.
type Plugin interface {
    // NewTransformer creates and returns a new Transformer instance.
    NewTransformer() Transformer
}
```

This interface represents our core business rules. Notice how it's simple and stable - it doesn't depend on any implementation details.

### Plugin Implementation

Here's how a simple passthrough plugin implements this interface:

```go
// passthroughPlugin implements transformer.Plugin without requiring any state.
type passthroughPlugin struct{}

// NewTransformer returns a new passthrough transformer instance.
func (passthroughPlugin) NewTransformer() transformer.Transformer {
    return &passthroughTransformer{}
}

// passthroughTransformer implements transformer.Transformer without requiring any state.
type passthroughTransformer struct{}

// Transform implements transformer.Transformer by returning the input bytes unmodified.
func (pt passthroughTransformer) Transform(input []byte) ([]byte, error) {
    return input, nil
}

// Plugin exports the passthrough transformer plugin for dynamic loading.
var Plugin transformer.Plugin = &passthroughPlugin{}
```

The beauty of this approach is that plugins are completely isolated from each other and only depend on the core interfaces.

## Dependency Inversion in Action

Our processor component demonstrates DIP perfectly:

```go
// Processor manages the loading and execution of transformation plugins.
type Processor struct {
    plugins map[string]transformer.Plugin
}

// NewProcessor creates and initializes a new Processor instance.
func NewProcessor() Processor {
    return &Processor{
        plugins: make(map[string]transformer.Plugin),
    }
}
```

Notice how the `Processor` depends on abstractions (`transformer.Plugin`), not concrete implementations. This is DIP in its purest form.

## The Plugin System at Work

The main application loads plugins dynamically:

```go
proc := processor.NewProcessor()

// Load plugins from the plugins directory relative to the executable.
pluginsDir := filepath.Join(execDir, "plugins")
plugins, err := filepath.Glob(filepath.Join(pluginsDir, "*.so"))
if err != nil || len(plugins) == 0 {
    log.Printf("Failed to list plugins: %v\n", err)
    os.Exit(1)
}

for _, plugin := range plugins {
    if err := proc.LoadPlugin(plugin); err != nil {
        log.Printf("Failed to load plugin %s: %v\n", plugin, err)
        continue
    }
}
```

This approach offers several benefits:

1. Plugins can be developed and deployed independently
2. The core application remains stable
3. New functionality can be added without modifying existing code

## Applying This to APIs

This pattern could be extended to API development. Imagine:

```go
type APIPlugin interface {
    RegisterRoutes(router Router)
    GetBasePath() string
}
```

Each plugin could handle a different API domain:

- `/users/*` routes in a users plugin
- `/products/*` routes in a products plugin
- `/orders/*` routes in an orders plugin

## Build System Integration

The project uses a Makefile to manage plugin compilation:

```makefile
# Go commands
GO := go
GOBUILD := $(GO) build
GOCLEAN := $(GO) clean

# Directories
BUILD_DIR := build
PLUGIN_DIR := plugins
CMD_DIR := cmd

.PHONY: all
all: build plugins

.PHONY: build
build:
    @mkdir -p $(BUILD_DIR)
    $(GOBUILD) -o $(BUILD_DIR)/transform $(CMD_DIR)/main.go

.PHONY: build-plugins
build-plugins:
    @mkdir -p $(BUILD_DIR)/plugins
    @echo "Building plugins..."
    @for plugin in $(PLUGIN_DIR)/*/ ; do \
        if [ -f $$plugin/go.mod ]; then \
            plugin_name=$$(basename $$plugin); \
            echo "Building plugin: $$plugin_name"; \
            cd $$plugin && go mod tidy && \
            $(GOBUILD) -buildmode=plugin -o ../../$(BUILD_DIR)/plugins/$$plugin_name.so || exit 1; \
            cd ../../; \
        fi \
    done
```

This ensures plugins are built with the correct flags and placed in the appropriate directory.

## Key Takeaways

1. **Clean Architecture** and the **SOLID** design principles enforces separation of concerns and makes the system more maintainable
2. **Dependency Inversion** in particular ensures our core business logic depends only on abstractions
3. **Plugin Systems** provide a practical way to implement these principles
4. This approach scales well from simple transformations to complex API systems

## Conclusion

Go's plugin system exemplifies the language's commitment to simplicity and pragmatic design. By providing a straightforward, powerful foundation for building modular systems, it demonstrates that complexity isn't necessary for sophistication. Combined with Clean Architecture principles, it enables us to create systems that are both flexible and robust.

The real power comes from this simplicity: by focusing on clear interfaces and proper dependency management, we can create systems that are easy to extend and maintain, whether we're building simple transformation pipelines or complex API services.

For more details and the complete implementation, check out the project repository at [github.com/cekrem/go-transform](https://github.com/cekrem/go-transform).
