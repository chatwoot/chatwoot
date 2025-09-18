'use strict';

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

function _get() { if (typeof Reflect !== "undefined" && Reflect.get) { _get = Reflect.get; } else { _get = function _get(target, property, receiver) { var base = _superPropBase(target, property); if (!base) return; var desc = Object.getOwnPropertyDescriptor(base, property); if (desc.get) { return desc.get.call(arguments.length < 3 ? target : receiver); } return desc.value; }; } return _get.apply(this, arguments); }

function _superPropBase(object, property) { while (!Object.prototype.hasOwnProperty.call(object, property)) { object = _getPrototypeOf(object); if (object === null) break; } return object; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

Object.defineProperty(exports, '__esModule', {
  value: true
});

var prosemirrorModel = require('prosemirror-model');

var prosemirrorTransform = require('prosemirror-transform');

var classesById = Object.create(null);

var Selection = function () {
  function Selection($anchor, $head, ranges) {
    _classCallCheck(this, Selection);

    this.$anchor = $anchor;
    this.$head = $head;
    this.ranges = ranges || [new SelectionRange($anchor.min($head), $anchor.max($head))];
  }

  _createClass(Selection, [{
    key: "anchor",
    get: function get() {
      return this.$anchor.pos;
    }
  }, {
    key: "head",
    get: function get() {
      return this.$head.pos;
    }
  }, {
    key: "from",
    get: function get() {
      return this.$from.pos;
    }
  }, {
    key: "to",
    get: function get() {
      return this.$to.pos;
    }
  }, {
    key: "$from",
    get: function get() {
      return this.ranges[0].$from;
    }
  }, {
    key: "$to",
    get: function get() {
      return this.ranges[0].$to;
    }
  }, {
    key: "empty",
    get: function get() {
      var ranges = this.ranges;

      for (var i = 0; i < ranges.length; i++) {
        if (ranges[i].$from.pos != ranges[i].$to.pos) return false;
      }

      return true;
    }
  }, {
    key: "content",
    value: function content() {
      return this.$from.doc.slice(this.from, this.to, true);
    }
  }, {
    key: "replace",
    value: function replace(tr) {
      var content = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : prosemirrorModel.Slice.empty;
      var lastNode = content.content.lastChild,
          lastParent = null;

      for (var i = 0; i < content.openEnd; i++) {
        lastParent = lastNode;
        lastNode = lastNode.lastChild;
      }

      var mapFrom = tr.steps.length,
          ranges = this.ranges;

      for (var _i = 0; _i < ranges.length; _i++) {
        var _ranges$_i = ranges[_i],
            $from = _ranges$_i.$from,
            $to = _ranges$_i.$to,
            mapping = tr.mapping.slice(mapFrom);
        tr.replaceRange(mapping.map($from.pos), mapping.map($to.pos), _i ? prosemirrorModel.Slice.empty : content);
        if (_i == 0) selectionToInsertionEnd(tr, mapFrom, (lastNode ? lastNode.isInline : lastParent && lastParent.isTextblock) ? -1 : 1);
      }
    }
  }, {
    key: "replaceWith",
    value: function replaceWith(tr, node) {
      var mapFrom = tr.steps.length,
          ranges = this.ranges;

      for (var i = 0; i < ranges.length; i++) {
        var _ranges$i = ranges[i],
            $from = _ranges$i.$from,
            $to = _ranges$i.$to,
            mapping = tr.mapping.slice(mapFrom);
        var from = mapping.map($from.pos),
            to = mapping.map($to.pos);

        if (i) {
          tr.deleteRange(from, to);
        } else {
          tr.replaceRangeWith(from, to, node);
          selectionToInsertionEnd(tr, mapFrom, node.isInline ? -1 : 1);
        }
      }
    }
  }, {
    key: "getBookmark",
    value: function getBookmark() {
      return TextSelection.between(this.$anchor, this.$head).getBookmark();
    }
  }], [{
    key: "findFrom",
    value: function findFrom($pos, dir) {
      var textOnly = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
      var inner = $pos.parent.inlineContent ? new TextSelection($pos) : findSelectionIn($pos.node(0), $pos.parent, $pos.pos, $pos.index(), dir, textOnly);
      if (inner) return inner;

      for (var depth = $pos.depth - 1; depth >= 0; depth--) {
        var found = dir < 0 ? findSelectionIn($pos.node(0), $pos.node(depth), $pos.before(depth + 1), $pos.index(depth), dir, textOnly) : findSelectionIn($pos.node(0), $pos.node(depth), $pos.after(depth + 1), $pos.index(depth) + 1, dir, textOnly);
        if (found) return found;
      }

      return null;
    }
  }, {
    key: "near",
    value: function near($pos) {
      var bias = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;
      return this.findFrom($pos, bias) || this.findFrom($pos, -bias) || new AllSelection($pos.node(0));
    }
  }, {
    key: "atStart",
    value: function atStart(doc) {
      return findSelectionIn(doc, doc, 0, 0, 1) || new AllSelection(doc);
    }
  }, {
    key: "atEnd",
    value: function atEnd(doc) {
      return findSelectionIn(doc, doc, doc.content.size, doc.childCount, -1) || new AllSelection(doc);
    }
  }, {
    key: "fromJSON",
    value: function fromJSON(doc, json) {
      if (!json || !json.type) throw new RangeError("Invalid input for Selection.fromJSON");
      var cls = classesById[json.type];
      if (!cls) throw new RangeError("No selection type ".concat(json.type, " defined"));
      return cls.fromJSON(doc, json);
    }
  }, {
    key: "jsonID",
    value: function jsonID(id, selectionClass) {
      if (id in classesById) throw new RangeError("Duplicate use of selection JSON ID " + id);
      classesById[id] = selectionClass;
      selectionClass.prototype.jsonID = id;
      return selectionClass;
    }
  }]);

  return Selection;
}();

Selection.prototype.visible = true;

var SelectionRange = _createClass(function SelectionRange($from, $to) {
  _classCallCheck(this, SelectionRange);

  this.$from = $from;
  this.$to = $to;
});

var warnedAboutTextSelection = false;

function checkTextSelection($pos) {
  if (!warnedAboutTextSelection && !$pos.parent.inlineContent) {
    warnedAboutTextSelection = true;
    console["warn"]("TextSelection endpoint not pointing into a node with inline content (" + $pos.parent.type.name + ")");
  }
}

var TextSelection = function (_Selection) {
  _inherits(TextSelection, _Selection);

  var _super = _createSuper(TextSelection);

  function TextSelection($anchor) {
    var $head = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : $anchor;

    _classCallCheck(this, TextSelection);

    checkTextSelection($anchor);
    checkTextSelection($head);
    return _super.call(this, $anchor, $head);
  }

  _createClass(TextSelection, [{
    key: "$cursor",
    get: function get() {
      return this.$anchor.pos == this.$head.pos ? this.$head : null;
    }
  }, {
    key: "map",
    value: function map(doc, mapping) {
      var $head = doc.resolve(mapping.map(this.head));
      if (!$head.parent.inlineContent) return Selection.near($head);
      var $anchor = doc.resolve(mapping.map(this.anchor));
      return new TextSelection($anchor.parent.inlineContent ? $anchor : $head, $head);
    }
  }, {
    key: "replace",
    value: function replace(tr) {
      var content = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : prosemirrorModel.Slice.empty;

      _get(_getPrototypeOf(TextSelection.prototype), "replace", this).call(this, tr, content);

      if (content == prosemirrorModel.Slice.empty) {
        var marks = this.$from.marksAcross(this.$to);
        if (marks) tr.ensureMarks(marks);
      }
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return other instanceof TextSelection && other.anchor == this.anchor && other.head == this.head;
    }
  }, {
    key: "getBookmark",
    value: function getBookmark() {
      return new TextBookmark(this.anchor, this.head);
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        type: "text",
        anchor: this.anchor,
        head: this.head
      };
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(doc, json) {
      if (typeof json.anchor != "number" || typeof json.head != "number") throw new RangeError("Invalid input for TextSelection.fromJSON");
      return new TextSelection(doc.resolve(json.anchor), doc.resolve(json.head));
    }
  }, {
    key: "create",
    value: function create(doc, anchor) {
      var head = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : anchor;
      var $anchor = doc.resolve(anchor);
      return new this($anchor, head == anchor ? $anchor : doc.resolve(head));
    }
  }, {
    key: "between",
    value: function between($anchor, $head, bias) {
      var dPos = $anchor.pos - $head.pos;
      if (!bias || dPos) bias = dPos >= 0 ? 1 : -1;

      if (!$head.parent.inlineContent) {
        var found = Selection.findFrom($head, bias, true) || Selection.findFrom($head, -bias, true);
        if (found) $head = found.$head;else return Selection.near($head, bias);
      }

      if (!$anchor.parent.inlineContent) {
        if (dPos == 0) {
          $anchor = $head;
        } else {
          $anchor = (Selection.findFrom($anchor, -bias, true) || Selection.findFrom($anchor, bias, true)).$anchor;
          if ($anchor.pos < $head.pos != dPos < 0) $anchor = $head;
        }
      }

      return new TextSelection($anchor, $head);
    }
  }]);

  return TextSelection;
}(Selection);

Selection.jsonID("text", TextSelection);

var TextBookmark = function () {
  function TextBookmark(anchor, head) {
    _classCallCheck(this, TextBookmark);

    this.anchor = anchor;
    this.head = head;
  }

  _createClass(TextBookmark, [{
    key: "map",
    value: function map(mapping) {
      return new TextBookmark(mapping.map(this.anchor), mapping.map(this.head));
    }
  }, {
    key: "resolve",
    value: function resolve(doc) {
      return TextSelection.between(doc.resolve(this.anchor), doc.resolve(this.head));
    }
  }]);

  return TextBookmark;
}();

var NodeSelection = function (_Selection2) {
  _inherits(NodeSelection, _Selection2);

  var _super2 = _createSuper(NodeSelection);

  function NodeSelection($pos) {
    var _this;

    _classCallCheck(this, NodeSelection);

    var node = $pos.nodeAfter;
    var $end = $pos.node(0).resolve($pos.pos + node.nodeSize);
    _this = _super2.call(this, $pos, $end);
    _this.node = node;
    return _this;
  }

  _createClass(NodeSelection, [{
    key: "map",
    value: function map(doc, mapping) {
      var _mapping$mapResult = mapping.mapResult(this.anchor),
          deleted = _mapping$mapResult.deleted,
          pos = _mapping$mapResult.pos;

      var $pos = doc.resolve(pos);
      if (deleted) return Selection.near($pos);
      return new NodeSelection($pos);
    }
  }, {
    key: "content",
    value: function content() {
      return new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(this.node), 0, 0);
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return other instanceof NodeSelection && other.anchor == this.anchor;
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        type: "node",
        anchor: this.anchor
      };
    }
  }, {
    key: "getBookmark",
    value: function getBookmark() {
      return new NodeBookmark(this.anchor);
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(doc, json) {
      if (typeof json.anchor != "number") throw new RangeError("Invalid input for NodeSelection.fromJSON");
      return new NodeSelection(doc.resolve(json.anchor));
    }
  }, {
    key: "create",
    value: function create(doc, from) {
      return new NodeSelection(doc.resolve(from));
    }
  }, {
    key: "isSelectable",
    value: function isSelectable(node) {
      return !node.isText && node.type.spec.selectable !== false;
    }
  }]);

  return NodeSelection;
}(Selection);

NodeSelection.prototype.visible = false;
Selection.jsonID("node", NodeSelection);

var NodeBookmark = function () {
  function NodeBookmark(anchor) {
    _classCallCheck(this, NodeBookmark);

    this.anchor = anchor;
  }

  _createClass(NodeBookmark, [{
    key: "map",
    value: function map(mapping) {
      var _mapping$mapResult2 = mapping.mapResult(this.anchor),
          deleted = _mapping$mapResult2.deleted,
          pos = _mapping$mapResult2.pos;

      return deleted ? new TextBookmark(pos, pos) : new NodeBookmark(pos);
    }
  }, {
    key: "resolve",
    value: function resolve(doc) {
      var $pos = doc.resolve(this.anchor),
          node = $pos.nodeAfter;
      if (node && NodeSelection.isSelectable(node)) return new NodeSelection($pos);
      return Selection.near($pos);
    }
  }]);

  return NodeBookmark;
}();

var AllSelection = function (_Selection3) {
  _inherits(AllSelection, _Selection3);

  var _super3 = _createSuper(AllSelection);

  function AllSelection(doc) {
    _classCallCheck(this, AllSelection);

    return _super3.call(this, doc.resolve(0), doc.resolve(doc.content.size));
  }

  _createClass(AllSelection, [{
    key: "replace",
    value: function replace(tr) {
      var content = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : prosemirrorModel.Slice.empty;

      if (content == prosemirrorModel.Slice.empty) {
        tr["delete"](0, tr.doc.content.size);
        var sel = Selection.atStart(tr.doc);
        if (!sel.eq(tr.selection)) tr.setSelection(sel);
      } else {
        _get(_getPrototypeOf(AllSelection.prototype), "replace", this).call(this, tr, content);
      }
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        type: "all"
      };
    }
  }, {
    key: "map",
    value: function map(doc) {
      return new AllSelection(doc);
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return other instanceof AllSelection;
    }
  }, {
    key: "getBookmark",
    value: function getBookmark() {
      return AllBookmark;
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(doc) {
      return new AllSelection(doc);
    }
  }]);

  return AllSelection;
}(Selection);

Selection.jsonID("all", AllSelection);
var AllBookmark = {
  map: function map() {
    return this;
  },
  resolve: function resolve(doc) {
    return new AllSelection(doc);
  }
};

function findSelectionIn(doc, node, pos, index, dir) {
  var text = arguments.length > 5 && arguments[5] !== undefined ? arguments[5] : false;
  if (node.inlineContent) return TextSelection.create(doc, pos);

  for (var i = index - (dir > 0 ? 0 : 1); dir > 0 ? i < node.childCount : i >= 0; i += dir) {
    var child = node.child(i);

    if (!child.isAtom) {
      var inner = findSelectionIn(doc, child, pos + dir, dir < 0 ? child.childCount : 0, dir, text);
      if (inner) return inner;
    } else if (!text && NodeSelection.isSelectable(child)) {
      return NodeSelection.create(doc, pos - (dir < 0 ? child.nodeSize : 0));
    }

    pos += child.nodeSize * dir;
  }

  return null;
}

function selectionToInsertionEnd(tr, startLen, bias) {
  var last = tr.steps.length - 1;
  if (last < startLen) return;
  var step = tr.steps[last];
  if (!(step instanceof prosemirrorTransform.ReplaceStep || step instanceof prosemirrorTransform.ReplaceAroundStep)) return;
  var map = tr.mapping.maps[last],
      end;
  map.forEach(function (_from, _to, _newFrom, newTo) {
    if (end == null) end = newTo;
  });
  tr.setSelection(Selection.near(tr.doc.resolve(end), bias));
}

var UPDATED_SEL = 1,
    UPDATED_MARKS = 2,
    UPDATED_SCROLL = 4;

var Transaction = function (_prosemirrorTransform) {
  _inherits(Transaction, _prosemirrorTransform);

  var _super4 = _createSuper(Transaction);

  function Transaction(state) {
    var _this2;

    _classCallCheck(this, Transaction);

    _this2 = _super4.call(this, state.doc);
    _this2.curSelectionFor = 0;
    _this2.updated = 0;
    _this2.meta = Object.create(null);
    _this2.time = Date.now();
    _this2.curSelection = state.selection;
    _this2.storedMarks = state.storedMarks;
    return _this2;
  }

  _createClass(Transaction, [{
    key: "selection",
    get: function get() {
      if (this.curSelectionFor < this.steps.length) {
        this.curSelection = this.curSelection.map(this.doc, this.mapping.slice(this.curSelectionFor));
        this.curSelectionFor = this.steps.length;
      }

      return this.curSelection;
    }
  }, {
    key: "setSelection",
    value: function setSelection(selection) {
      if (selection.$from.doc != this.doc) throw new RangeError("Selection passed to setSelection must point at the current document");
      this.curSelection = selection;
      this.curSelectionFor = this.steps.length;
      this.updated = (this.updated | UPDATED_SEL) & ~UPDATED_MARKS;
      this.storedMarks = null;
      return this;
    }
  }, {
    key: "selectionSet",
    get: function get() {
      return (this.updated & UPDATED_SEL) > 0;
    }
  }, {
    key: "setStoredMarks",
    value: function setStoredMarks(marks) {
      this.storedMarks = marks;
      this.updated |= UPDATED_MARKS;
      return this;
    }
  }, {
    key: "ensureMarks",
    value: function ensureMarks(marks) {
      if (!prosemirrorModel.Mark.sameSet(this.storedMarks || this.selection.$from.marks(), marks)) this.setStoredMarks(marks);
      return this;
    }
  }, {
    key: "addStoredMark",
    value: function addStoredMark(mark) {
      return this.ensureMarks(mark.addToSet(this.storedMarks || this.selection.$head.marks()));
    }
  }, {
    key: "removeStoredMark",
    value: function removeStoredMark(mark) {
      return this.ensureMarks(mark.removeFromSet(this.storedMarks || this.selection.$head.marks()));
    }
  }, {
    key: "storedMarksSet",
    get: function get() {
      return (this.updated & UPDATED_MARKS) > 0;
    }
  }, {
    key: "addStep",
    value: function addStep(step, doc) {
      _get(_getPrototypeOf(Transaction.prototype), "addStep", this).call(this, step, doc);

      this.updated = this.updated & ~UPDATED_MARKS;
      this.storedMarks = null;
    }
  }, {
    key: "setTime",
    value: function setTime(time) {
      this.time = time;
      return this;
    }
  }, {
    key: "replaceSelection",
    value: function replaceSelection(slice) {
      this.selection.replace(this, slice);
      return this;
    }
  }, {
    key: "replaceSelectionWith",
    value: function replaceSelectionWith(node) {
      var inheritMarks = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
      var selection = this.selection;
      if (inheritMarks) node = node.mark(this.storedMarks || (selection.empty ? selection.$from.marks() : selection.$from.marksAcross(selection.$to) || prosemirrorModel.Mark.none));
      selection.replaceWith(this, node);
      return this;
    }
  }, {
    key: "deleteSelection",
    value: function deleteSelection() {
      this.selection.replace(this);
      return this;
    }
  }, {
    key: "insertText",
    value: function insertText(text, from, to) {
      var schema = this.doc.type.schema;

      if (from == null) {
        if (!text) return this.deleteSelection();
        return this.replaceSelectionWith(schema.text(text), true);
      } else {
        if (to == null) to = from;
        to = to == null ? from : to;
        if (!text) return this.deleteRange(from, to);
        var marks = this.storedMarks;

        if (!marks) {
          var $from = this.doc.resolve(from);
          marks = to == from ? $from.marks() : $from.marksAcross(this.doc.resolve(to));
        }

        this.replaceRangeWith(from, to, schema.text(text, marks));
        if (!this.selection.empty) this.setSelection(Selection.near(this.selection.$to));
        return this;
      }
    }
  }, {
    key: "setMeta",
    value: function setMeta(key, value) {
      this.meta[typeof key == "string" ? key : key.key] = value;
      return this;
    }
  }, {
    key: "getMeta",
    value: function getMeta(key) {
      return this.meta[typeof key == "string" ? key : key.key];
    }
  }, {
    key: "isGeneric",
    get: function get() {
      for (var _ in this.meta) {
        return false;
      }

      return true;
    }
  }, {
    key: "scrollIntoView",
    value: function scrollIntoView() {
      this.updated |= UPDATED_SCROLL;
      return this;
    }
  }, {
    key: "scrolledIntoView",
    get: function get() {
      return (this.updated & UPDATED_SCROLL) > 0;
    }
  }]);

  return Transaction;
}(prosemirrorTransform.Transform);

function bind(f, self) {
  return !self || !f ? f : f.bind(self);
}

var FieldDesc = _createClass(function FieldDesc(name, desc, self) {
  _classCallCheck(this, FieldDesc);

  this.name = name;
  this.init = bind(desc.init, self);
  this.apply = bind(desc.apply, self);
});

var baseFields = [new FieldDesc("doc", {
  init: function init(config) {
    return config.doc || config.schema.topNodeType.createAndFill();
  },
  apply: function apply(tr) {
    return tr.doc;
  }
}), new FieldDesc("selection", {
  init: function init(config, instance) {
    return config.selection || Selection.atStart(instance.doc);
  },
  apply: function apply(tr) {
    return tr.selection;
  }
}), new FieldDesc("storedMarks", {
  init: function init(config) {
    return config.storedMarks || null;
  },
  apply: function apply(tr, _marks, _old, state) {
    return state.selection.$cursor ? tr.storedMarks : null;
  }
}), new FieldDesc("scrollToSelection", {
  init: function init() {
    return 0;
  },
  apply: function apply(tr, prev) {
    return tr.scrolledIntoView ? prev + 1 : prev;
  }
})];

var Configuration = _createClass(function Configuration(schema, plugins) {
  var _this3 = this;

  _classCallCheck(this, Configuration);

  this.schema = schema;
  this.plugins = [];
  this.pluginsByKey = Object.create(null);
  this.fields = baseFields.slice();
  if (plugins) plugins.forEach(function (plugin) {
    if (_this3.pluginsByKey[plugin.key]) throw new RangeError("Adding different instances of a keyed plugin (" + plugin.key + ")");

    _this3.plugins.push(plugin);

    _this3.pluginsByKey[plugin.key] = plugin;
    if (plugin.spec.state) _this3.fields.push(new FieldDesc(plugin.key, plugin.spec.state, plugin));
  });
});

var EditorState = function () {
  function EditorState(config) {
    _classCallCheck(this, EditorState);

    this.config = config;
  }

  _createClass(EditorState, [{
    key: "schema",
    get: function get() {
      return this.config.schema;
    }
  }, {
    key: "plugins",
    get: function get() {
      return this.config.plugins;
    }
  }, {
    key: "apply",
    value: function apply(tr) {
      return this.applyTransaction(tr).state;
    }
  }, {
    key: "filterTransaction",
    value: function filterTransaction(tr) {
      var ignore = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : -1;

      for (var i = 0; i < this.config.plugins.length; i++) {
        if (i != ignore) {
          var plugin = this.config.plugins[i];
          if (plugin.spec.filterTransaction && !plugin.spec.filterTransaction.call(plugin, tr, this)) return false;
        }
      }

      return true;
    }
  }, {
    key: "applyTransaction",
    value: function applyTransaction(rootTr) {
      if (!this.filterTransaction(rootTr)) return {
        state: this,
        transactions: []
      };
      var trs = [rootTr],
          newState = this.applyInner(rootTr),
          seen = null;

      for (;;) {
        var haveNew = false;

        for (var i = 0; i < this.config.plugins.length; i++) {
          var plugin = this.config.plugins[i];

          if (plugin.spec.appendTransaction) {
            var n = seen ? seen[i].n : 0,
                oldState = seen ? seen[i].state : this;
            var tr = n < trs.length && plugin.spec.appendTransaction.call(plugin, n ? trs.slice(n) : trs, oldState, newState);

            if (tr && newState.filterTransaction(tr, i)) {
              tr.setMeta("appendedTransaction", rootTr);

              if (!seen) {
                seen = [];

                for (var j = 0; j < this.config.plugins.length; j++) {
                  seen.push(j < i ? {
                    state: newState,
                    n: trs.length
                  } : {
                    state: this,
                    n: 0
                  });
                }
              }

              trs.push(tr);
              newState = newState.applyInner(tr);
              haveNew = true;
            }

            if (seen) seen[i] = {
              state: newState,
              n: trs.length
            };
          }
        }

        if (!haveNew) return {
          state: newState,
          transactions: trs
        };
      }
    }
  }, {
    key: "applyInner",
    value: function applyInner(tr) {
      if (!tr.before.eq(this.doc)) throw new RangeError("Applying a mismatched transaction");
      var newInstance = new EditorState(this.config),
          fields = this.config.fields;

      for (var i = 0; i < fields.length; i++) {
        var field = fields[i];
        newInstance[field.name] = field.apply(tr, this[field.name], this, newInstance);
      }

      return newInstance;
    }
  }, {
    key: "tr",
    get: function get() {
      return new Transaction(this);
    }
  }, {
    key: "reconfigure",
    value: function reconfigure(config) {
      var $config = new Configuration(this.schema, config.plugins);
      var fields = $config.fields,
          instance = new EditorState($config);

      for (var i = 0; i < fields.length; i++) {
        var name = fields[i].name;
        instance[name] = this.hasOwnProperty(name) ? this[name] : fields[i].init(config, instance);
      }

      return instance;
    }
  }, {
    key: "toJSON",
    value: function toJSON(pluginFields) {
      var result = {
        doc: this.doc.toJSON(),
        selection: this.selection.toJSON()
      };
      if (this.storedMarks) result.storedMarks = this.storedMarks.map(function (m) {
        return m.toJSON();
      });
      if (pluginFields && _typeof(pluginFields) == 'object') for (var prop in pluginFields) {
        if (prop == "doc" || prop == "selection") throw new RangeError("The JSON fields `doc` and `selection` are reserved");
        var plugin = pluginFields[prop],
            state = plugin.spec.state;
        if (state && state.toJSON) result[prop] = state.toJSON.call(plugin, this[plugin.key]);
      }
      return result;
    }
  }], [{
    key: "create",
    value: function create(config) {
      var $config = new Configuration(config.doc ? config.doc.type.schema : config.schema, config.plugins);
      var instance = new EditorState($config);

      for (var i = 0; i < $config.fields.length; i++) {
        instance[$config.fields[i].name] = $config.fields[i].init(config, instance);
      }

      return instance;
    }
  }, {
    key: "fromJSON",
    value: function fromJSON(config, json, pluginFields) {
      if (!json) throw new RangeError("Invalid input for EditorState.fromJSON");
      if (!config.schema) throw new RangeError("Required config field 'schema' missing");
      var $config = new Configuration(config.schema, config.plugins);
      var instance = new EditorState($config);
      $config.fields.forEach(function (field) {
        if (field.name == "doc") {
          instance.doc = prosemirrorModel.Node.fromJSON(config.schema, json.doc);
        } else if (field.name == "selection") {
          instance.selection = Selection.fromJSON(instance.doc, json.selection);
        } else if (field.name == "storedMarks") {
          if (json.storedMarks) instance.storedMarks = json.storedMarks.map(config.schema.markFromJSON);
        } else {
          if (pluginFields) for (var prop in pluginFields) {
            var plugin = pluginFields[prop],
                state = plugin.spec.state;

            if (plugin.key == field.name && state && state.fromJSON && Object.prototype.hasOwnProperty.call(json, prop)) {
              instance[field.name] = state.fromJSON.call(plugin, config, json[prop], instance);
              return;
            }
          }
          instance[field.name] = field.init(config, instance);
        }
      });
      return instance;
    }
  }]);

  return EditorState;
}();

function bindProps(obj, self, target) {
  for (var prop in obj) {
    var val = obj[prop];
    if (val instanceof Function) val = val.bind(self);else if (prop == "handleDOMEvents") val = bindProps(val, self, {});
    target[prop] = val;
  }

  return target;
}

var Plugin = function () {
  function Plugin(spec) {
    _classCallCheck(this, Plugin);

    this.spec = spec;
    this.props = {};
    if (spec.props) bindProps(spec.props, this, this.props);
    this.key = spec.key ? spec.key.key : createKey("plugin");
  }

  _createClass(Plugin, [{
    key: "getState",
    value: function getState(state) {
      return state[this.key];
    }
  }]);

  return Plugin;
}();

var keys = Object.create(null);

function createKey(name) {
  if (name in keys) return name + "$" + ++keys[name];
  keys[name] = 0;
  return name + "$";
}

var PluginKey = function () {
  function PluginKey() {
    var name = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : "key";

    _classCallCheck(this, PluginKey);

    this.key = createKey(name);
  }

  _createClass(PluginKey, [{
    key: "get",
    value: function get(state) {
      return state.config.pluginsByKey[this.key];
    }
  }, {
    key: "getState",
    value: function getState(state) {
      return state[this.key];
    }
  }]);

  return PluginKey;
}();

exports.AllSelection = AllSelection;
exports.EditorState = EditorState;
exports.NodeSelection = NodeSelection;
exports.Plugin = Plugin;
exports.PluginKey = PluginKey;
exports.Selection = Selection;
exports.SelectionRange = SelectionRange;
exports.TextSelection = TextSelection;
exports.Transaction = Transaction;
