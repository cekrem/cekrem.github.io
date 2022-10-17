+++
title = "Development plan 2021-2023"
description = "Level up with a plan!"
date = "2022-10-06"
tags = ["vipps", "personal development", "career"]
+++

What follows is my own personal development plan as a software engineer at [Vipps](https://vipps.io). Some terms and
expressions are a bit internal, as they will no doubt be for you as well on your own plan (should you find yourself
inspired to write one), but I'll leave it as is. Enjoy!

---

## Context

I've been at [Vipps](https://vipps.io) since 2018, mostly doing work that now belongs in the "Merchant Core" team. I
created a few small backend services from scratch (a very fun QR code generator, to name one), deprecated a few others (
let's not name those ever again...), helped kick off the Vipps Design System and most significantly worked on the Vipps
Merchant Portal and on automating merchant signup, risk analysis and onboarding. I've hosted a Vipps Community Of
Practice plainly called "Side Projects And Experiments" (SPÆ) where I've touched on quite a lot of exciting tech and
tried a few non-mainstream programming languages. Still 90% of my "real" work has been with Golang and React. And
lot's(!) of complex SQL. [In mid 2020, I decided to expand my horizon and challenge myself by doing something completely
other](/posts/changing-jobs-without-leaving-your-company); I learned Kotlin during my summer holidays, and joined the
Android app to learn from Norway's best app
developers. So the Android team is where I'm at now; the ~eCom~ Recurring Payments and Vipps Login subteams more
specifically.

## What do I want to be doing that I'm not doing now?

On my previous team, I had a reputation for getting stuff done and delivering value efficiently. I also did quite a bit
of mentoring and had a few internal talks on Golang development, and did the occasional "Show and Tell" on frontend
stuff. I want to grow into being able to do the same on my new team, where I'm less technically experienced (Android
development) and have less domain knowledge (eCom and apps in general). As an Android developer, I would like to obtain
the same skill level and expertise that I currently have in Golang and React. I want to keep being an empowering mentor
in the new team as well, and bring value to the company both through mentoring/sponsoring and actual code. I'd like to,
in time, become the CPS – Chief Problem Solver – on all tings Android/eCom specific, and provide meaningful insight from
my combined backend and app development experience.

<!--## Growth areas-->

<!--| Skill | Details /examples |-->
<!--| ----- | ----------------- |-->
<!--| TBA   |                   |-->

## Hall of Fame

| Achievement                                                                                                                                                                                               | Notes                                                                                                                                                                                           | Date       |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| Created proper development plan                                                                                                                                                                           | I've put this off for a while, so finishing it before summer vacation feels _ great_!                                                                                                           | 2021-07-07 |
| Created a surprisingly delightful tech blog :O                                                                                                                                                            | ... Initially just to host the above mentioned development plan. But hey!                                                                                                                       | 2021-07-07 |
| Codility August Challenge: [Golden award](https://app.codility.com/cert/view/certHZPW7W-29SSPZM7YGG6S5C9/)!                                                                                               | This one took a few tries, but it was generally a lot of fun!                                                                                                                                   | 2021-08-18 |
| Released the first version of the Vipps app (2.94) featuring JetPack Compose!                                                                                                                             | On ConfirmVippsLoginFragment, to be specific. Part of the thorough refactoring planned before my parental leave.                                                                                | 2021-09-06 |
| Finished cleanup and refactoring of the Vipps Login module (including more Compose)!                                                                                                                      | Tech debt, begone!                                                                                                                                                                              | 2021-09-30 |
| Became the main Android contact person for Vipps Login                                                                                                                                                    | And contributed to assigning contact persons for other areas as well to minimize context switching and improve efficiency                                                                       | 2021-09-23 |
| Hosted Jetpack Compose Workshop                                                                                                                                                                           | Showcasing compose tests and hybrid tests (composables/views)                                                                                                                                   | 2021-09-25 |
| Codility September Challenge: [Golden award](https://app.codility.com/cert/view/certYKAH4G-WBU8JZU38KNHW964/)!                                                                                            | Brute force > elegance on this one. But it works :D                                                                                                                                             | 2021-10-04 |
| Codility October Challenge: [Golden award](https://app.codility.com/cert/view/certA2U46J-NJ2WZX68FWEC8DQN/)!                                                                                              | Brute force yet again. I did get silver with some nice fold'n'reduce in Kotlin, but apparently it was too slow: [Silver award](https://app.codility.com/cert/view/cert7BVS9Q-X9N2NRDY6DUYMJY5/) | 2021-10-12 |
| Codility February Challenge: [Golden award](https://app.codility.com/cert/view/certN5JKFV-Q4F6SC3RUQGVTE9Z/)!                                                                                             | Golden award on first try! Good to be back after parental leave :D                                                                                                                              | 2022-03-22 |
| Reduced Android build times on Azure by 80%!                                                                                                                                                              | [Read about it](/posts/reducing-android-build-times-on-azure-by-80/)                                                                                                                            | 2022-04-08 |
| Got the Android build times article published on [The Vipps blog](https://medium.com/vipps)                                                                                                               | ...Which was actually one of my L4 goals :D                                                                                                                                                     | 2022-06-21 |
| Got the Android build times article published on [Kode24.no](https://www.kode24.no/artikkel/christian-byttet-jobb-internt-jeg-tror-dette-byttet-har-gjort-meg-til-en-bedre-utvikler/76546486) (Norwegian) | #larger-community-impact                                                                                                                                                                        | 2022-06-30 |
| Finished a complete rewrite of Vipps Login                                                                                                                                                                | Compose navigation, no fragments, proper view state and view effects                                                                                                                            | 2022-10-06 |

## Short-term goals (before parental leave '21)

| Goal                                                                         | Next steps                                                                                      | Success measures                                                                                                         | Support needed                                                                                                 |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| Create a habit of intentionally practicing hard deep-focus programming tasks | Do August challenge on Codility after summer vacation                                           | Complete all monthly challenges on Codility starting August '21, earn "Gold" on at least one out of three                | A predictable schedule is needed for this and other deep work tasks (i.e. same day meetings kept to a minimum) |
| Become the go-to person for all things "Vipps Login" on Android              | Do a thorough refactoring and cleanup (together with Max) after v2 login endpoints are in place | When something needs fixing related to Vipps Login, "ask @cekrem" is a viable response (and I'm actually able to fix it) | Time to actually dig into the login code and do (sorely needed) refactoring                                    |

## Mid-term goals (before summer '22)

| Goal                                                                                             | Next steps                                              | Success measures                                                                                             | Support needed                                             |
| ------------------------------------------------------------------------------------------------ | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| Make sure everyone on my team is familiar and confident with all things "Vipps Login" on Android | Schedule knowledge sharing session after v2 refactoring | Everyone in the team feels confident working on the "Vipps Login" part of our code base                      |                                                            |
| Become a/the significant Android resource for all things eCom on Android                         | TBA                                                     | Become an empowering mentor and problem solver who enables the team to do amazing work across all eCom areas | Time and help understanding the various eCom payment flows |
| Become a regular Open Source contributor                                                         | Decide which project(s) to contribute to                | Contribute monthly to at least one open source project with 100+ stars                                       |                                                            |

## Long-term goals

| Goal                                                  | Next steps                                                                                                      | Success measures                                                                                                                            | Support needed |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| Become a go-to guy for all things JetPack Compose     | Rewrite most of "Vipps Login" using Compose √                                                                   | Host a Compose workshop √                                                                                                                   |                |
| Become a Level 4 Engineer at Vipps ("staff engineer") | Start blogging semi-regularly and have a larger impact ([The Vipps blog @ Medium?](https://medium.com/vipps)) √ | Become thoroughly familiar with the most complicated and essential parts of the Vipps App: Payment and friends (AKA: slay the Vipps Dragon) |                |
