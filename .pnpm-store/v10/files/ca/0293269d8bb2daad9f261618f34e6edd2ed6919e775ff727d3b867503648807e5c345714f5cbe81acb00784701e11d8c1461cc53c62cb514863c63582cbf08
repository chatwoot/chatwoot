'use strict';

function _typeof(o) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (o) { return typeof o; } : function (o) { return o && "function" == typeof Symbol && o.constructor === Symbol && o !== Symbol.prototype ? "symbol" : typeof o; }, _typeof(o); }
function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, _toPropertyKey(descriptor.key), descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
function _toPropertyKey(arg) { var key = _toPrimitive(arg, "string"); return _typeof(key) === "symbol" ? key : String(key); }
function _toPrimitive(input, hint) { if (_typeof(input) !== "object" || input === null) return input; var prim = input[Symbol.toPrimitive]; if (prim !== undefined) { var res = prim.call(input, hint || "default"); if (_typeof(res) !== "object") return res; throw new TypeError("@@toPrimitive must return a primitive value."); } return (hint === "string" ? String : Number)(input); }
function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
var prosemirrorState = require('prosemirror-state');
var prosemirrorTransform = require('prosemirror-transform');
var InputRule = _createClass(function InputRule(match, handler) {
  var options = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
  _classCallCheck(this, InputRule);
  this.match = match;
  this.match = match;
  this.handler = typeof handler == "string" ? stringHandler(handler) : handler;
  this.undoable = options.undoable !== false;
  this.inCode = options.inCode || false;
});
function stringHandler(string) {
  return function (state, match, start, end) {
    var insert = string;
    if (match[1]) {
      var offset = match[0].lastIndexOf(match[1]);
      insert += match[0].slice(offset + match[1].length);
      start += offset;
      var cutOff = start - end;
      if (cutOff > 0) {
        insert = match[0].slice(offset - cutOff, offset) + insert;
        start = end;
      }
    }
    return state.tr.insertText(insert, start, end);
  };
}
var MAX_MATCH = 500;
function inputRules(_ref) {
  var rules = _ref.rules;
  var plugin = new prosemirrorState.Plugin({
    state: {
      init: function init() {
        return null;
      },
      apply: function apply(tr, prev) {
        var stored = tr.getMeta(this);
        if (stored) return stored;
        return tr.selectionSet || tr.docChanged ? null : prev;
      }
    },
    props: {
      handleTextInput: function handleTextInput(view, from, to, text) {
        return run(view, from, to, text, rules, plugin);
      },
      handleDOMEvents: {
        compositionend: function compositionend(view) {
          setTimeout(function () {
            var $cursor = view.state.selection.$cursor;
            if ($cursor) run(view, $cursor.pos, $cursor.pos, "", rules, plugin);
          });
        }
      }
    },
    isInputRules: true
  });
  return plugin;
}
function run(view, from, to, text, rules, plugin) {
  if (view.composing) return false;
  var state = view.state,
    $from = state.doc.resolve(from);
  var textBefore = $from.parent.textBetween(Math.max(0, $from.parentOffset - MAX_MATCH), $from.parentOffset, null, "\uFFFC") + text;
  for (var i = 0; i < rules.length; i++) {
    var rule = rules[i];
    if ($from.parent.type.spec.code) {
      if (!rule.inCode) continue;
    } else if (rule.inCode === "only") {
      continue;
    }
    var match = rule.match.exec(textBefore);
    var tr = match && rule.handler(state, match, from - (match[0].length - text.length), to);
    if (!tr) continue;
    if (rule.undoable) tr.setMeta(plugin, {
      transform: tr,
      from: from,
      to: to,
      text: text
    });
    view.dispatch(tr);
    return true;
  }
  return false;
}
var undoInputRule = function undoInputRule(state, dispatch) {
  var plugins = state.plugins;
  for (var i = 0; i < plugins.length; i++) {
    var plugin = plugins[i],
      undoable = void 0;
    if (plugin.spec.isInputRules && (undoable = plugin.getState(state))) {
      if (dispatch) {
        var tr = state.tr,
          toUndo = undoable.transform;
        for (var j = toUndo.steps.length - 1; j >= 0; j--) tr.step(toUndo.steps[j].invert(toUndo.docs[j]));
        if (undoable.text) {
          var marks = tr.doc.resolve(undoable.from).marks();
          tr.replaceWith(undoable.from, undoable.to, state.schema.text(undoable.text, marks));
        } else {
          tr["delete"](undoable.from, undoable.to);
        }
        dispatch(tr);
      }
      return true;
    }
  }
  return false;
};
var emDash = new InputRule(/--$/, "—");
var ellipsis = new InputRule(/\.\.\.$/, "…");
var openDoubleQuote = new InputRule(/(?:^|[\s\{\[\(\<'"\u2018\u201C])(")$/, "“");
var closeDoubleQuote = new InputRule(/"$/, "”");
var openSingleQuote = new InputRule(/(?:^|[\s\{\[\(\<'"\u2018\u201C])(')$/, "‘");
var closeSingleQuote = new InputRule(/'$/, "’");
var smartQuotes = [openDoubleQuote, closeDoubleQuote, openSingleQuote, closeSingleQuote];
function wrappingInputRule(regexp, nodeType) {
  var getAttrs = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;
  var joinPredicate = arguments.length > 3 ? arguments[3] : undefined;
  return new InputRule(regexp, function (state, match, start, end) {
    var attrs = getAttrs instanceof Function ? getAttrs(match) : getAttrs;
    var tr = state.tr["delete"](start, end);
    var $start = tr.doc.resolve(start),
      range = $start.blockRange(),
      wrapping = range && prosemirrorTransform.findWrapping(range, nodeType, attrs);
    if (!wrapping) return null;
    tr.wrap(range, wrapping);
    var before = tr.doc.resolve(start - 1).nodeBefore;
    if (before && before.type == nodeType && prosemirrorTransform.canJoin(tr.doc, start - 1) && (!joinPredicate || joinPredicate(match, before))) tr.join(start - 1);
    return tr;
  });
}
function textblockTypeInputRule(regexp, nodeType) {
  var getAttrs = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;
  return new InputRule(regexp, function (state, match, start, end) {
    var $start = state.doc.resolve(start);
    var attrs = getAttrs instanceof Function ? getAttrs(match) : getAttrs;
    if (!$start.node(-1).canReplaceWith($start.index(-1), $start.indexAfter(-1), nodeType)) return null;
    return state.tr["delete"](start, end).setBlockType(start, start, nodeType, attrs);
  });
}
exports.InputRule = InputRule;
exports.closeDoubleQuote = closeDoubleQuote;
exports.closeSingleQuote = closeSingleQuote;
exports.ellipsis = ellipsis;
exports.emDash = emDash;
exports.inputRules = inputRules;
exports.openDoubleQuote = openDoubleQuote;
exports.openSingleQuote = openSingleQuote;
exports.smartQuotes = smartQuotes;
exports.textblockTypeInputRule = textblockTypeInputRule;
exports.undoInputRule = undoInputRule;
exports.wrappingInputRule = wrappingInputRule;
