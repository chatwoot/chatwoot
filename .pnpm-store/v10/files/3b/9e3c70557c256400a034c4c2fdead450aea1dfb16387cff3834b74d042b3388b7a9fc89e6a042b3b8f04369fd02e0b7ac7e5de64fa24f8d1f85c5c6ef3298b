This module defines ProseMirror's content model, the data structures
used to represent and work with documents.

### Document Structure

A ProseMirror document is a tree. At each level, a [node](#model.Node)
describes the type of the content, and holds a
[fragment](#model.Fragment) containing its children.

@Node
@Fragment
@Mark
@Slice
@Attrs
@ReplaceError

### Resolved Positions

Positions in a document can be represented as integer
[offsets](/docs/guide/#doc.indexing). But you'll often want to use a
more convenient representation.

@ResolvedPos
@NodeRange

### Document Schema

Every ProseMirror document conforms to a
[schema](/docs/guide/#schema), which describes the set of nodes and
marks that it is made out of, along with the relations between those,
such as which node may occur as a child node of which other nodes.

@Schema

@SchemaSpec
@NodeSpec
@MarkSpec
@AttributeSpec

@NodeType
@MarkType

@ContentMatch

### DOM Representation

Because representing a document as a tree of DOM nodes is central to
the way ProseMirror operates, DOM [parsing](#model.DOMParser) and
[serializing](#model.DOMSerializer) is integrated with the model.

(But note that you do _not_ need to have a DOM implementation loaded
to use this module.)

@DOMParser
@ParseOptions
@GenericParseRule
@TagParseRule
@StyleParseRule
@ParseRule

@DOMSerializer
@DOMOutputSpec
