<h1>prosemirror-markdown</h1>
<p>[ <a href="http://prosemirror.net"><strong>WEBSITE</strong></a> | <a href="https://github.com/prosemirror/prosemirror-markdown/issues"><strong>ISSUES</strong></a> | <a href="https://discuss.prosemirror.net"><strong>FORUM</strong></a> | <a href="https://gitter.im/ProseMirror/prosemirror"><strong>GITTER</strong></a> ]</p>
<p>This is a (non-core) module for <a href="http://prosemirror.net">ProseMirror</a>.
ProseMirror is a well-behaved rich semantic content editor based on
contentEditable, with support for collaborative editing and custom
document schemas.</p>
<p>This module implements a ProseMirror
<a href="https://prosemirror.net/docs/guide/#schema">schema</a> that corresponds to
the document schema used by <a href="http://commonmark.org/">CommonMark</a>, and
a parser and serializer to convert between ProseMirror documents in
that schema and CommonMark/Markdown text.</p>
<p>This code is released under an
<a href="https://github.com/prosemirror/prosemirror/tree/master/LICENSE">MIT license</a>.
There's a <a href="http://discuss.prosemirror.net">forum</a> for general
discussion and support requests, and the
<a href="https://github.com/prosemirror/prosemirror/issues">Github bug tracker</a>
is the place to report issues.</p>
<p>We aim to be an inclusive, welcoming community. To make that explicit,
we have a <a href="http://contributor-covenant.org/version/1/1/0/">code of
conduct</a> that applies
to communication around the project.</p>
<h2>Documentation</h2>
<dl>
<dt id="schema">
  <code><strong><a href="#schema">schema</a></strong>: <span class="type">Schema</span>&lt;<span class="string">&quot;doc&quot;</span> | <span class="string">&quot;paragraph&quot;</span> | <span class="string">&quot;blockquote&quot;</span> | <span class="string">&quot;horizontal_rule&quot;</span> | <span class="string">&quot;heading&quot;</span> | <span class="string">&quot;code_block&quot;</span> | <span class="string">&quot;ordered_list&quot;</span> | <span class="string">&quot;bullet_list&quot;</span> | <span class="string">&quot;list_item&quot;</span> | <span class="string">&quot;text&quot;</span> | <span class="string">&quot;image&quot;</span> | <span class="string">&quot;hard_break&quot;</span>, <span class="string">&quot;em&quot;</span> | <span class="string">&quot;strong&quot;</span> | <span class="string">&quot;link&quot;</span> | <span class="string">&quot;code&quot;</span>&gt;</code></dt>

<dd><p>Document schema for the data model used by CommonMark.</p>
</dd>
<dt id="MarkdownParser">
  <h4>
    <code><span class=keyword>class</span></code>
    <a href="#MarkdownParser">MarkdownParser</a></h4>
</dt>

<dd><p>A configuration of a Markdown parser. Such a parser uses
<a href="https://github.com/markdown-it/markdown-it">markdown-it</a> to
tokenize a file, and then runs the custom rules it is given over
the tokens to create a ProseMirror document tree.</p>
<dl><dt id="MarkdownParser.constructor">
  <code><span class=keyword>new</span> <strong><a href="#MarkdownParser.constructor">MarkdownParser</a></strong>(<a id="MarkdownParser.constructor^schema" href="#MarkdownParser.constructor^schema"><span class=param>schema</span></a>: <span class="type">Schema</span>, <a id="MarkdownParser.constructor^tokenizer" href="#MarkdownParser.constructor^tokenizer"><span class=param>tokenizer</span></a>: <span class="type">any</span>, <a id="MarkdownParser.constructor^tokens" href="#MarkdownParser.constructor^tokens"><span class=param>tokens</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a>&lt;<a href="#ParseSpec"><span class="type">ParseSpec</span></a>&gt;)</code></dt>

<dd><p>Create a parser with the given configuration. You can configure
the markdown-it parser to parse the dialect you want, and provide
a description of the ProseMirror entities those tokens map to in
the <code>tokens</code> object, which maps token names to descriptions of
what to do with them. Such a description is an object, and may
have the following properties:</p>
</dd><dt id="MarkdownParser.schema">
  <code><strong><a href="#MarkdownParser.schema">schema</a></strong>: <span class="type">Schema</span></code></dt>

<dd><p>The parser's document schema.</p>
</dd><dt id="MarkdownParser.tokenizer">
  <code><strong><a href="#MarkdownParser.tokenizer">tokenizer</a></strong>: <span class="type">any</span></code></dt>

<dd><p>This parser's markdown-it tokenizer.</p>
</dd><dt id="MarkdownParser.tokens">
  <code><strong><a href="#MarkdownParser.tokens">tokens</a></strong>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a>&lt;<a href="#ParseSpec"><span class="type">ParseSpec</span></a>&gt;</code></dt>

<dd><p>The value of the <code>tokens</code> object used to construct this
parser. Can be useful to copy and modify to base other parsers
on.</p>
</dd><dt id="MarkdownParser.parse">
  <code><strong><a href="#MarkdownParser.parse">parse</a></strong>(<a id="MarkdownParser.parse^text" href="#MarkdownParser.parse^text"><span class=param>text</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>) → <span class="type">any</span></code></dt>

<dd><p>Parse a string as <a href="http://commonmark.org/">CommonMark</a> markup,
and create a ProseMirror document as prescribed by this parser's
rules.</p>
</dd></dl>

</dd>
<dt id="ParseSpec">
  <h4>
    <code><span class=keyword>interface</span></code>
    <a href="#ParseSpec">ParseSpec</a></h4>
</dt>

<dd><p>Object type used to specify how Markdown tokens should be parsed.</p>
<dl><dt id="ParseSpec.node">
  <code><strong><a href="#ParseSpec.node">node</a></strong>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a></code></dt>

<dd><p>This token maps to a single node, whose type can be looked up
in the schema under the given name. Exactly one of <code>node</code>,
<code>block</code>, or <code>mark</code> must be set.</p>
</dd><dt id="ParseSpec.block">
  <code><strong><a href="#ParseSpec.block">block</a></strong>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a></code></dt>

<dd><p>This token (unless <code>noCloseToken</code> is true) comes in <code>_open</code>
and <code>_close</code> variants (which are appended to the base token
name provides a the object property), and wraps a block of
content. The block should be wrapped in a node of the type
named to by the property's value. If the token does not have
<code>_open</code> or <code>_close</code>, use the <code>noCloseToken</code> option.</p>
</dd><dt id="ParseSpec.mark">
  <code><strong><a href="#ParseSpec.mark">mark</a></strong>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a></code></dt>

<dd><p>This token (again, unless <code>noCloseToken</code> is true) also comes
in <code>_open</code> and <code>_close</code> variants, but should add a mark
(named by the value) to its content, rather than wrapping it
in a node.</p>
</dd><dt id="ParseSpec.attrs">
  <code><strong><a href="#ParseSpec.attrs">attrs</a></strong>&#8288;?: <span class="type">Attrs</span></code></dt>

<dd><p>Attributes for the node or mark. When <code>getAttrs</code> is provided,
it takes precedence.</p>
</dd><dt id="ParseSpec.getAttrs">
  <code><strong><a href="#ParseSpec.getAttrs">getAttrs</a></strong>&#8288;?: <span class=fn>fn</span>(<a id="ParseSpec.getAttrs^token" href="#ParseSpec.getAttrs^token"><span class=param>token</span></a>: <span class="type">any</span>, <a id="ParseSpec.getAttrs^tokenStream" href="#ParseSpec.getAttrs^tokenStream"><span class=param>tokenStream</span></a>: <span class="type">any</span>[], <a id="ParseSpec.getAttrs^index" href="#ParseSpec.getAttrs^index"><span class=param>index</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number"><span class="prim">number</span></a>) → <span class="type">Attrs</span></code></dt>

<dd><p>A function used to compute the attributes for the node or mark
that takes a <a href="https://markdown-it.github.io/markdown-it/#Token">markdown-it
token</a> and
returns an attribute object.</p>
</dd><dt id="ParseSpec.noCloseToken">
  <code><strong><a href="#ParseSpec.noCloseToken">noCloseToken</a></strong>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean"><span class="prim">boolean</span></a></code></dt>

<dd><p>Indicates that the <a href="https://markdown-it.github.io/markdown-it/#Token">markdown-it
token</a> has
no <code>_open</code> or <code>_close</code> for the nodes. This defaults to <code>true</code>
for <code>code_inline</code>, <code>code_block</code> and <code>fence</code>.</p>
</dd><dt id="ParseSpec.ignore">
  <code><strong><a href="#ParseSpec.ignore">ignore</a></strong>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean"><span class="prim">boolean</span></a></code></dt>

<dd><p>When true, ignore content for the matched token.</p>
</dd></dl>

</dd>
<dt id="defaultMarkdownParser">
  <code><strong><a href="#defaultMarkdownParser">defaultMarkdownParser</a></strong>: <a href="#MarkdownParser"><span class="type">MarkdownParser</span></a></code></dt>

<dd><p>A parser parsing unextended <a href="http://commonmark.org/">CommonMark</a>,
without inline HTML, and producing a document in the basic schema.</p>
</dd>
<dt id="MarkdownSerializer">
  <h4>
    <code><span class=keyword>class</span></code>
    <a href="#MarkdownSerializer">MarkdownSerializer</a></h4>
</dt>

<dd><p>A specification for serializing a ProseMirror document as
Markdown/CommonMark text.</p>
<dl><dt id="MarkdownSerializer.constructor">
  <code><span class=keyword>new</span> <strong><a href="#MarkdownSerializer.constructor">MarkdownSerializer</a></strong>(<a id="MarkdownSerializer.constructor^nodes" href="#MarkdownSerializer.constructor^nodes"><span class=param>nodes</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a>&lt;<span class=fn>fn</span>(<a id="MarkdownSerializer.constructor^nodes^state" href="#MarkdownSerializer.constructor^nodes^state"><span class=param>state</span></a>: <a href="#MarkdownSerializerState"><span class="type">MarkdownSerializerState</span></a>, <a id="MarkdownSerializer.constructor^nodes^node" href="#MarkdownSerializer.constructor^nodes^node"><span class=param>node</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializer.constructor^nodes^parent" href="#MarkdownSerializer.constructor^nodes^parent"><span class=param>parent</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializer.constructor^nodes^index" href="#MarkdownSerializer.constructor^nodes^index"><span class=param>index</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number"><span class="prim">number</span></a>)&gt;, <a id="MarkdownSerializer.constructor^marks" href="#MarkdownSerializer.constructor^marks"><span class=param>marks</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a>&lt;<a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a>&gt;, <a id="MarkdownSerializer.constructor^options" href="#MarkdownSerializer.constructor^options"><span class=param>options</span></a>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a><span class=defaultvalue> = {}</span>)</code></dt>

<dd><p>Construct a serializer with the given configuration. The <code>nodes</code>
object should map node names in a given schema to function that
take a serializer state and such a node, and serialize the node.</p>
<dl><dt id="MarkdownSerializer.constructor^options">
  <code><strong><a href="#MarkdownSerializer.constructor^options">options</a></strong></code></dt>

<dd><dl><dt id="MarkdownSerializer.constructor^options.escapeExtraCharacters">
  <code><strong><a href="#MarkdownSerializer.constructor^options.escapeExtraCharacters">escapeExtraCharacters</a></strong>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp"><span class="type">RegExp</span></a></code></dt>

<dd><p>Extra characters can be added for escaping. This is passed
directly to String.replace(), and the matching characters are
preceded by a backslash.</p>
</dd></dl></dd></dl></dd><dt id="MarkdownSerializer.nodes">
  <code><strong><a href="#MarkdownSerializer.nodes">nodes</a></strong>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a>&lt;<span class=fn>fn</span>(<a id="MarkdownSerializer.nodes^state" href="#MarkdownSerializer.nodes^state"><span class=param>state</span></a>: <a href="#MarkdownSerializerState"><span class="type">MarkdownSerializerState</span></a>, <a id="MarkdownSerializer.nodes^node" href="#MarkdownSerializer.nodes^node"><span class=param>node</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializer.nodes^parent" href="#MarkdownSerializer.nodes^parent"><span class=param>parent</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializer.nodes^index" href="#MarkdownSerializer.nodes^index"><span class=param>index</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number"><span class="prim">number</span></a>)&gt;</code></dt>

<dd><p>The node serializer functions for this serializer.</p>
</dd><dt id="MarkdownSerializer.marks">
  <code><strong><a href="#MarkdownSerializer.marks">marks</a></strong>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a>&lt;<a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a>&gt;</code></dt>

<dd><p>The mark serializer info.</p>
</dd><dt id="MarkdownSerializer.options">
  <code><strong><a href="#MarkdownSerializer.options">options</a></strong>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a></code></dt>

<dd><dl><dt id="MarkdownSerializer.options.escapeExtraCharacters">
  <code><strong><a href="#MarkdownSerializer.options.escapeExtraCharacters">escapeExtraCharacters</a></strong>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp"><span class="type">RegExp</span></a></code></dt>

<dd><p>Extra characters can be added for escaping. This is passed
directly to String.replace(), and the matching characters are
preceded by a backslash.</p>
</dd></dl></dd><dt id="MarkdownSerializer.serialize">
  <code><strong><a href="#MarkdownSerializer.serialize">serialize</a></strong>(<a id="MarkdownSerializer.serialize^content" href="#MarkdownSerializer.serialize^content"><span class=param>content</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializer.serialize^options" href="#MarkdownSerializer.serialize^options"><span class=param>options</span></a>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object"><span class="type">Object</span></a><span class=defaultvalue> = {}</span>) → <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a></code></dt>

<dd><p>Serialize the content of the given node to
<a href="http://commonmark.org/">CommonMark</a>.</p>
<dl><dt id="MarkdownSerializer.serialize^options">
  <code><strong><a href="#MarkdownSerializer.serialize^options">options</a></strong></code></dt>

<dd><dl><dt id="MarkdownSerializer.serialize^options.tightLists">
  <code><strong><a href="#MarkdownSerializer.serialize^options.tightLists">tightLists</a></strong>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean"><span class="prim">boolean</span></a></code></dt>

<dd><p>Whether to render lists in a tight style. This can be overridden
on a node level by specifying a tight attribute on the node.
Defaults to false.</p>
</dd></dl></dd></dl></dd></dl>

</dd>
<dt id="MarkdownSerializerState">
  <h4>
    <code><span class=keyword>class</span></code>
    <a href="#MarkdownSerializerState">MarkdownSerializerState</a></h4>
</dt>

<dd><p>This is an object used to track state and expose
methods related to markdown serialization. Instances are passed to
node and mark serialization methods (see <code>toMarkdown</code>).</p>
<dl><dt id="MarkdownSerializerState.options">
  <code><strong><a href="#MarkdownSerializerState.options">options</a></strong>: {<span class=prop>tightLists</span>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean"><span class="prim">boolean</span></a>, <span class=prop>escapeExtraCharacters</span>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp"><span class="type">RegExp</span></a>}</code></dt>

<dd><p>The options passed to the serializer.</p>
</dd><dt id="MarkdownSerializerState.wrapBlock">
  <code><strong><a href="#MarkdownSerializerState.wrapBlock">wrapBlock</a></strong>(<a id="MarkdownSerializerState.wrapBlock^delim" href="#MarkdownSerializerState.wrapBlock^delim"><span class=param>delim</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>, <a id="MarkdownSerializerState.wrapBlock^firstDelim" href="#MarkdownSerializerState.wrapBlock^firstDelim"><span class=param>firstDelim</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>, <a id="MarkdownSerializerState.wrapBlock^node" href="#MarkdownSerializerState.wrapBlock^node"><span class=param>node</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializerState.wrapBlock^f" href="#MarkdownSerializerState.wrapBlock^f"><span class=param>f</span></a>: <span class=fn>fn</span>())</code></dt>

<dd><p>Render a block, prefixing each line with <code>delim</code>, and the first
line in <code>firstDelim</code>. <code>node</code> should be the node that is closed at
the end of the block, and <code>f</code> is a function that renders the
content of the block.</p>
</dd><dt id="MarkdownSerializerState.ensureNewLine">
  <code><strong><a href="#MarkdownSerializerState.ensureNewLine">ensureNewLine</a></strong>()</code></dt>

<dd><p>Ensure the current content ends with a newline.</p>
</dd><dt id="MarkdownSerializerState.write">
  <code><strong><a href="#MarkdownSerializerState.write">write</a></strong>(<a id="MarkdownSerializerState.write^content" href="#MarkdownSerializerState.write^content"><span class=param>content</span></a>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>)</code></dt>

<dd><p>Prepare the state for writing output (closing closed paragraphs,
adding delimiters, and so on), and then optionally add content
(unescaped) to the output.</p>
</dd><dt id="MarkdownSerializerState.closeBlock">
  <code><strong><a href="#MarkdownSerializerState.closeBlock">closeBlock</a></strong>(<a id="MarkdownSerializerState.closeBlock^node" href="#MarkdownSerializerState.closeBlock^node"><span class=param>node</span></a>: <span class="type">Node</span>)</code></dt>

<dd><p>Close the block for the given node.</p>
</dd><dt id="MarkdownSerializerState.text">
  <code><strong><a href="#MarkdownSerializerState.text">text</a></strong>(<a id="MarkdownSerializerState.text^text" href="#MarkdownSerializerState.text^text"><span class=param>text</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>, <a id="MarkdownSerializerState.text^escape" href="#MarkdownSerializerState.text^escape"><span class=param>escape</span></a>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean"><span class="prim">boolean</span></a><span class=defaultvalue> = true</span>)</code></dt>

<dd><p>Add the given text to the document. When escape is not <code>false</code>,
it will be escaped.</p>
</dd><dt id="MarkdownSerializerState.render">
  <code><strong><a href="#MarkdownSerializerState.render">render</a></strong>(<a id="MarkdownSerializerState.render^node" href="#MarkdownSerializerState.render^node"><span class=param>node</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializerState.render^parent" href="#MarkdownSerializerState.render^parent"><span class=param>parent</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializerState.render^index" href="#MarkdownSerializerState.render^index"><span class=param>index</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number"><span class="prim">number</span></a>)</code></dt>

<dd><p>Render the given node as a block.</p>
</dd><dt id="MarkdownSerializerState.renderContent">
  <code><strong><a href="#MarkdownSerializerState.renderContent">renderContent</a></strong>(<a id="MarkdownSerializerState.renderContent^parent" href="#MarkdownSerializerState.renderContent^parent"><span class=param>parent</span></a>: <span class="type">Node</span>)</code></dt>

<dd><p>Render the contents of <code>parent</code> as block nodes.</p>
</dd><dt id="MarkdownSerializerState.renderInline">
  <code><strong><a href="#MarkdownSerializerState.renderInline">renderInline</a></strong>(<a id="MarkdownSerializerState.renderInline^parent" href="#MarkdownSerializerState.renderInline^parent"><span class=param>parent</span></a>: <span class="type">Node</span>)</code></dt>

<dd><p>Render the contents of <code>parent</code> as inline content.</p>
</dd><dt id="MarkdownSerializerState.renderList">
  <code><strong><a href="#MarkdownSerializerState.renderList">renderList</a></strong>(<a id="MarkdownSerializerState.renderList^node" href="#MarkdownSerializerState.renderList^node"><span class=param>node</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializerState.renderList^delim" href="#MarkdownSerializerState.renderList^delim"><span class=param>delim</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>, <a id="MarkdownSerializerState.renderList^firstDelim" href="#MarkdownSerializerState.renderList^firstDelim"><span class=param>firstDelim</span></a>: <span class=fn>fn</span>(<a id="MarkdownSerializerState.renderList^firstDelim^index" href="#MarkdownSerializerState.renderList^firstDelim^index"><span class=param>index</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number"><span class="prim">number</span></a>) → <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>)</code></dt>

<dd><p>Render a node's content as a list. <code>delim</code> should be the extra
indentation added to all lines except the first in an item,
<code>firstDelim</code> is a function going from an item index to a
delimiter for the first line of the item.</p>
</dd><dt id="MarkdownSerializerState.esc">
  <code><strong><a href="#MarkdownSerializerState.esc">esc</a></strong>(<a id="MarkdownSerializerState.esc^str" href="#MarkdownSerializerState.esc^str"><span class=param>str</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>, <a id="MarkdownSerializerState.esc^startOfLine" href="#MarkdownSerializerState.esc^startOfLine"><span class=param>startOfLine</span></a>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean"><span class="prim">boolean</span></a><span class=defaultvalue> = false</span>) → <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a></code></dt>

<dd><p>Escape the given string so that it can safely appear in Markdown
content. If <code>startOfLine</code> is true, also escape characters that
have special meaning only at the start of the line.</p>
</dd><dt id="MarkdownSerializerState.repeat">
  <code><strong><a href="#MarkdownSerializerState.repeat">repeat</a></strong>(<a id="MarkdownSerializerState.repeat^str" href="#MarkdownSerializerState.repeat^str"><span class=param>str</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>, <a id="MarkdownSerializerState.repeat^n" href="#MarkdownSerializerState.repeat^n"><span class=param>n</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number"><span class="prim">number</span></a>) → <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a></code></dt>

<dd><p>Repeat the given string <code>n</code> times.</p>
</dd><dt id="MarkdownSerializerState.markString">
  <code><strong><a href="#MarkdownSerializerState.markString">markString</a></strong>(<a id="MarkdownSerializerState.markString^mark" href="#MarkdownSerializerState.markString^mark"><span class=param>mark</span></a>: <span class="type">Mark</span>, <a id="MarkdownSerializerState.markString^open" href="#MarkdownSerializerState.markString^open"><span class=param>open</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean"><span class="prim">boolean</span></a>, <a id="MarkdownSerializerState.markString^parent" href="#MarkdownSerializerState.markString^parent"><span class=param>parent</span></a>: <span class="type">Node</span>, <a id="MarkdownSerializerState.markString^index" href="#MarkdownSerializerState.markString^index"><span class=param>index</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number"><span class="prim">number</span></a>) → <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a></code></dt>

<dd><p>Get the markdown string for a given opening or closing mark.</p>
</dd><dt id="MarkdownSerializerState.getEnclosingWhitespace">
  <code><strong><a href="#MarkdownSerializerState.getEnclosingWhitespace">getEnclosingWhitespace</a></strong>(<a id="MarkdownSerializerState.getEnclosingWhitespace^text" href="#MarkdownSerializerState.getEnclosingWhitespace^text"><span class=param>text</span></a>: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>) → {<span class=prop>leading</span>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>, <span class=prop>trailing</span>&#8288;?: <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String"><span class="prim">string</span></a>}</code></dt>

<dd><p>Get leading and trailing whitespace from a string. Values of
leading or trailing property of the return object will be undefined
if there is no match.</p>
</dd></dl>

</dd>
<dt id="defaultMarkdownSerializer">
  <code><strong><a href="#defaultMarkdownSerializer">defaultMarkdownSerializer</a></strong>: <a href="#MarkdownSerializer"><span class="type">MarkdownSerializer</span></a></code></dt>

<dd><p>A serializer for the <a href="#schema">basic schema</a>.</p>
</dd>
</dl>

