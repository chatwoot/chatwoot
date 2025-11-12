import { Schema, Mark } from 'prosemirror-model';
import MarkdownIt from 'markdown-it';

/**
Document schema for the data model used by CommonMark.
*/
const schema = new Schema({
    nodes: {
        doc: {
            content: "block+"
        },
        paragraph: {
            content: "inline*",
            group: "block",
            parseDOM: [{ tag: "p" }],
            toDOM() { return ["p", 0]; }
        },
        blockquote: {
            content: "block+",
            group: "block",
            parseDOM: [{ tag: "blockquote" }],
            toDOM() { return ["blockquote", 0]; }
        },
        horizontal_rule: {
            group: "block",
            parseDOM: [{ tag: "hr" }],
            toDOM() { return ["div", ["hr"]]; }
        },
        heading: {
            attrs: { level: { default: 1 } },
            content: "(text | image)*",
            group: "block",
            defining: true,
            parseDOM: [{ tag: "h1", attrs: { level: 1 } },
                { tag: "h2", attrs: { level: 2 } },
                { tag: "h3", attrs: { level: 3 } },
                { tag: "h4", attrs: { level: 4 } },
                { tag: "h5", attrs: { level: 5 } },
                { tag: "h6", attrs: { level: 6 } }],
            toDOM(node) { return ["h" + node.attrs.level, 0]; }
        },
        code_block: {
            content: "text*",
            group: "block",
            code: true,
            defining: true,
            marks: "",
            attrs: { params: { default: "" } },
            parseDOM: [{ tag: "pre", preserveWhitespace: "full", getAttrs: node => ({ params: node.getAttribute("data-params") || "" }) }],
            toDOM(node) { return ["pre", node.attrs.params ? { "data-params": node.attrs.params } : {}, ["code", 0]]; }
        },
        ordered_list: {
            content: "list_item+",
            group: "block",
            attrs: { order: { default: 1 }, tight: { default: false } },
            parseDOM: [{ tag: "ol", getAttrs(dom) {
                        return { order: dom.hasAttribute("start") ? +dom.getAttribute("start") : 1,
                            tight: dom.hasAttribute("data-tight") };
                    } }],
            toDOM(node) {
                return ["ol", { start: node.attrs.order == 1 ? null : node.attrs.order,
                        "data-tight": node.attrs.tight ? "true" : null }, 0];
            }
        },
        bullet_list: {
            content: "list_item+",
            group: "block",
            attrs: { tight: { default: false } },
            parseDOM: [{ tag: "ul", getAttrs: dom => ({ tight: dom.hasAttribute("data-tight") }) }],
            toDOM(node) { return ["ul", { "data-tight": node.attrs.tight ? "true" : null }, 0]; }
        },
        list_item: {
            content: "block+",
            defining: true,
            parseDOM: [{ tag: "li" }],
            toDOM() { return ["li", 0]; }
        },
        text: {
            group: "inline"
        },
        image: {
            inline: true,
            attrs: {
                src: {},
                alt: { default: null },
                title: { default: null }
            },
            group: "inline",
            draggable: true,
            parseDOM: [{ tag: "img[src]", getAttrs(dom) {
                        return {
                            src: dom.getAttribute("src"),
                            title: dom.getAttribute("title"),
                            alt: dom.getAttribute("alt")
                        };
                    } }],
            toDOM(node) { return ["img", node.attrs]; }
        },
        hard_break: {
            inline: true,
            group: "inline",
            selectable: false,
            parseDOM: [{ tag: "br" }],
            toDOM() { return ["br"]; }
        }
    },
    marks: {
        em: {
            parseDOM: [
                { tag: "i" }, { tag: "em" },
                { style: "font-style=italic" },
                { style: "font-style=normal", clearMark: m => m.type.name == "em" }
            ],
            toDOM() { return ["em"]; }
        },
        strong: {
            parseDOM: [
                { tag: "strong" },
                { tag: "b", getAttrs: node => node.style.fontWeight != "normal" && null },
                { style: "font-weight=400", clearMark: m => m.type.name == "strong" },
                { style: "font-weight", getAttrs: value => /^(bold(er)?|[5-9]\d{2,})$/.test(value) && null }
            ],
            toDOM() { return ["strong"]; }
        },
        link: {
            attrs: {
                href: {},
                title: { default: null }
            },
            inclusive: false,
            parseDOM: [{ tag: "a[href]", getAttrs(dom) {
                        return { href: dom.getAttribute("href"), title: dom.getAttribute("title") };
                    } }],
            toDOM(node) { return ["a", node.attrs]; }
        },
        code: {
            parseDOM: [{ tag: "code" }],
            toDOM() { return ["code"]; }
        }
    }
});

// @ts-ignore
function maybeMerge(a, b) {
    if (a.isText && b.isText && Mark.sameSet(a.marks, b.marks))
        return a.withText(a.text + b.text);
}
// Object used to track the context of a running parse.
class MarkdownParseState {
    constructor(schema, tokenHandlers) {
        this.schema = schema;
        this.tokenHandlers = tokenHandlers;
        this.stack = [{ type: schema.topNodeType, attrs: null, content: [], marks: Mark.none }];
    }
    top() {
        return this.stack[this.stack.length - 1];
    }
    push(elt) {
        if (this.stack.length)
            this.top().content.push(elt);
    }
    // Adds the given text to the current position in the document,
    // using the current marks as styling.
    addText(text) {
        if (!text)
            return;
        let top = this.top(), nodes = top.content, last = nodes[nodes.length - 1];
        let node = this.schema.text(text, top.marks), merged;
        if (last && (merged = maybeMerge(last, node)))
            nodes[nodes.length - 1] = merged;
        else
            nodes.push(node);
    }
    // Adds the given mark to the set of active marks.
    openMark(mark) {
        let top = this.top();
        top.marks = mark.addToSet(top.marks);
    }
    // Removes the given mark from the set of active marks.
    closeMark(mark) {
        let top = this.top();
        top.marks = mark.removeFromSet(top.marks);
    }
    parseTokens(toks) {
        for (let i = 0; i < toks.length; i++) {
            let tok = toks[i];
            let handler = this.tokenHandlers[tok.type];
            if (!handler)
                throw new Error("Token type `" + tok.type + "` not supported by Markdown parser");
            handler(this, tok, toks, i);
        }
    }
    // Add a node at the current position.
    addNode(type, attrs, content) {
        let top = this.top();
        let node = type.createAndFill(attrs, content, top ? top.marks : []);
        if (!node)
            return null;
        this.push(node);
        return node;
    }
    // Wrap subsequent content in a node of the given type.
    openNode(type, attrs) {
        this.stack.push({ type: type, attrs: attrs, content: [], marks: Mark.none });
    }
    // Close and return the node that is currently on top of the stack.
    closeNode() {
        let info = this.stack.pop();
        return this.addNode(info.type, info.attrs, info.content);
    }
}
function attrs(spec, token, tokens, i) {
    if (spec.getAttrs)
        return spec.getAttrs(token, tokens, i);
    // For backwards compatibility when `attrs` is a Function
    else if (spec.attrs instanceof Function)
        return spec.attrs(token);
    else
        return spec.attrs;
}
// Code content is represented as a single token with a `content`
// property in Markdown-it.
function noCloseToken(spec, type) {
    return spec.noCloseToken || type == "code_inline" || type == "code_block" || type == "fence";
}
function withoutTrailingNewline(str) {
    return str[str.length - 1] == "\n" ? str.slice(0, str.length - 1) : str;
}
function noOp() { }
function tokenHandlers(schema, tokens) {
    let handlers = Object.create(null);
    for (let type in tokens) {
        let spec = tokens[type];
        if (spec.block) {
            let nodeType = schema.nodeType(spec.block);
            if (noCloseToken(spec, type)) {
                handlers[type] = (state, tok, tokens, i) => {
                    state.openNode(nodeType, attrs(spec, tok, tokens, i));
                    state.addText(withoutTrailingNewline(tok.content));
                    state.closeNode();
                };
            }
            else {
                handlers[type + "_open"] = (state, tok, tokens, i) => state.openNode(nodeType, attrs(spec, tok, tokens, i));
                handlers[type + "_close"] = state => state.closeNode();
            }
        }
        else if (spec.node) {
            let nodeType = schema.nodeType(spec.node);
            handlers[type] = (state, tok, tokens, i) => state.addNode(nodeType, attrs(spec, tok, tokens, i));
        }
        else if (spec.mark) {
            let markType = schema.marks[spec.mark];
            if (noCloseToken(spec, type)) {
                handlers[type] = (state, tok, tokens, i) => {
                    state.openMark(markType.create(attrs(spec, tok, tokens, i)));
                    state.addText(withoutTrailingNewline(tok.content));
                    state.closeMark(markType);
                };
            }
            else {
                handlers[type + "_open"] = (state, tok, tokens, i) => state.openMark(markType.create(attrs(spec, tok, tokens, i)));
                handlers[type + "_close"] = state => state.closeMark(markType);
            }
        }
        else if (spec.ignore) {
            if (noCloseToken(spec, type)) {
                handlers[type] = noOp;
            }
            else {
                handlers[type + "_open"] = noOp;
                handlers[type + "_close"] = noOp;
            }
        }
        else {
            throw new RangeError("Unrecognized parsing spec " + JSON.stringify(spec));
        }
    }
    handlers.text = (state, tok) => state.addText(tok.content);
    handlers.inline = (state, tok) => state.parseTokens(tok.children);
    handlers.softbreak = handlers.softbreak || (state => state.addText(" "));
    return handlers;
}
/**
A configuration of a Markdown parser. Such a parser uses
[markdown-it](https://github.com/markdown-it/markdown-it) to
tokenize a file, and then runs the custom rules it is given over
the tokens to create a ProseMirror document tree.
*/
class MarkdownParser {
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
    schema, 
    /**
    This parser's markdown-it tokenizer.
    */
    tokenizer, 
    /**
    The value of the `tokens` object used to construct this
    parser. Can be useful to copy and modify to base other parsers
    on.
    */
    tokens) {
        this.schema = schema;
        this.tokenizer = tokenizer;
        this.tokens = tokens;
        this.tokenHandlers = tokenHandlers(schema, tokens);
    }
    /**
    Parse a string as [CommonMark](http://commonmark.org/) markup,
    and create a ProseMirror document as prescribed by this parser's
    rules.
    
    The second argument, when given, is passed through to the
    [Markdown
    parser](https://markdown-it.github.io/markdown-it/#MarkdownIt.parse).
    */
    parse(text, markdownEnv = {}) {
        let state = new MarkdownParseState(this.schema, this.tokenHandlers), doc;
        state.parseTokens(this.tokenizer.parse(text, markdownEnv));
        do {
            doc = state.closeNode();
        } while (state.stack.length);
        return doc || this.schema.topNodeType.createAndFill();
    }
}
function listIsTight(tokens, i) {
    while (++i < tokens.length)
        if (tokens[i].type != "list_item_open")
            return tokens[i].hidden;
    return false;
}
/**
A parser parsing unextended [CommonMark](http://commonmark.org/),
without inline HTML, and producing a document in the basic schema.
*/
const defaultMarkdownParser = new MarkdownParser(schema, MarkdownIt("commonmark", { html: false }), {
    blockquote: { block: "blockquote" },
    paragraph: { block: "paragraph" },
    list_item: { block: "list_item" },
    bullet_list: { block: "bullet_list", getAttrs: (_, tokens, i) => ({ tight: listIsTight(tokens, i) }) },
    ordered_list: { block: "ordered_list", getAttrs: (tok, tokens, i) => ({
            order: +tok.attrGet("start") || 1,
            tight: listIsTight(tokens, i)
        }) },
    heading: { block: "heading", getAttrs: tok => ({ level: +tok.tag.slice(1) }) },
    code_block: { block: "code_block", noCloseToken: true },
    fence: { block: "code_block", getAttrs: tok => ({ params: tok.info || "" }), noCloseToken: true },
    hr: { node: "horizontal_rule" },
    image: { node: "image", getAttrs: tok => ({
            src: tok.attrGet("src"),
            title: tok.attrGet("title") || null,
            alt: tok.children[0] && tok.children[0].content || null
        }) },
    hardbreak: { node: "hard_break" },
    em: { mark: "em" },
    strong: { mark: "strong" },
    link: { mark: "link", getAttrs: tok => ({
            href: tok.attrGet("href"),
            title: tok.attrGet("title") || null
        }) },
    code_inline: { mark: "code", noCloseToken: true }
});

const blankMark = { open: "", close: "", mixable: true };
/**
A specification for serializing a ProseMirror document as
Markdown/CommonMark text.
*/
class MarkdownSerializer {
    /**
    Construct a serializer with the given configuration. The `nodes`
    object should map node names in a given schema to function that
    take a serializer state and such a node, and serialize the node.
    */
    constructor(
    /**
    The node serializer functions for this serializer.
    */
    nodes, 
    /**
    The mark serializer info.
    */
    marks, options = {}) {
        this.nodes = nodes;
        this.marks = marks;
        this.options = options;
    }
    /**
    Serialize the content of the given node to
    [CommonMark](http://commonmark.org/).
    */
    serialize(content, options = {}) {
        options = Object.assign({}, this.options, options);
        let state = new MarkdownSerializerState(this.nodes, this.marks, options);
        state.renderContent(content);
        return state.out;
    }
}
/**
A serializer for the [basic schema](https://prosemirror.net/docs/ref/#schema).
*/
const defaultMarkdownSerializer = new MarkdownSerializer({
    blockquote(state, node) {
        state.wrapBlock("> ", null, node, () => state.renderContent(node));
    },
    code_block(state, node) {
        // Make sure the front matter fences are longer than any dash sequence within it
        const backticks = node.textContent.match(/`{3,}/gm);
        const fence = backticks ? (backticks.sort().slice(-1)[0] + "`") : "```";
        state.write(fence + (node.attrs.params || "") + "\n");
        state.text(node.textContent, false);
        // Add a newline to the current content before adding closing marker
        state.write("\n");
        state.write(fence);
        state.closeBlock(node);
    },
    heading(state, node) {
        state.write(state.repeat("#", node.attrs.level) + " ");
        state.renderInline(node, false);
        state.closeBlock(node);
    },
    horizontal_rule(state, node) {
        state.write(node.attrs.markup || "---");
        state.closeBlock(node);
    },
    bullet_list(state, node) {
        state.renderList(node, "  ", () => (node.attrs.bullet || "*") + " ");
    },
    ordered_list(state, node) {
        let start = node.attrs.order || 1;
        let maxW = String(start + node.childCount - 1).length;
        let space = state.repeat(" ", maxW + 2);
        state.renderList(node, space, i => {
            let nStr = String(start + i);
            return state.repeat(" ", maxW - nStr.length) + nStr + ". ";
        });
    },
    list_item(state, node) {
        state.renderContent(node);
    },
    paragraph(state, node) {
        state.renderInline(node);
        state.closeBlock(node);
    },
    image(state, node) {
        state.write("![" + state.esc(node.attrs.alt || "") + "](" + node.attrs.src.replace(/[\(\)]/g, "\\$&") +
            (node.attrs.title ? ' "' + node.attrs.title.replace(/"/g, '\\"') + '"' : "") + ")");
    },
    hard_break(state, node, parent, index) {
        for (let i = index + 1; i < parent.childCount; i++)
            if (parent.child(i).type != node.type) {
                state.write("\\\n");
                return;
            }
    },
    text(state, node) {
        state.text(node.text, !state.inAutolink);
    }
}, {
    em: { open: "*", close: "*", mixable: true, expelEnclosingWhitespace: true },
    strong: { open: "**", close: "**", mixable: true, expelEnclosingWhitespace: true },
    link: {
        open(state, mark, parent, index) {
            state.inAutolink = isPlainURL(mark, parent, index);
            return state.inAutolink ? "<" : "[";
        },
        close(state, mark, parent, index) {
            let { inAutolink } = state;
            state.inAutolink = undefined;
            return inAutolink ? ">"
                : "](" + mark.attrs.href.replace(/[\(\)"]/g, "\\$&") + (mark.attrs.title ? ` "${mark.attrs.title.replace(/"/g, '\\"')}"` : "") + ")";
        },
        mixable: true
    },
    code: { open(_state, _mark, parent, index) { return backticksFor(parent.child(index), -1); },
        close(_state, _mark, parent, index) { return backticksFor(parent.child(index - 1), 1); },
        escape: false }
});
function backticksFor(node, side) {
    let ticks = /`+/g, m, len = 0;
    if (node.isText)
        while (m = ticks.exec(node.text))
            len = Math.max(len, m[0].length);
    let result = len > 0 && side > 0 ? " `" : "`";
    for (let i = 0; i < len; i++)
        result += "`";
    if (len > 0 && side < 0)
        result += " ";
    return result;
}
function isPlainURL(link, parent, index) {
    if (link.attrs.title || !/^\w+:/.test(link.attrs.href))
        return false;
    let content = parent.child(index);
    if (!content.isText || content.text != link.attrs.href || content.marks[content.marks.length - 1] != link)
        return false;
    return index == parent.childCount - 1 || !link.isInSet(parent.child(index + 1).marks);
}
/**
This is an object used to track state and expose
methods related to markdown serialization. Instances are passed to
node and mark serialization methods (see `toMarkdown`).
*/
class MarkdownSerializerState {
    /**
    @internal
    */
    constructor(
    /**
    @internal
    */
    nodes, 
    /**
    @internal
    */
    marks, 
    /**
    The options passed to the serializer.
    */
    options) {
        this.nodes = nodes;
        this.marks = marks;
        this.options = options;
        /**
        @internal
        */
        this.delim = "";
        /**
        @internal
        */
        this.out = "";
        /**
        @internal
        */
        this.closed = null;
        /**
        @internal
        */
        this.inAutolink = undefined;
        /**
        @internal
        */
        this.atBlockStart = false;
        /**
        @internal
        */
        this.inTightList = false;
        if (typeof this.options.tightLists == "undefined")
            this.options.tightLists = false;
        if (typeof this.options.hardBreakNodeName == "undefined")
            this.options.hardBreakNodeName = "hard_break";
    }
    /**
    @internal
    */
    flushClose(size = 2) {
        if (this.closed) {
            if (!this.atBlank())
                this.out += "\n";
            if (size > 1) {
                let delimMin = this.delim;
                let trim = /\s+$/.exec(delimMin);
                if (trim)
                    delimMin = delimMin.slice(0, delimMin.length - trim[0].length);
                for (let i = 1; i < size; i++)
                    this.out += delimMin + "\n";
            }
            this.closed = null;
        }
    }
    /**
    @internal
    */
    getMark(name) {
        let info = this.marks[name];
        if (!info) {
            if (this.options.strict !== false)
                throw new Error(`Mark type \`${name}\` not supported by Markdown renderer`);
            info = blankMark;
        }
        return info;
    }
    /**
    Render a block, prefixing each line with `delim`, and the first
    line in `firstDelim`. `node` should be the node that is closed at
    the end of the block, and `f` is a function that renders the
    content of the block.
    */
    wrapBlock(delim, firstDelim, node, f) {
        let old = this.delim;
        this.write(firstDelim != null ? firstDelim : delim);
        this.delim += delim;
        f();
        this.delim = old;
        this.closeBlock(node);
    }
    /**
    @internal
    */
    atBlank() {
        return /(^|\n)$/.test(this.out);
    }
    /**
    Ensure the current content ends with a newline.
    */
    ensureNewLine() {
        if (!this.atBlank())
            this.out += "\n";
    }
    /**
    Prepare the state for writing output (closing closed paragraphs,
    adding delimiters, and so on), and then optionally add content
    (unescaped) to the output.
    */
    write(content) {
        this.flushClose();
        if (this.delim && this.atBlank())
            this.out += this.delim;
        if (content)
            this.out += content;
    }
    /**
    Close the block for the given node.
    */
    closeBlock(node) {
        this.closed = node;
    }
    /**
    Add the given text to the document. When escape is not `false`,
    it will be escaped.
    */
    text(text, escape = true) {
        let lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            this.write();
            // Escape exclamation marks in front of links
            if (!escape && lines[i][0] == "[" && /(^|[^\\])\!$/.test(this.out))
                this.out = this.out.slice(0, this.out.length - 1) + "\\!";
            this.out += escape ? this.esc(lines[i], this.atBlockStart) : lines[i];
            if (i != lines.length - 1)
                this.out += "\n";
        }
    }
    /**
    Render the given node as a block.
    */
    render(node, parent, index) {
        if (this.nodes[node.type.name]) {
            this.nodes[node.type.name](this, node, parent, index);
        }
        else {
            if (this.options.strict !== false) {
                throw new Error("Token type `" + node.type.name + "` not supported by Markdown renderer");
            }
            else if (!node.type.isLeaf) {
                if (node.type.inlineContent)
                    this.renderInline(node);
                else
                    this.renderContent(node);
                if (node.isBlock)
                    this.closeBlock(node);
            }
        }
    }
    /**
    Render the contents of `parent` as block nodes.
    */
    renderContent(parent) {
        parent.forEach((node, _, i) => this.render(node, parent, i));
    }
    /**
    Render the contents of `parent` as inline content.
    */
    renderInline(parent, fromBlockStart = true) {
        this.atBlockStart = fromBlockStart;
        let active = [], trailing = "";
        let progress = (node, offset, index) => {
            let marks = node ? node.marks : [];
            // Remove marks from `hard_break` that are the last node inside
            // that mark to prevent parser edge cases with new lines just
            // before closing marks.
            if (node && node.type.name === this.options.hardBreakNodeName)
                marks = marks.filter(m => {
                    if (index + 1 == parent.childCount)
                        return false;
                    let next = parent.child(index + 1);
                    return m.isInSet(next.marks) && (!next.isText || /\S/.test(next.text));
                });
            let leading = trailing;
            trailing = "";
            // If whitespace has to be expelled from the node, adjust
            // leading and trailing accordingly.
            if (node && node.isText && marks.some(mark => {
                let info = this.getMark(mark.type.name);
                return info && info.expelEnclosingWhitespace && !mark.isInSet(active);
            })) {
                let [_, lead, rest] = /^(\s*)(.*)$/m.exec(node.text);
                if (lead) {
                    leading += lead;
                    node = rest ? node.withText(rest) : null;
                    if (!node)
                        marks = active;
                }
            }
            if (node && node.isText && marks.some(mark => {
                let info = this.getMark(mark.type.name);
                return info && info.expelEnclosingWhitespace &&
                    (index == parent.childCount - 1 || !mark.isInSet(parent.child(index + 1).marks));
            })) {
                let [_, rest, trail] = /^(.*?)(\s*)$/m.exec(node.text);
                if (trail) {
                    trailing = trail;
                    node = rest ? node.withText(rest) : null;
                    if (!node)
                        marks = active;
                }
            }
            let inner = marks.length ? marks[marks.length - 1] : null;
            let noEsc = inner && this.getMark(inner.type.name).escape === false;
            let len = marks.length - (noEsc ? 1 : 0);
            // Try to reorder 'mixable' marks, such as em and strong, which
            // in Markdown may be opened and closed in different order, so
            // that order of the marks for the token matches the order in
            // active.
            outer: for (let i = 0; i < len; i++) {
                let mark = marks[i];
                if (!this.getMark(mark.type.name).mixable)
                    break;
                for (let j = 0; j < active.length; j++) {
                    let other = active[j];
                    if (!this.getMark(other.type.name).mixable)
                        break;
                    if (mark.eq(other)) {
                        if (i > j)
                            marks = marks.slice(0, j).concat(mark).concat(marks.slice(j, i)).concat(marks.slice(i + 1, len));
                        else if (j > i)
                            marks = marks.slice(0, i).concat(marks.slice(i + 1, j)).concat(mark).concat(marks.slice(j, len));
                        continue outer;
                    }
                }
            }
            // Find the prefix of the mark set that didn't change
            let keep = 0;
            while (keep < Math.min(active.length, len) && marks[keep].eq(active[keep]))
                ++keep;
            // Close the marks that need to be closed
            while (keep < active.length)
                this.text(this.markString(active.pop(), false, parent, index), false);
            // Output any previously expelled trailing whitespace outside the marks
            if (leading)
                this.text(leading);
            // Open the marks that need to be opened
            if (node) {
                while (active.length < len) {
                    let add = marks[active.length];
                    active.push(add);
                    this.text(this.markString(add, true, parent, index), false);
                    this.atBlockStart = false;
                }
                // Render the node. Special case code marks, since their content
                // may not be escaped.
                if (noEsc && node.isText)
                    this.text(this.markString(inner, true, parent, index) + node.text +
                        this.markString(inner, false, parent, index + 1), false);
                else
                    this.render(node, parent, index);
                this.atBlockStart = false;
            }
            // After the first non-empty text node is rendered, the end of output
            // is no longer at block start.
            //
            // FIXME: If a non-text node writes something to the output for this
            // block, the end of output is also no longer at block start. But how
            // can we detect that?
            if ((node === null || node === void 0 ? void 0 : node.isText) && node.nodeSize > 0) {
                this.atBlockStart = false;
            }
        };
        parent.forEach(progress);
        progress(null, 0, parent.childCount);
        this.atBlockStart = false;
    }
    /**
    Render a node's content as a list. `delim` should be the extra
    indentation added to all lines except the first in an item,
    `firstDelim` is a function going from an item index to a
    delimiter for the first line of the item.
    */
    renderList(node, delim, firstDelim) {
        if (this.closed && this.closed.type == node.type)
            this.flushClose(3);
        else if (this.inTightList)
            this.flushClose(1);
        let isTight = typeof node.attrs.tight != "undefined" ? node.attrs.tight : this.options.tightLists;
        let prevTight = this.inTightList;
        this.inTightList = isTight;
        node.forEach((child, _, i) => {
            if (i && isTight)
                this.flushClose(1);
            this.wrapBlock(delim, firstDelim(i), node, () => this.render(child, node, i));
        });
        this.inTightList = prevTight;
    }
    /**
    Escape the given string so that it can safely appear in Markdown
    content. If `startOfLine` is true, also escape characters that
    have special meaning only at the start of the line.
    */
    esc(str, startOfLine = false) {
        str = str.replace(/[`*\\~\[\]_]/g, (m, i) => m == "_" && i > 0 && i + 1 < str.length && str[i - 1].match(/\w/) && str[i + 1].match(/\w/) ? m : "\\" + m);
        if (startOfLine)
            str = str.replace(/^(\+[ ]|[\-*>])/, "\\$&").replace(/^(\s*)(#{1,6})(\s|$)/, '$1\\$2$3').replace(/^(\s*\d+)\.\s/, "$1\\. ");
        if (this.options.escapeExtraCharacters)
            str = str.replace(this.options.escapeExtraCharacters, "\\$&");
        return str;
    }
    /**
    @internal
    */
    quote(str) {
        let wrap = str.indexOf('"') == -1 ? '""' : str.indexOf("'") == -1 ? "''" : "()";
        return wrap[0] + str + wrap[1];
    }
    /**
    Repeat the given string `n` times.
    */
    repeat(str, n) {
        let out = "";
        for (let i = 0; i < n; i++)
            out += str;
        return out;
    }
    /**
    Get the markdown string for a given opening or closing mark.
    */
    markString(mark, open, parent, index) {
        let info = this.getMark(mark.type.name);
        let value = open ? info.open : info.close;
        return typeof value == "string" ? value : value(this, mark, parent, index);
    }
    /**
    Get leading and trailing whitespace from a string. Values of
    leading or trailing property of the return object will be undefined
    if there is no match.
    */
    getEnclosingWhitespace(text) {
        return {
            leading: (text.match(/^(\s+)/) || [undefined])[0],
            trailing: (text.match(/(\s+)$/) || [undefined])[0]
        };
    }
}

export { MarkdownParser, MarkdownSerializer, MarkdownSerializerState, defaultMarkdownParser, defaultMarkdownSerializer, schema };
