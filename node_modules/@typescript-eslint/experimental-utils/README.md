<h1 align="center">Utils for ESLint Plugins</h1>

<p align="center">Utilities for working with TypeScript + ESLint together.</p>

<p align="center">
    <img src="https://github.com/typescript-eslint/typescript-eslint/workflows/CI/badge.svg" alt="CI" />
    <a href="https://www.npmjs.com/package/@typescript-eslint/experimental-utils"><img src="https://img.shields.io/npm/v/@typescript-eslint/experimental-utils.svg?style=flat-square" alt="NPM Version" /></a>
    <a href="https://www.npmjs.com/package/@typescript-eslint/experimental-utils"><img src="https://img.shields.io/npm/dm/@typescript-eslint/experimental-utils.svg?style=flat-square" alt="NPM Downloads" /></a>
</p>

## Note

**This package is purely a re-export of `@typescript-eslint/utils`.**
You should switch to importing from that non-experimental package instead.

```diff
- import { RuleCreator } from '@typescript-eslint/experimental-utils';
+ import { RuleCreator } from '@typescript-eslint/utils';
```

> ⚠ A future major version of this old package will `console.warn` to ask you to switch.

## Contributing

[See the contributing guide here](../../CONTRIBUTING.md)
