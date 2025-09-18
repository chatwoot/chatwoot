## 1.4.1 (2024-07-14)

### Bug fixes

Add attribute type validation for ordered list nodes.

## 1.4.0 (2024-06-10)

### New features

The new `splitListItemKeepMarks` command can be used like `splitListItem` but will keep the active marks from the original item.

## 1.3.0 (2023-06-01)

### New features

`splitListItem` now takes an optional second argument to set the attributes of the new list item node. Rename parameter

## 1.2.3 (2023-05-17)

### Bug fixes

Include CommonJS type declarations in the package to please new TypeScript resolution settings.

## 1.2.2 (2022-09-09)

### Bug fixes

Fix an issue where `liftListItem` could create adjacent sublists when lifting an item with sub-items.

## 1.2.1 (2022-07-20)

### Bug fixes

Fix a regression where lifting a nested list could crash.

## 1.2.0 (2022-05-30)

### New features

Include TypeScript type declarations.

## 1.1.6 (2021-09-21)

### Bug fixes

Fix a crash in `liftListItem` that happens when list items that can't be merged are lifted together.

## 1.1.5 (2021-07-06)

### Bug fixes

Fix an issue where `splitListItem` would delete content when activated in a sublist that had content directly after it.

## 1.1.4 (2020-08-11)

### Bug fixes

Fix a regression where `liftListItem` couldn't lift a paragraph from the end of a composite list item.

## 1.1.3 (2020-08-04)

### Bug fixes

Fix an issue where `splitListItem` could delete other content in the item when pressing enter in an empty paragraph that had other content below it in a list item.

## 1.1.2 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.1.1 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.1.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.0.4 (2019-10-08)

### Bug fixes

Fix regression where `splitListItem` doesn't work at the end of an item when the content for list items has different first and non-first allowed nodes.

## 1.0.3 (2019-04-19)

### Bug fixes

`sinkListItem` will no longer copy the attributes of the parent list when creating an inner list.

## 1.0.2 (2019-01-31)

### Bug fixes

`sinkListItem` no longer preserves marks from the outer list when creating an inner list.

## 1.0.1 (2018-03-16)

### Bug fixes

Fixes a bug that caused [`wrapInList`](https://prosemirror.net/docs/ref/#schema-list.wrapInList) to split list items in the wrong place.

## 0.23.0 (2017-09-13)

### Bug fixes

The [`splitListItem` command](https://prosemirror.net/docs/ref/version/0.23.0.html#schema-list.splitListItem) now splits the parent list item when executed in a (trailing) empty list item in a nested list.

## 0.20.0 (2017-04-03)

### New features

The [`liftListItem`](https://prosemirror.net/docs/ref/version/0.20.0.html#schema-list.liftListItem) command can now lift items out of a list entirely, when the parent node isn't another list.

## 0.11.0 (2016-09-21)

### Breaking changes

New module combining the node [specs](https://prosemirror.net/docs/ref/version/0.11.0.html#model.NodeSpec) from
[schema-basic](https://prosemirror.net/docs/ref/version/0.11.0.html#schema-basic), and the list-related
[commands](https://prosemirror.net/docs/ref/version/0.11.0.html#commands) from the commands module.

