## 1.4.0 (2024-01-30)

### New features

Input rules now take an `inCode` option that controls whether they should apply inside nodes marked as code.

## 1.3.0 (2023-11-16)

### New features

Input rules can now be set to be non-undoable, preventing `undoInputRule` from rolling them back.

## 1.2.1 (2023-05-17)

### Bug fixes

Include CommonJS type declarations in the package to please new TypeScript resolution settings.

## 1.2.0 (2022-05-30)

### New features

Include TypeScript type declarations.

## 1.1.3 (2020-09-16)

### Bug fixes

Fix crash when undoing input rules when the rule was triggered without inserting text.

## 1.1.2 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.1.1 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.1.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.0.4 (2019-05-17)

### Bug fixes

Fix a null-dereference when running in strict mode.

## 1.0.3 (2019-05-17)

### Bug fixes

Prevent input rules from running during compositions, since they will annoyingly interrupt them.

## 1.0.2 (2019-05-08)

### Bug fixes

Improve selection handling during text replacement.

## 1.0.1 (2017-11-10)

### Bug fixes

Input rules no longer fire in blocks that have their `code` spec set to true.

## 0.23.0 (2017-09-13)

### Breaking changes

Schema-specific rule-builders `blockQuoteRule`, `orderedListRule`, `bulletListRule`, `codeBlockRule`, and `headingRule`, along with the `allInputRules` array, are no longer included in this module.

## 0.22.0 (2017-06-29)

### Bug fixes

Input rules with spaces in them now match any whitespace where the space is expected, to avoid mysteriously not working when a non-breaking space is present.

## 0.20.0 (2017-04-03)

### Breaking changes

The input rules [plugin](https://prosemirror.net/docs/ref/version/0.20.0.html#inputrules.inputRules) no longer implicitly binds backspace to undo the last applied rule.

### New features

This module now exposes a command [`undoInputRule`](https://prosemirror.net/docs/ref/version/0.20.0.html#inputrules.undoInputRule), which will revert an input rule when run directly after one was applied.

## 0.11.0 (2016-09-21)

### Breaking changes

Moved into a separate module.

You can now add this plugin multiple times to add different sets of
rules to an editor (if you want). It is not possible to change the set
of rules of an existing plugin instance.

[Rules](https://prosemirror.net/docs/ref/version/0.11.0.html#inputrules.InputRule) no longer take a `filter` argument.

The signature of the `handler` callback for a
[rule](https://prosemirror.net/docs/ref/version/0.11.0.html#inputrules.InputRule) changed.

