'use strict';

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }
function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }
function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }
function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) arr2[i] = arr[i]; return arr2; }
function _iterableToArrayLimit(r, l) { var t = null == r ? null : "undefined" != typeof Symbol && r[Symbol.iterator] || r["@@iterator"]; if (null != t) { var e, n, i, u, a = [], f = !0, o = !1; try { if (i = (t = t.call(r)).next, 0 === l) { if (Object(t) !== t) return; f = !1; } else for (; !(f = (e = i.call(t)).done) && (a.push(e.value), a.length !== l); f = !0); } catch (r) { o = !0, n = r; } finally { try { if (!f && null != t["return"] && (u = t["return"](), Object(u) !== u)) return; } finally { if (o) throw n; } } return a; } }
function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }
function _typeof(o) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (o) { return typeof o; } : function (o) { return o && "function" == typeof Symbol && o.constructor === Symbol && o !== Symbol.prototype ? "symbol" : typeof o; }, _typeof(o); }
function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, _toPropertyKey(descriptor.key), descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
function _toPropertyKey(arg) { var key = _toPrimitive(arg, "string"); return _typeof(key) === "symbol" ? key : String(key); }
function _toPrimitive(input, hint) { if (_typeof(input) !== "object" || input === null) return input; var prim = input[Symbol.toPrimitive]; if (prim !== undefined) { var res = prim.call(input, hint || "default"); if (_typeof(res) !== "object") return res; throw new TypeError("@@toPrimitive must return a primitive value."); } return (hint === "string" ? String : Number)(input); }
var prosemirrorModel = require('prosemirror-model');
var MarkdownIt = require('markdown-it');
var schema = new prosemirrorModel.Schema({
  nodes: {
    doc: {
      content: "block+"
    },
    paragraph: {
      content: "inline*",
      group: "block",
      parseDOM: [{
        tag: "p"
      }],
      toDOM: function toDOM() {
        return ["p", 0];
      }
    },
    blockquote: {
      content: "block+",
      group: "block",
      parseDOM: [{
        tag: "blockquote"
      }],
      toDOM: function toDOM() {
        return ["blockquote", 0];
      }
    },
    horizontal_rule: {
      group: "block",
      parseDOM: [{
        tag: "hr"
      }],
      toDOM: function toDOM() {
        return ["div", ["hr"]];
      }
    },
    heading: {
      attrs: {
        level: {
          "default": 1
        }
      },
      content: "(text | image)*",
      group: "block",
      defining: true,
      parseDOM: [{
        tag: "h1",
        attrs: {
          level: 1
        }
      }, {
        tag: "h2",
        attrs: {
          level: 2
        }
      }, {
        tag: "h3",
        attrs: {
          level: 3
        }
      }, {
        tag: "h4",
        attrs: {
          level: 4
        }
      }, {
        tag: "h5",
        attrs: {
          level: 5
        }
      }, {
        tag: "h6",
        attrs: {
          level: 6
        }
      }],
      toDOM: function toDOM(node) {
        return ["h" + node.attrs.level, 0];
      }
    },
    code_block: {
      content: "text*",
      group: "block",
      code: true,
      defining: true,
      marks: "",
      attrs: {
        params: {
          "default": ""
        }
      },
      parseDOM: [{
        tag: "pre",
        preserveWhitespace: "full",
        getAttrs: function getAttrs(node) {
          return {
            params: node.getAttribute("data-params") || ""
          };
        }
      }],
      toDOM: function toDOM(node) {
        return ["pre", node.attrs.params ? {
          "data-params": node.attrs.params
        } : {}, ["code", 0]];
      }
    },
    ordered_list: {
      content: "list_item+",
      group: "block",
      attrs: {
        order: {
          "default": 1
        },
        tight: {
          "default": false
        }
      },
      parseDOM: [{
        tag: "ol",
        getAttrs: function getAttrs(dom) {
          return {
            order: dom.hasAttribute("start") ? +dom.getAttribute("start") : 1,
            tight: dom.hasAttribute("data-tight")
          };
        }
      }],
      toDOM: function toDOM(node) {
        return ["ol", {
          start: node.attrs.order == 1 ? null : node.attrs.order,
          "data-tight": node.attrs.tight ? "true" : null
        }, 0];
      }
    },
    bullet_list: {
      content: "list_item+",
      group: "block",
      attrs: {
        tight: {
          "default": false
        }
      },
      parseDOM: [{
        tag: "ul",
        getAttrs: function getAttrs(dom) {
          return {
            tight: dom.hasAttribute("data-tight")
          };
        }
      }],
      toDOM: function toDOM(node) {
        return ["ul", {
          "data-tight": node.attrs.tight ? "true" : null
        }, 0];
      }
    },
    list_item: {
      content: "block+",
      defining: true,
      parseDOM: [{
        tag: "li"
      }],
      toDOM: function toDOM() {
        return ["li", 0];
      }
    },
    text: {
      group: "inline"
    },
    image: {
      inline: true,
      attrs: {
        src: {},
        alt: {
          "default": null
        },
        title: {
          "default": null
        }
      },
      group: "inline",
      draggable: true,
      parseDOM: [{
        tag: "img[src]",
        getAttrs: function getAttrs(dom) {
          return {
            src: dom.getAttribute("src"),
            title: dom.getAttribute("title"),
            alt: dom.getAttribute("alt")
          };
        }
      }],
      toDOM: function toDOM(node) {
        return ["img", node.attrs];
      }
    },
    hard_break: {
      inline: true,
      group: "inline",
      selectable: false,
      parseDOM: [{
        tag: "br"
      }],
      toDOM: function toDOM() {
        return ["br"];
      }
    }
  },
  marks: {
    em: {
      parseDOM: [{
        tag: "i"
      }, {
        tag: "em"
      }, {
        style: "font-style=italic"
      }, {
        style: "font-style=normal",
        clearMark: function clearMark(m) {
          return m.type.name == "em";
        }
      }],
      toDOM: function toDOM() {
        return ["em"];
      }
    },
    strong: {
      parseDOM: [{
        tag: "strong"
      }, {
        tag: "b",
        getAttrs: function getAttrs(node) {
          return node.style.fontWeight != "normal" && null;
        }
      }, {
        style: "font-weight=400",
        clearMark: function clearMark(m) {
          return m.type.name == "strong";
        }
      }, {
        style: "font-weight",
        getAttrs: function getAttrs(value) {
          return /^(bold(er)?|[5-9]\d{2,})$/.test(value) && null;
        }
      }],
      toDOM: function toDOM() {
        return ["strong"];
      }
    },
    link: {
      attrs: {
        href: {},
        title: {
          "default": null
        }
      },
      inclusive: false,
      parseDOM: [{
        tag: "a[href]",
        getAttrs: function getAttrs(dom) {
          return {
            href: dom.getAttribute("href"),
            title: dom.getAttribute("title")
          };
        }
      }],
      toDOM: function toDOM(node) {
        return ["a", node.attrs];
      }
    },
    code: {
      parseDOM: [{
        tag: "code"
      }],
      toDOM: function toDOM() {
        return ["code"];
      }
    }
  }
});
function maybeMerge(a, b) {
  if (a.isText && b.isText && prosemirrorModel.Mark.sameSet(a.marks, b.marks)) return a.withText(a.text + b.text);
}
var MarkdownParseState = function () {
  function MarkdownParseState(schema, tokenHandlers) {
    _classCallCheck(this, MarkdownParseState);
    this.schema = schema;
    this.tokenHandlers = tokenHandlers;
    this.stack = [{
      type: schema.topNodeType,
      attrs: null,
      content: [],
      marks: prosemirrorModel.Mark.none
    }];
  }
  _createClass(MarkdownParseState, [{
    key: "top",
    value: function top() {
      return this.stack[this.stack.length - 1];
    }
  }, {
    key: "push",
    value: function push(elt) {
      if (this.stack.length) this.top().content.push(elt);
    }
  }, {
    key: "addText",
    value: function addText(text) {
      if (!text) return;
      var top = this.top(),
        nodes = top.content,
        last = nodes[nodes.length - 1];
      var node = this.schema.text(text, top.marks),
        merged;
      if (last && (merged = maybeMerge(last, node))) nodes[nodes.length - 1] = merged;else nodes.push(node);
    }
  }, {
    key: "openMark",
    value: function openMark(mark) {
      var top = this.top();
      top.marks = mark.addToSet(top.marks);
    }
  }, {
    key: "closeMark",
    value: function closeMark(mark) {
      var top = this.top();
      top.marks = mark.removeFromSet(top.marks);
    }
  }, {
    key: "parseTokens",
    value: function parseTokens(toks) {
      for (var i = 0; i < toks.length; i++) {
        var tok = toks[i];
        var handler = this.tokenHandlers[tok.type];
        if (!handler) throw new Error("Token type `" + tok.type + "` not supported by Markdown parser");
        handler(this, tok, toks, i);
      }
    }
  }, {
    key: "addNode",
    value: function addNode(type, attrs, content) {
      var top = this.top();
      var node = type.createAndFill(attrs, content, top ? top.marks : []);
      if (!node) return null;
      this.push(node);
      return node;
    }
  }, {
    key: "openNode",
    value: function openNode(type, attrs) {
      this.stack.push({
        type: type,
        attrs: attrs,
        content: [],
        marks: prosemirrorModel.Mark.none
      });
    }
  }, {
    key: "closeNode",
    value: function closeNode() {
      var info = this.stack.pop();
      return this.addNode(info.type, info.attrs, info.content);
    }
  }]);
  return MarkdownParseState;
}();
function attrs(spec, token, tokens, i) {
  if (spec.getAttrs) return spec.getAttrs(token, tokens, i);else if (spec.attrs instanceof Function) return spec.attrs(token);else return spec.attrs;
}
function noCloseToken(spec, type) {
  return spec.noCloseToken || type == "code_inline" || type == "code_block" || type == "fence";
}
function withoutTrailingNewline(str) {
  return str[str.length - 1] == "\n" ? str.slice(0, str.length - 1) : str;
}
function noOp() {}
function tokenHandlers(schema, tokens) {
  var handlers = Object.create(null);
  var _loop = function _loop() {
    var spec = tokens[type];
    if (spec.block) {
      var nodeType = schema.nodeType(spec.block);
      if (noCloseToken(spec, type)) {
        handlers[type] = function (state, tok, tokens, i) {
          state.openNode(nodeType, attrs(spec, tok, tokens, i));
          state.addText(withoutTrailingNewline(tok.content));
          state.closeNode();
        };
      } else {
        handlers[type + "_open"] = function (state, tok, tokens, i) {
          return state.openNode(nodeType, attrs(spec, tok, tokens, i));
        };
        handlers[type + "_close"] = function (state) {
          return state.closeNode();
        };
      }
    } else if (spec.node) {
      var _nodeType = schema.nodeType(spec.node);
      handlers[type] = function (state, tok, tokens, i) {
        return state.addNode(_nodeType, attrs(spec, tok, tokens, i));
      };
    } else if (spec.mark) {
      var markType = schema.marks[spec.mark];
      if (noCloseToken(spec, type)) {
        handlers[type] = function (state, tok, tokens, i) {
          state.openMark(markType.create(attrs(spec, tok, tokens, i)));
          state.addText(withoutTrailingNewline(tok.content));
          state.closeMark(markType);
        };
      } else {
        handlers[type + "_open"] = function (state, tok, tokens, i) {
          return state.openMark(markType.create(attrs(spec, tok, tokens, i)));
        };
        handlers[type + "_close"] = function (state) {
          return state.closeMark(markType);
        };
      }
    } else if (spec.ignore) {
      if (noCloseToken(spec, type)) {
        handlers[type] = noOp;
      } else {
        handlers[type + "_open"] = noOp;
        handlers[type + "_close"] = noOp;
      }
    } else {
      throw new RangeError("Unrecognized parsing spec " + JSON.stringify(spec));
    }
  };
  for (var type in tokens) {
    _loop();
  }
  handlers.text = function (state, tok) {
    return state.addText(tok.content);
  };
  handlers.inline = function (state, tok) {
    return state.parseTokens(tok.children);
  };
  handlers.softbreak = handlers.softbreak || function (state) {
    return state.addText(" ");
  };
  return handlers;
}
var MarkdownParser = function () {
  function MarkdownParser(schema, tokenizer, tokens) {
    _classCallCheck(this, MarkdownParser);
    this.schema = schema;
    this.tokenizer = tokenizer;
    this.tokens = tokens;
    this.tokenHandlers = tokenHandlers(schema, tokens);
  }
  _createClass(MarkdownParser, [{
    key: "parse",
    value: function parse(text) {
      var markdownEnv = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var state = new MarkdownParseState(this.schema, this.tokenHandlers),
        doc;
      state.parseTokens(this.tokenizer.parse(text, markdownEnv));
      do {
        doc = state.closeNode();
      } while (state.stack.length);
      return doc || this.schema.topNodeType.createAndFill();
    }
  }]);
  return MarkdownParser;
}();
function listIsTight(tokens, i) {
  while (++i < tokens.length) if (tokens[i].type != "list_item_open") return tokens[i].hidden;
  return false;
}
var defaultMarkdownParser = new MarkdownParser(schema, MarkdownIt("commonmark", {
  html: false
}), {
  blockquote: {
    block: "blockquote"
  },
  paragraph: {
    block: "paragraph"
  },
  list_item: {
    block: "list_item"
  },
  bullet_list: {
    block: "bullet_list",
    getAttrs: function getAttrs(_, tokens, i) {
      return {
        tight: listIsTight(tokens, i)
      };
    }
  },
  ordered_list: {
    block: "ordered_list",
    getAttrs: function getAttrs(tok, tokens, i) {
      return {
        order: +tok.attrGet("start") || 1,
        tight: listIsTight(tokens, i)
      };
    }
  },
  heading: {
    block: "heading",
    getAttrs: function getAttrs(tok) {
      return {
        level: +tok.tag.slice(1)
      };
    }
  },
  code_block: {
    block: "code_block",
    noCloseToken: true
  },
  fence: {
    block: "code_block",
    getAttrs: function getAttrs(tok) {
      return {
        params: tok.info || ""
      };
    },
    noCloseToken: true
  },
  hr: {
    node: "horizontal_rule"
  },
  image: {
    node: "image",
    getAttrs: function getAttrs(tok) {
      return {
        src: tok.attrGet("src"),
        title: tok.attrGet("title") || null,
        alt: tok.children[0] && tok.children[0].content || null
      };
    }
  },
  hardbreak: {
    node: "hard_break"
  },
  em: {
    mark: "em"
  },
  strong: {
    mark: "strong"
  },
  link: {
    mark: "link",
    getAttrs: function getAttrs(tok) {
      return {
        href: tok.attrGet("href"),
        title: tok.attrGet("title") || null
      };
    }
  },
  code_inline: {
    mark: "code",
    noCloseToken: true
  }
});
var blankMark = {
  open: "",
  close: "",
  mixable: true
};
var MarkdownSerializer = function () {
  function MarkdownSerializer(nodes, marks) {
    var options = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
    _classCallCheck(this, MarkdownSerializer);
    this.nodes = nodes;
    this.marks = marks;
    this.options = options;
  }
  _createClass(MarkdownSerializer, [{
    key: "serialize",
    value: function serialize(content) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      options = Object.assign({}, this.options, options);
      var state = new MarkdownSerializerState(this.nodes, this.marks, options);
      state.renderContent(content);
      return state.out;
    }
  }]);
  return MarkdownSerializer;
}();
var defaultMarkdownSerializer = new MarkdownSerializer({
  blockquote: function blockquote(state, node) {
    state.wrapBlock("> ", null, node, function () {
      return state.renderContent(node);
    });
  },
  code_block: function code_block(state, node) {
    var backticks = node.textContent.match(/`{3,}/gm);
    var fence = backticks ? backticks.sort().slice(-1)[0] + "`" : "```";
    state.write(fence + (node.attrs.params || "") + "\n");
    state.text(node.textContent, false);
    state.write("\n");
    state.write(fence);
    state.closeBlock(node);
  },
  heading: function heading(state, node) {
    state.write(state.repeat("#", node.attrs.level) + " ");
    state.renderInline(node, false);
    state.closeBlock(node);
  },
  horizontal_rule: function horizontal_rule(state, node) {
    state.write(node.attrs.markup || "---");
    state.closeBlock(node);
  },
  bullet_list: function bullet_list(state, node) {
    state.renderList(node, "  ", function () {
      return (node.attrs.bullet || "*") + " ";
    });
  },
  ordered_list: function ordered_list(state, node) {
    var start = node.attrs.order || 1;
    var maxW = String(start + node.childCount - 1).length;
    var space = state.repeat(" ", maxW + 2);
    state.renderList(node, space, function (i) {
      var nStr = String(start + i);
      return state.repeat(" ", maxW - nStr.length) + nStr + ". ";
    });
  },
  list_item: function list_item(state, node) {
    state.renderContent(node);
  },
  paragraph: function paragraph(state, node) {
    state.renderInline(node);
    state.closeBlock(node);
  },
  image: function image(state, node) {
    state.write("![" + state.esc(node.attrs.alt || "") + "](" + node.attrs.src.replace(/[\(\)]/g, "\\$&") + (node.attrs.title ? ' "' + node.attrs.title.replace(/"/g, '\\"') + '"' : "") + ")");
  },
  hard_break: function hard_break(state, node, parent, index) {
    for (var i = index + 1; i < parent.childCount; i++) if (parent.child(i).type != node.type) {
      state.write("\\\n");
      return;
    }
  },
  text: function text(state, node) {
    state.text(node.text, !state.inAutolink);
  }
}, {
  em: {
    open: "*",
    close: "*",
    mixable: true,
    expelEnclosingWhitespace: true
  },
  strong: {
    open: "**",
    close: "**",
    mixable: true,
    expelEnclosingWhitespace: true
  },
  link: {
    open: function open(state, mark, parent, index) {
      state.inAutolink = isPlainURL(mark, parent, index);
      return state.inAutolink ? "<" : "[";
    },
    close: function close(state, mark, parent, index) {
      var inAutolink = state.inAutolink;
      state.inAutolink = undefined;
      return inAutolink ? ">" : "](" + mark.attrs.href.replace(/[\(\)"]/g, "\\$&") + (mark.attrs.title ? " \"".concat(mark.attrs.title.replace(/"/g, '\\"'), "\"") : "") + ")";
    },
    mixable: true
  },
  code: {
    open: function open(_state, _mark, parent, index) {
      return backticksFor(parent.child(index), -1);
    },
    close: function close(_state, _mark, parent, index) {
      return backticksFor(parent.child(index - 1), 1);
    },
    escape: false
  }
});
function backticksFor(node, side) {
  var ticks = /`+/g,
    m,
    len = 0;
  if (node.isText) while (m = ticks.exec(node.text)) len = Math.max(len, m[0].length);
  var result = len > 0 && side > 0 ? " `" : "`";
  for (var i = 0; i < len; i++) result += "`";
  if (len > 0 && side < 0) result += " ";
  return result;
}
function isPlainURL(link, parent, index) {
  if (link.attrs.title || !/^\w+:/.test(link.attrs.href)) return false;
  var content = parent.child(index);
  if (!content.isText || content.text != link.attrs.href || content.marks[content.marks.length - 1] != link) return false;
  return index == parent.childCount - 1 || !link.isInSet(parent.child(index + 1).marks);
}
var MarkdownSerializerState = function () {
  function MarkdownSerializerState(nodes, marks, options) {
    _classCallCheck(this, MarkdownSerializerState);
    this.nodes = nodes;
    this.marks = marks;
    this.options = options;
    this.delim = "";
    this.out = "";
    this.closed = null;
    this.inAutolink = undefined;
    this.atBlockStart = false;
    this.inTightList = false;
    if (typeof this.options.tightLists == "undefined") this.options.tightLists = false;
    if (typeof this.options.hardBreakNodeName == "undefined") this.options.hardBreakNodeName = "hard_break";
  }
  _createClass(MarkdownSerializerState, [{
    key: "flushClose",
    value: function flushClose() {
      var size = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 2;
      if (this.closed) {
        if (!this.atBlank()) this.out += "\n";
        if (size > 1) {
          var delimMin = this.delim;
          var trim = /\s+$/.exec(delimMin);
          if (trim) delimMin = delimMin.slice(0, delimMin.length - trim[0].length);
          for (var i = 1; i < size; i++) this.out += delimMin + "\n";
        }
        this.closed = null;
      }
    }
  }, {
    key: "getMark",
    value: function getMark(name) {
      var info = this.marks[name];
      if (!info) {
        if (this.options.strict !== false) throw new Error("Mark type `".concat(name, "` not supported by Markdown renderer"));
        info = blankMark;
      }
      return info;
    }
  }, {
    key: "wrapBlock",
    value: function wrapBlock(delim, firstDelim, node, f) {
      var old = this.delim;
      this.write(firstDelim != null ? firstDelim : delim);
      this.delim += delim;
      f();
      this.delim = old;
      this.closeBlock(node);
    }
  }, {
    key: "atBlank",
    value: function atBlank() {
      return /(^|\n)$/.test(this.out);
    }
  }, {
    key: "ensureNewLine",
    value: function ensureNewLine() {
      if (!this.atBlank()) this.out += "\n";
    }
  }, {
    key: "write",
    value: function write(content) {
      this.flushClose();
      if (this.delim && this.atBlank()) this.out += this.delim;
      if (content) this.out += content;
    }
  }, {
    key: "closeBlock",
    value: function closeBlock(node) {
      this.closed = node;
    }
  }, {
    key: "text",
    value: function text(_text) {
      var escape = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
      var lines = _text.split("\n");
      for (var i = 0; i < lines.length; i++) {
        this.write();
        if (!escape && lines[i][0] == "[" && /(^|[^\\])\!$/.test(this.out)) this.out = this.out.slice(0, this.out.length - 1) + "\\!";
        this.out += escape ? this.esc(lines[i], this.atBlockStart) : lines[i];
        if (i != lines.length - 1) this.out += "\n";
      }
    }
  }, {
    key: "render",
    value: function render(node, parent, index) {
      if (this.nodes[node.type.name]) {
        this.nodes[node.type.name](this, node, parent, index);
      } else {
        if (this.options.strict !== false) {
          throw new Error("Token type `" + node.type.name + "` not supported by Markdown renderer");
        } else if (!node.type.isLeaf) {
          if (node.type.inlineContent) this.renderInline(node);else this.renderContent(node);
          if (node.isBlock) this.closeBlock(node);
        }
      }
    }
  }, {
    key: "renderContent",
    value: function renderContent(parent) {
      var _this = this;
      parent.forEach(function (node, _, i) {
        return _this.render(node, parent, i);
      });
    }
  }, {
    key: "renderInline",
    value: function renderInline(parent) {
      var _this2 = this;
      var fromBlockStart = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
      this.atBlockStart = fromBlockStart;
      var active = [],
        trailing = "";
      var progress = function progress(node, offset, index) {
        var marks = node ? node.marks : [];
        if (node && node.type.name === _this2.options.hardBreakNodeName) marks = marks.filter(function (m) {
          if (index + 1 == parent.childCount) return false;
          var next = parent.child(index + 1);
          return m.isInSet(next.marks) && (!next.isText || /\S/.test(next.text));
        });
        var leading = trailing;
        trailing = "";
        if (node && node.isText && marks.some(function (mark) {
          var info = _this2.getMark(mark.type.name);
          return info && info.expelEnclosingWhitespace && !mark.isInSet(active);
        })) {
          var _exec = /^(\s*)(.*)$/m.exec(node.text),
            _exec2 = _slicedToArray(_exec, 3),
            _ = _exec2[0],
            lead = _exec2[1],
            rest = _exec2[2];
          if (lead) {
            leading += lead;
            node = rest ? node.withText(rest) : null;
            if (!node) marks = active;
          }
        }
        if (node && node.isText && marks.some(function (mark) {
          var info = _this2.getMark(mark.type.name);
          return info && info.expelEnclosingWhitespace && (index == parent.childCount - 1 || !mark.isInSet(parent.child(index + 1).marks));
        })) {
          var _exec3 = /^(.*?)(\s*)$/m.exec(node.text),
            _exec4 = _slicedToArray(_exec3, 3),
            _2 = _exec4[0],
            _rest = _exec4[1],
            trail = _exec4[2];
          if (trail) {
            trailing = trail;
            node = _rest ? node.withText(_rest) : null;
            if (!node) marks = active;
          }
        }
        var inner = marks.length ? marks[marks.length - 1] : null;
        var noEsc = inner && _this2.getMark(inner.type.name).escape === false;
        var len = marks.length - (noEsc ? 1 : 0);
        outer: for (var i = 0; i < len; i++) {
          var mark = marks[i];
          if (!_this2.getMark(mark.type.name).mixable) break;
          for (var j = 0; j < active.length; j++) {
            var other = active[j];
            if (!_this2.getMark(other.type.name).mixable) break;
            if (mark.eq(other)) {
              if (i > j) marks = marks.slice(0, j).concat(mark).concat(marks.slice(j, i)).concat(marks.slice(i + 1, len));else if (j > i) marks = marks.slice(0, i).concat(marks.slice(i + 1, j)).concat(mark).concat(marks.slice(j, len));
              continue outer;
            }
          }
        }
        var keep = 0;
        while (keep < Math.min(active.length, len) && marks[keep].eq(active[keep])) ++keep;
        while (keep < active.length) _this2.text(_this2.markString(active.pop(), false, parent, index), false);
        if (leading) _this2.text(leading);
        if (node) {
          while (active.length < len) {
            var add = marks[active.length];
            active.push(add);
            _this2.text(_this2.markString(add, true, parent, index), false);
            _this2.atBlockStart = false;
          }
          if (noEsc && node.isText) _this2.text(_this2.markString(inner, true, parent, index) + node.text + _this2.markString(inner, false, parent, index + 1), false);else _this2.render(node, parent, index);
          _this2.atBlockStart = false;
        }
        if ((node === null || node === void 0 ? void 0 : node.isText) && node.nodeSize > 0) {
          _this2.atBlockStart = false;
        }
      };
      parent.forEach(progress);
      progress(null, 0, parent.childCount);
      this.atBlockStart = false;
    }
  }, {
    key: "renderList",
    value: function renderList(node, delim, firstDelim) {
      var _this3 = this;
      if (this.closed && this.closed.type == node.type) this.flushClose(3);else if (this.inTightList) this.flushClose(1);
      var isTight = typeof node.attrs.tight != "undefined" ? node.attrs.tight : this.options.tightLists;
      var prevTight = this.inTightList;
      this.inTightList = isTight;
      node.forEach(function (child, _, i) {
        if (i && isTight) _this3.flushClose(1);
        _this3.wrapBlock(delim, firstDelim(i), node, function () {
          return _this3.render(child, node, i);
        });
      });
      this.inTightList = prevTight;
    }
  }, {
    key: "esc",
    value: function esc(str) {
      var startOfLine = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
      str = str.replace(/[`*\\~\[\]_]/g, function (m, i) {
        return m == "_" && i > 0 && i + 1 < str.length && str[i - 1].match(/\w/) && str[i + 1].match(/\w/) ? m : "\\" + m;
      });
      if (startOfLine) str = str.replace(/^(\+[ ]|[\-*>])/, "\\$&").replace(/^(\s*)(#{1,6})(\s|$)/, '$1\\$2$3').replace(/^(\s*\d+)\.\s/, "$1\\. ");
      if (this.options.escapeExtraCharacters) str = str.replace(this.options.escapeExtraCharacters, "\\$&");
      return str;
    }
  }, {
    key: "quote",
    value: function quote(str) {
      var wrap = str.indexOf('"') == -1 ? '""' : str.indexOf("'") == -1 ? "''" : "()";
      return wrap[0] + str + wrap[1];
    }
  }, {
    key: "repeat",
    value: function repeat(str, n) {
      var out = "";
      for (var i = 0; i < n; i++) out += str;
      return out;
    }
  }, {
    key: "markString",
    value: function markString(mark, open, parent, index) {
      var info = this.getMark(mark.type.name);
      var value = open ? info.open : info.close;
      return typeof value == "string" ? value : value(this, mark, parent, index);
    }
  }, {
    key: "getEnclosingWhitespace",
    value: function getEnclosingWhitespace(text) {
      return {
        leading: (text.match(/^(\s+)/) || [undefined])[0],
        trailing: (text.match(/(\s+)$/) || [undefined])[0]
      };
    }
  }]);
  return MarkdownSerializerState;
}();
exports.MarkdownParser = MarkdownParser;
exports.MarkdownSerializer = MarkdownSerializer;
exports.MarkdownSerializerState = MarkdownSerializerState;
exports.defaultMarkdownParser = defaultMarkdownParser;
exports.defaultMarkdownSerializer = defaultMarkdownSerializer;
exports.schema = schema;
