
# detect-package-manager

[![NPM version](https://img.shields.io/npm/v/detect-package-manager.svg?style=flat)](https://npmjs.com/package/detect-package-manager) [![NPM downloads](https://img.shields.io/npm/dm/detect-package-manager.svg?style=flat)](https://npmjs.com/package/detect-package-manager) [![CircleCI](https://circleci.com/gh/egoist/detect-package-manager/tree/master.svg?style=shield)](https://circleci.com/gh/egoist/detect-package-manager/tree/master)  [![donate](https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&style=flat)](https://github.com/egoist/donate)

## How does this work?

1. When there's `yarn.lock`, `package-lock.json`, or `pnpm-lock.yaml` in current working directory, it will skip other operations and directly resolve `yarn`, `npm`, or `pnpm`.
2. When there's no lockfile found, it checks if `yarn` and `pnpm` command exists. If so, it resolves `yarn` or `pnpm` otherwise `npm`.
3. Results are cached.

## Install

```bash
yarn add detect-package-manager
```

## Usage

```js
const { detect } = require('detect-package-manager')

detect()
  .then(pm => {
    console.log(pm)
    //=> 'yarn', 'npm', or 'pnpm'
  })
```

## API

### detect([opts])

- Arguments:
  - `opts.cwd`: `string` Optional, defaults to `.`, the directory to look up `yarn.lock`, `package-lock.json`, or `pnpm-lock.yaml`.
- Returns: `Promise<PM>`

It returns a Promise resolving the name of package manager, could be `npm`, `yarn`, or `pnpm`.

### getNpmVersion([pm])

- Arguments:
  - `pm`: `string` Optional, defaults to `npm`, could be `npm`, `yarn`, or `pnpm`
- Returns: `Promise<string>`

It returns a Promise resolving the version of npm or the package manager you specified.

### clearCache()

- Returns: `void`

Clear cache.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D


## Author

**detect-package-manager** © [EGOIST](https://github.com/egoist), Released under the [MIT](./LICENSE) License.<br>
Authored and maintained by EGOIST with help from contributors ([list](https://github.com/egoist/detect-package-manager/contributors)).

> [github.com/egoist](https://github.com/egoist) · GitHub [@EGOIST](https://github.com/egoist) · Twitter [@_egoistlily](https://twitter.com/_egoistlily)
