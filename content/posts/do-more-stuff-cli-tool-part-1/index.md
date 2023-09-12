+++ 
date = 2023-08-29
title = "Exploring UIs in the terminal part 1: React/Ink"
description = "Creating a React app!"
tags = ["cli", "ui", "npm package", "react", "ink"]
+++

## Where do UIs belong?

Most of us consider ReactJS a tool for rendering UI components on the web (or the DOM, specifically), and if by "React" we mean "ReactDOM" then we're right. But as we've seen with React Native, React is not confined to the DOM at all, and can render to any number of environments. After all, like it says on the box, React is a "JavaScript library for building user interfaces". We've seen the same with [Compose Multiplatform](https://www.jetbrains.com/lp/compose-multiplatform/): what used to be a framework for creating Android UI can actually be used for so much more.

Personally I think the actual _rendering_ part of both React and Compose is super interesting! But it feels a bit overwhelming to dive in to all that's going on when interacting with the DOM, let alone the mobile targets with all their domain specific weirdness. If only there was an even simpler environment where a UI could live. Something a lot more constrained and minimalistic than web/mobile, and ideally something I'm already familiar with...

## The terminal!

The simplicity, power and general feelgood of a properly set up terminal is just unbeatable. Mine is not as heavily customized as it used to be, especially after I started using [Warp](https://www.warp.dev/), but it's still the space I spend most time tweaking to my liking. And even after growing quite dependent on Android Studio for Android stuff, it's still an environment I spend a lot of my working hours in. **And I recently learned that there are libraries available for using both React and Compose for the terminal**! The one and only Jake Wharton has made [Mosaic](https://github.com/JakeWharton/mosaic), "an experimental tool for building console UI in Kotlin using the Jetpack Compose compiler/runtime." Mosaic is based on [ink](https://github.com/vadimdemedes/ink), which is basically the same only it's using React instead of Compose to render. To be fair, btw, ink came first; if we're giving out points the first one goes to the React community.

These libraries are great for two reasons:

1. it's a lot more fun to write React/Compose than doing `printf("\033[%dB", lineNumber)` til kingdom come just to move your cursor.
2. It's a perfect case study to learn how rendering works.

## Starting with ink

Since I'm already somewhat familiar with how React rendering works when targeting the DOM, this is where I'll start my terminal UI adventure: **I'll create a simple yet hopefully useful CLI as a case study for rendering UI in the terminal**. In the next part I'll try and make the same tool only using Mosaic instead. If my courage doesn't fail me, I'll sum it all up with a final post exploring some differences and key takeaways from both libraries. Maybe, just maybe, I'll be inspired to make something similar myself with Elm or something. Exciting!

## What I made

Basically, I made `domorestuff`, a simple tool to run multiple shell commands in parallel, and inspect the output of each one. Since ink actually supports all React features, it felt instantly familiar. The only sort of domain specific caveat I encountered was how to keep the app from exciting after initial output. TL;DR: it seems any input listener or interval running will keep stuff alive, but there might be more to it than that.

![`domorestuff`, ink edition](inkdomorestuff.gif)

You can try the tool yourself, just `npx domorestuff`. I've taken a few shortcuts here and there, but the [source code](https://github.com/cekrem/domorestuff) should be fairly straight forward for those familiar with React.

In fact, let me prove that:

```JSX
// source/command.js sure looks like React to me!

import React, {useEffect, useState} from 'react';
import {Box, Spacer, Text} from 'ink';
import {spawn} from 'child_process';

export const Command = ({cmd, active}) => {
	const [summary, setSummary] = useState('');
	const [color, setColor] = useState(COLORS.pending);
	const [output, setOutput] = useState(null);

	useEffect(() => {
		// {skipped for brevity, TL;DR: spawn process, handle output etc}
	}, [cmd]);

	return (
		<Box
			overflow="hidden"
			flexDirection="column" // it even has flexbox!
			width="100%"
			borderStyle="bold"
			borderColor={color}
		>
			<Box>
				<Text bold>
					{`${active ? '* ' : ''}${cmd}`}
					{!active && output?.length > 1 && <Text dimColor> (...)</Text>}
				</Text>

				<Spacer />

				<Text color={color}>{summary}</Text>
			</Box>

			{active && output?.length > 1 && (
				<Box marginTop="1" overflow="hidden">
					<Text overflow="hidden" wrap="truncate">
						{output.toString().trim()}
					</Text>
				</Box>
			)}
		</Box>
	);
};
```

It's not fair make comparisons before I've at least tried Mason, but I can say straight away that ink is super smooth. Also, NPM is a _very_ efficient means to publish CLI tools. You're basically done before even starting. I might even use NPM to publish the Kotlin/Compose version of this app as well, that's how smooth the ecosystem is. (Yes, it's perfectly fine to publish non-JavaScript binaries, as demonstrated with [create-elm-live-app](/posts/create-elm-live-app/#the-simplest-possible-solution-that-actually-works).)

Stay tuned for part two: `doevenmorestuff`, starring Kotlin, Compose and Mason! Coming soon.
