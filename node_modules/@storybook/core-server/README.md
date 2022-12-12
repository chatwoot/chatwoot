# Storybook Core-server

This package contains common node-side functionality used among the different frameworks (React, RN, Vue, Ember, Angular, etc).

It contains:

- CLI arg parsing
- Storybook UI "manager" webpack configuration
- `start-storybook` dev server
- `build-storybook` static builder
- presets handling

The "preview" (aka iframe) side is implemented in pluggable builders:

- `@storybook/builder-webpack4`
- `@storybook/builder-webpack5`

These builders abstract both the webpack dependencies as well as the various core configurations and loader/plugin dependencies provided out of the box with Storybook.
