+++ 
date = 2023-09-12
title = "Exploring UIs in the terminal part 2: More ink!"
description = "Why I'm not bothering with Mason after all..."
tags = ["cli", "ui", "npm package", "react", "redux", "ink"]
+++

## Abandon ship, all y'all

In [part 1](/posts/do-more-stuff-cli-tool-part-1), I made a small POC cli tool for doing multiple things in parallel. Like curling multiple endpoints and collecting the responses in a neat and tidy list instead of opening several terminal tabs/panes. The goal was partly to explore how rendering actually works in a more confined environment than the DOM (web), or more complicated yet: native mobile apps. The other goal, as usual, was to have fun while doing it. My adventures in part 2 have, however, been slightly shipwrecked.

## Mosaic, you're no fun

My plan was to proceed this series by creating the [same app as I did in the previous post](https://github.com/cekrem/domorestuff), only using [Mosaic](https://github.com/JakeWharton/mosaic) instead of [Ink](https://github.com/vadimdemedes/ink). Turns out, that wasn't as much fun as I anticipated. When my 2-year-old is acting up, I tell him "fun, or room?". Using the same approach, I'm sending Mosaic to his (her?) room for the following reasons:

- Getting even "hello world" to work was a real hassle. Gradle this, dependency that, and frankly not plug and play at all. npm > gradle when measuring "fun".
- It's not really proper Compose after all. [We can't use LaunchedEffect](https://github.com/JakeWharton/mosaic#why-doesnt-work-take-place-in-a-launchedeffect), so there's no `remember`, and all work is being done in the main scope. It just feels wrong.
- I work with Kotlin, Compose and Gradle every day anyway, so for a refreshing side project it doesn't quite cut it for me :P

I still think it's an amazing ~~project~~ concept, and kudos to mr Wharton for kicking it off. But it's not for me. After all, why do a side project if it's no fun?

## Back in Ink-land

I'm having a hoot and a half tweaking [domorestuff](https://github.com/cekrem/domorestuff) every once in a while. [Redux](https://redux.js.org) also works, although there's this weird issue with needing ReactDOM to get the [new tooling](https://redux.js.org/introduction/why-rtk-is-redux-today) to work. I can't see that it's actually called, but builds fail without it. I can live with that ¯\\_(ツ)_/¯

Is this how the cool kids write Redux these days? I don't know. But it felt oh-so-good to make reducers again, and better still knowing that it'll be used to render something in the terminal:

```JavaScript
https://github.com/cekrem/domorestuff/blob/master/source/store.js

import pkg from '@reduxjs/toolkit';
import {v4 as uuidv4} from 'uuid';

const {configureStore, createSlice} = pkg;

export const COLORS = {
	success: 'green',
	error: 'red',
	pending: 'black',
};

const [normal, input, search] = ['normal', 'input', 'search'];
export const MODE = Object.freeze({
	normal,
	input,
	search,
});

const initialState = {
	commands: {},
	newCommand: '',
	activeIndex: 0,
	inputMode: MODE.normal,
};

const parseCommand = raw => {
	const [root, ...args] = raw.includes(' ') ? raw.split(' ') : [raw];
	return {
		id: uuidv4(),
		raw,
		root,
		args,
		color: COLORS.pending,
	};
};

const rootSlice = createSlice({
	name: 'root',
	initialState,
	reducers: {
		setInitial: (_, {payload}) => {
			const commands = payload.map(parseCommand);
			return {
				...initialState,
				commands: commands.reduce(
					(acc, entry) => ({
						...acc,
						[entry.id]: entry,
					}),
					{},
				),
			};
		},
		addCommand: ({commands, ...state}, {payload}) => {
			const command = parseCommand(payload);
			return {
				...state,
				inputMode: MODE.normal,
				newCommand: '',
				commands: {...commands, [command.id]: command},
			};
		},
		nextCommand: ({activeIndex, ...state}) => ({
			...state,
			activeIndex: activeIndex + 1,
		}),
		previousCommand: ({activeIndex, ...state}) => ({
			...state,
			activeIndex: activeIndex - 1,
		}),
		deleteCommand: ({commands, ...state}) => {
			const ids = Object.values(commands).map(({id}) => id);
			const id = ids[state.activeIndex % ids.length];

			const {[id]: _, ...remainingCommands} = commands;
			return {
				...state,
				commands: remainingCommands,
			};
		},
		setInputMode: (state, {payload}) => ({
			...state,
			newCommand: '',
			inputMode: payload,
		}),
		inputCharacter: ({newCommand, ...state}, {payload}) => ({
			...state,
			newCommand: newCommand + payload,
		}),
		inputDelete: ({newCommand, ...state}) => ({
			...state,
			inputMode: newCommand.length ? MODE.input : MODE.normal,
			newCommand: newCommand.slice(0, -1),
		}),
		// set any prop (but only for existing commands)
		setCommandProp: ({commands, ...state}, {payload}) =>
			payload.id in commands
				? {
						...state,
						commands: {
							...commands,
							[payload.id]: {
								...commands[payload.id],
								[payload.key]: payload.value,
							},
						},
				  }
				: {
						...state,
						commands,
				  },
	},
});

export const {
	setInitial,
	addCommand,
	deleteCommand,
	nextCommand,
	previousCommand,
	inputCharacter,
	inputDelete,
	setInputMode,
	setCommandProp,
} = rootSlice.actions;

export const store = configureStore({
	reducer: {
		root: rootSlice.reducer,
	},
});
```

Compose, sadly, can't touch this. And Gradle troubleshooting is the worst. Also, as the keen observer might notice: I'm adding search/filtering. It's not done yet, and maybe not even useful at all. But definitely fun!
