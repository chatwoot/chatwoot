# 🚫💩 lint-staged ![GitHub Actions](https://github.com/okonet/lint-staged/workflows/CI/badge.svg) [![Build Status for Windows](https://ci.appveyor.com/api/projects/status/github/okonet/lint-staged?branch=master&svg=true)](https://ci.appveyor.com/project/okonet/lint-staged) [![npm version](https://badge.fury.io/js/lint-staged.svg)](https://badge.fury.io/js/lint-staged) [![Codecov](https://codecov.io/gh/okonet/lint-staged/branch/master/graph/badge.svg)](https://codecov.io/gh/okonet/lint-staged)

Run linters against staged git files and don't let :poop: slip into your code base!

[![asciicast](https://asciinema.org/a/199934.svg)](https://asciinema.org/a/199934)

## Why

Linting makes more sense when run before committing your code. By doing so you can ensure no errors go into the repository and enforce code style. But running a lint process on a whole project is slow and linting results can be irrelevant. Ultimately you only want to lint files that will be committed.

This project contains a script that will run arbitrary shell tasks with a list of staged files as an argument, filtered by a specified glob pattern.

## Related blogs posts and talks

- [Introductory Medium post - Andrey Okonetchnikov, 2016](https://medium.com/@okonetchnikov/make-linting-great-again-f3890e1ad6b8#.8qepn2b5l)
- [Running Jest Tests Before Each Git Commit - Ben McCormick, 2017](https://benmccormick.org/2017/02/26/running-jest-tests-before-each-git-commit/)
- [AgentConf presentation - Andrey Okonetchnikov, 2018](https://www.youtube.com/watch?v=-mhY7e-EsC4)
- [SurviveJS interview - Juho Vepsäläinen and Andrey Okonetchnikov, 2018](https://survivejs.com/blog/lint-staged-interview/)
- [Prettier your CSharp with `dotnet-format` and `lint-staged`](https://blog.johnnyreilly.com/2020/12/prettier-your-csharp-with-dotnet-format-and-lint-staged.html)

> If you've written one, please submit a PR with the link to it!

## Installation and setup

The fastest way to start using lint-staged is to run following command in your terminal:

```bash
npx mrm lint-staged
```

It will install and configure [husky](https://github.com/typicode/husky) and lint-staged depending on code quality tools from `package.json` dependencies so please make sure you install (`npm install --save-dev`) and configure all code quality tools like [Prettier](https://prettier.io), [ESlint](https://eslint.org) prior that.

Don't forget to commit changes to `package.json` to share this setup with your team!

Now change a few files, `git add` or `git add --patch` some of them to your commit and try to `git commit` them.

See [examples](#examples) and [configuration](#configuration) for more information.

## Changelog

See [Releases](https://github.com/okonet/lint-staged/releases)

### Migration

#### v10

- From `v10.0.0` onwards any new modifications to originally staged files will be automatically added to the commit.
  If your task previously contained a `git add` step, please remove this.
  The automatic behaviour ensures there are less race-conditions,
  since trying to run multiple git operations at the same time usually results in an error.
- From `v10.0.0` onwards _lint-staged_ uses git stashes to improve speed and provide backups while running.
  Since git stashes require at least an initial commit, you shouldn't run _lint-staged_ in an empty repo.
- From `v10.0.0` onwards _lint-staged_ requires Node.js version 10.13.0 or later.
- From `v10.0.0` onwards _lint-staged_ will abort the commit if linter tasks undo all staged changes. To allow creating empty commit, please use the `--allow-empty` option.

## Command line flags

```bash
❯ npx lint-staged --help
Usage: lint-staged [options]

Options:
  -V, --version                      output the version number
  --allow-empty                      allow empty commits when tasks revert all staged changes
                                     (default: false)
  -c, --config [path]                path to configuration file, or - to read from stdin
  -d, --debug                        print additional debug information (default: false)
  --no-stash                         disable the backup stash, and do not revert in case of
                                     errors
  -p, --concurrent <parallel tasks>  the number of tasks to run concurrently, or false to run
                                     tasks serially (default: true)
  -q, --quiet                        disable lint-staged’s own console output (default: false)
  -r, --relative                     pass relative filepaths to tasks (default: false)
  -x, --shell                        skip parsing of tasks for better shell support (default:
                                     false)
  -v, --verbose                      show task output even when tasks succeed; by default only
                                     failed output is shown (default: false)
  -h, --help                         display help for command
```

- **`--allow-empty`**: By default, when linter tasks undo all staged changes, lint-staged will exit with an error and abort the commit. Use this flag to allow creating empty git commits.
- **`--config [path]`**: Manually specify a path to a config file or npm package name. Note: when used, lint-staged won't perform the config file search and print an error if the specified file cannot be found. If '-' is provided as the filename then the config will be read from stdin, allowing piping in the config like `cat my-config.json | npx lint-staged --config -`.
- **`--debug`**: Run in debug mode. When set, it does the following:
  - uses [debug](https://github.com/visionmedia/debug) internally to log additional information about staged files, commands being executed, location of binaries, etc. Debug logs, which are automatically enabled by passing the flag, can also be enabled by setting the environment variable `$DEBUG` to `lint-staged*`.
  - uses [`verbose` renderer](https://github.com/SamVerschueren/listr-verbose-renderer) for `listr`; this causes serial, uncoloured output to the terminal, instead of the default (beautified, dynamic) output.
- **`--concurrent [number | (true/false)]`**: Controls the concurrency of tasks being run by lint-staged. **NOTE**: This does NOT affect the concurrency of subtasks (they will always be run sequentially). Possible values are:
  - `false`: Run all tasks serially
  - `true` (default) : _Infinite_ concurrency. Runs as many tasks in parallel as possible.
  - `{number}`: Run the specified number of tasks in parallel, where `1` is equivalent to `false`.
- **`--no-stash`**: By default a backup stash will be created before running the tasks, and all task modifications will be reverted in case of an error. This option will disable creating the stash, and instead leave all modifications in the index when aborting the commit.
- **`--quiet`**: Supress all CLI output, except from tasks.
- **`--relative`**: Pass filepaths relative to `process.cwd()` (where `lint-staged` runs) to tasks. Default is `false`.
- **`--shell`**: By default linter commands will be parsed for speed and security. This has the side-effect that regular shell scripts might not work as expected. You can skip parsing of commands with this option.
- **`--verbose`**: Show task output even when tasks succeed. By default only failed output is shown.

## Configuration

Starting with v3.1 you can now use different ways of configuring it:

- `lint-staged` object in your `package.json`
- `.lintstagedrc` file in JSON or YML format, or you can be explicit with the file extension:
  - `.lintstagedrc.json`
  - `.lintstagedrc.yaml`
  - `.lintstagedrc.yml`
- `lint-staged.config.js`, `.lintstagedrc.js`, or `.lintstagedrc.cjs` file in JS format
- Pass a configuration file using the `--config` or `-c` flag

See [cosmiconfig](https://github.com/davidtheclark/cosmiconfig) for more details on what formats are supported.

Configuration should be an object where each value is a command to run and its key is a glob pattern to use for this command. This package uses [micromatch](https://github.com/micromatch/micromatch) for glob patterns.

#### `package.json` example:

```json
{
  "lint-staged": {
    "*": "your-cmd"
  }
}
```

#### `.lintstagedrc` example

```json
{
  "*": "your-cmd"
}
```

This config will execute `your-cmd` with the list of currently staged files passed as arguments.

So, considering you did `git add file1.ext file2.ext`, lint-staged will run the following command:

`your-cmd file1.ext file2.ext`

## Filtering files

Linter commands work on a subset of all staged files, defined by a _glob pattern_. `lint-staged´ uses [micromatch](https://github.com/micromatch/micromatch) for matching files with the following rules:

- If the glob pattern contains no slashes (`/`), micromatch's `matchBase` option will enabled, so globs match a file's basename regardless of directory:
  - **`"*.js"`** will match all JS files, like `/test.js` and `/foo/bar/test.js`
  - **`"!(*test).js"`**. will match all JS files, except those ending in `test.js`, so `foo.js` but not `foo.test.js`
- If the glob pattern does contain a slash (`/`), it will match for paths as well:
  - **`"./*.js"`** will match all JS files in the git repo root, so `/test.js` but not `/foo/bar/test.js`
  - **`"foo/**/\*.js"`** will match all JS files inside the`/foo`directory, so`/foo/bar/test.js`but not`/test.js`

When matching, `lint-staged` will do the following

- Resolve the git root automatically, no configuration needed.
- Pick the staged files which are present inside the project directory.
- Filter them using the specified glob patterns.
- Pass absolute paths to the linters as arguments.

**NOTE:** `lint-staged` will pass _absolute_ paths to the linters to avoid any confusion in case they're executed in a different working directory (i.e. when your `.git` directory isn't the same as your `package.json` directory).

Also see [How to use `lint-staged` in a multi package monorepo?](#how-to-use-lint-staged-in-a-multi-package-monorepo)

### Ignoring files

The concept of `lint-staged` is to run configured linter (or other) tasks on files that are staged in git. `lint-staged` will always pass a list of all staged files to the task, and ignoring any files should be configured in the task itself.

Consider a project that uses [`prettier`](https://prettier.io/) to keep code format consistent across all files. The project also stores minified 3rd-party vendor libraries in the `vendor/` directory. To keep `prettier` from throwing errors on these files, the vendor directory should be added to prettier's ignore configuration, the `.prettierignore` file. Running `npx prettier .` will ignore the entire vendor directory, throwing no errors. When `lint-staged` is added to the project and configured to run prettier, all modified and staged files in the vendor directory will be ignored by prettier, even though it receives them as input.

In advanced scenarios, where it is impossible to configure the linter task itself to ignore files, but some staged files should still be ignored by `lint-staged`, it is possible to filter filepaths before passing them to tasks by using the function syntax. See [Example: Ignore files from match](#example-ignore-files-from-match).

## What commands are supported?

Supported are any executables installed locally or globally via `npm` as well as any executable from your \$PATH.

> Using globally installed scripts is discouraged, since lint-staged may not work for someone who doesn’t have it installed.

`lint-staged` uses [execa](https://github.com/sindresorhus/execa#preferlocal) to locate locally installed scripts. So in your `.lintstagedrc` you can write:

```json
{
  "*.js": "eslint --fix"
}
```

Pass arguments to your commands separated by space as you would do in the shell. See [examples](#examples) below.

## Running multiple commands in a sequence

You can run multiple commands in a sequence on every glob. To do so, pass an array of commands instead of a single one. This is useful for running autoformatting tools like `eslint --fix` or `stylefmt` but can be used for any arbitrary sequences.

For example:

```json
{
  "*.js": ["eslint", "prettier --write"]
}
```

going to execute `eslint` and if it exits with `0` code, it will execute `prettier --write` on all staged `*.js` files.

## Using JS configuration file

Writing the configuration file in JavaScript is the most powerful way to configure _lint-staged_ (`lint-staged.config.js`, [similar](https://github.com/okonet/lint-staged/README.md#configuration), or passed via `--config`). From the configuration file, you can export either a single function, or an object.

If the `exports` value is a function, it will receive an array of all staged filenames. You can then build your own matchers for the files, and return a command string, or an array or command strings. These strings are considered complete and should include the filename arguments, if wanted.

If the `exports` value is an object, its keys should be glob matches (like in the normal non-js config format). The values can either be like in the normal config, or individual functions like described above. Instead of receiving all matched files, the functions in the exported object will only receive the staged files matching the corresponding glob key.

### Function signature

The function can also be async:

```ts
(filenames: string[]) => string | string[] | Promise<string | string[]>
```

### Example: Export a function to build your own matchers

<details>
  <summary>Click to expand</summary>

```js
// lint-staged.config.js
const micromatch = require('micromatch')

module.exports = (allStagedFiles) => {
  const shFiles = micromatch(allStagedFiles, ['**/src/**/*.sh'])
  if (shFiles.length) {
    return `printf '%s\n' "Script files aren't allowed in src directory" >&2`
  }
  const codeFiles = micromatch(allStagedFiles, ['**/*.js', '**/*.ts'])
  const docFiles = micromatch(allStagedFiles, ['**/*.md'])
  return [`eslint ${codeFiles.join(' ')}`, `mdl ${docFiles.join(' ')}`]
}
```

</details>

### Example: Wrap filenames in single quotes and run once per file

<details>
  <summary>Click to expand</summary>

```js
// .lintstagedrc.js
module.exports = {
  '**/*.js?(x)': (filenames) => filenames.map((filename) => `prettier --write '${filename}'`),
}
```

</details>

### Example: Run `tsc` on changes to TypeScript files, but do not pass any filename arguments

<details>
  <summary>Click to expand</summary>

```js
// lint-staged.config.js
module.exports = {
  '**/*.ts?(x)': () => 'tsc -p tsconfig.json --noEmit',
}
```

</details>

### Example: Run eslint on entire repo if more than 10 staged files

<details>
  <summary>Click to expand</summary>

```js
// .lintstagedrc.js
module.exports = {
  '**/*.js?(x)': (filenames) =>
    filenames.length > 10 ? 'eslint .' : `eslint ${filenames.join(' ')}`,
}
```

</details>

### Example: Use your own globs

<details>
  <summary>Click to expand</summary>

It's better to use the [function-based configuration (seen above)](https://github.com/okonet/lint-staged/README.md#example-export-a-function-to-build-your-own-matchers), if your use case is this.

```js
// lint-staged.config.js
const micromatch = require('micromatch')

module.exports = {
  '*': (allFiles) => {
    const codeFiles = micromatch(allFiles, ['**/*.js', '**/*.ts'])
    const docFiles = micromatch(allFiles, ['**/*.md'])
    return [`eslint ${codeFiles.join(' ')}`, `mdl ${docFiles.join(' ')}`]
  },
}
```

</details>

### Example: Ignore files from match

<details>
  <summary>Click to expand</summary>

If for some reason you want to ignore files from the glob match, you can use `micromatch.not()`:

```js
// lint-staged.config.js
const micromatch = require('micromatch')

module.exports = {
  '*.js': (files) => {
    // from `files` filter those _NOT_ matching `*test.js`
    const match = micromatch.not(files, '*test.js')
    return `eslint ${match.join(' ')}`
  },
}
```

Please note that for most cases, globs can achieve the same effect. For the above example, a matching glob would be `!(*test).js`.

</details>

### Example: Use relative paths for commands

<details>
  <summary>Click to expand</summary>

```js
const path = require('path')

module.exports = {
  '*.ts': (absolutePaths) => {
    const cwd = process.cwd()
    const relativePaths = absolutePaths.map((file) => path.relative(cwd, file))
    return `ng lint myProjectName --files ${relativePaths.join(' ')}`
  },
}
```

</details>

## Reformatting the code

Tools like [Prettier](https://prettier.io), ESLint/TSLint, or stylelint can reformat your code according to an appropriate config by running `prettier --write`/`eslint --fix`/`tslint --fix`/`stylelint --fix`. Lint-staged will automatically add any modifications to the commit as long as there are no errors.

```json
{
  "*.js": "prettier --write"
}
```

Prior to version 10, tasks had to manually include `git add` as the final step. This behavior has been integrated into lint-staged itself in order to prevent race conditions with multiple tasks editing the same files. If lint-staged detects `git add` in task configurations, it will show a warning in the console. Please remove `git add` from your configuration after upgrading.

## Examples

All examples assuming you’ve already set up lint-staged and husky in the `package.json`.

```json
{
  "name": "My project",
  "version": "0.1.0",
  "scripts": {
    "my-custom-script": "linter --arg1 --arg2"
  },
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {}
}
```

_Note we don’t pass a path as an argument for the runners. This is important since lint-staged will do this for you._

### ESLint with default parameters for `*.js` and `*.jsx` running as a pre-commit hook

<details>
  <summary>Click to expand</summary>

```json
{
  "*.{js,jsx}": "eslint"
}
```

</details>

### Automatically fix code style with `--fix` and add to commit

<details>
  <summary>Click to expand</summary>

```json
{
  "*.js": "eslint --fix"
}
```

This will run `eslint --fix` and automatically add changes to the commit.

</details>

### Reuse npm script

<details>
  <summary>Click to expand</summary>

If you wish to reuse a npm script defined in your package.json:

```json
{
  "*.js": "npm run my-custom-script --"
}
```

The following is equivalent:

```json
{
  "*.js": "linter --arg1 --arg2"
}
```

</details>

### Use environment variables with linting commands

<details>
  <summary>Click to expand</summary>

Linting commands _do not_ support the shell convention of expanding environment variables. To enable the convention yourself, use a tool like [`cross-env`](https://github.com/kentcdodds/cross-env).

For example, here is `jest` running on all `.js` files with the `NODE_ENV` variable being set to `"test"`:

```json
{
  "*.js": ["cross-env NODE_ENV=test jest --bail --findRelatedTests"]
}
```

</details>

### Automatically fix code style with `prettier` for any format prettier supports

<details>
  <summary>Click to expand</summary>

You need to add `micromatch` as a dev dependency.

```sh
$ npm i --save-dev micromatch
```

```js
// lint-staged.config.js
const micromatch = require('micromatch')
const prettier = require('prettier')

const prettierSupportedExtensions = prettier
  .getSupportInfo()
  .languages.map(({ extensions }) => extensions)
  .flat()
const addQuotes = (a) => `"${a}"`

module.exports = (allStagedFiles) => {
  const prettierFiles = micromatch(
    allStagedFiles,
    prettierSupportedExtensions.map((extension) => `**/*${extension}`)
  )
  return [`prettier --write ${prettierFiles.map(addQuotes).join(' ')}`]
}
```

</details>

### Automatically fix code style with `prettier` for javascript, typescript, markdown, HTML, or CSS

<details>
  <summary>Click to expand</summary>

```json
{
  "*.{js,jsx,ts,tsx,md,html,css}": "prettier --write"
}
```

</details>

### Stylelint for CSS with defaults and for SCSS with SCSS syntax

<details>
  <summary>Click to expand</summary>

```json
{
  "*.css": "stylelint",
  "*.scss": "stylelint --syntax=scss"
}
```

</details>

### Run PostCSS sorting and Stylelint to check

<details>
  <summary>Click to expand</summary>

```json
{
  "*.scss": ["postcss --config path/to/your/config --replace", "stylelint"]
}
```

</details>

### Minify the images

<details>
  <summary>Click to expand</summary>

```json
{
  "*.{png,jpeg,jpg,gif,svg}": "imagemin-lint-staged"
}
```

<details>
  <summary>More about <code>imagemin-lint-staged</code></summary>

[imagemin-lint-staged](https://github.com/tomchentw/imagemin-lint-staged) is a CLI tool designed for lint-staged usage with sensible defaults.

See more on [this blog post](https://medium.com/@tomchentw/imagemin-lint-staged-in-place-minify-the-images-before-adding-to-the-git-repo-5acda0b4c57e) for benefits of this approach.

</details>
</details>

### Typecheck your staged files with flow

<details>
  <summary>Click to expand</summary>

```json
{
  "*.{js,jsx}": "flow focus-check"
}
```

</details>

## Frequently Asked Questions

### Can I use `lint-staged` via node?

<details>
  <summary>Click to expand</summary>

Yes!

```js
const lintStaged = require('lint-staged')

try {
  const success = await lintStaged()
  console.log(success ? 'Linting was successful!' : 'Linting failed!')
} catch (e) {
  // Failed to load configuration
  console.error(e)
}
```

Parameters to `lintStaged` are equivalent to their CLI counterparts:

```js
const success = await lintStaged({
  allowEmpty: false,
  concurrent: true,
  configPath: './path/to/configuration/file',
  cwd: process.cwd(),
  debug: false,
  maxArgLength: null,
  quiet: false,
  relative: false,
  shell: false
  stash: true,
  verbose: false
})
```

You can also pass config directly with `config` option:

```js
const success = await lintStaged({
  allowEmpty: false,
  concurrent: true,
  config: { '*.js': 'eslint --fix' },
  cwd: process.cwd(),
  debug: false,
  maxArgLength: null,
  quiet: false,
  relative: false,
  shell: false,
  stash: true,
  verbose: false,
})
```

The `maxArgLength` option configures chunking of tasks into multiple parts that are run one after the other. This is to avoid issues on Windows platforms where the maximum length of the command line argument string is limited to 8192 characters. Lint-staged might generate a very long argument string when there are many staged files. This option is set automatically from the cli, but not via the Node.js API by default.

</details>

### Using with JetBrains IDEs _(WebStorm, PyCharm, IntelliJ IDEA, RubyMine, etc.)_

<details>
  <summary>Click to expand</summary>

_**Update**_: The latest version of JetBrains IDEs now support running hooks as you would expect.

When using the IDE's GUI to commit changes with the `precommit` hook, you might see inconsistencies in the IDE and command line. This is [known issue](https://youtrack.jetbrains.com/issue/IDEA-135454) at JetBrains so if you want this fixed, please vote for it on YouTrack.

Until the issue is resolved in the IDE, you can use the following config to work around it:

husky v1.x

```json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "post-commit": "git update-index --again"
    }
  }
}
```

husky v0.x

```json
{
  "scripts": {
    "precommit": "lint-staged",
    "postcommit": "git update-index --again"
  }
}
```

_Thanks to [this comment](https://youtrack.jetbrains.com/issue/IDEA-135454#comment=27-2710654) for the fix!_

</details>

### How to use `lint-staged` in a multi package monorepo?

<details>
  <summary>Click to expand</summary>

Starting with v5.0, `lint-staged` automatically resolves the git root **without any** additional configuration. You configure `lint-staged` as you normally would if your project root and git root were the same directory.

If you wish to use `lint-staged` in a multi package monorepo, it is recommended to install [`husky`](https://github.com/typicode/husky) in the root package.json.
[`lerna`](https://github.com/lerna/lerna) can be used to execute the `precommit` script in all sub-packages.

Example repo: [sudo-suhas/lint-staged-multi-pkg](https://github.com/sudo-suhas/lint-staged-multi-pkg).

</details>

### Can I lint files outside of the current project folder?

<details>
  <summary>Click to expand</summary>

tl;dr: Yes, but the pattern should start with `../`.

By default, `lint-staged` executes linters only on the files present inside the project folder(where `lint-staged` is installed and run from).
So this question is relevant _only_ when the project folder is a child folder inside the git repo.
In certain project setups, it might be desirable to bypass this restriction. See [#425](https://github.com/okonet/lint-staged/issues/425), [#487](https://github.com/okonet/lint-staged/issues/487) for more context.

`lint-staged` provides an escape hatch for the same(`>= v7.3.0`). For patterns that start with `../`, all the staged files are allowed to match against the pattern.
Note that patterns like `*.js`, `**/*.js` will still only match the project files and not any of the files in parent or sibling directories.

Example repo: [sudo-suhas/lint-staged-django-react-demo](https://github.com/sudo-suhas/lint-staged-django-react-demo).

</details>

### How can i ignore files from `.eslintignore` ?

<details>
  <summary>Click to expand</summary>

ESLint throws out `warning File ignored because of a matching ignore pattern. Use "--no-ignore" to override` warnings that breaks the linting process ( if you used `--max-warnings=0` which is recommended ).

</details>

#### ESLint < 7

<details>
  <summary>Click to expand</summary>

Based on the discussion from [this issue](https://github.com/eslint/eslint/issues/9977), it was decided that using [the outlined script ](https://github.com/eslint/eslint/issues/9977#issuecomment-406420893)is the best route to fix this.

So you can setup a `.lintstagedrc.js` config file to do this:

```js
const { CLIEngine } = require('eslint')

const cli = new CLIEngine({})

module.exports = {
  '*.js': (files) =>
    'eslint --max-warnings=0 ' + files.filter((file) => !cli.isPathIgnored(file)).join(' '),
}
```

</details>

#### ESlint >= 7

<details>
  <summary>Click to expand</summary>

In versions of ESlint > 7, [isPathIgnored](https://eslint.org/docs/developer-guide/nodejs-api#-eslintispathignoredfilepath) is an async function and now returns a promise. The code below can be used to reinstate the above functionality.

This particular code uses a tiny package, [node-filter-async](https://www.npmjs.com/package/node-filter-async), to filter the files array with an async function. If you prefer to not have an extra dependency, it is quite simple to write a similar function.

Since [10.5.3](https://github.com/okonet/lint-staged/releases), any errors due to a bad eslint config will come through to the console.

```js
const { ESLint } = require('eslint')
const filterAsync = require('node-filter-async').default

const eslintCli = new ESLint()

const removeIgnoredFiles = async (files) => {
  const filteredFiles = await filterAsync(files, async (file) => {
    const isIgnored = await eslintCli.isPathIgnored(file)
    return !isIgnored
  })
  return filteredFiles.join(' ')
}

module.exports = {
  '**/*.{ts,tsx,js,jsx}': async (files) => {
    const filesToLint = await removeIgnoredFiles(files)
    return [`eslint --max-warnings=0 ${filesToLint}`]
  },
}
```

</details>
