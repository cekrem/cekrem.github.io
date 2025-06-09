# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is Christian Ekrem's personal blog and portfolio website - a GitHub Pages hosted site using a hybrid architecture that combines **Hugo** (static site generator) with **Elm** (functional programming) for interactive components.

## Key Technologies

- **Hugo**: Static site generator with hugo-coder theme
- **Elm 0.19.1**: Powers interactive widgets (testimonials carousel)
- **Node.js tooling**: elm-tooling, elm-watch for development

## Common Commands

### Development
```bash
npm install     # Install dependencies and Elm tooling
npm start       # Start Hugo dev server + Elm hot reload
```

### Build
```bash
npm run build   # Compile Elm to optimized JS (static/widget.js)
hugo build      # Generate static site for production
```

### Elm Development
```bash
elm-watch hot   # Hot reload during Elm development (included in npm start)
```

## Architecture

### Content Structure
- `content/posts/` - Blog posts in Markdown with TOML frontmatter
- `static/testimonials.json` - Data source for Elm testimonials widget
- `src/Main.elm` - Entry point that mounts testimonials widget conditionally

### Elm Integration
- Elm compiles to `static/widget.js` which Hugo includes
- Testimonials widget only renders on specific pages (controlled by `activePaths` in `src/Testimonials.elm`)
- Widget receives current path as flags from JavaScript for conditional rendering
- Uses inline styles to avoid CSS conflicts with Hugo theme

### Build Process
1. `npm run build` compiles Elm with `--optimize` flag
2. Hugo includes the compiled `static/widget.js` in the site
3. JavaScript in footer mounts Elm app with current path as flags

## Key Files

- `config.toml` - Hugo site configuration
- `elm.json` - Elm project configuration
- `src/Testimonials.elm` - Main interactive component
- `layouts/partials/footer.html` - Elm integration point
- `static/testimonials.json` - Testimonial data
- `assets/scss/` - Custom SCSS overrides for hugo-coder theme

## Content Management

### Adding Blog Posts
Create markdown files in `content/posts/` with TOML frontmatter. Support for both single files and directories containing assets.

### Modifying Testimonials
1. Update `static/testimonials.json` for data changes
2. Modify `activePaths` in `src/Testimonials.elm` to control which pages show the widget

### Theme Customization
- Override templates in `layouts/partials/`
- Add custom styles in `assets/scss/`
- Theme uses CSS custom properties for easy customization