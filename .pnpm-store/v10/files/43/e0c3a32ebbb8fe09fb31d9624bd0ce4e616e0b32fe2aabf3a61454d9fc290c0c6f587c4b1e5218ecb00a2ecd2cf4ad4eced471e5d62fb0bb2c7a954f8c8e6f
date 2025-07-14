## 1.4.3 (2023-05-17)

### Bug fixes

Include CommonJS type declarations in the package to please new TypeScript resolution settings.

## 1.4.2 (2022-10-17)

### Bug fixes

Make sure the `this` bindings in editor props defined as part of a plugin spec refers to the proper plugin type.

## 1.4.1 (2022-06-23)

### Bug fixes

Make the `SelectionRange` constructor public in the types.

## 1.4.0 (2022-05-30)

### Bug fixes

Creating a `TextSelection` with endpoints that don't point at inline positions now emits a warning. (It is technically an error, but crashing on it might be too disruptive for some existing setups.)

### New features

Include TypeScript type declarations.

## 1.3.4 (2021-01-20)

### Bug fixes

Remove (broken, poorly conceptualized) `schema` option to `EditorState.reconfigure`.

## 1.3.3 (2020-03-18)

### Bug fixes

When deleting a whole-document-selection causes default content to be generated, make sure the selection is moved to the start of the document.

## 1.3.2 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.3.1 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.3.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.2.4 (2019-08-12)

### Bug fixes

`Transaction.setSelection` now immediately checks whether the given selection points into the proper document, rather than silently accepting an invalid selection.

## 1.2.3 (2019-05-08)

### Bug fixes

The [`insertText`](https://prosemirror.net/docs/ref/#state.Transaction.insertText) method now collapses the selection to the end of the inserted text, even when given explicit start/end positions.

## 1.2.2 (2018-07-23)

### Bug fixes

The `"appendedTransaction"` meta property on appended transactions now points to the root transaction instead of at the transaction itself, which it accidentally did before.

## 1.2.1 (2018-07-02)

### Bug fixes

Fixes a bug in the default implementation of `Selection.getBookmark`.

## 1.2.0 (2018-04-05)

### New features

[`EditorState.create`](https://prosemirror.net/docs/ref/#state.EditorState^create) now accepts a `storedMark` option to set the state's stored marks.

[`EditorState.toJSON`](https://prosemirror.net/docs/ref/#state.EditorState.toJSON) and [`fromJSON`](https://prosemirror.net/docs/ref/#state.EditorState^fromJSON) persist the set of stored marks, when available.

## 1.1.1 (2018-03-15)

### Bug fixes

Throw errors, rather than constructing invalid objects, when deserializing from invalid JSON data.

## 1.1.0 (2018-01-22)

### New features

[`EditorState.toJSON`](https://prosemirror.net/docs/ref/#state.EditorState.toJSON) now accepts a string or number as argument to support the way `JSON.stringify` can call it.

## 1.0.2 (2017-12-13)

### Bug fixes

Fix issue where a character might be selected after overwriting across block nodes.

Make sure `replaceSelectionWith` doesn't needlessly copy unmarked nodes.

## 1.0.1 (2017-11-01)

### Bug fixes

Typing over marked text now properly makes the new text inherit the old text's marks.

## 0.21.0 (2017-05-03)

### Breaking changes

[`Selection.atStart`](https://prosemirror.net/docs/ref/version/0.21.0.html#state.Selection^atStart), and [`atEnd`](https://prosemirror.net/docs/ref/version/0.21.0.html#state.Selection^atEnd) no longer take a second `textOnly` parameter.

### New features

[`Selection.near`](https://prosemirror.net/docs/ref/version/0.21.0.html#state.Selection^near), [`atStart`](https://prosemirror.net/docs/ref/version/0.21.0.html#state.Selection^atStart), and [`atEnd`](https://prosemirror.net/docs/ref/version/0.21.0.html#state.Selection^atEnd) will now fall back to returning an [`AllSelection`](https://prosemirror.net/docs/ref/version/0.21.0.html#state.AllSelection) when unable to find a valid selection. This removes the (undocumented) requirement that documents always contain a valid selection position (though you'll probably still want to maintain this for practical UI reasons).

## 0.20.0 (2017-04-03)

### Breaking changes

[`Selection.near`](https://prosemirror.net/docs/ref/version/0.20.0.html#state.Selection^near) no longer accepts a `textOnly` parameter.

### Bug fixes

[`TextSelection.between`](https://prosemirror.net/docs/ref/version/0.20.0.html#state.TextSelection^between) may now return a node selection when the document does not contain a valid cursor position.

### New features

[`Selection`](https://prosemirror.net/docs/ref/version/0.20.0.html#model.Selection) objects now implement a [`content`](https://prosemirror.net/docs/ref/version/0.20.0.html#model.Selection.content) method that returns their content. This is used to determine what ends up on the clipboard when the selection is copied or dragged.

Selections may now specify multiple [ranges](https://prosemirror.net/docs/ref/version/0.20.0.html#state.Selection.ranges) that they cover, to generalize to more types of selections. The [`Selection`](https://prosemirror.net/docs/ref/version/0.20.0.html#state.Selection) superclass constructor takes an array of [ranges](https://prosemirror.net/docs/ref/version/0.20.0.html#state.SelectionRange) as optional third argument.

Selections gained new methods [`replace`](https://prosemirror.net/docs/ref/version/0.20.0.html#state.Selection.replace) and [`replaceWith`](https://prosemirror.net/docs/ref/version/0.20.0.html#state.Selection.replaceWith) to provide subclasses more control over how selections of that type respond to being deleted or overwritten.

Selections have a new method [`getBookmark`](https://prosemirror.net/docs/ref/version/0.20.0.html#state.Selection.getBookmark) that custom selection classes can implement to allow the undo history to accurately store and restore them.

The new selection class [`AllSelection`](https://prosemirror.net/docs/ref/version/0.20.0.html#state.AllSelection) can be used to select the entire document.

## 0.19.1 (2017-03-17)

### Bug fixes

Fix an issue where `ensureMarks` would fail to reset the marks to the empty set when turning off the last mark.

## 0.19.0 (2017-03-16)

### Breaking changes

`Selection.between` is now called [`TextSelection.between`](state.TextSelection^between), and only returns text selections.

The JSON representation of selections changed. [`fromJSON`](https://prosemirror.net/docs/ref/version/0.19.0.html#state.Selection^fromJSON) will continue to understand the old representation, but if your own code touches the JSON data, you'll have to adjust it.

All `Selection` objects now have [`$head`](https://prosemirror.net/docs/ref/version/0.19.0.html#state.Selection.$head)/[`$anchor`](https://prosemirror.net/docs/ref/version/0.19.0.html#state.Selection.$anchor) properties, so those can no longer be used to recognize text selections (use [`$cursor`](https://prosemirror.net/docs/ref/version/0.19.0.html#state.TextSelection.$cursor) or `instanceof`).

### New features

It is now possible to write your own [`Selection`](https://prosemirror.net/docs/ref/version/0.19.0.html#state.Selection) subclasses and set the editor selection to an instance of them (provided you implement all required methods and register them with [`Selection.jsonID`](https://prosemirror.net/docs/ref/version/0.19.0.html#state.Selection^jsonID)).

Text selections now have a [`$cursor`](https://prosemirror.net/docs/ref/version/0.19.0.html#state.TextSelection.$cursor) getter which returns a position only if this is a cursor selection.

The new [`Transaction.ensureMarks`](https://prosemirror.net/docs/ref/version/0.19.0.html#state.Transaction.ensureMarks) method makes it easier to ensure given set of active marks without needlessly setting `storedMarks`.

## 0.18.0 (2017-02-24)

### Breaking changes

Plugin objects now store their spec under a [`spec`](https://prosemirror.net/docs/ref/version/0.18.0.html#state.PluginSpec.spec) instead of an `options` property. The `options` property still works with a warning in this release.

## 0.17.1 (2017-02-08)

### Bug fixes

[`Transaction.scrolledIntoView`](https://prosemirror.net/docs/ref/version/0.17.0.html##state.Transaction.scrolledIntoView) no longer always returns true.

[`Selection.near`](https://prosemirror.net/docs/ref/version/0.17.0.html#state.Selection^neard) now takes a third `textOnly` argument, as the docs already claimed.

## 0.17.0 (2017-01-05)

### Breaking changes

The way state is updated was changed. Instead of applying an action (a raw object with a `type` property), it is now done by [applying](https://prosemirror.net/docs/ref/version/0.17.0.html#state.EditorState.apply) a [`Transaction`](https://prosemirror.net/docs/ref/version/0.17.0.html#state.Transaction).

The `EditorTransform` class was renamed [`Transaction`](https://prosemirror.net/docs/ref/version/0.17.0.html#state.Transaction), and extended to allow changing the set of stored marks and attaching custom metadata.

### New features

Plugins now accept a [`filterTransaction`](https://prosemirror.net/docs/ref/version/0.17.0.html#state.Plugin.constructor^options.filterTransaction) option that can be used to filter out transactions as they come in.

Plugins also got an [`appendTransaction`](https://prosemirror.net/docs/ref/version/0.17.0.html#state.Plugin.constructor^options.appendTransaction) option making it possible to follow up transactions with another transaction.

## 0.16.0 (2016-12-23)

### New features

Plugins now take a [`view` option](https://prosemirror.net/docs/ref/version/0.16.0.html#state.Plugin.constructor^options.view) that can be used to interact with the [editor view](https://prosemirror.net/docs/ref/version/0.16.0.html#view.EditorView).

## 0.15.0 (2016-12-10)

### Breaking changes

Selection actions no longer scroll the new selection into view by default (they never were supposed to, but due to a bug they did). Add a `scrollIntoView` property to the action to get this behavior.

## 0.14.0 (2016-11-28)

### New features

[Selection actions](https://prosemirror.net/docs/ref/version/0.14.0.html#state.SelectionAction) now have a `time` field and an (optional) `origin` field.

## 0.13.0 (2016-11-11)

### Breaking changes

[`EditorTransform.replaceSelection`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.EditorTransform.replaceSelection) now takes a [slice](https://prosemirror.net/docs/ref/version/0.13.0.html#model.Slice), no longer a node. The new [`replaceSelectionWith`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.EditorTransform.replaceSelectionWith) method should be used to replace the selection with a node. Until the next release, calling it the old way will still work and emit a warning.

### Bug fixes

The documentation for [`applyAction`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.StateField.applyAction) now actually reflects the arguments this method is given.

### New features

A state field's [`applyAction`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.StateField.applyAction) method is now passed the previous state as 4th argument, so that it has access to the new doc and selection.

[`EditorTransform.replaceSelection`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.EditorTransform.replaceSelection) now accepts a slice (or, as before, as a node), and uses a revised algorithm, relying on the [`defining`](https://prosemirror.net/docs/ref/version/0.13.0.html#model.NodeSpec.defining) node flag.

The [`TextSelection`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.TextSelection) and [`NodeSelection`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.NodeSelection) classes now have a static [`create`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.TextSelection^create) convenience method for creating selections from unresolved positions.

Allow [transform actions](https://prosemirror.net/docs/ref/version/0.13.0.html#state.TransformAction) to be extended during dispatch using [`extendTransformAction`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.extendTransformAction). Introduce [`sealed`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.TransformAction.sealed) flag to indicate when this is not safe.

A new utility function [`NodeSelection.isSelectable`](https://prosemirror.net/docs/ref/version/0.13.0.html#state.NodeSelection.isSelectable) can be used to test whether a node can be the target of a node selection.

## 0.12.0 (2016-10-21)

### Breaking changes

The interace to
[`EditorState.toJSON`](https://prosemirror.net/docs/ref/version/0.12.0.html#state.EditorState.toJSON) and
[`EditorState.fromJSON`](https://prosemirror.net/docs/ref/version/0.12.0.html#state.EditorState.fromJSON) has changed.

The way plugins declare their [state
field](https://prosemirror.net/docs/ref/version/0.12.0.html#state.Plugin.constructor.options.state) has changed. Only one
state field per plugin is supported, and state fields no longer have
hard-coded names. [`Plugin.getState`](https://prosemirror.net/docs/ref/version/0.12.0.html#state.Plugin.getState) is the
way to access plugin state now.

Plugin dependencies are no longer supported.

`Plugin.reconfigure` is gone. Plugins are now always created
with [`new Plugin`](https://prosemirror.net/docs/ref/version/0.12.0.html#state.Plugin.constructor).

Plugins no longer have a `config` field.

### Bug fixes

Node selections are now properly dropped when mapped over a
change that replaces their nodes.

### New features

[Plugin keys](https://prosemirror.net/docs/ref/version/0.12.0.html#state.PluginKey) can now be used to find
plugins by identity.

[Transform actions](https://prosemirror.net/docs/ref/version/0.12.0.html#state.TransformAction) now have a
`time` field containing the timestamp when the change was made.

## 0.11.0 (2016-09-21)

### Breaking changes

New module inheriting the [`Selection`](https://prosemirror.net/docs/ref/version/0.11.0.html#state.Selection) and
[`EditorTransform`](https://prosemirror.net/docs/ref/version/0.11.0.html#state.EditorTransform) abstraction, along with
the persistent [state](https://prosemirror.net/docs/ref/version/0.11.0.html#state.EditorState) value that is now separate
from the display logic, and the [plugin](https://prosemirror.net/docs/ref/version/0.11.0.html#state.Plugin) system.

`Selection.findAtStart`/`End` was renamed to
[`Selection.atStart`](https://prosemirror.net/docs/ref/version/0.11.0.html#state.Selection^atStart)/[`End`](https://prosemirror.net/docs/ref/version/0.11.0.html#state.Selection^atEnd),
and `Selection.findNear` to
[`Selection.near`](https://prosemirror.net/docs/ref/version/0.11.0.html#state.Selection^near).

