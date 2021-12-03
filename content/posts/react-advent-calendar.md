+++
title = "React Advent Calendar – keto vegan, gluten free and no parabens or plastic wrapping"
description = "When you want/need something a bit different"
tags = ["advent calendar", "advent", "christmas", "react"]
date = "2021-12-03"
+++

# TL;DR: I made an advent calendar in React, my wife loved it

I grew up with a lot of creative advent calendars. The one type I _didn't_ get was the standard chocolate one that's most common these days. While I've not consistently been very good at paying this forward, I do make an effort some years to do something a bit different for my wife. Yes, my wife; the kids get standard ones :P This year's plan was simple: create an online calendar with cozy favors, encouragements and the like each day until Christmas. I had planned to spend exactly one evening on this - the last evening of November, to be precise. But, my wife's plans for the evening evaporated as she decided she "really wanted to hang out with me at home" instead. Needless to say, I had to work quite fast.

The product (which is in norwegian, btw, sorry about that!) was mostly made while the rest of the family watched two episodes of "Bamselegen" (norwegian children's TV). I've made a few tweaks and added some content after that, mostly during bathroom breaks. **Point being: React is insanely effective!** The idealistic part of me wanted to do this in Elm, but I didn't dare given my lack of _real_ familiarity with it and my crazy time constraint. But I'll probably make an Elm version for comparison one day. Not now, though, now it's back to paternal leave until March. Yay!

Feel free to check out the [code](https://github.com/cekrem/adventskalender2021)!

It's hosted [here](https://birgitte.herokuapp.com/) (on Heroku's free tier, btw, so you might have to wait for a cold boot :D).

**Point two: [Heroku](https://www.heroku.com) is also insanely effective:** Signing up, connecting to github && deploying takes like half a minute. And after that CI/CD just works – it requires _no_ extra config; if your package.json makes even remotely sense, Heroku figures out the rest. Suck on that, A$ure.
