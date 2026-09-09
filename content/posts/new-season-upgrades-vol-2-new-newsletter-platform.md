+++
date = 2026-09-09
title = "New Season Upgrades Vol 2: New Newsletter Platform!"
description = "The newsletter moves to Buttondown, and one (1) duplicate email is headed your way. Sorry about that."
tags = ["new season", "upgrades", "newsletter", "buttondown"]
draft = false
+++

The migration season continues! In [Volume 1](/posts/new-season-upgrades-vol-1-leaving-gmail/) I finally moved my _incoming_ mail from Gmail to Protonmail. Today it's the outgoing kind: the newsletter (that thing that pings you whenever I post here) is moving to [Buttondown](https://buttondown.com).

The old setup was follow.it, and to be fair, it did its job. Emails went out, people got them. But it never felt like something I'd pick twice, and rather than listing my grievances I'll just show you the old subscribe form that lived at the bottom of this very page:

```html
<form
  action="https://api.follow.it/subscription-form/SDRVMUk2VmsySENBNk94RDNKNDFnS3NmWlQ5a3gxejNIeUlJWHl3QjdqNnRHdENkaXp5aXZhZlFvcGtzcEZ3K0o5TFVRdSt2WWM5RWRsWmZwWVhNUS9PZjJqMWZ3aHBwZUhjT1ZpWXBGRkdZOWtIcGhYQkJkSkE4QTQ1eHl5YkF8RTZHTExQOWFrN1pFY1F0RzZ5c3pVN2I1QTI1YXNtMjZiYllLU25zQkJ3bz0=/8"
></form>
```

And here's the new one:

```html
<form action="https://buttondown.com/api/emails/embed-subscribe/cekrem"></form>
```

I rest my case.

Buttondown is the kind of tool I wish more of the web was made of: a small crew that actually seems to _like_ email, writing in plain markdown, an API that makes sense, and tracking you can simply turn off. Minimal and developer friendly, in other words. My kind of thing.

## So what changes for you?

From now on, newsletter emails will come from **<hi@cekrem.dev>** (or possibly **<cekrem@buttondown.email>** while domain verification is ongoing). If your spam filter is the trigger-happy type, now would be a great time to add that address to your contacts. This very post is the only one (hopefully!) going out from _both_ the old and the new sender, so if it shows up twice in your inbox: sorry, but also, working as intended.

(While I was elbow-deep in the footer anyway, I ripped out the PostHog analytics snippet as well. The whole migration diff ended up at 5 lines added, 66 removed. My favorite type of diff.)

If you got this email zero times instead of two, the shiny new subscribe box at the bottom of this page is happy to fix that 👇

_Please_ let me know if anything breaks 😅
