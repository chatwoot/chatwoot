import { Schema, Attrs, Node, Mark } from 'prosemirror-model';
import MarkdownIt from 'markdown-it';
import Token from 'markdown-it/lib/token';

/**
Document schema for the data model used by CommonMark.
*/
declare const schema: Schema<"blockquote" | "image" | "text" | "paragraph" | "code_block" | "doc" | "horizontal_rule" | "heading" | "ordered_list" | "bullet_list" | "list_item" | "hard_break", "link" | "code" | "em" | "strong">;

/**
Object type used to specify how Markdown tokens should be parsed.
*/
interface ParseSpec {
    /**
    This token maps to a single node, whose type can be looked up
    in the schema under the given name. Exactly one of `node`,
    `block`, or `mark` must be set.
    */
    node?: string;
    /**
    This token (unless `noCloseToken` is true) comes in `_open`
    and `_close` variants (which are appended to the base token
    name provides a the object property), and wraps a block of
    content. The block should be wrapped in a node of the type
    named to by the property's value. If the token does not have
    `_open` or `_close`, use the `noCloseToken` option.
    */
    block?: string;
    /**
    This token (again, unless `noCloseToken` is true) also comes
    in `_open` and `_close` variants, but should add a mark
    (named by the value) to its content, rather than wrapping it
    in a node.
    */
    mark?: string;
    /**
    Attributes for the node or mark. When `getAttrs` is provided,
    it takes precedence.
    */
    attrs?: Attrs | null;
    /**
    A function used to compute the attributes for the node or mark
    that takes a [markdown-it
    token](https://markdown-it.github.io/markdown-it/#Token) and
    returns an attribute object.
    */
    getAttrs?: (token: Token, tokenStream: Token[], index: number) => Attrs | null;
    /**
    Indicates that the [markdown-it
    token](https://markdown-it.github.io/markdown-it/#Token) has
    no `_open` or `_close` for the nodes. This defaults to `true`
    for `code_inline`, `code_block` and `fence`.
    */
    noCloseToken?: boolean;
    /**
    When true, ignore content for the matched token.
    */
    ignore?: boolean;
}
/**
A configuration of a Markdown parser. Such a parser uses
[markdown-it](https://github.com/markdown-it/markdown-it) to
tokenize a file, and then runs the custom rules it is given over
the tokens to create a ProseMirror document tree.
*/
declare class MarkdownParser {
    /**
    The parser's document schema.
    */
    readonly schema: Schema;
    /**
    This parser's markdown-it tokenizer.
    */
    readonly tokenizer: MarkdownIt;
    /**
    The value of the `tokens` object used to construct this
    parser. Can be useful to copy and modify to base other parsers
    on.
    */
    readonly tokens: {
        [name: string]: ParseSpec;
    };
    /**
    Create a parser with the given configuration. You can configure
    the markdown-it parser to parse the dialect you want, and provide
    a description of the ProseMirror entities those tokens map to in
    the `tokens` object, which maps token names to descriptions of
    what to do with them. Such a description is an object, and may
    have the following properties:
    */
    constructor(
    /**
    The parser's document schema.
    */
    schema: Schema, 
    /**
    This parser's markdown-it tokenizer.
    */
    tokenizer: MarkdownIt, 
    /**
    The value of the `tokens` object used to construct this
    parser. Can be useful to copy and modify to base other parsers
    on.
    */
    tokens: {
        [name: string]: ParseSpec;
    });
    /**
    Parse a string as [CommonMark](http://commonmark.org/) markup,
    and create a ProseMirror document as prescribed by this parser's
    rules.
    
    The second argument, when given, is passed through to the
    [Markdown
    parser](https://markdown-it.github.io/markdown-it/#MarkdownIt.parse).
    */
    parse(text: string, markdownEnv?: Object): Node;
}
/**
A parser parsing unextended [CommonMark](http://commonmark.org/),
without inline HTML, and producing a document in the basic schema.
*/
declare const defaultMarkdownParser: MarkdownParser;

type MarkSerializerSpec = {
    /**
    The string that should appear before a piece of content marked
    by this mark, either directly or as a function that returns an
    appropriate string.
    */
    open: string | ((state: MarkdownSerializerState, mark: Mark, parent: Node, index: number) => string);
    /**
    The string that should appear after a piece of content marked by
    this mark.
    */
    close: string | ((state: MarkdownSerializerState, mark: Mark, parent: Node, index: number) => string);
    /**
    When `true`, this indicates that the order in which the mark's
    opening and closing syntax appears relative to other mixable
    marks can be varied. (For example, you can say `**a *b***` and
    `*a **b***`, but not `` `a *b*` ``.)
    */
    mixable?: boolean;
    /**
    When enabled, causes the serializer to move enclosing whitespace
    from inside the marks to outside the marks. This is necessary
    for emphasis marks as CommonMark does not permit enclosing
    whitespace inside emphasis marks, see:
    http:spec.commonmark.org/0.26/#example-330
    */
    expelEnclosingWhitespace?: boolean;
    /**
    Can be set to `false` to disable character escaping in a mark. A
    non-escaping mark has to have the highest precedence (must
    always be the innermost mark).
    */
    escape?: boolean;
};
/**
A specification for serializing a ProseMirror document as
Markdown/CommonMark text.
*/
declare class MarkdownSerializer {
    /**
    The node serializer functions for this serializer.
    */
    readonly nodes: {
        [node: string]: (state: MarkdownSerializerState, node: Node, parent: Node, index: number) => void;
    };
    /**
    The mark serializer info.
    */
    readonly marks: {
        [mark: string]: MarkSerializerSpec;
    };
    readonly options: {
        /**
        Extra characters can be added for escaping. This is passed
        directly to String.replace(), and the matching characters are
        preceded by a backslash.
        */
        escapeExtraCharacters?: RegExp;
        /**
        Specify the node name of hard breaks.
        Defaults to "hard_break"
        */
        hardBreakNodeName?: string;
        /**
        By default, the serializer raises an error when it finds a
        node or mark type for which no serializer is defined. Set
        this to `false` to make it just ignore such elements,
        rendering only their content.
        */
        strict?: boolean;
    };
    /**
    Construct a serializer with the given configuration. The `nodes`
    object should map node names in a given schema to function that
    take a serializer state and such a node, and serialize the node.
    */
    constructor(
    /**
    The node serializer functions for this serializer.
    */
    nodes: {
        [node: string]: (state: MarkdownSerializerState, node: Node, parent: Node, index: number) => void;
    }, 
    /**
    The mark serializer info.
    */
    marks: {
        [mark: string]: MarkSerializerSpec;
    }, options?: {
        /**
        Extra characters can be added for escaping. This is passed
        directly to String.replace(), and the matching characters are
        preceded by a backslash.
        */
        escapeExtraCharacters?: RegExp;
        /**
        Specify the node name of hard breaks.
        Defaults to "hard_break"
        */
        hardBreakNodeName?: string;
        /**
        By default, the serializer raises an error when it finds a
        node or mark type for which no serializer is defined. Set
        this to `false` to make it just ignore such elements,
        rendering only their content.
        */
        strict?: boolean;
    });
    /**
    Serialize the content of the given node to
    [CommonMark](http://commonmark.org/).
    */
    serialize(content: Node, options?: {
        /**
        Whether to render lists in a tight style. This can be overridden
        on a node level by specifying a tight attribute on the node.
        Defaults to false.
        */
        tightLists?: boolean;
    }): string;
}
/**
A serializer for the [basic schema](https://prosemirror.net/docs/ref/#schema).
*/
declare const defaultMarkdownSerializer: MarkdownSerializer;
/**
This is an object used to track state and expose
methods related to markdown serialization. Instances are passed to
node and mark serialization methods (see `toMarkdown`).
*/
declare class MarkdownSerializerState {
    /**
    The options passed to the serializer.
    */
    readonly options: {
        tightLists?: boolean;
        escapeExtraCharacters?: RegExp;
        hardBreakNodeName?: string;
        strict?: boolean;
    };
    /**
    Render a block, prefixing each line with `delim`, and the first
    line in `firstDelim`. `node` should be the node that is closed at
    the end of the block, and `f` is a function that renders the
    content of the block.
    */
    wrapBlock(delim: string, firstDelim: string | null, node: Node, f: () => void): void;
    /**
    Ensure the current content ends with a newline.
    */
    ensureNewLine(): void;
    /**
    Prepare the state for writing output (closing closed paragraphs,
    adding delimiters, and so on), and then optionally add content
    (unescaped) to the output.
    */
    write(content?: string): void;
    /**
    Close the block for the given node.
    */
    closeBlock(node: Node): void;
    /**
    Add the given text to the document. When escape is not `false`,
    it will be escaped.
    */
    text(text: string, escape?: boolean): void;
    /**
    Render the given node as a block.
    */
    render(node: Node, parent: Node, index: number): void;
    /**
    Render the contents of `parent` as block nodes.
    */
    renderContent(parent: Node): void;
    /**
    Render the contents of `parent` as inline content.
    */
    renderInline(parent: Node, fromBlockStart?: boolean): void;
    /**
    Render a node's content as a list. `delim` should be the extra
    indentation added to all lines except the first in an item,
    `firstDelim` is a function going from an item index to a
    delimiter for the first line of the item.
    */
    renderList(node: Node, delim: string, firstDelim: (index: number) => string): void;
    /**
    Escape the given string so that it can safely appear in Markdown
    content. If `startOfLine` is true, also escape characters that
    have special meaning only at the start of the line.
    */
    esc(str: string, startOfLine?: boolean): string;
    /**
    Repeat the given string `n` times.
    */
    repeat(str: string, n: number): string;
    /**
    Get the markdown string for a given opening or closing mark.
    */
    markString(mark: Mark, open: boolean, parent: Node, index: number): string;
    /**
    Get leading and trailing whitespace from a string. Values of
    leading or trailing property of the return object will be undefined
    if there is no match.
    */
    getEnclosingWhitespace(text: string): {
        leading?: string;
        trailing?: string;
    };
}

export { MarkdownParser, MarkdownSerializer, MarkdownSerializerState, type ParseSpec, defaultMarkdownParser, defaultMarkdownSerializer, schema };
