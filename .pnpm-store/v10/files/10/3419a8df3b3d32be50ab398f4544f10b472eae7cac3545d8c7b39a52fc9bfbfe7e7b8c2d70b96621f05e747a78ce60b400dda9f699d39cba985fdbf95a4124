<p align="center">
  <img alt="Cover image" src="./docs/cover.svg" />
</p>

<h2 align="center">The CLI tool to fix huge number of ESLint errors</h2>

<p align="center">
  <em>Quick fixes, per rule.</em>
  <br />
  <em>
    Run <code>eslint --fix</code>,  disable per line, apply suggestions, and more!
  </em>
  <img alt="Screenshot" src="./docs/screenshot.png" />
</p>

## Motivation

The default ESLint output contains a lot of useful messages for developers, such as the source of the error and hints for fixing it. While this works for many use cases, it does not work well in situations where many messages are reported. For example, when introducing ESLint into a project, or when making big changes to the `.eslintrc` of a project. In these situations, the output of ESLint can be quite large, making it difficult for developers to analyze the output. It is also difficult for the developer to fix messages mechanically, because messages of many rules are mixed up in the output.

In such the above situation, I think two things are important:

- Show a summary of all problems (called _"warnings"_ or _"errors"_ in ESLint) so that the whole picture can be easily understood
  - Showing the details of each problem will confuse developers.
- Provide an efficient way to fix many problems
  - `eslint --fix` is one of the best ways to fix problems efficiently, but it auto-fixes all rule problems at once.
  - Depending on the rule, auto-fix may affect the behavior of the code, so auto-fix should be done with care.
  - Therefore, it is desirable to provide a way to auto-fix in smaller units than `eslint --fix`.

So, I created a tool called `eslint-interactive` which wraps ESLint. This tool groups all problems by rule and outputs formatted number of problems per rule. In addition to the breakdown of problems per rule, it also outputs the number of fixable problems and other hints to help developers fix problems.

It also supports the following actions in addition to `eslint --fix`. All actions can be applied for each rule:

- Display details of lint results
- Run `eslint --fix`
- Disable per line (by `// eslint-disable-next-line <rule-name>`)
- Disable per file (`/* eslint-disable <rule-name> */`)
- Convert error to warning per file (`/* eslint <rule-name>: 1 */`)
- Apply suggestions
- Make forcibly fixable and run `eslint --fix`

## Requirements

- Node.js `>=18.0.0`
- ESLint `>=8.45.0`
  - If you use ESLint `<8.45.0`, use `eslint-interactive@^10`.

## Installation

:memo: NOTE: The globally installed `eslint-interactive` is **not officially supported**. It is recommended to install `eslint-interactive` locally. See [FAQ](#why-is-global-installation-not-officially-supported).

```console
$ # For npm
$ npm i -D eslint-interactive
$ npx eslint-interactive --help

$ # For yarn
$ yarn add -D eslint-interactive
$ yarn eslint-interactive --help

$ # For pnpm
$ pnpm add -D eslint-interactive
$ pnpm exec eslint-interactive --help
```

## Usage

The interface of `eslint-interactive` is partially compatible with `eslint`. So, in most cases, simply replacing `eslint` with `eslint-interactive` in the command to lint (e.g. `eslint ./src --ext .ts,.tsx`) will work. However, eslint-interactive is installed locally, so you need to add `npx`.

```console
$ # Show help
$ npx eslint-interactive --help
eslint-interactive [file.js] [dir]

Options:
      --help                         Show help                                                                                     [boolean]
      --version                      Show version number                                                                           [boolean]
      --eslintrc                     Enable use of configuration from .eslintrc.*                                  [boolean] [default: true]
  -c, --config                       Use this configuration, overriding .eslintrc.* config options if present                       [string]
      --resolve-plugins-relative-to  A folder where plugins should be resolved from, CWD by default                                 [string]
      --ext                          Specify JavaScript file extensions                                                              [array]
      --rulesdir                     Use additional rules from this directory                                                        [array]
      --ignore-path                  Specify path of ignore file                                                                    [string]
      --format                       Specify the format to be used for the `Display problem messages` action [string] [default: "codeframe"]
      --quiet                        Report errors only                                                           [boolean] [default: false]
      --cache                        Only check changed files                                                      [boolean] [default: true]
      --cache-location               Path to the cache file or directory
                                                            [string] [default: "node_modules/.cache/eslint-interactive/10.6.0/.eslintcache"]

Examples:
  eslint-interactive ./src                                           Lint ./src/ directory
  eslint-interactive ./src ./test                                    Lint multiple directories
  eslint-interactive './src/**/*.{ts,tsx,vue}'                       Lint with glob pattern
  eslint-interactive ./src --ext .ts,.tsx,.vue                       Lint with custom extensions
  eslint-interactive ./src --rulesdir ./rules                        Lint with custom rules
  eslint-interactive ./src --no-eslintrc --config ./.eslintrc.ci.js  Lint with custom config
```

## Available actions

Actions can be executed per rule.

- Display details of lint results
  - Displays ESLint error reports.
- Run `eslint --fix`
  - Apply fixable problems.
- Disable per line
  - Add disable comments (`// eslint-disable-next-line <rule-name>`) per line.
- Disable per file
  - Add disable comments (`// eslint-disable <rule-name>`) per file.
- Convert error to warning per file
  - Add inline config comments (`/* eslint <rule-name>: 1 */`) per file.
- Apply suggestions (experimental, for experts)
  - Select one of the applicable suggestions and apply it. ([What's _suggestions_?](#whats-suggestions))
  - Users can write JavaScript code to programmatically select the suggestion to be applied.
  - The tool will tell you how to use the feature in detail. Please follow the instructions of the tool.
  - This feature is experimental and may change significantly.
- Make forcibly fixable and run `eslint --fix` (experimental, for experts)
  - This feature make forcibly un-fixable problems fixable, and apply them.
  - The tool will tell you how to use the feature in detail. Please follow the instructions of the tool.
  - This feature is experimental and may change significantly.

## Programmable API

See [Programmable API documentation](./docs/programmable-api.md).

## FAQ

### What's _suggestions_?

> Excerpt a quote from [official ESLint documentation](https://eslint.org/docs/developer-guide/working-with-rules#providing-suggestions).

In some cases fixes aren't appropriate to be automatically applied, for example, if a fix potentially changes functionality or if there are multiple valid ways to fix a rule depending on the implementation intent. In such a case, the ESLint rule provides candidates for a fix. These are called _suggestions_.

Suggestion can be one or more. The user has to manually decide if that fix should be applied or which fix should be applied because automatically applying of suggestion is inappropriate. For this reason, ESLint has stated that it will not officially provide a way to automatically apply suggestion ([ref](https://github.com/eslint/rfcs/tree/64b2511da6f2c10e1692671315459eb916aea53f/designs/2019-suggestions#:~:text=Unlike%20fixes%2C%20suggestion%20will%20not%20expose%20a%20new%20API%20function)). Instead, tools such as [`vscode-eslint`](https://github.com/microsoft/vscode-eslint) allow users to apply suggestions manually ([ref](https://github.com/microsoft/vscode-eslint/pull/814#issuecomment-587011529)).

### Why is global installation not officially supported?

`eslint` is installed locally in most projects. In such a case, if `eslint-interactive` is installed globally, it will be installed in a different space than `eslint`. The space separation makes some resources of `eslint-interactive` inaccessible from `eslint` and may break them (ref: [#77](https://github.com/mizdra/eslint-interactive/issues/77)). Therefore, global installation of `eslint-interactive` is not officially supported.

### Is global installation prohibited?

No. `eslint-interactive` does not prohibit global installation. Global installation is allowed because it has the advantage of saving installation effort. However, it is not officially supported and users must use it at their own risk.

If the global installation does not work, you can send a patch by pull request. However, whether the patch will be accepted depends on the case.

### What's the difference from [eslint-nibble](https://github.com/IanVS/eslint-nibble)?

A tool similar to `eslint-interactive` is [eslint-nibble](https://github.com/IanVS/eslint-nibble). Both tools solve the same problem, but `eslint-interactive` has some features that `eslint-nibble` does not have. For example, `eslint-interactive` prints the number of fixable problems per rule, while `eslint-nibble` does not. Also, `eslint-interactive` has various tricks to speed up the cycle of auto-fixing per-rule, but `eslint-nibble` auto-fixes once and terminates the process every time, so it is not as fast as `eslint-interactive`.

I think these features are very important to solve the aforementioned problem. At first, I thought of implementing these features in `eslint-nibble`, but it required a major rewrite of the code, so I implemented it as a new tool `eslint-interactive`. Although `eslint-interactive` is a tool independent of `eslint-nibble`, it is influenced by the ideas of `eslint-nibble` and inherits some of its code. That's why you can find the names of [@IanVS](https://github.com/IanVS) and others in [the license of `eslint-interactive`](https://github.com/mizdra/eslint-interactive/blob/main/LICENSE).

Thanks, [@IanVS](https://github.com/IanVS).

### What's the difference from [suppress-eslint-errors](https://github.com/amanda-mitchell/suppress-eslint-errors)?

[suppress-eslint-errors](https://github.com/amanda-mitchell/suppress-eslint-errors) is an excellent tool to add comments for disable mechanically. Just like `eslint-interactive`, it allows you to add disable comments for each rule and leave the purpose of disable as a comment. There is no functional difference between the two, but there is a difference in the API used to insert the comments.

`suppress-eslint-errors` uses [`jscodeshift`](https://github.com/facebook/jscodeshift) to insert comments. `jscodeshift` modifies the file in parallel, so `suppress-eslint-errors` has the advantage of being able to insert comments faster. However, `jscodeshift` cannot reuse the AST of ESLint, so you need to reparse the code in `jscodeshift`. This means that you have to pass `jscodeshift` the information it needs to parse your code (parser type, parser options). In fact, `suppress-eslint-errors` requires `--extensions` and `--parser` command line option. Normally, users specify the parsing options in `.eslintrc`, so passing these options may seem cumbersome. Also, due to the difference in the way ESLint and `jscodeshift` parse, it may not be possible to insert comments correctly.

On the other hand, `eslint-interactive` uses [`ESLint.outputFixes`](https://eslint.org/docs/developer-guide/nodejs-api#-eslintoutputfixesresults) to insert comments. It uses ESLint's API to do everything from parsing the code to inserting the comments, so it works as expected in many cases. Also, `eslint-interactive` will parse the code using the parsing options specified in `.eslintrc`. Therefore, comments can be inserted without any additional command line options. By the way, comment insertion is slower than `suppress-eslint-errors` because, unlike `suppress-eslint-errors`, it cannot modify files in parallel. However, this limitation may be improved when ESLint supports parallel processing in the near future.

## Benchmark

- https://mizdra.github.io/eslint-interactive/dev/bench/
