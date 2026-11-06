+++
title = "Go 1.27: encoding/json/v2, Stricter Defaults, and Finally [] for Nil Slices"
description = "encoding/json/v2 is stable in Go 1.27. Nil slices become [], duplicate keys and invalid UTF-8 are errors, case-insensitive matching is gone, and time.Duration has no default encoding. What changed, with code I ran on go1.27.3."
date = 2026-11-06
author = "Christian Ekrem"
tags = ["go", "golang", "json", "parse-dont-validate", "type-safety"]
categories = ["Programming", "Go"]
+++

The Go team [just shipped `encoding/json/v2`](https://go.dev/blog/jsonv2) as stable in Go 1.27. It's been available behind `GOEXPERIMENT=jsonv2` since 1.25, and I've been meaning to try it ever since (I never got around to it). So now I finally did.

First of all: I have some mixed feelings about `encoding/json`. It works fine most of the time, but it also accepts quite a lot of stuff it shouldn't, without telling you. Coming from Elm, where a decoder fails the moment something doesn't match, v1 always felt a bit too forgiving for my taste. v2 is a lot stricter, and I like it!

The snippets below run against `go1.27.3`. To use both versions side by side, the migration guide suggests this import:

```go
import (
 jsonv1 "encoding/json"
 "encoding/json/v2"
)
```

So `json.X` is v2 and `jsonv1.X` is the old one from here on.

## Nil slices are `[]` now

The classic: a frontend gets `null` where it expected an array, calls `.map` on it, and crashes.

```go
type Pet struct {
 Name      string
 Nicknames []string
 Tags      map[string]string
}

p := Pet{Name: "Fido"}
```

```
v1: {"Name":"Fido","Nicknames":null,"Tags":null}
v2: {"Name":"Fido","Nicknames":[],"Tags":{}}
```

Finally! Most Go code treats a nil slice and an empty slice the same way (you can `append` to it, `len` it, `range` over it), so it was always a bit odd that the JSON depended on which one you happened to have. Whether a client got `null` or `[]` came down to how the slice was created, not to anything the API meant. (Maps are a little different, since writing to a nil map panics, but the JSON argument is the same.)

If you _do_ depend on the `null` (and the migration guide assumes someone downstream does), there's an option for it:

```go
json.Marshal(p, json.FormatNilSliceAsNull(true))
// {"Name":"Fido","Nicknames":null,"Tags":{}}
```

`FormatNilMapAsNull` does the same for maps. Options are just extra arguments now, `Marshal(in any, opts ...Options)`, so you don't need an `Encoder` just to set one flag.

## Case-insensitive matching is gone

I'd actually forgotten v1 did this. It matches JSON keys to struct fields case-insensitively:

```go
type User struct {
 Name  string `json:"name"`
 Admin bool   `json:"admin"`
}

in := []byte(`{"name":"bob","ADMIN":true}`)
```

```
v1: {Name:bob Admin:true}
v2: {Name:bob Admin:false}
```

v1 took `"ADMIN"` and set `Admin` to true. Now say a gateway in front of your service rejects requests containing `"admin"`. It doesn't treat `"ADMIN"` as the same key, so the request goes through, and v1 happily makes Bob an admin. Two parsers disagreeing about the same payload is a pretty well-known way to get security bugs. Insecurity through obscurity, ish?

Note that v2 doesn't reject `"ADMIN"` either. It just ignores it, unless you turn on `RejectUnknownMembers` (more on that below).

If you need the old behavior (some third-party API that can't make up its mind about casing? Idk...), you can opt in per field with a tag, or for everything with an option:

```go
type User struct {
 Name  string `json:"name"`
 Admin bool   `json:"admin,case:ignore"`
}

// or, for everything:
json.Unmarshal(in, &u, json.MatchCaseInsensitiveNames(true))
```

I like that it's spelled out where it's used, so at least you can grep for it later. Also making "stupid" explicit is always good :D

## Duplicate keys and invalid UTF-8 are errors

Two more things v1 just... accepts:

```go
dup := []byte(`{"name":"bob","admin":false,"admin":true}`)
bad := []byte("{\"name\":\"b\xffob\"}")
```

```
dup  v1: <nil>, last one wins (Admin: true)
dup  v2: jsontext: duplicate object member name "admin"
utf8 v1: <nil>, Name: "b�ob"
utf8 v2: jsontext: invalid UTF-8 within "/name" after offset 10
```

Duplicate keys are the same kind of problem as the casing thing. Which `"admin"` is the real one depends on which parser you ask, so v2 rejects the input instead of picking one. Fair enough.

The error messages are also a lot better. `within "/name" after offset 10` is a JSON Pointer plus a byte offset, so you know exactly where the problem is. v1 mostly doesn't tell you that. Not quite elm compiler level helpfulness, but a step up for sure!

## time.Duration has no default

Lo and behold:

```go
type Job struct {
 Name    string        `json:"name"`
 Timeout time.Duration `json:"timeout"`
}

j := Job{Name: "backup", Timeout: 90 * time.Second}
```

```
v1: {"name":"backup","timeout":90000000000}
v2: json: cannot marshal from Go time.Duration within "/timeout": no default representation
```

In v1, a `time.Duration` is just an `int64` of nanoseconds, so that's what goes over the wire. Everyone consuming your API has to know the unit, and it's very easy to assume milliseconds on the other end.

There are several reasonable ways to encode a duration (nanoseconds, seconds, `"1m30s"`, ISO 8601), and none of them is obviously the right one. So v2 makes you choose instead of exposing the internal `int64`. (I tried a `format:` tag option on the field too, by the way; 1.27.3 rejects it with "unsupported `format` tag option".) The way to choose is the next section, which is also quite interesting.

## Caller-specified marshalers

In v1, if you wanted custom JSON for a type, you implemented `MarshalJSON` on it. That's fine for your own types, but it doesn't work for `time.Duration`, since you can't add methods to types you don't own. So you'd wrap it in `type MyDuration time.Duration` and convert back and forth everywhere, which isn't great.

v2 lets the _caller_ decide how a type is encoded:

```go
durAsString := json.MarshalToFunc(func(enc *jsontext.Encoder, d time.Duration) error {
 return enc.WriteToken(jsontext.String(d.String()))
})

b, _ := json.Marshal(j, json.WithMarshalers(durAsString))
// {"name":"backup","timeout":"1m30s"}
```

And the other way:

```go
parseDuration := json.UnmarshalFromFunc(func(dec *jsontext.Decoder, d *time.Duration) error {
 tok, err := dec.ReadToken()
 if err != nil {
  return err
 }
 parsed, err := time.ParseDuration(tok.String())
 if err != nil {
  return err
 }
 *d = parsed
 return nil
})

json.Unmarshal([]byte(`{"name":"backup","timeout":"1m30s"}`), &j, json.WithUnmarshalers(parseDuration))
// {Name:backup Timeout:1m30s}
```

That `UnmarshalFromFunc` reminds me a bit of an Elm decoder. It reads tokens and either fills in a `time.Duration` or returns an error, and you register it where you decode, not on the type. `Job` doesn't need a wrapper type for its `Timeout` field.

It's a step towards [parse, don't validate](/posts/parse-dont-validate-typescript/): turning wire data into a Go value happens in one place, at the edge. Only a step, though :D. A missing `"timeout"` still decodes to `0` without an error, and nothing stops you from writing `Job{Timeout: -1}`. A Go struct can't make invalid states unrepresentable the way an Elm custom type can.

There's also `JoinMarshalers` for combining several, so you can build one `*Marshalers` value for your API layer and pass it around.

## Two packages, not one

That `jsontext` import in the examples above is the other structural change. v2 splits JSON into two layers. `encoding/json/jsontext` only deals with _syntax_: tokens, values, a streaming `Encoder`/`Decoder` (no reflection!). `encoding/json/v2` handles _semantics_, meaning the mapping between JSON and Go types.

Most code will only ever call `json.Marshal` and won't care. But the custom functions above get a `*jsontext.Encoder` or `*jsontext.Decoder` instead of a `[]byte`, and that matters for performance.

## Performance

The blog post says `Marshal` is roughly on par with v1, while `Unmarshal` is "up to 10x" faster in their benchmarks. I haven't benchmarked it myself, so I'm taking their word for it.

The reason is mostly these two new interfaces:

```go
type MarshalerTo interface {
 MarshalJSONTo(*jsontext.Encoder) error
}

type UnmarshalerFrom interface {
 UnmarshalJSONFrom(*jsontext.Decoder) error
}
```

The old `UnmarshalJSON([]byte) error` forces the package to find the end of the value, slice it out and hand you the bytes, which you then parse _again_. Nest a few of those (OpenAPI schemas, for instance, which are recursive) and it gets slow fast. Kubernetes ran into exactly that in [kube-openapi](https://github.com/kubernetes/kube-openapi/issues/315), and switching to `UnmarshalJSONFrom` improved things "by orders of magnitude". The new interfaces also get the caller's options passed along, which the v1 ones never could.

## omitempty changed meaning (careful now...!)

If ever there was a single point to be extra careful during migration:

```go
type Opt struct {
 A string `json:"a,omitempty"`
 B int    `json:"b,omitempty"`
 C int    `json:"c,omitzero"`
 D *int   `json:"d,omitempty"`
}
```

```
v1: {}
v2: {"b":0}
```

In v2, `omitempty` means "omit if the _JSON_ would be empty": `null`, `""`, `[]` or `{}`. A zero `int` encodes as `0`, which isn't empty JSON, so it stays. If you meant "omit the Go zero value", that's `omitzero` (which v1 has also supported since Go 1.24). It's more consistent, and I think it's the right call, but it _will_ change some payloads without any error to warn you.

## Unknown fields, embedding and other small things

`json.RejectUnknownMembers(true)` is the v2 version of v1's `Decoder.DisallowUnknownFields`, and it works with plain `Unmarshal`, no decoder needed:

```
json: cannot unmarshal JSON string into Go main.User: unknown object member name "role"
```

There's also an `embed` tag option for flattening a struct field into its parent. It can't be combined with a name, so `json:"meta,embed"` is an error, while `json:",embed"` works:

```go
type Doc struct {
 Title string `json:"title"`
 Meta  Meta   `json:",embed"`
}
// {"title":"hi","version":2}
```

(Guess which one I tried first :P)

## So do I have to migrate?

No. `encoding/json` is covered by the Go 1 compatibility promise and isn't going anywhere. v1 is now _implemented on top of_ v2, with a full set of compatibility options, so the two work together: a type implementing `MarshalerTo` is honored by `jsonv1.Marshal` too.

So the safest migration is pretty boring. Switch your calls to v2, but pass the v1 defaults:

```go
b, err := json.Marshal(p, jsonv1.DefaultOptionsV1())
// {"Name":"Fido","Nicknames":null,"Tags":null}
```

The above will give same output as before; then turn off v1 behaviors one option at a time, since later options win:

```go
json.Marshal(p, jsonv1.DefaultOptionsV1(), json.FormatNilSliceAsNull(false))
```

For production services, the [migration guide](https://go.dev/doc/jsonv2-migration) describes [`jsonsplit`](https://github.com/go-json-experiment/jsonsplit), which runs both v1 and v2 on the same input and reports where they disagree. It roughly doubles your marshaling cost while it's on, but you can sample a fraction of calls. I'd do that for anything public-facing. The `omitempty` change alone is the kind of thing all your tests are happy with until some client isn't.

## Conclusion?

I've always thought of Go as a language that prefers boring and explicit over clever, and v1 was a bit un-Go-like in that sense: it guessed quite a lot. v2 guesses less. It still fills in zero values for missing fields and ignores unknown ones by default, so it isn't strict the way Elm is. But when it does say no, it tells you where.

It's still not an Elm decoder, but it's a lot closer than I expected Go to get. Not bad at all!

And JSON package implementation(s) aside, I still think it's cool that Go features JSON as something built in, without our needing to reach for anything third party!
