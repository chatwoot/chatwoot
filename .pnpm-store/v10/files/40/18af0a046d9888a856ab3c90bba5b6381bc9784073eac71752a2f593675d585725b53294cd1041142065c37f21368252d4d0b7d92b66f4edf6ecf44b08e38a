'use strict';

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

Object.defineProperty(exports, '__esModule', {
  value: true
});

var prosemirrorKeymap = require('prosemirror-keymap');

var prosemirrorState = require('prosemirror-state');

var prosemirrorModel = require('prosemirror-model');

var prosemirrorView = require('prosemirror-view');

var GapCursor = function (_prosemirrorState$Sel) {
  _inherits(GapCursor, _prosemirrorState$Sel);

  var _super = _createSuper(GapCursor);

  function GapCursor($pos) {
    _classCallCheck(this, GapCursor);

    return _super.call(this, $pos, $pos);
  }

  _createClass(GapCursor, [{
    key: "map",
    value: function map(doc, mapping) {
      var $pos = doc.resolve(mapping.map(this.head));
      return GapCursor.valid($pos) ? new GapCursor($pos) : prosemirrorState.Selection.near($pos);
    }
  }, {
    key: "content",
    value: function content() {
      return prosemirrorModel.Slice.empty;
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return other instanceof GapCursor && other.head == this.head;
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        type: "gapcursor",
        pos: this.head
      };
    }
  }, {
    key: "getBookmark",
    value: function getBookmark() {
      return new GapBookmark(this.anchor);
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(doc, json) {
      if (typeof json.pos != "number") throw new RangeError("Invalid input for GapCursor.fromJSON");
      return new GapCursor(doc.resolve(json.pos));
    }
  }, {
    key: "valid",
    value: function valid($pos) {
      var parent = $pos.parent;
      if (parent.isTextblock || !closedBefore($pos) || !closedAfter($pos)) return false;
      var override = parent.type.spec.allowGapCursor;
      if (override != null) return override;
      var deflt = parent.contentMatchAt($pos.index()).defaultType;
      return deflt && deflt.isTextblock;
    }
  }, {
    key: "findGapCursorFrom",
    value: function findGapCursorFrom($pos, dir) {
      var mustMove = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

      search: for (;;) {
        if (!mustMove && GapCursor.valid($pos)) return $pos;
        var pos = $pos.pos,
            next = null;

        for (var d = $pos.depth;; d--) {
          var parent = $pos.node(d);

          if (dir > 0 ? $pos.indexAfter(d) < parent.childCount : $pos.index(d) > 0) {
            next = parent.child(dir > 0 ? $pos.indexAfter(d) : $pos.index(d) - 1);
            break;
          } else if (d == 0) {
            return null;
          }

          pos += dir;
          var $cur = $pos.doc.resolve(pos);
          if (GapCursor.valid($cur)) return $cur;
        }

        for (;;) {
          var inside = dir > 0 ? next.firstChild : next.lastChild;

          if (!inside) {
            if (next.isAtom && !next.isText && !prosemirrorState.NodeSelection.isSelectable(next)) {
              $pos = $pos.doc.resolve(pos + next.nodeSize * dir);
              mustMove = false;
              continue search;
            }

            break;
          }

          next = inside;
          pos += dir;

          var _$cur = $pos.doc.resolve(pos);

          if (GapCursor.valid(_$cur)) return _$cur;
        }

        return null;
      }
    }
  }]);

  return GapCursor;
}(prosemirrorState.Selection);

GapCursor.prototype.visible = false;
GapCursor.findFrom = GapCursor.findGapCursorFrom;
prosemirrorState.Selection.jsonID("gapcursor", GapCursor);

var GapBookmark = function () {
  function GapBookmark(pos) {
    _classCallCheck(this, GapBookmark);

    this.pos = pos;
  }

  _createClass(GapBookmark, [{
    key: "map",
    value: function map(mapping) {
      return new GapBookmark(mapping.map(this.pos));
    }
  }, {
    key: "resolve",
    value: function resolve(doc) {
      var $pos = doc.resolve(this.pos);
      return GapCursor.valid($pos) ? new GapCursor($pos) : prosemirrorState.Selection.near($pos);
    }
  }]);

  return GapBookmark;
}();

function closedBefore($pos) {
  for (var d = $pos.depth; d >= 0; d--) {
    var index = $pos.index(d),
        parent = $pos.node(d);

    if (index == 0) {
      if (parent.type.spec.isolating) return true;
      continue;
    }

    for (var before = parent.child(index - 1);; before = before.lastChild) {
      if (before.childCount == 0 && !before.inlineContent || before.isAtom || before.type.spec.isolating) return true;
      if (before.inlineContent) return false;
    }
  }

  return true;
}

function closedAfter($pos) {
  for (var d = $pos.depth; d >= 0; d--) {
    var index = $pos.indexAfter(d),
        parent = $pos.node(d);

    if (index == parent.childCount) {
      if (parent.type.spec.isolating) return true;
      continue;
    }

    for (var after = parent.child(index);; after = after.firstChild) {
      if (after.childCount == 0 && !after.inlineContent || after.isAtom || after.type.spec.isolating) return true;
      if (after.inlineContent) return false;
    }
  }

  return true;
}

function gapCursor() {
  return new prosemirrorState.Plugin({
    props: {
      decorations: drawGapCursor,
      createSelectionBetween: function createSelectionBetween(_view, $anchor, $head) {
        return $anchor.pos == $head.pos && GapCursor.valid($head) ? new GapCursor($head) : null;
      },
      handleClick: handleClick,
      handleKeyDown: handleKeyDown,
      handleDOMEvents: {
        beforeinput: beforeinput
      }
    }
  });
}

var handleKeyDown = prosemirrorKeymap.keydownHandler({
  "ArrowLeft": arrow("horiz", -1),
  "ArrowRight": arrow("horiz", 1),
  "ArrowUp": arrow("vert", -1),
  "ArrowDown": arrow("vert", 1)
});

function arrow(axis, dir) {
  var dirStr = axis == "vert" ? dir > 0 ? "down" : "up" : dir > 0 ? "right" : "left";
  return function (state, dispatch, view) {
    var sel = state.selection;
    var $start = dir > 0 ? sel.$to : sel.$from,
        mustMove = sel.empty;

    if (sel instanceof prosemirrorState.TextSelection) {
      if (!view.endOfTextblock(dirStr) || $start.depth == 0) return false;
      mustMove = false;
      $start = state.doc.resolve(dir > 0 ? $start.after() : $start.before());
    }

    var $found = GapCursor.findGapCursorFrom($start, dir, mustMove);
    if (!$found) return false;
    if (dispatch) dispatch(state.tr.setSelection(new GapCursor($found)));
    return true;
  };
}

function handleClick(view, pos, event) {
  if (!view || !view.editable) return false;
  var $pos = view.state.doc.resolve(pos);
  if (!GapCursor.valid($pos)) return false;
  var clickPos = view.posAtCoords({
    left: event.clientX,
    top: event.clientY
  });
  if (clickPos && clickPos.inside > -1 && prosemirrorState.NodeSelection.isSelectable(view.state.doc.nodeAt(clickPos.inside))) return false;
  view.dispatch(view.state.tr.setSelection(new GapCursor($pos)));
  return true;
}

function beforeinput(view, event) {
  if (event.inputType != "insertCompositionText" || !(view.state.selection instanceof GapCursor)) return false;
  var $from = view.state.selection.$from;
  var insert = $from.parent.contentMatchAt($from.index()).findWrapping(view.state.schema.nodes.text);
  if (!insert) return false;
  var frag = prosemirrorModel.Fragment.empty;

  for (var i = insert.length - 1; i >= 0; i--) {
    frag = prosemirrorModel.Fragment.from(insert[i].createAndFill(null, frag));
  }

  var tr = view.state.tr.replace($from.pos, $from.pos, new prosemirrorModel.Slice(frag, 0, 0));
  tr.setSelection(prosemirrorState.TextSelection.near(tr.doc.resolve($from.pos + 1)));
  view.dispatch(tr);
  return false;
}

function drawGapCursor(state) {
  if (!(state.selection instanceof GapCursor)) return null;
  var node = document.createElement("div");
  node.className = "ProseMirror-gapcursor";
  return prosemirrorView.DecorationSet.create(state.doc, [prosemirrorView.Decoration.widget(state.selection.head, node, {
    key: "gapcursor"
  })]);
}

exports.GapCursor = GapCursor;
exports.gapCursor = gapCursor;
