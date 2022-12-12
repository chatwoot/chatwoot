# `@storybook/client-api` -- Deprecated Story APIs (`storiesOf`)

**NOTE** This API is deprecated, and the CSF format is preferred for all stories.

## `storiesOf` API

The `@storybook/client` API provides the [`storiesOf()` API](../core/docs/storiesOf.md), which is proxied through to the CSF API.

### Internals

In order to appear to the store like the CSF API, a call to `storiesOf().add()` does the following:

- Tracks the story added in a synthetic `StoryIndex` data structure
- Constructs a `moduleExports` object that is equivalent to the exports from a CSF file that produced the same stories.

In order to achieve the old `storySort` functionality, the client API also needs access to the project annotations.
