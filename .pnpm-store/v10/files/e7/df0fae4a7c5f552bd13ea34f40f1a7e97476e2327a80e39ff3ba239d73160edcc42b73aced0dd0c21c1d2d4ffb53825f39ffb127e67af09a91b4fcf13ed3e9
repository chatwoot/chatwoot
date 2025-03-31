## 1.2.2 (2023-05-17)

### Bug fixes

Include CommonJS type declarations in the package to please new TypeScript resolution settings.

## 1.2.1 (2023-02-14)

### Bug fixes

Work around macOS putting the unmodified character in `KeyboardEvent.key` when Cmd is held down, fixing shift-cmd-letter bindings.

## 1.2.0 (2022-05-30)

### New features

Include TypeScript type declarations.

## 1.1.5 (2021-10-29)

### Bug fixes

Fix issue where iPhones and iPads with a hardware keyboard didn't have Mod converted to Cmd.

## 1.1.4 (2020-05-18)

### Bug fixes

Fall through to the name associated with a key's `keyCode` when the character produced isn't ASCII and isn't directly bound.

## 1.1.3 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.1.2 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.1.1 (2019-11-15)

### Bug fixes

Fix an issue where keyboards layouts that use shift to produce characters that are created without shift on a US keyboard would fail to fire bindings for those keys that include the Shift- modifier.

## 1.1.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.0.2 (2019-10-16)

### Bug fixes

Upgrade w3c-keyname package dependency.

## 1.0.1 (2018-02-23)

### Bug fixes

Upgrade `w3c-keyname` dependency to version 1.1.8 to prevent users getting stuck with a buggy version.

## 0.22.1 (2017-07-14)

### Bug fixes

Bindings like Alt-3 should now fire even if your keyboard produces a special character for that combination.

## 0.18.0 (2017-02-24)

### New features

Add a [`keydownHandler`](https://prosemirror.net/docs/ref/version/0.18.0.html#keymap.keydownHandler) function, which takes a keymap and produces a [`handleKeydown` prop](https://prosemirror.net/docs/ref/version/0.18.0.html#view.EditorProps.handleKeydown)-style function.

## 0.12.0 (2016-10-21)

### Breaking changes

Key names are now based on
[`KeyboardEvent.key`](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key)
instead of
[`.code`](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code).
This means that, for character-producing keys, you'll want to use the
character typed, not the key name. So `Ctrl-Z` now means uppercase Z,
and you'll usually want `Ctrl-z` instead. Single-quoted key names are
no longer supported.

## 0.11.0 (2016-09-21)

### Breaking changes

New module, takes the same role as the old built-in keymap support in
the `ProseMirror` class.

