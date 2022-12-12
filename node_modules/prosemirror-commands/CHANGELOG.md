## 1.1.5 (2021-01-14)

### Bug fixes

`joinBackward` and `joinForward` will now, when the textblock after the cut can't be moved into the structure before the cut, try to just join the inline content onto the last child in the structure before the cut.

`toggleMark` will now skip whitespace at the start and end of the selection when adding a mark.

## 1.1.4 (2020-04-15)

### Bug fixes

`selectNodeForward` and `selectNodeBackward` will now also select nodes next to a gap cursor (or other custom empty selection type).

## 1.1.3 (2020-01-03)

### Bug fixes

Fix an issue where, since version 1.7.4 of prosemirror-model, `splitBlock` fails to create the expected new textblock in some schemas.

## 1.1.2 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.1.1 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.1.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.0.8 (2019-05-14)

### Bug fixes

Fix a crash caused by using a position potentially outside the document in [`splitBlock`](https://prosemirror.net/docs/ref/#commands.splitBlock).

## 1.0.7 (2018-04-09)

### Bug fixes

Fixes an issue where [`joinBackward`](https://prosemirror.net/docs/ref/#commands.joinBackward) might create a selection pointing into the old document.

## 1.0.6 (2018-04-04)

### Bug fixes

The [`setBlockType` command](https://prosemirror.net/docs/ref/#commands.setBlockType) command is now considered applicable when _any_ of the selected textblocks can be changed (it used to only look at the first one).

Fix crash when calling [`splitBlock`](https://prosemirror.net/docs/ref/#commands.splitBlock) when the selection isn't in a block node (by disabling the command in that case).

Fixes an issue where [`joinForward`](https://prosemirror.net/docs/ref/#commands.joinForward) might create a selection pointing into the old document.

## 1.0.5 (2018-01-30)

### Bug fixes

Fix crash in [`splitBlock`](https://prosemirror.net/docs/ref/#commands.splitBlock) when `defaultContentType` returns null.

## 1.0.4 (2018-01-18)

### Bug fixes

Pressing delete in front of an [isolating](https://prosemirror.net/docs/ref/#model.NodeSpec.isolating) node no longer opens it.

## 1.0.3 (2017-12-19)

### Bug fixes

Fix issue where [`joinBackward`](https://prosemirror.net/docs/ref/#commands.joinBackward) would sometimes create an invalid selection.

## 1.0.2 (2017-11-21)

### Bug fixes

[`splitBlock`](https://prosemirror.net/docs/ref/#commands.splitBlock) no longer crashes when used in a block that's it's parent node's only allowed child.

## 1.0.0 (2017-10-13)

### New features

The [`setBlockType` command](https://prosemirror.net/docs/ref/#commands.setBlockType) can now be used to change the types of multiple selected textblocks (rather than only one).

The platform-dependent versions of the [base keymap](https://prosemirror.net/docs/ref/#commands.baseKeymap) are now exported separately as [`pcBaseKeymap`](https://prosemirror.net/docs/ref/#commands.pcBaseKeymap) and [`macBaseKeymap`](https://prosemirror.net/docs/ref/#commands.macBaseKeymap).

## 0.23.0 (2017-09-13)

### Breaking changes

`joinForward` and `joinBackward` no longer fall back to selecting the next node when no other behavior is possible. There are now separate commands `selectNodeForward` and `selectNodeBackward` that do this, which the base keymap binds as fallback behavior.

[`baseKeymap`](https://prosemirror.net/docs/ref/version/0.23.0.html#commands.baseKeymap) no longer binds keys for `joinUp`, `joinDown`, `lift`, and `selectParentNode`.

### New features

New commands [`selectNodeForward`](https://prosemirror.net/docs/ref/version/0.23.0.html#commands.selectNodeForward) and [`selectNodeBackward`](https://prosemirror.net/docs/ref/version/0.23.0.html#commands.selectNodeBackward) added.

## 0.20.0 (2017-04-03)

### New features

The new [`selectAll` command](https://prosemirror.net/docs/ref/version/0.20.0.html#commands.selectAll), bound to Mod-a in the base keymap, sets the selection to an [`AllSelection`](https://prosemirror.net/docs/ref/version/0.20.0.html#state.AllSelection).

## 0.19.0 (2017-03-16)

### Bug fixes

Calling `joinBackward` at the start of a node that can't be joined no longer raises an error.

## 0.18.0 (2017-02-24)

### New features

New command [`splitBlockKeepMarks`](https://prosemirror.net/docs/ref/version/0.18.0.html#commands.splitBlockKeepMarks) which splits a block but preserves the marks at the cursor.

## 0.17.1 (2017-01-16)

### Bug fixes

Make sure [`toggleMark`](https://prosemirror.net/docs/ref/version/0.17.0.html#commands.toggleMark) also works in the top-level node (when it is a textblock).

## 0.17.0 (2017-01-05)

### Breaking changes

The `dispatch` function passed to commands is now passed a [`Transaction`](https://prosemirror.net/docs/ref/version/0.17.0.html#state.Transaction), not an action object.

## 0.15.0 (2016-12-10)

### Breaking changes

Drops suppport for `delete(Char|Word)(Before|After)` and `move(Back|For)ward`, since we are now letting the browser handle those natively.

### Bug fixes

The [`joinForward`](https://prosemirror.net/docs/ref/version/0.15.0.html#commands.joinForward) and [`joinBackward`](https://prosemirror.net/docs/ref/version/0.15.0.html#commands.joinBackward) commands can now strip out markup and nodes that aren't allowed in the joined node.

### New features

A new command [`exitCode`](https://prosemirror.net/docs/ref/version/0.15.0.html#commands.exitCode) allows a user to exit a code block by creating a new paragraph below it.

The [`joinForward`](https://prosemirror.net/docs/ref/version/0.15.0.html#commands.joinForward) and [`joinBackward`](https://prosemirror.net/docs/ref/version/0.15.0.html#commands.joinBackward) commands now use a bidirectional-text-aware way to determine whether the cursor is at the proper side of its parent textblock when they are passed a view.

## 0.13.0 (2016-11-11)

### New features

The [`autoJoin`](https://prosemirror.net/docs/ref/version/0.13.0.html#commands.autoJoin) function allows you to wrap command functions so that when the command makes nodes of a certain type occur next to each other, they are automatically joined.

## 0.12.0 (2016-10-21)

### Bug fixes

Fix crash when backspacing into nodes with complex content
expressions.

## 0.11.0 (2016-09-21)

### Breaking changes

Moved into a separate module.

The interface for command functions was changed to work with the new
[state](https://prosemirror.net/docs/ref/version/0.11.0.html#state.EditorState)/[action](https://prosemirror.net/docs/ref/version/0.11.0.html#state.Action) abstractions.

