+++ 
date = 2021-07-07
title = "pretty-git-report – a CLI to give you daily commit metrics"
description = "npx pretty-git-report <dir-containing-repos> <git-user-handle>"
tags = ["cli", "git", "npm package"]
+++

## Have you ever...

- Wanted to track your daily additions and deletions without leaving your beloved terminal?
- Busted your back piping `git log {insert-hundred-flags}` through endless hoops trying to create a somewhat human readable and useful output?
- Wanted to use a functional node.js cli with an immoral amount of [Rambda](https://ramdajs.com/) usage? (Sorry about that, btw, I just wanted to see how far I could go. [Quite far](https://github.com/cekrem/pretty-git-report/blob/master/index.js), it turns out!)
- Wished you would live to see a tool (any tool at all) that treverses a directory tree - :O – concurrently?

Then look no further. Lo and behold:

```
$ npx pretty-git-report ~/code cekrem
Repo                                              +       -
--------------------------------------------------------------
/elm-chess                                       10       0
/android-app-starter                             20       0
/deep-neural-network-blockchain-pivot-starter  1307     791
--------------------------------------------------------------
Total                                          1337     791
```

Feel free to check out the [code](https://github.com/cekrem/git-report), but don't try all that Rambda stuff at home :|
