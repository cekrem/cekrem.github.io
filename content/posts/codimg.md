+++
title = "codimg: code blocks -> syntax highlighted SVG"
description = "Webflow mangles code blocks, so I made a little Go + Elm tool that renders them as SVG instead. The fun part: there's no database -- your code lives, compressed, inside the image URL."
tags = ["go", "elm", "svg", "side project", "functional-programming", "webflow"]
date = 2026-06-02
draft = false
+++

Leaving my _general_ dislike for Webflow aside for now, let's at least agree on one specific thing: it is terrible at code. We have [markdown.enso.no](https://markdown.enso.no) for the actual writing -- you draft in markdown, it gives you something you can paste straight into Webflow's WYSIWYG editor -- and that pipeline is fine, right up until there's a code block in it. Then it falls apart. Smart quotes where you typed straight ones, your indentation quietly flattened, the whole thing landing in the body font like it's a line from a brochure. There are workarounds (an embed block, or an iframe if you really hate yourself), and not one of them is nice.

So I made [codimg](https://github.com/ensolabs/codimg). The _why_ is that paragraph above. The _what_ turned out to be the fun part, so that's the part I actually want to talk about.

**TL;DR: `codimg` transforms code to a syntax highlighted SVG that you can embed anywhere!**

And it's completely stateless and pure: code in (as part of query param) -> svg out!

## It's just an image

Here's the entire integration story:

```html
<img src="https://codimg.alwaysdata.net/code.svg?input=...&lang=go" />
```

That's it. It's an image. Webflow can render an image. So can email, Notion, a GitHub README, a PDF, your mum's fridge if you print it out. Anywhere an `<img>` works -- which is everywhere -- a syntax-highlighted code block now works too. No embed script, no widget to initialize. The browser already knows how to fetch a URL and draw whatever picture comes back. We just made the picture be your code.

Here, type some code and watch the image update as you go:

<iframe src="https://codimg.alwaysdata.net" style="width:100%; height:500px; border:0; border-radius:8px; overflow:hidden;" sandbox="allow-forms allow-scripts allow-same-origin"></iframe>

## Where does the code live?

Look closer at that `src`. There's no id in it. No `?gist=abc123` pointing at a row in some database we have to host and back up forever. The code _is_ the URL.

On the frontend (Elm, because of course it is) the encoding reads top-to-bottom like a sentence:

```elm
encodeCodeBlock : String -> String
encodeCodeBlock =
    Encode.string
        >> Encode.encode
        >> Flate.deflate
        >> Base64.fromBytes
        >> Maybe.withDefault "invalid data"
        >> Url.percentEncode
```

String to bytes, deflate-compress it, base64 it, make it URL-safe. The Go backend reads the same sentence backwards -- percent-decode, un-base64, inflate -- and gets your source back. Two codebases, two languages, held together by a wire format that neither file bothers to write down anywhere. The contract is the whole design, and it's completely implicit. (I have feelings about that. They're mostly good feelings.)

What I like is that nothing is _stored_. There's no document to lose, no migration, no "where did that snippet go." A code block became a value you can paste into a chat window. The address bar is the database.

## No headless Chrome was harmed

The obvious way to turn code into an image is to boot a headless Chrome, render an HTML code block, and screenshot it. That's hundreds of megabytes of browser to produce a blurry PNG. codimg doesn't do any of that. It writes the SVG by hand:

```go
fmt.Fprintf(w, `<tspan fill="%s">%s</tspan>`, tok.Color, svgEscaper.Replace(tok.Text))
```

[Chroma](https://github.com/alecthomas/chroma) (genuinely great Go library) does the lexing -- you hand it source plus a language name and it hands back tokens with types. We ask the gruvbox theme for the colour of each token type, then emit one `<tspan>` per token. That's the renderer.

And because it's a monospace font, the hard problem in any text renderer -- working out where each glyph goes -- collapses into arithmetic:

```go
width := int(float64(maxLen)*charWidth) + paddingX*2
```

`charWidth` is `9.6`. That is the entire layout engine. No font metrics, no measuring, no line-breaking logic. Multiply by the longest line, add some padding, done. SVG means the result is vector (crisp at any zoom), it's tiny, and the text inside the image is still, technically, text.

## The tape holding it together

It's held together with a bit of tape, and I'd rather show you where than pretend otherwise.

base64's standard alphabet uses `+`, and `+` in a URL means a space, so for a brief and stupid window I was manually swapping characters back and forth on both ends. The git log preserves my shame faithfully: a commit called `replace _ -> +`, then one called `don't manually replace + -> -`. (The actual fix was using the right encoding in the first place. It usually is.)

The decoder is a guesser, not a parser. It tries to base64-decode the input, and if that fails it just shrugs and treats whatever you sent as plain text:

```go
raw, ok := tryBase64(s)
if !ok {
    return s
}
```

Fine until it isn't. And there's a `Maybe.withDefault "invalid data"` sitting up in that Elm pipeline that quietly turns a failure into a perfectly normal-looking string and ships it as if it were your code. Scott Wlaschin would point out, very politely, that I've taken a perfectly good `Maybe` and lied about it. He'd be quite right; the honest version models the two cases instead of flattening one into a magic string. I'll get to it.

Also `charWidth = 9.6` assumes exactly one font at one size, and a wide CJK glyph gets counted as a single cell when it really wants two, so anything with Chinese in it spills out of its box a little. Nothing is cached either -- every request re-tokenizes from scratch. For an internal tool whose whole job is drawing code blocks for a website, none of this has bitten us yet.

It's all on GitHub: [github.com/ensolabs/codimg](https://github.com/ensolabs/codimg). If your CMS keeps picking fights with you over code blocks, steal it.
