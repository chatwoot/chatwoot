# package-manager-detector

[![npm version][npm-version-src]][npm-version-href]
[![npm downloads][npm-downloads-src]][npm-downloads-href]

Package manager detector is based on lock files and the `packageManager` field in the current project's `package.json` file.

It will detect your `yarn.lock` / `pnpm-lock.yaml` / `package-lock.json` / `bun.lockb` to know the current package manager and use the `packageManager` field in your `package.json` if present.

## Install

```sh
# pnpm
pnpm add package-manager-detector

# npm
npm i package-manager-detector

# yarn
yarn add package-manager-detector
```

## Usage

```js
// ESM
import { detect } from 'package-manager-detector/detect'
```

```js
// CommonJS
const { detect } = require('package-manager-detector/detect')
```

## Agents and Commands

This package includes package manager agents and their corresponding commands for:

- `'agent'` - run the package manager with no arguments
- `'install'` - install dependencies
- `'frozen'` - install dependencies using frozen lockfile
- `'add'` - add dependencies
- `'uninstall'` - remove dependencies
- `'global'` - install global packages
- `'global_uninstall'` - remove global packages
- `'upgrade'` - upgrade dependencies
- `'upgrade-interactive'` - upgrade dependencies interactively: not available for `npm` and `bun`
- `'execute'` - download & execute binary scripts
- `'run'` - run `package.json` scripts

### Using Agents and Commands

A `resolveCommand` function is provided to resolve the command for a specific agent.

```ts
import { detect } from 'package-manager-detector/detect'
import { resolveCommand } from 'package-manager-detector/commands'

const pm = await detect()
if (!pm)
  throw new Error('Could not detect package manager')

const { command, args } = resolveCommand(pm.agent, 'add', ['@antfu/ni']) // { cli: 'pnpm', args: ['add', '@antfu/ni'] }
console.log(`Detected the ${pm.agent} package manager. You can run a install with ${command} ${args.join(' ')}`)
```

## License

[MIT](./LICENSE) License © 2020-PRESENT [Anthony Fu](https://github.com/antfu)

<!-- Badges -->

[npm-version-src]: https://img.shields.io/npm/v/package-manager-detector?style=flat&colorA=18181B&colorB=F0DB4F
[npm-version-href]: https://npmjs.com/package/package-manager-detector
[npm-downloads-src]: https://img.shields.io/npm/dm/package-manager-detector?style=flat&colorA=18181B&colorB=F0DB4F
[npm-downloads-href]: https://npmjs.com/package/package-manager-detector
[license-href]: https://github.com/userquin/package-manager-detector/blob/main/LICENSE
