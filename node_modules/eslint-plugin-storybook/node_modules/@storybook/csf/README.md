# Storybook Component Story Format (CSF)

A minimal set of utility functions for dealing with Storybook [Component Story Format (CSF)](https://storybook.js.org/docs/formats/component-story-format/).

## Install

```sh
yarn add @storybook/csf
```

## API

See package source for function definitions and types:

- `isExportStory(key, { includeStories, excludeStories })` - Does a named export match CSF inclusion/exclusion options?

- `parseKind(kind, { rootSeparator, groupSeparator })` - Parse out the component/kind name from a path, using the given separator config.

- `sanitize(string)` - Remove punctuation and illegal characters from a story ID.

- `toId(kind, name)` - Generate a storybook ID from a component/kind and story name.

## Contributing

If you have any suggestions, please open an issue or a PR.

All contributions are welcome!

### run tests:

```sh
yarn test
```
