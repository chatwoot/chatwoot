# Preview (Web)

This is the main API for the (web) version of the Storybook Preview.

The preview's job is:

1. Read and update the URL (via the URL Store)

2. Listen to instructions on the channel and emit events as things occur.

3. Render the current selection to the web view in either story or docs mode.

## V7 Store vs Legacy (V6)

The story store is designed to load stories 'on demand', and will operate in this fashion if the `storyStoreV7` feature is enabled.

However, for back-compat reasons, in v6 mode, we need to load all stories, synchronously on bootup, emitting the `SET_STORIES` event.

In V7 mode we do not emit that event, instead preferring the `STORY_PREPARED` event, with the data for the single story being rendered.

## Initialization

The preview is `initialized` in two ways.

### V7 Mode:

- `importFn` - is an async `import()` function

- `getProjectAnnotations` - is a simple function that evaluations `preview.js` and addon config files and combines them. If it errors, the Preview will show the error.

- No `getStoryIndex` function is passed, instead the preview creates a `StoryIndexClient` that pulls `stories.json` from node and watches the event stream for invalidation events.

### V6 Mode

- `importFn` - is a simulated `import()` function, that is synchronous, see `client-api` for details.
- `getProjectAnnotations` - also evaluates `preview.js` et al, but watches for calls to `setStories`, and passes them to the `ClientApi`
- `getStoryIndex` is a local function (that must be called _after_ `getProjectAnnotations`) that gets the list of stories added.

See `client-api` for more details on this process.

## Story Rendering and interruptions

The Preview is split into three parts responsible for state management:

- `PreviewWeb` - which story is rendered, receives events and (maybe) changes/re-renders stories
- `StoryRender` - (imports +) prepares the story, renders it through the various phases
- `DocsRender` - if a story renders in docs mode, it is "transformed" into a `DocsRender` once we know.

A rendering story goes through these phases:

- `preparing` - (maybe async) import the story file and prepare the story function.
- `loading` - async loaders are running
- `rendering` - the `renderToDOM` function for the framework is running
- `playing` - the `play` function is running
- `completed` - the story is done.

It also has two error states:

- `aborted` - the story was stopped midway (see below)
- `errored` - there was an error thrown somewhere along the way.

### Re-rendering and aborting

A story may re-render due to various events, which can have implications if the story is not in the `completed` phase:

- `UPDATE_STORY_ARGS` / `UPDATE_GLOBALS` -- change of inputs
- `FORCE_RE_RENDER` - re-render unchanged

If these events happen during a render:

- if the story is `preparing` or `loading`, leave thing unchanged and let the new `args`/`globals` be picked up by the render phase
- otherwise, use the result of the previous `loaders` run, and simply re-render over the top

- `FORCE_REMOUNT` - remount (or equivalent) the component and re-render.

If this happens during a render, treat `loading` similarly, but:

- if the story is `rendering`, start a new render and abort the previous render immediately afterwards
- if the story is `playing`, attempt to abort the previous play function, and start a new render.

### Changing story

Also the `SET_CURRENT_STORY` event may change the current story. We need to check:

- If the `storyId` changed
- If the `viewMode` changed
- If the story implementation changed (i.e if HMR occurred).

If the _previous_ story is still `preparing`, we cannot know if the implementation changed, so we
abort the preparing immediately, and let the new story take over.

Otherwise, if all of the above are the same, we do nothing.

If they are different, and the old story is not `completed`, we try to abort it immediately. If that fails (e.g. the `play` function doesn't respond to the `abort` event), then we reload the window.
