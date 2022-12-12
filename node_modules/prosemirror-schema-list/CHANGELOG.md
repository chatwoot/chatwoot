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

