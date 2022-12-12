<img src="https://user-images.githubusercontent.com/42671/89649515-eceafc00-d88e-11ea-9728-5ef80cdf8462.png" width="321px" height="236px" />

# Component Story Format (CSF)

### Why a standard format?
Components have risen to dominate the UI landscape. There are new component-oriented tools for development, testing, design, and prototyping. These tools engage in the creation and consumption of components and component examples (a.k.a. stories). But each tool has its own proprietary format because a simple, platform-agnostic way to express component examples doesn't yet exist.

### The "Story" is the source of truth for a component.
A story is a code snippet that renders an example of a component in a specific state. Think about it like a "[user story](https://en.wikipedia.org/wiki/User_story)".

It uses the production code shipped to users, making it the most accurate representation of a component example. What's more, stories are expressed in the view layer you use to build your app.


### Component Story Format
The Component Story Format is an open standard for component examples based on JavaScript ES6 modules. This enables interoperation between development, testing, and design tools.

```js
export default { title: 'atoms/Button' };
export const text = () => <Button>Hello</Button>;
export const emoji = () => <Button>😀😎👍💯</Button>;
```

💎 **Simple.** Writing component "stories" is as easy as exporting ES6 functions using a clean, widely-used format.

🚚 **Non-proprietary.** CSF doesn't require any vendor-specific libraries. Component stories are easily consumed anywhere ES6 modules live, including your favourite testing tools like Jest and Cypress.

☝️ **Declarative.** The declarative syntax is isomorphic to higher-level formats like MDX, enabling clean, verifiable transformations.

🔥 **Optimized.** Component stories don't need any libraries other than your components. And because they're ES6 modules, they're even tree-shakeable!

### Who uses CSF?

**Tools:** [Storybook](https://storybook.js.org), [WebComponents.dev](https://webcomponents.dev), [Components.studio](https://components.studio), [RedwoodJS](https://redwoodjs.com/), [UXPin](https://www.uxpin.com/)

**Compatible with:** [Jest](https://jestjs.io/), [Enzyme](https://enzymejs.github.io/enzyme), [Testing Library](https://testing-library.com), [Cypress](https://www.cypress.io/), [Playwright](https://playwright.dev/), [Mocha](https://mochajs.org), etc.


## CSF utilities

A minimal set of utility functions for dealing with [Component Story Format (CSF)](https://storybook.js.org/docs/formats/component-story-format/).


### Install

```sh
yarn add @componentdriven/csf
```

### API

See package source for function definitions and types:

- `storyNameFromExport(key)` - Enhance export name (`key`) of the story. Currently implemented with [startCase](https://lodash.com/docs/4.17.11#startCase).

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
