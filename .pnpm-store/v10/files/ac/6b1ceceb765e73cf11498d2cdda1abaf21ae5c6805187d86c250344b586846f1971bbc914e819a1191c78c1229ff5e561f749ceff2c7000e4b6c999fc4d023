## 1.22.3 (2024-08-06)

### Bug fixes

Fix some corner cases in the way the DOM parser tracks active marks.

## 1.22.2 (2024-07-18)

### Bug fixes

Make attribute validation messages more informative.

## 1.22.1 (2024-07-14)

### Bug fixes

Add code to `DOMSerializer` that rejects DOM output specs when they originate from attribute values, to protect against XSS attacks that use corrupt attribute input.

## 1.22.0 (2024-07-14)

### New features

Attribute specs now support a `validate` property that can be used to provide a validation function for the attribute, to guard against corrupt JSON input.

## 1.21.3 (2024-06-26)

### Bug fixes

Fix an issue where parse rules for CSS properties that were shorthands for a number of more detailed properties weren't matching properly.

## 1.21.2 (2024-06-25)

### Bug fixes

Make sure resolved positions (and thus the document and schema hanging off them) don't get kept in the cache when their document can be garbage-collected.

## 1.21.1 (2024-06-03)

### Bug fixes

Improve performance and accuracy of `DOMParser` style matching by using the DOM's own `style` object.

## 1.21.0 (2024-05-06)

### New features

The new `linebreakReplacement` property on node specs makes it possible to configure a node type that `setBlockType` will convert to and from line breaks when appropriate.

## 1.20.0 (2024-04-08)

### New features

The `ParseRule` type is now a union of `TagParseRule` and `StyleParseRule`, with more specific types being used when appropriate.

## 1.19.4 (2023-12-11)

### Bug fixes

Make `textBetween` emit block separators for empty textblocks.

## 1.19.3 (2023-07-13)

### Bug fixes

Don't apply style parse rules for nodes that are skipped by other parse rules.

## 1.19.2 (2023-05-23)

### Bug fixes

Allow parse rules with a `clearMark` directive to clear marks that have already been applied.

## 1.19.1 (2023-05-17)

### Bug fixes

Fix the types of `Fragment.desendants` to include the index parameter to the callback. Add release note

Include CommonJS type declarations in the package to please new TypeScript resolution settings.

## 1.19.0 (2023-01-18)

### New features

Parse rules for styles can now provide a `clearMark` property to remove pending marks (for example for `font-style: normal`).

## 1.18.3 (2022-11-18)

### Bug fixes

Copy all properties from the input spec to `Schema.spec`.

## 1.18.2 (2022-11-14)

### Bug fixes

Improve DOM parsing of nested block elements mixing block and inline children.

## 1.18.1 (2022-06-15)

### Bug fixes

Upgrade to orderedmap 2.0.0 to avoid around a TypeScript compilation issue.

## 1.18.0 (2022-06-07)

### New features

Node specs for leaf nodes now support a property `leafText` which, when given, will be used by `textContent` and `textBetween` to serialize the node.

Add optional type parameters to `Schema` for the node and mark names. Clarify Schema type parameters

## 1.17.0 (2022-05-30)

### Bug fixes

Fix a crash in DOM parsing.

### New features

Include TypeScript type declarations.

## 1.16.1 (2021-12-29)

### Bug fixes

Fix a bug in the way whitespace-preservation options were handled in `DOMParser`.

## 1.16.0 (2021-12-27)

### New features

A new `NodeSpec` property, `whitespace`, allows more control over the way whitespace in the content of the node is parsed.

## 1.15.0 (2021-10-25)

### New features

`textBetween` now allows its leaf text argument to be a function.

## 1.14.3 (2021-07-22)

### Bug fixes

`DOMSerializer.serializeNode` will no longer ignore the node's marks.

## 1.14.2 (2021-06-16)

### Bug fixes

Be less agressive about dropping whitespace when the context isn't know in `DOMParser.parseSlice`.

## 1.14.1 (2021-04-26)

### Bug fixes

DOM parsing with `preserveWhitespace: "full"` will no longer ignore whitespace-only nodes.

## 1.14.0 (2021-04-06)

### Bug fixes

`Node.check` will now error if a node has an invalid combination of marks.

Don't leave carriage return characters in parsed DOM content, since they confuse Chrome's cursor motion.

### New features

`Fragment.textBetween` is now public.

## 1.13.3 (2021-02-04)

### Bug fixes

Fix an issue where nested tags that match mark parser rules could cause the parser to apply marks in invalid places.

## 1.13.2 (2021-02-04)

### Bug fixes

`MarkType.removeFromSet` now removes all instances of the mark, not just the first one.

## 1.13.1 (2020-12-20)

### Bug fixes

Fix a bug where nested marks of the same type would be applied to the wrong node when parsing from DOM.

## 1.13.0 (2020-12-11)

### New features

Parse rules can now have a `consuming: false` property which allows other rules to match their tag or style even when they apply.

## 1.12.0 (2020-10-11)

### New features

The output of `toDOM` functions can now be a `{dom, contentDOM}` object specifying the precise parent and content DOM elements.

## 1.11.2 (2020-09-12)

### Bug fixes

Fix issue where 1.11.1 uses an array method not available on Internet Explorer.

## 1.11.1 (2020-09-11)

### Bug fixes

Fix an issue where an inner node's mark information could reset the same mark provided by an outer node in the DOM parser.

## 1.11.0 (2020-07-08)

### New features

Resolved positions have a new convenience method, `posAtIndex`, which can resolve a depth and index to a position.

## 1.10.1 (2020-07-08)

### Bug fixes

Fix a bug that prevented non-canonical list structure from being normalized.

## 1.10.0 (2020-05-25)

### Bug fixes

Avoid fixing directly nested list nodes during DOM parsing when it looks like the schema allows those.

### New features

DOM parser rules can now specify `closeParent: true` to have the effect of closing their parent node when matched.

## 1.9.1 (2020-01-17)

### Bug fixes

Marks found in the DOM at the wrong level (for example, a bold style on a block node) are now properly moved to the node content.

## 1.9.0 (2020-01-07)

### New features

The `NodeType` method [`hasRequiredAttrs`](https://prosemirror.net/docs/ref/#model.NodeType.hasRequiredAttrs) is now public.

Element and attribute names in [`DOMOutputSpec`](https://prosemirror.net/docs/ref/#model.DOMOutputSpec) structures can now contain namespaces.

## 1.8.2 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.8.1 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.8.0 (2019-11-08)

### New features

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

Add a `module` field to package json file.

## 1.7.5 (2019-11-07)

### Bug fixes

`ContentMatch.edge` now throws, as it is supposed to, when you try to access the edge past the last one.

## 1.7.4 (2019-10-10)

### Bug fixes

Fix an issue where `fillBefore` would in some cases insert unneccesary optional child nodes in the generated content.

## 1.7.3 (2019-10-03)

### Bug fixes

Fix an issue where _any_ whitespace (not just the characters that HTML collapses) was collapsed by the parser in non-whitespace-preserving mode.

## 1.7.2 (2019-09-04)

### Bug fixes

When `<br>` DOM nodes can't be parsed normally, the parser now converts them to newlines. This should improve parsing of some forms of source code HTML.

## 1.7.1 (2019-05-31)

### Bug fixes

Using `Fragment.from` on an invalid value, including a `Fragment` instance from a different version/instance of the library, now raises a meaningful error rather than getting confused.

Fix a bug in parsing overlapping marks of the same non-self-exclusive type.

## 1.7.0 (2019-01-29)

### New features

Mark specs now support a property [`spanning`](https://prosemirror.net/docs/ref/#model.MarkSpec.spanning) which, when set to `false`, prevents the mark's DOM markup from spanning multiple nodes, so that a separate wrapper is created for each adjacent marked node.

## 1.6.4 (2019-01-05)

### Bug fixes

Don't output empty style attributes when a style property with a null value is present in `renderSpec`.

## 1.6.3 (2018-10-26)

### Bug fixes

The DOM parser now drops whitespace after BR nodes when not in whitespace-preserving mode.

## 1.6.2 (2018-10-01)

### Bug fixes

Prevent [`ContentMatch.findWrapping`](https://prosemirror.net/docs/ref/#model.ContentMatch.findWrapping) from returning node types with required attributes.

## 1.6.1 (2018-07-24)

### Bug fixes

Fix a bug where marks were sometimes parsed incorrectly.

## 1.6.0 (2018-07-20)

### Bug fixes

Fix issue where marks would be applied to the wrong node when parsing a slice from DOM.

### New features

Adds a new node spec property, [`toDebugString`](https://prosemirror.net/docs/ref/#model.NodeSpec.toDebugString), making it possible to customize your nodes' `toString` behavior.

## 1.5.0 (2018-05-31)

### New features

[`ParseRule.getContent`](https://prosemirror.net/docs/ref/#model.ParseRule.getContent) is now passed the parser schema as second argument.

## 1.4.4 (2018-05-03)

### Bug fixes

Fix a regression where `DOMParser.parse` would fail to apply mark nodes directly at the start of the input.

## 1.4.3 (2018-04-27)

### Bug fixes

[`DOMParser.parseSlice`](https://prosemirror.net/docs/ref/#model.DOMParser.parseSlice) can now correctly parses marks at the top level again.

## 1.4.2 (2018-04-15)

### Bug fixes

Remove a `console.log` that was accidentally left in the previous release.

## 1.4.1 (2018-04-13)

### Bug fixes

`DOMParser` can now parse marks on block nodes.

## 1.4.0 (2018-03-22)

### New features

[`ContentMatch.defaultType`](https://prosemirror.net/docs/ref/#model.ContentMatch.defaultType), a way to get a matching node type at a content match position, is now public.

## 1.3.0 (2018-03-22)

### New features

`ContentMatch` objects now have an [`edgeCount`](https://prosemirror.net/docs/ref/#model.ContentMatch.edgeCount) property and an [`edge`](https://prosemirror.net/docs/ref/#model.ContentMatch.edge) method, providing direct access to the finite automaton structure.

## 1.2.2 (2018-03-15)

### Bug fixes

Throw errors, rather than constructing invalid objects, when deserializing from invalid JSON data.

## 1.2.1 (2018-03-15)

### Bug fixes

Content expressions with text nodes in required positions now raise the appropriate error about being unable to generate such nodes.

## 1.2.0 (2018-03-14)

### Bug fixes

[`rangeHasMark`](https://prosemirror.net/docs/ref/#model.Node.rangeHasMark) now always returns false for empty ranges.

The DOM renderer no longer needlessly splits mark nodes when starting a non-rendered mark.

### New features

[`DOMSerializer`](https://prosemirror.net/docs/ref/#model.DOMSerializer) now allows [DOM specs](https://prosemirror.net/docs/ref/#model.DOMOutputSpec) for marks to have holes in them, to specify the precise position where their content should be rendered.

The base position parameter to [`Node.nodesBetween`](https://prosemirror.net/docs/ref/#model.Node.nodesBetween) and [`Fragment.nodesBetween`](https://prosemirror.net/docs/ref/#model.Fragment.nodesBetween) is now part of the public interface.

## 1.1.0 (2018-01-05)

### New features

[`Slice.maxOpen`](https://prosemirror.net/docs/ref/#model.Slice^maxOpen) now has a second argument that can be used to prevent it from opening isolating nodes.

## 1.0.1 (2017-11-10)

### Bug fixes

[`ReplaceError`](https://prosemirror.net/docs/ref/#model.ReplaceError) instances now properly inherit from `Error`.

## 1.0.0 (2017-10-13)

### New features

[`ParseRule.context`](https://prosemirror.net/docs/ref/#model.ParseRule.context) may now include multiple, pipe-separated context expressions.

## 0.23.1 (2017-09-21)

### Bug fixes

`NodeType.allowsMarks` and `allowedMarks` now actually work for nodes that allow only specific marks.

## 0.23.0 (2017-09-13)

### Breaking changes

[`ResolvedPos.marks`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.ResolvedPos.marks) no longer takes a parameter (you probably want [`marksAcross`](https://prosemirror.net/doc/ref/version/0.23.0.html#model.ResolvedPos.marksAcross) if you were passing true there).

Attribute and mark constraints in [content expressions](https://prosemirror.net/docs/ref/version/0.23.0.html#model.NodeSpec.content) are no longer supported (this also means the `prosemirror-schema-table` package, which relied on them, is no longer supported). In this release, mark constraints are still (approximately) recognized with a warning, when present.

[`ContentMatch`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.ContentMatch) objects lost a number of methods: `matchNode`, `matchToEnd`, `findWrappingFor` (which can be easily emulated using the remaining API), and `allowsMark`, which is now the responsibility of [node types](https://prosemirror.net/docs/ref/version/0.23.0.html#model.NodeType.allowsMarkType) instead.

[`ContentMatch.validEnd`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.ContentMatch.validEnd) is now a property rather than a method.

[`ContentMatch.findWrapping`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.ContentMatch.findWrapping) now returns an array of plain node types, with no attribute information (since this is no longer necessary).

The `compute` method for attributes is no longer supported.

Fragments no longer have an `offsetAt` method.

`DOMParser.schemaRules` is no longer public (use [`fromSchema`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.DOMParser^fromSchema) and get the resulting parser's `rules` property instead).

The DOM parser option `topStart` has been replaced by [`topMatch`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.ParseOptions.topMatch).

The `DOMSerializer` methods `nodesFromSchema` and `marksFromSchema` are no longer public (construct a serializer with [`fromSchema`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.DOMSerializer^fromSchema) and read its `nodes` and `marks` properties instead).

### Bug fixes

Fix issue where whitespace at node boundaries was sometimes dropped during content parsing.

Attribute default values of `undefined` are now allowed.

### New features

[`contentElement`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.ParseRule.contentElement) in parse rules may now be a function.

The new method [`ResolvedPos.marksAcross`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.ResolvedPos.marksAcross) can be used to find the set of marks that should be preserved after a deletion.

[Content expressions](https://prosemirror.net/docs/ref/version/0.23.0.html#model.NodeSpec.content) are now a regular language, meaning all the operators can be nested and composed as desired, and a bunch of constraints on what could appear next to what have been lifted.

The starting content match for a node type now lives in [`NodeType.contentMatch`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.NodeType.contentMatch).

Allowed marks are now specified per node, rather than in content expressions, using the [`marks`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.NodeSpec.marks) property on the node spec.

Node types received new methods [`allowsMarkType`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.NodeType.allowsMarkType), [`allowsMarks`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.NodeType.allowsMarks), and [`allowedMarks`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.NodeType.allowedMarks), which tell you about the marks that node supports.

The [`style`](https://prosemirror.net/docs/ref/version/0.23.0.html#model.ParseRule.style) property on parse rules may now have the form `"font-style=italic"` to only match styles that have the value after the equals sign.

## 0.22.0 (2017-06-29)

### Bug fixes

When using [`parseSlice`](https://prosemirror.net/docs/ref/version/0.22.0.html#model.DOMParser.parseSlice), inline DOM content wrapped in block elements for which no parse rule is defined will now be properly wrapped in a textblock node.

### New features

[Resolved positions](https://prosemirror.net/docs/ref/version/0.22.0.html#model.ResolvedPos) now have a [`doc`](https://prosemirror.net/docs/ref/version/0.22.0.html#model.ResolvedPos.doc) accessor to easily get their root node.

Parse rules now support a [`namespace` property](https://prosemirror.net/docs/ref/version/0.22.0.html#model.ParseRule.namespace) to match XML namespaces.

The [`NodeRange`](https://prosemirror.net/docs/ref/version/0.22.0.html#model.NodeRange) constructor is now public (whereas before you could only construct these through [`blockRange`](https://prosemirror.net/docs/ref/version/0.22.0.html#model.ResolvedPos.blockRange)).

## 0.21.0 (2017-05-03)

### Breaking changes

The `openLeft` and `openRight` properties of `Slice` objects have been renamed to [`openStart`](https://prosemirror.net/docs/ref/version/0.21.0.html#model.Slice.openStart) and [`openEnd`](https://prosemirror.net/docs/ref/version/0.21.0.html#model.Slice.openEnd) to avoid confusion in right-to-left text. The old names will continue to work with a warning until the next release.

### New features

Mark [serializing functions](https://prosemirror.net/docs/ref/version/0.21.0.html#model.MarkSpec.toDOM) now get a second parameter that indicates whether the mark's content is inline or block nodes.

Setting a mark serializer to `null` in a [`DOMSerializer`](https://prosemirror.net/docs/ref/version/0.21.0.html#model.DOMSerializer) can now be used to omit that mark when serializing.

Node specs support a new property [`isolating`](https://prosemirror.net/docs/ref/version/0.21.0.html#model.NodeSpec.isolating), which is used to disable editing actions like backspacing and lifting across such a node's boundaries.

## 0.20.0 (2017-04-03)

### Breaking changes

Newlines in the text are now normalized to spaces when parsing except when you set `preserveWhitespace` to `"full"` in your [options](https://prosemirror.net/docs/ref/version/0.20.0.html#model.DOMParser.parse) or in a [parse rule](https://prosemirror.net/docs/ref/version/0.20.0.html#model.ParseRule.preserveWhitespace).

### Bug fixes

Fix crash in IE when parsing DOM content.

### New features

Fragments now have [`nodesBetween`](https://prosemirror.net/docs/ref/version/0.20.0.html#model.Fragment.nodesBetween) and [`descendants`](https://prosemirror.net/docs/ref/version/0.20.0.html#model.Fragments.descendants) methods, providing the same functionality as the methods by the same name on nodes.

Resolved positions now have [`max`](https://prosemirror.net/docs/ref/version/0.20.0.html#model.ResolvedPos.max) and [`min`](https://prosemirror.net/docs/ref/version/0.20.0.html#model.ResolvedPos.min) methods to easily find a maximum or minimum position.

## 0.19.0 (2017-03-16)

### Breaking changes

`MarkSpec.inclusiveRight` was replaced by [`inclusive`](https://prosemirror.net/docs/ref/version/0.19.0.html#model.MarkSpec.inclusive), which behaves slightly differently. `inclusiveRight` will be interpreted as `inclusive` (with a warning) until the next release.

### New features

The new [`inlineContent`](https://prosemirror.net/docs/ref/version/0.19.0.html#model.Node.inlineContent) property on nodes and node types tells you whether a node type supports inline content.

[`MarkSpec.inclusive`](https://prosemirror.net/docs/ref/version/0.19.0.html#model.MarkSpec.inclusive) can now be used to control whether content inserted at the boundary of a mark receives that mark.

Parse rule [`context`](https://prosemirror.net/docs/ref/version/0.19.0.html#model.ParseRule.context) restrictions can now use node [groups](https://prosemirror.net/docs/ref/version/0.19.0.html#model.NodeSpec.group), not just node names, to specify valid context.

## 0.18.0 (2017-02-24)

### Breaking changes

`schema.nodeSpec` and `schema.markSpec` have been deprecated in favor of [`schema.spec`](https://prosemirror.net/docs/ref/version/0.18.0.html#model.Schema.spec). The properties still work with a warning in this release, but will be dropped in the next.

### New features

`Node` objects now have a [`check`](https://prosemirror.net/docs/ref/version/0.18.0.html#model.Node.check) method which can be used to assert that they conform to the schema.

Node specs now support an [`atom` property](https://prosemirror.net/docs/ref/version/0.18.0.html#model.NodeSpec.atom), and nodes an [`isAtom` accessor](https://prosemirror.net/docs/ref/version/0.18.0.html#model.Node.isAtom), which is currently only used to determine whether such nodes should be directly selectable (for example when they are rendered as an uneditable node view).

The new [`excludes`](https://prosemirror.net/docs/ref/version/0.18.0.html#model.MarkSpec.excludes) field on mark specs can be used to control the marks that this mark may coexist with. Mark type objects also gained an [`excludes` _method_](https://prosemirror.net/docs/ref/version/0.18.0.html#model.MarkType.excludes) to querty this relation.

Mark specs now support a [`group`](https://prosemirror.net/docs/ref/version/0.18.0.html#model.MarkSpec.group) property, and marks can be referred to by group name in content specs.

The `Schema` class now provides its whole [spec](https://prosemirror.net/docs/ref/version/0.18.0.html#model.SchemaSpec) under its [`spec`](https://prosemirror.net/docs/ref/version/0.18.0.html#model.Schema.spec) property.

The name of a schema's default top-level node is now [configurable](https://prosemirror.net/docs/ref/version/0.18.0.html#model.SchemaSpec.topNode). You can use [`schema.topNodeType`](https://prosemirror.net/docs/ref/version/0.18.0.html#model.Schema.topNodeType) to retrieve the top node type.

[Parse rules](https://prosemirror.net/docs/ref/version/0.18.0.html#model.ParseRule) now support a [`context` field](https://prosemirror.net/docs/ref/version/0.18.0.html#model.ParseRule.context) that can be used to only make the rule match inside certain ancestor nodes.

## 0.17.0 (2017-01-05)

### Breaking changes

`Node.marksAt` was replaced with [`ResolvedPos.marks`](https://prosemirror.net/docs/ref/version/0.17.0.html#model.ResolvedPos.marks). It still works (with a warning) in this release, but will be removed in the next one.

## 0.15.0 (2016-12-10)

### Breaking changes

`ResolvedPos.atNodeBoundary` is deprecated and will be removed in the next release. Use `textOffset > 0` instead.

### New features

Parse rules associated with a schema can now specify a [`priority`](https://prosemirror.net/docs/ref/version/0.15.0.html#model.ParseRule.priority) to influence the order in which they are applied.

Resolved positions have a new getter [`textOffset`](https://prosemirror.net/docs/ref/version/0.15.0.html#model.ResolvedPos.textOffset) to find their position within a text node (if any).

## 0.14.1 (2016-11-30)

### Bug fixes

[`DOMParser.parseSlice`](https://prosemirror.net/docs/ref/version/0.14.0.html#model.DOMParser.parseSlice) will now ignore whitespace-only text nodes at the top of the slice.

## 0.14.0 (2016-11-28)

### New features

Parse rules now support [`skip`](https://prosemirror.net/docs/ref/version/0.14.0.html#model.ParseRule.skip) (skip outer element, parse content) and [`getContent`](https://prosemirror.net/docs/ref/version/0.14.0.html#model.ParseRule.getContent) (compute content using custom code) properties.

The `DOMSerializer` class now exports a static [`renderSpec`](https://prosemirror.net/docs/ref/version/0.14.0.html#model.DOMSerializer^renderSpec) method that can help render DOM spec arrays.

## 0.13.0 (2016-11-11)

### Breaking changes

`ResolvedPos.sameDepth` is now called [`ResolvedPos.sharedDepth`](https://prosemirror.net/docs/ref/version/0.13.0.html#model.ResolvedPos.sharedDepth), and takes a raw, unresolved position as argument.

### New features

[`DOMSerializer`](https://prosemirror.net/docs/ref/version/0.13.0.html#model.DOMSerializer)'s `nodes` and `marks` properties are now public.

[`ContentMatch.findWrapping`](https://prosemirror.net/docs/ref/version/0.13.0.html#model.ContentMatch.findWrapping) now takes a third argument, `marks`. There's a new method [`findWrappingFor`](https://prosemirror.net/docs/ref/version/0.13.0.html#model.ContentMatch.findWrappingFor) that accepts a whole node.

Adds [`Slice.maxOpen`](https://prosemirror.net/docs/ref/version/0.13.0.html#model.Slice^maxOpen) static method to create maximally open slices.

DOM parser objects now have a [`parseSlice`](https://prosemirror.net/docs/ref/version/0.13.0.html#model.DOMParser.parseSlice) method which parses an HTML fragment into a [`Slice`](https://prosemirror.net/docs/ref/version/0.13.0.html#model.Slice), rather than trying to create a whole document from it.

## 0.12.0 (2016-10-21)

### Breaking changes

Drops support for some undocumented options to the DOM
serializer that were used by the view.

### Bug fixes

When rendering DOM attributes, only ignore null values, not all
falsy values.

## 0.11.0 (2016-09-21)

### Breaking changes

Moved into a separate module.

The JSON representation of [marks](https://prosemirror.net/docs/ref/version/0.11.0.html#model.Mark) has changed from
`{"_": "type", "attr1": "value"}` to `{"type": "type", "attrs":
{"attr1": "value"}}`, where `attrs` may be omitted when the mark has
no attributes.

Mark-related JSON methods now live on the
[`Mark` class](https://prosemirror.net/docs/ref/version/0.11.0.html#model.Mark^fromJSON).

The way node and mark types in a schema are defined was changed from
defining subclasses to passing plain objects
([`NodeSpec`](https://prosemirror.net/docs/ref/version/0.11.0.html#model.NodeSpec) and [`MarkSpec`](https://prosemirror.net/docs/ref/version/0.11.0.html#model.MarkSpec)).

DOM serialization and parsing logic is now done through dedicated
objects ([`DOMSerializer`](https://prosemirror.net/docs/ref/version/0.11.0.html#model.DOMSerializer) and
[`DOMParser`](https://prosemirror.net/docs/ref/version/0.11.0.html#model.DOMParser)), rather than through the schema. It
is now possible to define alternative parsing and serializing
strategies without touching the schema.

### New features

The [`Slice`](https://prosemirror.net/docs/ref/version/0.11.0.html#model.Slice) class now has an [`eq` method](https://prosemirror.net/docs/ref/version/0.11.0.html#model.Slice.eq).

The [`Node.marksAt`](https://prosemirror.net/docs/ref/version/0.11.0.html#model.Node.marksAt) method got a second
parameter to indicate you're interested in the marks _after_ the
position.

