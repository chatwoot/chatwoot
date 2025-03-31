## 1.3.2 (2023-05-17)

### Bug fixes

Include CommonJS type declarations in the package to please new TypeScript resolution settings.

## 1.3.1 (2022-06-07)

### Bug fixes

Export CSS file from package.json.

## 1.3.0 (2022-05-30)

### New features

Include TypeScript type declarations.

## 1.2.2 (2022-02-25)

### Bug fixes

Make sure compositions started from a gap cursor have their inline context created in advance, so that they don't get aborted right away.

## 1.2.1 (2021-12-20)

### Bug fixes

Fix an issue where a gap cursor would fail to show up at the start or end of some isolating nodes.

## 1.2.0 (2021-09-20)

### New features

The `GapCursor` constructor is now public.

## 1.1.5 (2020-04-05)

### Bug fixes

Fix an issue where the gap cursor plugin would sometimes cause perfectly selectable content to be skipped when moving the selection with the arrow keys.

## 1.1.4 (2020-03-20)

### Bug fixes

Improve behavior around unselectable block nodes.

## 1.1.3 (2020-01-22)

### Bug fixes

Fix a crash in documents that have a textblock as top node.

## 1.1.2 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.1.1 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.1.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.0.4 (2019-06-24)

### Bug fixes

Do not show a gap cursor when the view isn't editable.

## 1.0.3 (2018-10-01)

### Bug fixes

Don't blanket-forbid gap cursors next to textblocks

## 1.0.2 (2018-03-15)

### Bug fixes

Throw errors, rather than constructing invalid objects, when deserializing from invalid JSON data.

## 1.0.1 (2018-02-16)

### Bug fixes

Prevent issue where clicking on a selectable node near a valid gap cursor position would create a gap cursor rather than select the node.

## 1.0.0 (2017-10-13)

### New features

Valid gap cursor positions are not determined in a way that allows them inside nested nodes. By default, any position where a textblock can be inserted is valid gap cursor position.

Nodes can override whether they allow gap cursors with the `allowGapCursor` property in their spec.

## 0.23.1 (2017-09-19)

### Bug fixes

Moving out of a table with the arrow keys now creates a gap cursor when appropriate.

