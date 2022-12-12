# Storybook Postinstall Utilties

A minimal utility library for addons to update project configurations after the addon is installed via the [Storybook CLI](https://github.com/storybookjs/storybook/tree/main/lib/cli), e.g. `sb add docs`.

Each postinstall is written as a [jscodeshift](https://github.com/facebook/jscodeshift) codemod, with the naming convention `addon-name/postinstall/<file>.js` where `file` is one of { `config`, `addons`, `presets` }.

If these files are present in the addon, the CLI will run them on the existing file in the user's project (or create a new empty file if one doesn't exist). This library exists to make it really easy to make common modifications without having to muck with jscodeshift internals.

## Adding a preset

To add a preset to `presets.js`, simply create a file `postinstall/presets.js` in your addon:

```js
import { presetsAddPreset } = require('@storybook/postinstall');
export default function transformer(file, api) {
  const root = api.jscodeshift(file.source);
  presetsAddPreset(`@storybook/addon-docs/preset`, { some: 'options' }, { root, api });
  return root.toSource();
};
```
