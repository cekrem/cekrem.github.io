+++
draft = false
date = 2025-05-23
title = "Passion"
description = "What (or rather Who) it's all about."
tags = ["passion"]
+++

It's Friday, and I'm up at 4am, wide awake, head filled with thoughts on recursive data structures and how to efficiently deal with them in our client's Elm application. I tried going back to sleep for a few minutes, but decided against it. My (Garmin) sleep score averages well above 90%, so I can deal with one slightly short night. _If I can just solve this puzzle_, it'll be more than worth it! I'm doing test driven development on this particular problem. Not because I want to be fancy or make a point, but out of necessity – the complexity is far beyond what I would entrust myself without some guard rails while I iterate on it. **It feels great**, and I'm already looking forward to the Sabbath moment when I can behold the work of my hands and see that it was good.

Suffice it to say I'm passionate about my job! Sure, there's a deadline coming up when we'll release our new application, and there's lots of work to be done before that. But that's not why I'm up early. I'm up because I want to make this great, and I love doing so – so much that I can't wait for the night to be over before starting! Making great things is a far greater motivation than meeting deadlines.

```elm
-- It works, I promise! And it's tail call optimized 🤤
flattenRecursiveMessage : RecursiveAIMessage -> List LinearAIMessage
flattenRecursiveMessage recursiveMessage =
    let
        flattenWithAcc acc msg =
            case msg of
                None ->
                    acc

                Leaf message ->
                    message :: acc

                WithSingleResponse ( message, response ) ->
                    flattenWithAcc (message :: acc) response

                WithMultiResponse ( message, selectedId, responseDict ) ->
                    case Dict.get selectedId responseDict of
                        Just selectedResponse ->
                            flattenWithAcc (message :: acc) selectedResponse

                        Nothing ->
                            message :: acc
    in
    flattenWithAcc [] recursiveMessage |> List.reverse
```

If you're reading this, I hope you get to experience doing something you're passionate about. Sure, there's a time and a place to simply do what needs doing. But there's something close to magic that happens when a human being does what he/she was made for, and it's quite something.

I'm enjoying this early morning, with an extra big cup of coffee (decaff, for sure, in case I suddenly slay this recursive tree dragon and want to go to sleep again!), down in the basement next to my drum kit. But there's something I'm far more passionate about, and I thought you should know.

There's a tradition in my consultancy where all new employees are interviewed, and [the interview is posted on enso.no](https://www.enso.no/feeden/velkommen-christian)(🇳🇴). It's mostly standard stuff; tech background, experience etc. But the last question leaves some leeway to go beyond that (and I did).

## "What do you do on your time off?"

There's plenty of room, facing this question, to give a quite shallow answer. We've already covered the "professional" side of things, so now I can list all my hobbies (if any) and be done with it – isn't that the idea? I could, but that would paint a very incomplete picture. So I had to say that I'm still married to the love of my life, the wonderful woman I proposed to at 18. **And, I had to close with the following statement: "Beyond all that, Jesus is most important of all."**

Because He Is.

Interests, fascinations and all that come and go. But there's one passion that won't (can't!) deteriorate over time, and his name is Jesus. Before getting up this early morning, He was there. Whether I succeed or not with this programming problem, he'll be there smiling at me. Awake or asleep, I'm at peace because I belong to him. I never work to obtain my identity, I work _from_ knowing how He sees me.

Here's one of my favorite artists and friends summing it all up, along with Jordan Peterson:

<iframe style="border-radius:12px" src="https://open.spotify.com/embed/track/7I3gzsNzG1QSIulABo5VwQ?utm_source=generator" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>

So beyond all else I write about on this blog, I thought you should know, that I say like King David of old:

> The one thing I ask of the Lord—
> the thing I seek most—
> is to live in the house of the Lord all the days of my life,
> delighting in the Lord’s perfections
> and meditating in his Temple.
>
> For he will conceal me there when troubles come;
> he will hide me in his sanctuary.
> He will place me out of reach on a high rock.
>
> Then I will hold my head high
> above my enemies who surround me.
> At his sanctuary I will offer sacrifices with shouts of joy,
> singing and praising the Lord with music.
>
> Hear me as I pray, O Lord.
> Be merciful and answer me!
> My heart has heard you say, “Come and talk with me.”
> And my heart responds, “Lord, I am coming.”
>
> Psalm 27, 4-8

And, speaking of passion, I'm confident he's more passionate about you than you've ever been about anything and anyone. I truly hope you get to know him, if you haven't.
