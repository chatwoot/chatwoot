# prosemirror-markdown

[ [**WEBSITE**](https://prosemirror.net) | [**ISSUES**](https://github.com/prosemirror/prosemirror-markdown/issues) | [**FORUM**](https://discuss.prosemirror.net) | [**GITTER**](https://gitter.im/ProseMirror/prosemirror) ]

This is a (non-core) module for [ProseMirror](https://prosemirror.net).
ProseMirror is a well-behaved rich semantic content editor based on
contentEditable, with support for collaborative editing and custom
document schemas.

This module implements a ProseMirror
[schema](https://prosemirror.net/docs/guide/#schema) that corresponds to
the document schema used by [CommonMark](http://commonmark.org/), and
a parser and serializer to convert between ProseMirror documents in
that schema and CommonMark/Markdown text.

This code is released under an
[MIT license](https://github.com/prosemirror/prosemirror/tree/master/LICENSE).
There's a [forum](http://discuss.prosemirror.net) for general
discussion and support requests, and the
[Github bug tracker](https://github.com/prosemirror/prosemirror/issues)
is the place to report issues.

We aim to be an inclusive, welcoming community. To make that explicit,
we have a [code of
conduct](http://contributor-covenant.org/version/1/1/0/) that applies
to communication around the project.

## Documentation

 * **`schema`**`: Schema`\
   Document schema for the data model used by CommonMark.


### class MarkdownParser

A configuration of a Markdown parser. Such a parser uses
[markdown-it](https://github.com/markdown-it/markdown-it) to
tokenize a file, and then runs the custom rules it is given over
the tokens to create a ProseMirror document tree.

 * `new `**`MarkdownParser`**`(schema: Schema, tokenizer: MarkdownIt, tokens: Object)`\
   Create a parser with the given configuration. You can configure
   the markdown-it parser to parse the dialect you want, and provide
   a description of the ProseMirror entities those tokens map to in
   the `tokens` object, which maps token names to descriptions of
   what to do with them. Such a description is an object, and may
   have the following properties:

   **`node`**`: ?string`
     : This token maps to a single node, whose type can be looked up
       in the schema under the given name. Exactly one of `node`,
       `block`, or `mark` must be set.

   **`block`**`: ?string`
     : This token comes in `_open` and `_close` variants (which are
       appended to the base token name provides a the object
       property), and wraps a block of content. The block should be
       wrapped in a node of the type named to by the property's
       value. If the token does not have `_open` or `_close`, use
       the `noCloseToken` option.

   **`mark`**`: ?string`
     : This token also comes in `_open` and `_close` variants, but
       should add a mark (named by the value) to its content, rather
       than wrapping it in a node.

   **`attrs`**`: ?Object`
     : Attributes for the node or mark. When `getAttrs` is provided,
       it takes precedence.

   **`getAttrs`**`: ?(MarkdownToken) → Object`
     : A function used to compute the attributes for the node or mark
       that takes a [markdown-it
       token](https://markdown-it.github.io/markdown-it/#Token) and
       returns an attribute object.

   **`noCloseToken`**`: ?boolean`
     : Indicates that the [markdown-it
       token](https://markdown-it.github.io/markdown-it/#Token) has
       no `_open` or `_close` for the nodes. This defaults to `true`
       for `code_inline`, `code_block` and `fence`.

   **`ignore`**`: ?bool`
     : When true, ignore content for the matched token.

 * **`tokens`**`: Object`\
   The value of the `tokens` object used to construct
   this parser. Can be useful to copy and modify to base other
   parsers on.

 * **`parse`**`(text: string) → Node`\
   Parse a string as [CommonMark](http://commonmark.org/) markup,
   and create a ProseMirror document as prescribed by this parser's
   rules.


 * **`defaultMarkdownParser`**`: MarkdownParser`\
   A parser parsing unextended [CommonMark](http://commonmark.org/),
   without inline HTML, and producing a document in the basic schema.


### class MarkdownSerializer

A specification for serializing a ProseMirror document as
Markdown/CommonMark text.

 * `new `**`MarkdownSerializer`**`(nodes: Object< fn(state: MarkdownSerializerState, node: Node, parent: Node, index: number) >, marks: Object)`

   Construct a serializer with the given configuration. The `nodes`
   object should map node names in a given schema to function that
   take a serializer state and such a node, and serialize the node.

   The `marks` object should hold objects with `open` and `close`
   properties, which hold the strings that should appear before and
   after a piece of text marked that way, either directly or as a
   function that takes a serializer state and a mark, and returns a
   string.

   Mark information objects can also have a `mixable` property
   which, when `true`, indicates that the order in which the mark's
   opening and closing syntax appears relative to other mixable
   marks can be varied. (For example, you can say `**a *b***` and
   `*a **b***`, but not `` `a *b*` ``.)

   To disable character escaping in a mark, you can give it an
   `escape` property of `false`. Such a mark has to have the highest
   precedence (must always be the innermost mark).

   The `expelEnclosingWhitespace` mark property causes the
   serializer to move enclosing whitespace from inside the marks to
   outside the marks. This is necessary for emphasis marks as
   CommonMark does not permit enclosing whitespace inside emphasis
   marks, see: http://spec.commonmark.org/0.26/#example-330

 * **`nodes`**`: Object< fn(MarkdownSerializerState, Node) >`\
   The node serializer
   functions for this serializer.

 * **`marks`**`: Object`\
   The mark serializer info.

 * **`serialize`**`(content: Node, options: ?Object) → string`\
   Serialize the content of the given node to
   [CommonMark](http://commonmark.org/).


### class MarkdownSerializerState

This is an object used to track state and expose
methods related to markdown serialization. Instances are passed to
node and mark serialization methods (see `toMarkdown`).

 * **`options`**`: Object`\
   The options passed to the serializer.

    * **`tightLists`**`: ?bool`\
      Whether to render lists in a tight style. This can be overridden
      on a node level by specifying a tight attribute on the node.
      Defaults to false.

 * **`wrapBlock`**`(delim: string, firstDelim: ?string, node: Node, f: fn())`\
   Render a block, prefixing each line with `delim`, and the first
   line in `firstDelim`. `node` should be the node that is closed at
   the end of the block, and `f` is a function that renders the
   content of the block.

 * **`ensureNewLine`**`()`\
   Ensure the current content ends with a newline.

 * **`write`**`(content: ?string)`\
   Prepare the state for writing output (closing closed paragraphs,
   adding delimiters, and so on), and then optionally add content
   (unescaped) to the output.

 * **`closeBlock`**`(node: Node)`\
   Close the block for the given node.

 * **`text`**`(text: string, escape: ?bool)`\
   Add the given text to the document. When escape is not `false`,
   it will be escaped.

 * **`render`**`(node: Node)`\
   Render the given node as a block.

 * **`renderContent`**`(parent: Node)`\
   Render the contents of `parent` as block nodes.

 * **`renderInline`**`(parent: Node)`\
   Render the contents of `parent` as inline content.

 * **`renderList`**`(node: Node, delim: string, firstDelim: fn(number) → string)`\
   Render a node's content as a list. `delim` should be the extra
   indentation added to all lines except the first in an item,
   `firstDelim` is a function going from an item index to a
   delimiter for the first line of the item.

 * **`esc`**`(str: string, startOfLine: ?bool) → string`\
   Escape the given string so that it can safely appear in Markdown
   content. If `startOfLine` is true, also escape characters that
   has special meaning only at the start of the line.

 * **`repeat`**`(str: string, n: number) → string`\
   Repeat the given string `n` times.

 * **`getEnclosingWhitespace`**`(text: string) → {leading: ?string, trailing: ?string}`\
   Get leading and trailing whitespace from a string. Values of
   leading or trailing property of the return object will be undefined
   if there is no match.


 * **`defaultMarkdownSerializer`**`: MarkdownSerializer`\
   A serializer for the [basic schema](#schema).


