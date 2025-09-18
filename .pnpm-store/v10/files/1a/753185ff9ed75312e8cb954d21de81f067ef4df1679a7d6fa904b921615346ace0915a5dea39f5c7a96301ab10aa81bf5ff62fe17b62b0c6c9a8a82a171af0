## 1.10.0 (2024-08-13)

### New features

`setBlockType` can now take a function that computes attributes for the new nodes, instead of a static attribute object.

## 1.9.0 (2024-05-06)

### Bug fixes

Fix an issue in `ReplaceAroundStep.map` that broke mapping steps that wrapped content over steps that inserted content at the start of the step.

### New features

`setBlockMarkup` now uses the linebreak equivalent node defined in the schema.

## 1.8.0 (2023-10-01)

### New features

The new `DocAttrStep` can be used to set attributes on the document's top node.

`Transform.setDocAttribute` can be used to create a `DocAttrStep` in a transform.

## 1.7.5 (2023-08-22)

### Bug fixes

Fix a failure in `replaceRange` to drop wrapper nodes when the same wrapper is already present.

## 1.7.4 (2023-07-28)

### Bug fixes

When using `setBlockType` to convert a code block to a type of node that doesn't contain code, replace newlines with spaces.

## 1.7.3 (2023-06-01)

### Bug fixes

Fix a bug in `canSplit` that made it interpret the `typesAfter` argument incorrectly on splits of depth greater than 1.

## 1.7.2 (2023-05-17)

### Bug fixes

Include CommonJS type declarations in the package to please new TypeScript resolution settings.

## 1.7.1 (2023-01-20)

### Bug fixes

Keep content in isolating nodes inside their parent when fitting a replace step.

`Transform.setNodeMarkup` will no longer clear the node's marks when it isn't given an array of marks.

## 1.7.0 (2022-08-16)

### New features

The new `AttrStep` (and `Transform.setNodeAttribute`) can be used to set individual attributes on a node.

`AddNodeMarkStep` and `RemoveNodeMarkStep` can now be used to add and remove marks on individual nodes. `Transform.addNodeMark`/`removeNodeMark` provide an interface to these in transform objects.

## 1.6.0 (2022-06-01)

### Bug fixes

Allow replace steps to be mapped through changes that delete content next to their start and end points, as long as no delete spans across those points.

### New features

`MapResult` objects now provide information about whether the tokens before, after, and around the position were deleted.

## 1.5.0 (2022-05-30)

### New features

Include TypeScript type declarations.

## 1.4.2 (2022-04-05)

### Bug fixes

Make replacements that span to the end of a textblock more consistent with those ending in the middle of the block.

## 1.4.1 (2022-03-31)

### Bug fixes

`replaceRange` will now close multiple defining parent nodes when appropriate.

## 1.4.0 (2022-03-21)

### New features

Node specs can now use the `definingForContent` and `definingAsContext` properties to opt in to specific parts of the existing `defining` behavior.

## 1.3.4 (2022-02-04)

### Bug fixes

Make sure that constructing an empty `StepMap` returns `StepMap.empty`.

## 1.3.3 (2021-09-29)

### Bug fixes

Fix an inconsistency in `deleteRange` where it would delete the parent node for ranges covering all textblocks in a given parent.

## 1.3.2 (2021-04-06)

### Bug fixes

Fix a regression in `dropPoint` that caused it to dereference undefined in some circumstances.

## 1.3.1 (2021-04-01)

### Bug fixes

Fix a crash in `Transform.replaceRange` when called with under specific circumstances.

Fix an issue where `dropPoint` could return an invalid drop point.

## 1.3.0 (2021-03-31)

### New features

The various properties of subclasses of `Step` (`ReplaceStep`, `ReplaceAroundStep`, `AddMarkStep`, and `RemoveMarkStep`) are now part of the public interface.

## 1.2.12 (2021-02-20)

### Bug fixes

Fix a bug where merging replace steps with the `structure` flag could create steps that couldn't be applied.

## 1.2.11 (2021-02-06)

### Bug fixes

Fix an issue in `Transform.removeMark` where the mark type was passed through to be removed instead of the mark itself.

## 1.2.10 (2021-02-05)

### Bug fixes

Fix an issue where `Transform.removeMark`, when given a mark type, would only remove the first instance from nodes that had multiple marks of the type.

## 1.2.9 (2021-01-19)

### Bug fixes

Fix an issue where `AddMarkStep` would mark inline nodes with content.

## 1.2.8 (2020-08-11)

### Bug fixes

Fix an issue where fitting a slice at the top level of the document would, in some circumstances, crash.

## 1.2.7 (2020-07-09)

### Bug fixes

Fix an issue where in some cases replace fitting would insert an additional bogus node when fitting content into nodes with strict content restrictions.

## 1.2.6 (2020-06-10)

### Bug fixes

Fix an issue where creating a replace step would sometimes fail due to unmatchable close tokens after the replaced range.

## 1.2.5 (2020-04-15)

### Bug fixes

Rewrite the slice-fitting code used by `replaceStep` to handle a few more corner cases.

## 1.2.4 (2020-03-10)

### Bug fixes

Fix `joinPoint` to return check whether the parent node allows a given join.

## 1.2.3 (2019-12-03)

### Bug fixes

Fix a crash in `deleteRange` that occurred when deleting a region that spans to the ends of two nodes at different depths.

## 1.2.2 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.2.1 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.2.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.1.6 (2019-11-01)

### Bug fixes

Fixes an issue where deleting a range from the start of block A to the end of block B would leave you with an empty block of type B.

## 1.1.5 (2019-10-02)

### Bug fixes

Fix crash in building replace steps for open-ended slices with complicated node content expressions.

## 1.1.4 (2019-08-26)

### Bug fixes

[`Mapping.invert`](https://prosemirror.net/docs/ref/#transform.Mapping.invert) is now part of the documented API (it was intented to be public from the start, but a typo prevented it from showing up in the docs).

Fix an issue where a replace could needlessly drop content when the first node of the slice didn't fit the target context.

`replaceRange` now more aggressively expands the replaced region if `replace` fails to place the slice.

## 1.1.3 (2018-07-03)

### Bug fixes

Replacing from a code block into a paragraph that has marks, or similar scenarios that would join content with the wrong marks into a node, no longer crashes.

## 1.1.2 (2018-06-29)

### Bug fixes

Fix issue where [`replaceRange`](https://prosemirror.net/docs/ref/#transform.Transform.replaceRange) might create invalid nodes.

## 1.1.1 (2018-06-26)

### Bug fixes

Fix issues in the new [`dropPoint`](https://prosemirror.net/docs/ref/#transform.dropPoint) function.

## 1.1.0 (2018-06-20)

### New features

[`Transform.getMirror`](https://prosemirror.net/docs/ref/#transform.Transform.getMirror), usable in obscure circumstances for inspecting the mirroring structure or a transform, is now a public method.

New utility function [`dropPoint`](https://prosemirror.net/docs/ref/#transform.dropPoint), which tries to find a valid position for dropping a slice near a given document position.

## 1.0.10 (2018-04-15)

### Bug fixes

[`Transform.setBlockType`](https://prosemirror.net/docs/ref/#transform.Transform.setBlockType) no longer drops marks on the nodes it updates.

## 1.0.9 (2018-04-05)

### Bug fixes

Fix a bug that made [`replaceStep`](https://prosemirror.net/docs/ref/#transform.replaceStep) unable to generate wrapper nodes in some circumstances.

## 1.0.8 (2018-04-04)

### Bug fixes

Fixes an issue where [`replaceStep`](https://prosemirror.net/docs/ref/#transform.replaceStep) could generate slices that internally violated the schema.

## 1.0.7 (2018-03-21)

### Bug fixes

[`Transform.deleteRange`](https://prosemirror.net/docs/ref/#transform.Transform.deleteRange) will cover unmatched opening at the start of the deleted range.

## 1.0.6 (2018-03-15)

### Bug fixes

Throw errors, rather than constructing invalid objects, when deserializing from invalid JSON data.

## 1.0.5 (2018-03-14)

### Bug fixes

[`replaceStep`](https://prosemirror.net/docs/ref/#transform.replaceStep) will now return null rather than an empty step when it fails to place the slice.

Avoid duplicating defining parent nodes in [`replaceRange`](https://prosemirror.net/docs/ref/#tranform.Transform.replaceRange).

## 1.0.4 (2018-02-23)

### Bug fixes

Fix overeager closing of destination nodes when fitting a slice during replacing.

## 1.0.3 (2018-02-23)

### Bug fixes

Fix a problem where slice-placing didn't handle content matches correctly and might generate invalid steps or fail to generate steps though a valid one exists.

Allows adjacent nodes from an inserted slice to be placed in different parent nodes, allowing `Transform.replace` to create fits that weren't previously found.

## 1.0.2 (2018-01-24)

### Bug fixes

Fixes a crash in [`replace`](https://prosemirror.net/docs/ref/#transform.Transform.replace).

## 1.0.1 (2017-11-10)

### Bug fixes

The errors raised by [`Transform.step`](https://prosemirror.net/docs/ref/#transform.Transform.step) now properly inherit from Error.

## 1.0.0 (2017-10-13)

### Bug fixes

When [`setBlockType`](https://prosemirror.net/docs/ref/#transform.Transform.setBlockType) comes across a textblock that can't be changed due to schema constraints, it skips it instead of failing.

[`canSplit`](https://prosemirror.net/docs/ref/#transform.canSplit) now returns false when the requested split goes through isolating nodes.

## 0.24.0 (2017-09-25)

### Breaking changes

The `setNodeType` method on transforms is now more descriptively called [`setNodeMarkup`](https://prosemirror.net/docs/ref/version/0.24.0.html#transform.Transform.setNodeMarkup). The old name will continue to work with a warning until the next release.

## 0.23.0 (2017-09-13)

### Breaking changes

[`Step.toJSON`](https://prosemirror.net/docs/ref/version/0.23.0.html#transform.Step.toJSON) no longer has a default implementation.

Steps no longer have an `offset` method. Map them through a map created with [`StepMap.offset`](https://prosemirror.net/docs/ref/version/0.23.0.html#transform.StepMap^offset) instead.

The `clearMarkup` method on [`Transform`](https://prosemirror.net/docs/ref/version/0.23.0.html#transform.Transform) is no longer supported (you probably needed [`clearIncompatible`](https://prosemirror.net/docs/ref/version/0.23.0.html#transform.Transform.clearIncompatible) anyway).

### Bug fixes

Pasting a list item at the start of a non-empty textblock now wraps the textblock in a list.

Marks on open nodes at the left of a slice are no longer dropped by [`Transform.replace`](https://prosemirror.net/docs/ref/version/0.23.0.html#transform.Transform.replace).

### New features

`StepMap` now has a static method [`offset`](https://prosemirror.net/docs/ref/version/0.23.0.html#transform.StepMap^offset), which can be used to create a map that offsets all positions by a given distance.

Transform objects now have a [`clearIncompatible`](https://prosemirror.net/docs/ref/version/0.23.0.html#transform.Transform.clearIncompatible) method that can help make sure a node's content matches another node type.

## 0.22.2 (2017-07-06)

### Bug fixes

Fix another bug in the way `canSplit` interpreted its `typesAfter` argument.

## 0.22.1 (2017-07-03)

### Bug fixes

Fix crash in [`canSplit`](https://prosemirror.net/docs/ref/version/0.22.0.html#transform.canSplit) when an array containing null fields is passed as fourth argument.

## 0.22.0 (2017-06-29)

### Bug fixes

[`canSplit`](https://prosemirror.net/docs/ref/version/0.22.0.html#transform.canSplit) now returns false when given custom after-split node types that don't match the content at that point.

Fixes [`canLift`](https://prosemirror.net/docs/ref/version/0.22.0.html#transform.canLift) incorrectly returning null when lifting into an isolating node.

## 0.21.1 (2017-05-16)

### Bug fixes

[`addMark`](https://prosemirror.net/docs/ref/version/0.21.0.html#transform.Transform.addMark) no longer assumes marks always [exclude](https://prosemirror.net/docs/ref/version/0.21.0.html#model.MarkSpec.excludes) only themselves.

`replaceRange`](https://prosemirror.net/docs/ref/version/0.21.0.html#transform.Transform.replaceRange) and [`deleteRange`](https://prosemirror.net/docs/ref/version/0.21.0.html#transform.Transform.deleteRange) will no longer expand the range across isolating node boundaries.

## 0.20.0 (2017-04-03)

### Bug fixes

Fixes issue where replacing would sometimes unexpectedly split nodes.

## 0.18.0 (2017-02-24)

### New features

[`Transform.setNodeType`](https://prosemirror.net/docs/ref/version/0.18.0.html#transform.Transform.setNodeType) now takes an optional argument to set the new node's attributes.

Steps now provide an [`offset`](https://prosemirror.net/docs/ref/version/0.18.0.html#transform.Step.offset) method, which makes it possible to create a copy the step with its position offset by a given amount.

[`docChanged`](https://prosemirror.net/docs/ref/version/0.18.0.html#transform.Transform.docChanged) is now a property on the `Transform` class, rather than its `Transaction` subclass.

`Mapping` instances now have [`invert`](https://prosemirror.net/docs/ref/version/0.18.0.html#transform.Mapping.invert) and [`appendMappingInverted`](https://prosemirror.net/docs/ref/version/0.18.0.html#transform.Mapping.appendMappingInverted) methods to make mapping through them in reverse easier.

## 0.15.0 (2016-12-10)

### Bug fixes

Fix bug where pasted/inserted content would sometimes get incorrectly closed at the right side.

## 0.13.0 (2016-11-11)

### Bug fixes

Fix issue where [`Transform.replace`](https://prosemirror.net/docs/ref/version/0.13.0.html#transform.Transform.replace) would, in specific circumstances, unneccessarily drop content.

### New features

The new [`Transform`](https://prosemirror.net/docs/ref/version/0.13.0.html#transform.Transform) method [`replaceRange`](https://prosemirror.net/docs/ref/version/0.13.0.html#transform.Transform.replaceRange), [`replaceRangeWith`](https://prosemirror.net/docs/ref/version/0.13.0.html#transform.Transform.replaceRangeWith), and [`deleteRange`](https://prosemirror.net/docs/ref/version/0.13.0.html#transform.Transform.deleteRange) provide a way to replace and delete content in a 'do what I mean' way, automatically expanding the replaced region over empty parent nodes and including the parent nodes in the inserted content when appropriate.

## 0.12.1 (2016-11-01)

### Bug fixes

Fix bug in `Transform.setBlockType` when used in a transform that already has steps.

## 0.12.0 (2016-10-21)

### Breaking changes

Mapped positions now count as deleted when the token to the
side specified by the `assoc` parameter is deleted, rather than when
both tokens around them are deleted. (This is usually what you already
wanted anyway.)

## 0.11.0 (2016-09-21)

### Breaking changes

Moved into a separate module.

The `Remapping` class was renamed to `Mapping` and works differently
(simpler, grows in only one direction, and has provision for mapping
through only a part of it).

[`Transform`](https://prosemirror.net/docs/ref/version/0.11.0.html#transform.Transform) objects now build up a `Mapping`
instead of an array of maps.

`PosMap` was renamed to [`StepMap`](https://prosemirror.net/docs/ref/version/0.11.0.html#transform.StepMap) to make it
clearer that this applies only to a single step (as opposed to
[`Mapping`](https://prosemirror.net/docs/ref/version/0.11.0.html#transform.Mapping).

The arguments to [`canSplit`](https://prosemirror.net/docs/ref/version/0.11.0.html#transform.canSplit) and
[`split`](https://prosemirror.net/docs/ref/version/0.11.0.html#transform.Transform.split) were changed to make it
possible to specify multiple split-off node types for splits with a
depth greater than 1.

Rename `joinable` to [`canJoin`](https://prosemirror.net/docs/ref/version/0.11.0.html#transform.canJoin).

### New features

Steps can now be [merged](https://prosemirror.net/docs/ref/version/0.11.0.html#transform.Step.merge) in some
circumstances, which can be useful when storing a lot of them.

