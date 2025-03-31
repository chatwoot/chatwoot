'use strict';

function _createForOfIteratorHelper(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (!it) { if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e) { throw _e; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var normalCompletion = true, didErr = false, err; return { s: function s() { it = it.call(o); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e2) { didErr = true; err = _e2; }, f: function f() { try { if (!normalCompletion && it["return"] != null) it["return"](); } finally { if (didErr) throw err; } } }; }
function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }
function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) arr2[i] = arr[i]; return arr2; }
function _get() { if (typeof Reflect !== "undefined" && Reflect.get) { _get = Reflect.get.bind(); } else { _get = function _get(target, property, receiver) { var base = _superPropBase(target, property); if (!base) return; var desc = Object.getOwnPropertyDescriptor(base, property); if (desc.get) { return desc.get.call(arguments.length < 3 ? target : receiver); } return desc.value; }; } return _get.apply(this, arguments); }
function _superPropBase(object, property) { while (!Object.prototype.hasOwnProperty.call(object, property)) { object = _getPrototypeOf(object); if (object === null) break; } return object; }
function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }
function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }
function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }
function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }
function _wrapNativeSuper(Class) { var _cache = typeof Map === "function" ? new Map() : undefined; _wrapNativeSuper = function _wrapNativeSuper(Class) { if (Class === null || !_isNativeFunction(Class)) return Class; if (typeof Class !== "function") { throw new TypeError("Super expression must either be null or a function"); } if (typeof _cache !== "undefined") { if (_cache.has(Class)) return _cache.get(Class); _cache.set(Class, Wrapper); } function Wrapper() { return _construct(Class, arguments, _getPrototypeOf(this).constructor); } Wrapper.prototype = Object.create(Class.prototype, { constructor: { value: Wrapper, enumerable: false, writable: true, configurable: true } }); return _setPrototypeOf(Wrapper, Class); }; return _wrapNativeSuper(Class); }
function _construct(Parent, args, Class) { if (_isNativeReflectConstruct()) { _construct = Reflect.construct.bind(); } else { _construct = function _construct(Parent, args, Class) { var a = [null]; a.push.apply(a, args); var Constructor = Function.bind.apply(Parent, a); var instance = new Constructor(); if (Class) _setPrototypeOf(instance, Class.prototype); return instance; }; } return _construct.apply(null, arguments); }
function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }
function _isNativeFunction(fn) { try { return Function.toString.call(fn).indexOf("[native code]") !== -1; } catch (e) { return typeof fn === "function"; } }
function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }
function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }
function _typeof(o) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (o) { return typeof o; } : function (o) { return o && "function" == typeof Symbol && o.constructor === Symbol && o !== Symbol.prototype ? "symbol" : typeof o; }, _typeof(o); }
function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, _toPropertyKey(descriptor.key), descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
function _toPropertyKey(arg) { var key = _toPrimitive(arg, "string"); return _typeof(key) === "symbol" ? key : String(key); }
function _toPrimitive(input, hint) { if (_typeof(input) !== "object" || input === null) return input; var prim = input[Symbol.toPrimitive]; if (prim !== undefined) { var res = prim.call(input, hint || "default"); if (_typeof(res) !== "object") return res; throw new TypeError("@@toPrimitive must return a primitive value."); } return (hint === "string" ? String : Number)(input); }
var OrderedMap = require('orderedmap');
function _findDiffStart(a, b, pos) {
  for (var i = 0;; i++) {
    if (i == a.childCount || i == b.childCount) return a.childCount == b.childCount ? null : pos;
    var childA = a.child(i),
      childB = b.child(i);
    if (childA == childB) {
      pos += childA.nodeSize;
      continue;
    }
    if (!childA.sameMarkup(childB)) return pos;
    if (childA.isText && childA.text != childB.text) {
      for (var j = 0; childA.text[j] == childB.text[j]; j++) pos++;
      return pos;
    }
    if (childA.content.size || childB.content.size) {
      var inner = _findDiffStart(childA.content, childB.content, pos + 1);
      if (inner != null) return inner;
    }
    pos += childA.nodeSize;
  }
}
function _findDiffEnd(a, b, posA, posB) {
  for (var iA = a.childCount, iB = b.childCount;;) {
    if (iA == 0 || iB == 0) return iA == iB ? null : {
      a: posA,
      b: posB
    };
    var childA = a.child(--iA),
      childB = b.child(--iB),
      size = childA.nodeSize;
    if (childA == childB) {
      posA -= size;
      posB -= size;
      continue;
    }
    if (!childA.sameMarkup(childB)) return {
      a: posA,
      b: posB
    };
    if (childA.isText && childA.text != childB.text) {
      var same = 0,
        minSize = Math.min(childA.text.length, childB.text.length);
      while (same < minSize && childA.text[childA.text.length - same - 1] == childB.text[childB.text.length - same - 1]) {
        same++;
        posA--;
        posB--;
      }
      return {
        a: posA,
        b: posB
      };
    }
    if (childA.content.size || childB.content.size) {
      var inner = _findDiffEnd(childA.content, childB.content, posA - 1, posB - 1);
      if (inner) return inner;
    }
    posA -= size;
    posB -= size;
  }
}
var Fragment = function () {
  function Fragment(content, size) {
    _classCallCheck(this, Fragment);
    this.content = content;
    this.size = size || 0;
    if (size == null) for (var i = 0; i < content.length; i++) this.size += content[i].nodeSize;
  }
  _createClass(Fragment, [{
    key: "nodesBetween",
    value: function nodesBetween(from, to, f) {
      var nodeStart = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 0;
      var parent = arguments.length > 4 ? arguments[4] : undefined;
      for (var i = 0, pos = 0; pos < to; i++) {
        var child = this.content[i],
          end = pos + child.nodeSize;
        if (end > from && f(child, nodeStart + pos, parent || null, i) !== false && child.content.size) {
          var start = pos + 1;
          child.nodesBetween(Math.max(0, from - start), Math.min(child.content.size, to - start), f, nodeStart + start);
        }
        pos = end;
      }
    }
  }, {
    key: "descendants",
    value: function descendants(f) {
      this.nodesBetween(0, this.size, f);
    }
  }, {
    key: "textBetween",
    value: function textBetween(from, to, blockSeparator, leafText) {
      var text = "",
        first = true;
      this.nodesBetween(from, to, function (node, pos) {
        var nodeText = node.isText ? node.text.slice(Math.max(from, pos) - pos, to - pos) : !node.isLeaf ? "" : leafText ? typeof leafText === "function" ? leafText(node) : leafText : node.type.spec.leafText ? node.type.spec.leafText(node) : "";
        if (node.isBlock && (node.isLeaf && nodeText || node.isTextblock) && blockSeparator) {
          if (first) first = false;else text += blockSeparator;
        }
        text += nodeText;
      }, 0);
      return text;
    }
  }, {
    key: "append",
    value: function append(other) {
      if (!other.size) return this;
      if (!this.size) return other;
      var last = this.lastChild,
        first = other.firstChild,
        content = this.content.slice(),
        i = 0;
      if (last.isText && last.sameMarkup(first)) {
        content[content.length - 1] = last.withText(last.text + first.text);
        i = 1;
      }
      for (; i < other.content.length; i++) content.push(other.content[i]);
      return new Fragment(content, this.size + other.size);
    }
  }, {
    key: "cut",
    value: function cut(from) {
      var to = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : this.size;
      if (from == 0 && to == this.size) return this;
      var result = [],
        size = 0;
      if (to > from) for (var i = 0, pos = 0; pos < to; i++) {
        var child = this.content[i],
          end = pos + child.nodeSize;
        if (end > from) {
          if (pos < from || end > to) {
            if (child.isText) child = child.cut(Math.max(0, from - pos), Math.min(child.text.length, to - pos));else child = child.cut(Math.max(0, from - pos - 1), Math.min(child.content.size, to - pos - 1));
          }
          result.push(child);
          size += child.nodeSize;
        }
        pos = end;
      }
      return new Fragment(result, size);
    }
  }, {
    key: "cutByIndex",
    value: function cutByIndex(from, to) {
      if (from == to) return Fragment.empty;
      if (from == 0 && to == this.content.length) return this;
      return new Fragment(this.content.slice(from, to));
    }
  }, {
    key: "replaceChild",
    value: function replaceChild(index, node) {
      var current = this.content[index];
      if (current == node) return this;
      var copy = this.content.slice();
      var size = this.size + node.nodeSize - current.nodeSize;
      copy[index] = node;
      return new Fragment(copy, size);
    }
  }, {
    key: "addToStart",
    value: function addToStart(node) {
      return new Fragment([node].concat(this.content), this.size + node.nodeSize);
    }
  }, {
    key: "addToEnd",
    value: function addToEnd(node) {
      return new Fragment(this.content.concat(node), this.size + node.nodeSize);
    }
  }, {
    key: "eq",
    value: function eq(other) {
      if (this.content.length != other.content.length) return false;
      for (var i = 0; i < this.content.length; i++) if (!this.content[i].eq(other.content[i])) return false;
      return true;
    }
  }, {
    key: "firstChild",
    get: function get() {
      return this.content.length ? this.content[0] : null;
    }
  }, {
    key: "lastChild",
    get: function get() {
      return this.content.length ? this.content[this.content.length - 1] : null;
    }
  }, {
    key: "childCount",
    get: function get() {
      return this.content.length;
    }
  }, {
    key: "child",
    value: function child(index) {
      var found = this.content[index];
      if (!found) throw new RangeError("Index " + index + " out of range for " + this);
      return found;
    }
  }, {
    key: "maybeChild",
    value: function maybeChild(index) {
      return this.content[index] || null;
    }
  }, {
    key: "forEach",
    value: function forEach(f) {
      for (var i = 0, p = 0; i < this.content.length; i++) {
        var child = this.content[i];
        f(child, p, i);
        p += child.nodeSize;
      }
    }
  }, {
    key: "findDiffStart",
    value: function findDiffStart(other) {
      var pos = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
      return _findDiffStart(this, other, pos);
    }
  }, {
    key: "findDiffEnd",
    value: function findDiffEnd(other) {
      var pos = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : this.size;
      var otherPos = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : other.size;
      return _findDiffEnd(this, other, pos, otherPos);
    }
  }, {
    key: "findIndex",
    value: function findIndex(pos) {
      var round = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : -1;
      if (pos == 0) return retIndex(0, pos);
      if (pos == this.size) return retIndex(this.content.length, pos);
      if (pos > this.size || pos < 0) throw new RangeError("Position ".concat(pos, " outside of fragment (").concat(this, ")"));
      for (var i = 0, curPos = 0;; i++) {
        var cur = this.child(i),
          end = curPos + cur.nodeSize;
        if (end >= pos) {
          if (end == pos || round > 0) return retIndex(i + 1, end);
          return retIndex(i, curPos);
        }
        curPos = end;
      }
    }
  }, {
    key: "toString",
    value: function toString() {
      return "<" + this.toStringInner() + ">";
    }
  }, {
    key: "toStringInner",
    value: function toStringInner() {
      return this.content.join(", ");
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return this.content.length ? this.content.map(function (n) {
        return n.toJSON();
      }) : null;
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, value) {
      if (!value) return Fragment.empty;
      if (!Array.isArray(value)) throw new RangeError("Invalid input for Fragment.fromJSON");
      return new Fragment(value.map(schema.nodeFromJSON));
    }
  }, {
    key: "fromArray",
    value: function fromArray(array) {
      if (!array.length) return Fragment.empty;
      var joined,
        size = 0;
      for (var i = 0; i < array.length; i++) {
        var node = array[i];
        size += node.nodeSize;
        if (i && node.isText && array[i - 1].sameMarkup(node)) {
          if (!joined) joined = array.slice(0, i);
          joined[joined.length - 1] = node.withText(joined[joined.length - 1].text + node.text);
        } else if (joined) {
          joined.push(node);
        }
      }
      return new Fragment(joined || array, size);
    }
  }, {
    key: "from",
    value: function from(nodes) {
      if (!nodes) return Fragment.empty;
      if (nodes instanceof Fragment) return nodes;
      if (Array.isArray(nodes)) return this.fromArray(nodes);
      if (nodes.attrs) return new Fragment([nodes], nodes.nodeSize);
      throw new RangeError("Can not convert " + nodes + " to a Fragment" + (nodes.nodesBetween ? " (looks like multiple versions of prosemirror-model were loaded)" : ""));
    }
  }]);
  return Fragment;
}();
Fragment.empty = new Fragment([], 0);
var found = {
  index: 0,
  offset: 0
};
function retIndex(index, offset) {
  found.index = index;
  found.offset = offset;
  return found;
}
function compareDeep(a, b) {
  if (a === b) return true;
  if (!(a && _typeof(a) == "object") || !(b && _typeof(b) == "object")) return false;
  var array = Array.isArray(a);
  if (Array.isArray(b) != array) return false;
  if (array) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) if (!compareDeep(a[i], b[i])) return false;
  } else {
    for (var p in a) if (!(p in b) || !compareDeep(a[p], b[p])) return false;
    for (var _p in b) if (!(_p in a)) return false;
  }
  return true;
}
var Mark = function () {
  function Mark(type, attrs) {
    _classCallCheck(this, Mark);
    this.type = type;
    this.attrs = attrs;
  }
  _createClass(Mark, [{
    key: "addToSet",
    value: function addToSet(set) {
      var copy,
        placed = false;
      for (var i = 0; i < set.length; i++) {
        var other = set[i];
        if (this.eq(other)) return set;
        if (this.type.excludes(other.type)) {
          if (!copy) copy = set.slice(0, i);
        } else if (other.type.excludes(this.type)) {
          return set;
        } else {
          if (!placed && other.type.rank > this.type.rank) {
            if (!copy) copy = set.slice(0, i);
            copy.push(this);
            placed = true;
          }
          if (copy) copy.push(other);
        }
      }
      if (!copy) copy = set.slice();
      if (!placed) copy.push(this);
      return copy;
    }
  }, {
    key: "removeFromSet",
    value: function removeFromSet(set) {
      for (var i = 0; i < set.length; i++) if (this.eq(set[i])) return set.slice(0, i).concat(set.slice(i + 1));
      return set;
    }
  }, {
    key: "isInSet",
    value: function isInSet(set) {
      for (var i = 0; i < set.length; i++) if (this.eq(set[i])) return true;
      return false;
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return this == other || this.type == other.type && compareDeep(this.attrs, other.attrs);
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      var obj = {
        type: this.type.name
      };
      for (var _ in this.attrs) {
        obj.attrs = this.attrs;
        break;
      }
      return obj;
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (!json) throw new RangeError("Invalid input for Mark.fromJSON");
      var type = schema.marks[json.type];
      if (!type) throw new RangeError("There is no mark type ".concat(json.type, " in this schema"));
      var mark = type.create(json.attrs);
      type.checkAttrs(mark.attrs);
      return mark;
    }
  }, {
    key: "sameSet",
    value: function sameSet(a, b) {
      if (a == b) return true;
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) if (!a[i].eq(b[i])) return false;
      return true;
    }
  }, {
    key: "setFrom",
    value: function setFrom(marks) {
      if (!marks || Array.isArray(marks) && marks.length == 0) return Mark.none;
      if (marks instanceof Mark) return [marks];
      var copy = marks.slice();
      copy.sort(function (a, b) {
        return a.type.rank - b.type.rank;
      });
      return copy;
    }
  }]);
  return Mark;
}();
Mark.none = [];
var ReplaceError = function (_Error) {
  _inherits(ReplaceError, _Error);
  var _super = _createSuper(ReplaceError);
  function ReplaceError() {
    _classCallCheck(this, ReplaceError);
    return _super.apply(this, arguments);
  }
  return _createClass(ReplaceError);
}(_wrapNativeSuper(Error));
var Slice = function () {
  function Slice(content, openStart, openEnd) {
    _classCallCheck(this, Slice);
    this.content = content;
    this.openStart = openStart;
    this.openEnd = openEnd;
  }
  _createClass(Slice, [{
    key: "size",
    get: function get() {
      return this.content.size - this.openStart - this.openEnd;
    }
  }, {
    key: "insertAt",
    value: function insertAt(pos, fragment) {
      var content = insertInto(this.content, pos + this.openStart, fragment);
      return content && new Slice(content, this.openStart, this.openEnd);
    }
  }, {
    key: "removeBetween",
    value: function removeBetween(from, to) {
      return new Slice(removeRange(this.content, from + this.openStart, to + this.openStart), this.openStart, this.openEnd);
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return this.content.eq(other.content) && this.openStart == other.openStart && this.openEnd == other.openEnd;
    }
  }, {
    key: "toString",
    value: function toString() {
      return this.content + "(" + this.openStart + "," + this.openEnd + ")";
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      if (!this.content.size) return null;
      var json = {
        content: this.content.toJSON()
      };
      if (this.openStart > 0) json.openStart = this.openStart;
      if (this.openEnd > 0) json.openEnd = this.openEnd;
      return json;
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (!json) return Slice.empty;
      var openStart = json.openStart || 0,
        openEnd = json.openEnd || 0;
      if (typeof openStart != "number" || typeof openEnd != "number") throw new RangeError("Invalid input for Slice.fromJSON");
      return new Slice(Fragment.fromJSON(schema, json.content), openStart, openEnd);
    }
  }, {
    key: "maxOpen",
    value: function maxOpen(fragment) {
      var openIsolating = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
      var openStart = 0,
        openEnd = 0;
      for (var n = fragment.firstChild; n && !n.isLeaf && (openIsolating || !n.type.spec.isolating); n = n.firstChild) openStart++;
      for (var _n = fragment.lastChild; _n && !_n.isLeaf && (openIsolating || !_n.type.spec.isolating); _n = _n.lastChild) openEnd++;
      return new Slice(fragment, openStart, openEnd);
    }
  }]);
  return Slice;
}();
Slice.empty = new Slice(Fragment.empty, 0, 0);
function removeRange(content, from, to) {
  var _content$findIndex = content.findIndex(from),
    index = _content$findIndex.index,
    offset = _content$findIndex.offset,
    child = content.maybeChild(index);
  var _content$findIndex2 = content.findIndex(to),
    indexTo = _content$findIndex2.index,
    offsetTo = _content$findIndex2.offset;
  if (offset == from || child.isText) {
    if (offsetTo != to && !content.child(indexTo).isText) throw new RangeError("Removing non-flat range");
    return content.cut(0, from).append(content.cut(to));
  }
  if (index != indexTo) throw new RangeError("Removing non-flat range");
  return content.replaceChild(index, child.copy(removeRange(child.content, from - offset - 1, to - offset - 1)));
}
function insertInto(content, dist, insert, parent) {
  var _content$findIndex3 = content.findIndex(dist),
    index = _content$findIndex3.index,
    offset = _content$findIndex3.offset,
    child = content.maybeChild(index);
  if (offset == dist || child.isText) {
    if (parent && !parent.canReplace(index, index, insert)) return null;
    return content.cut(0, dist).append(insert).append(content.cut(dist));
  }
  var inner = insertInto(child.content, dist - offset - 1, insert);
  return inner && content.replaceChild(index, child.copy(inner));
}
function _replace($from, $to, slice) {
  if (slice.openStart > $from.depth) throw new ReplaceError("Inserted content deeper than insertion position");
  if ($from.depth - slice.openStart != $to.depth - slice.openEnd) throw new ReplaceError("Inconsistent open depths");
  return replaceOuter($from, $to, slice, 0);
}
function replaceOuter($from, $to, slice, depth) {
  var index = $from.index(depth),
    node = $from.node(depth);
  if (index == $to.index(depth) && depth < $from.depth - slice.openStart) {
    var inner = replaceOuter($from, $to, slice, depth + 1);
    return node.copy(node.content.replaceChild(index, inner));
  } else if (!slice.content.size) {
    return close(node, replaceTwoWay($from, $to, depth));
  } else if (!slice.openStart && !slice.openEnd && $from.depth == depth && $to.depth == depth) {
    var parent = $from.parent,
      content = parent.content;
    return close(parent, content.cut(0, $from.parentOffset).append(slice.content).append(content.cut($to.parentOffset)));
  } else {
    var _prepareSliceForRepla = prepareSliceForReplace(slice, $from),
      start = _prepareSliceForRepla.start,
      end = _prepareSliceForRepla.end;
    return close(node, replaceThreeWay($from, start, end, $to, depth));
  }
}
function checkJoin(main, sub) {
  if (!sub.type.compatibleContent(main.type)) throw new ReplaceError("Cannot join " + sub.type.name + " onto " + main.type.name);
}
function joinable($before, $after, depth) {
  var node = $before.node(depth);
  checkJoin(node, $after.node(depth));
  return node;
}
function addNode(child, target) {
  var last = target.length - 1;
  if (last >= 0 && child.isText && child.sameMarkup(target[last])) target[last] = child.withText(target[last].text + child.text);else target.push(child);
}
function addRange($start, $end, depth, target) {
  var node = ($end || $start).node(depth);
  var startIndex = 0,
    endIndex = $end ? $end.index(depth) : node.childCount;
  if ($start) {
    startIndex = $start.index(depth);
    if ($start.depth > depth) {
      startIndex++;
    } else if ($start.textOffset) {
      addNode($start.nodeAfter, target);
      startIndex++;
    }
  }
  for (var i = startIndex; i < endIndex; i++) addNode(node.child(i), target);
  if ($end && $end.depth == depth && $end.textOffset) addNode($end.nodeBefore, target);
}
function close(node, content) {
  node.type.checkContent(content);
  return node.copy(content);
}
function replaceThreeWay($from, $start, $end, $to, depth) {
  var openStart = $from.depth > depth && joinable($from, $start, depth + 1);
  var openEnd = $to.depth > depth && joinable($end, $to, depth + 1);
  var content = [];
  addRange(null, $from, depth, content);
  if (openStart && openEnd && $start.index(depth) == $end.index(depth)) {
    checkJoin(openStart, openEnd);
    addNode(close(openStart, replaceThreeWay($from, $start, $end, $to, depth + 1)), content);
  } else {
    if (openStart) addNode(close(openStart, replaceTwoWay($from, $start, depth + 1)), content);
    addRange($start, $end, depth, content);
    if (openEnd) addNode(close(openEnd, replaceTwoWay($end, $to, depth + 1)), content);
  }
  addRange($to, null, depth, content);
  return new Fragment(content);
}
function replaceTwoWay($from, $to, depth) {
  var content = [];
  addRange(null, $from, depth, content);
  if ($from.depth > depth) {
    var type = joinable($from, $to, depth + 1);
    addNode(close(type, replaceTwoWay($from, $to, depth + 1)), content);
  }
  addRange($to, null, depth, content);
  return new Fragment(content);
}
function prepareSliceForReplace(slice, $along) {
  var extra = $along.depth - slice.openStart,
    parent = $along.node(extra);
  var node = parent.copy(slice.content);
  for (var i = extra - 1; i >= 0; i--) node = $along.node(i).copy(Fragment.from(node));
  return {
    start: node.resolveNoCache(slice.openStart + extra),
    end: node.resolveNoCache(node.content.size - slice.openEnd - extra)
  };
}
var ResolvedPos = function () {
  function ResolvedPos(pos, path, parentOffset) {
    _classCallCheck(this, ResolvedPos);
    this.pos = pos;
    this.path = path;
    this.parentOffset = parentOffset;
    this.depth = path.length / 3 - 1;
  }
  _createClass(ResolvedPos, [{
    key: "resolveDepth",
    value: function resolveDepth(val) {
      if (val == null) return this.depth;
      if (val < 0) return this.depth + val;
      return val;
    }
  }, {
    key: "parent",
    get: function get() {
      return this.node(this.depth);
    }
  }, {
    key: "doc",
    get: function get() {
      return this.node(0);
    }
  }, {
    key: "node",
    value: function node(depth) {
      return this.path[this.resolveDepth(depth) * 3];
    }
  }, {
    key: "index",
    value: function index(depth) {
      return this.path[this.resolveDepth(depth) * 3 + 1];
    }
  }, {
    key: "indexAfter",
    value: function indexAfter(depth) {
      depth = this.resolveDepth(depth);
      return this.index(depth) + (depth == this.depth && !this.textOffset ? 0 : 1);
    }
  }, {
    key: "start",
    value: function start(depth) {
      depth = this.resolveDepth(depth);
      return depth == 0 ? 0 : this.path[depth * 3 - 1] + 1;
    }
  }, {
    key: "end",
    value: function end(depth) {
      depth = this.resolveDepth(depth);
      return this.start(depth) + this.node(depth).content.size;
    }
  }, {
    key: "before",
    value: function before(depth) {
      depth = this.resolveDepth(depth);
      if (!depth) throw new RangeError("There is no position before the top-level node");
      return depth == this.depth + 1 ? this.pos : this.path[depth * 3 - 1];
    }
  }, {
    key: "after",
    value: function after(depth) {
      depth = this.resolveDepth(depth);
      if (!depth) throw new RangeError("There is no position after the top-level node");
      return depth == this.depth + 1 ? this.pos : this.path[depth * 3 - 1] + this.path[depth * 3].nodeSize;
    }
  }, {
    key: "textOffset",
    get: function get() {
      return this.pos - this.path[this.path.length - 1];
    }
  }, {
    key: "nodeAfter",
    get: function get() {
      var parent = this.parent,
        index = this.index(this.depth);
      if (index == parent.childCount) return null;
      var dOff = this.pos - this.path[this.path.length - 1],
        child = parent.child(index);
      return dOff ? parent.child(index).cut(dOff) : child;
    }
  }, {
    key: "nodeBefore",
    get: function get() {
      var index = this.index(this.depth);
      var dOff = this.pos - this.path[this.path.length - 1];
      if (dOff) return this.parent.child(index).cut(0, dOff);
      return index == 0 ? null : this.parent.child(index - 1);
    }
  }, {
    key: "posAtIndex",
    value: function posAtIndex(index, depth) {
      depth = this.resolveDepth(depth);
      var node = this.path[depth * 3],
        pos = depth == 0 ? 0 : this.path[depth * 3 - 1] + 1;
      for (var i = 0; i < index; i++) pos += node.child(i).nodeSize;
      return pos;
    }
  }, {
    key: "marks",
    value: function marks() {
      var parent = this.parent,
        index = this.index();
      if (parent.content.size == 0) return Mark.none;
      if (this.textOffset) return parent.child(index).marks;
      var main = parent.maybeChild(index - 1),
        other = parent.maybeChild(index);
      if (!main) {
        var tmp = main;
        main = other;
        other = tmp;
      }
      var marks = main.marks;
      for (var i = 0; i < marks.length; i++) if (marks[i].type.spec.inclusive === false && (!other || !marks[i].isInSet(other.marks))) marks = marks[i--].removeFromSet(marks);
      return marks;
    }
  }, {
    key: "marksAcross",
    value: function marksAcross($end) {
      var after = this.parent.maybeChild(this.index());
      if (!after || !after.isInline) return null;
      var marks = after.marks,
        next = $end.parent.maybeChild($end.index());
      for (var i = 0; i < marks.length; i++) if (marks[i].type.spec.inclusive === false && (!next || !marks[i].isInSet(next.marks))) marks = marks[i--].removeFromSet(marks);
      return marks;
    }
  }, {
    key: "sharedDepth",
    value: function sharedDepth(pos) {
      for (var depth = this.depth; depth > 0; depth--) if (this.start(depth) <= pos && this.end(depth) >= pos) return depth;
      return 0;
    }
  }, {
    key: "blockRange",
    value: function blockRange() {
      var other = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : this;
      var pred = arguments.length > 1 ? arguments[1] : undefined;
      if (other.pos < this.pos) return other.blockRange(this);
      for (var d = this.depth - (this.parent.inlineContent || this.pos == other.pos ? 1 : 0); d >= 0; d--) if (other.pos <= this.end(d) && (!pred || pred(this.node(d)))) return new NodeRange(this, other, d);
      return null;
    }
  }, {
    key: "sameParent",
    value: function sameParent(other) {
      return this.pos - this.parentOffset == other.pos - other.parentOffset;
    }
  }, {
    key: "max",
    value: function max(other) {
      return other.pos > this.pos ? other : this;
    }
  }, {
    key: "min",
    value: function min(other) {
      return other.pos < this.pos ? other : this;
    }
  }, {
    key: "toString",
    value: function toString() {
      var str = "";
      for (var i = 1; i <= this.depth; i++) str += (str ? "/" : "") + this.node(i).type.name + "_" + this.index(i - 1);
      return str + ":" + this.parentOffset;
    }
  }], [{
    key: "resolve",
    value: function resolve(doc, pos) {
      if (!(pos >= 0 && pos <= doc.content.size)) throw new RangeError("Position " + pos + " out of range");
      var path = [];
      var start = 0,
        parentOffset = pos;
      for (var node = doc;;) {
        var _node$content$findInd = node.content.findIndex(parentOffset),
          index = _node$content$findInd.index,
          offset = _node$content$findInd.offset;
        var rem = parentOffset - offset;
        path.push(node, index, start + offset);
        if (!rem) break;
        node = node.child(index);
        if (node.isText) break;
        parentOffset = rem - 1;
        start += offset + 1;
      }
      return new ResolvedPos(pos, path, parentOffset);
    }
  }, {
    key: "resolveCached",
    value: function resolveCached(doc, pos) {
      var cache = resolveCache.get(doc);
      if (cache) {
        for (var i = 0; i < cache.elts.length; i++) {
          var elt = cache.elts[i];
          if (elt.pos == pos) return elt;
        }
      } else {
        resolveCache.set(doc, cache = new ResolveCache());
      }
      var result = cache.elts[cache.i] = ResolvedPos.resolve(doc, pos);
      cache.i = (cache.i + 1) % resolveCacheSize;
      return result;
    }
  }]);
  return ResolvedPos;
}();
var ResolveCache = _createClass(function ResolveCache() {
  _classCallCheck(this, ResolveCache);
  this.elts = [];
  this.i = 0;
});
var resolveCacheSize = 12,
  resolveCache = new WeakMap();
var NodeRange = function () {
  function NodeRange($from, $to, depth) {
    _classCallCheck(this, NodeRange);
    this.$from = $from;
    this.$to = $to;
    this.depth = depth;
  }
  _createClass(NodeRange, [{
    key: "start",
    get: function get() {
      return this.$from.before(this.depth + 1);
    }
  }, {
    key: "end",
    get: function get() {
      return this.$to.after(this.depth + 1);
    }
  }, {
    key: "parent",
    get: function get() {
      return this.$from.node(this.depth);
    }
  }, {
    key: "startIndex",
    get: function get() {
      return this.$from.index(this.depth);
    }
  }, {
    key: "endIndex",
    get: function get() {
      return this.$to.indexAfter(this.depth);
    }
  }]);
  return NodeRange;
}();
var emptyAttrs = Object.create(null);
var Node = function () {
  function Node(type, attrs, content) {
    var marks = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : Mark.none;
    _classCallCheck(this, Node);
    this.type = type;
    this.attrs = attrs;
    this.marks = marks;
    this.content = content || Fragment.empty;
  }
  _createClass(Node, [{
    key: "nodeSize",
    get: function get() {
      return this.isLeaf ? 1 : 2 + this.content.size;
    }
  }, {
    key: "childCount",
    get: function get() {
      return this.content.childCount;
    }
  }, {
    key: "child",
    value: function child(index) {
      return this.content.child(index);
    }
  }, {
    key: "maybeChild",
    value: function maybeChild(index) {
      return this.content.maybeChild(index);
    }
  }, {
    key: "forEach",
    value: function forEach(f) {
      this.content.forEach(f);
    }
  }, {
    key: "nodesBetween",
    value: function nodesBetween(from, to, f) {
      var startPos = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 0;
      this.content.nodesBetween(from, to, f, startPos, this);
    }
  }, {
    key: "descendants",
    value: function descendants(f) {
      this.nodesBetween(0, this.content.size, f);
    }
  }, {
    key: "textContent",
    get: function get() {
      return this.isLeaf && this.type.spec.leafText ? this.type.spec.leafText(this) : this.textBetween(0, this.content.size, "");
    }
  }, {
    key: "textBetween",
    value: function textBetween(from, to, blockSeparator, leafText) {
      return this.content.textBetween(from, to, blockSeparator, leafText);
    }
  }, {
    key: "firstChild",
    get: function get() {
      return this.content.firstChild;
    }
  }, {
    key: "lastChild",
    get: function get() {
      return this.content.lastChild;
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return this == other || this.sameMarkup(other) && this.content.eq(other.content);
    }
  }, {
    key: "sameMarkup",
    value: function sameMarkup(other) {
      return this.hasMarkup(other.type, other.attrs, other.marks);
    }
  }, {
    key: "hasMarkup",
    value: function hasMarkup(type, attrs, marks) {
      return this.type == type && compareDeep(this.attrs, attrs || type.defaultAttrs || emptyAttrs) && Mark.sameSet(this.marks, marks || Mark.none);
    }
  }, {
    key: "copy",
    value: function copy() {
      var content = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : null;
      if (content == this.content) return this;
      return new Node(this.type, this.attrs, content, this.marks);
    }
  }, {
    key: "mark",
    value: function mark(marks) {
      return marks == this.marks ? this : new Node(this.type, this.attrs, this.content, marks);
    }
  }, {
    key: "cut",
    value: function cut(from) {
      var to = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : this.content.size;
      if (from == 0 && to == this.content.size) return this;
      return this.copy(this.content.cut(from, to));
    }
  }, {
    key: "slice",
    value: function slice(from) {
      var to = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : this.content.size;
      var includeParents = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
      if (from == to) return Slice.empty;
      var $from = this.resolve(from),
        $to = this.resolve(to);
      var depth = includeParents ? 0 : $from.sharedDepth(to);
      var start = $from.start(depth),
        node = $from.node(depth);
      var content = node.content.cut($from.pos - start, $to.pos - start);
      return new Slice(content, $from.depth - depth, $to.depth - depth);
    }
  }, {
    key: "replace",
    value: function replace(from, to, slice) {
      return _replace(this.resolve(from), this.resolve(to), slice);
    }
  }, {
    key: "nodeAt",
    value: function nodeAt(pos) {
      for (var node = this;;) {
        var _node$content$findInd2 = node.content.findIndex(pos),
          index = _node$content$findInd2.index,
          offset = _node$content$findInd2.offset;
        node = node.maybeChild(index);
        if (!node) return null;
        if (offset == pos || node.isText) return node;
        pos -= offset + 1;
      }
    }
  }, {
    key: "childAfter",
    value: function childAfter(pos) {
      var _this$content$findInd = this.content.findIndex(pos),
        index = _this$content$findInd.index,
        offset = _this$content$findInd.offset;
      return {
        node: this.content.maybeChild(index),
        index: index,
        offset: offset
      };
    }
  }, {
    key: "childBefore",
    value: function childBefore(pos) {
      if (pos == 0) return {
        node: null,
        index: 0,
        offset: 0
      };
      var _this$content$findInd2 = this.content.findIndex(pos),
        index = _this$content$findInd2.index,
        offset = _this$content$findInd2.offset;
      if (offset < pos) return {
        node: this.content.child(index),
        index: index,
        offset: offset
      };
      var node = this.content.child(index - 1);
      return {
        node: node,
        index: index - 1,
        offset: offset - node.nodeSize
      };
    }
  }, {
    key: "resolve",
    value: function resolve(pos) {
      return ResolvedPos.resolveCached(this, pos);
    }
  }, {
    key: "resolveNoCache",
    value: function resolveNoCache(pos) {
      return ResolvedPos.resolve(this, pos);
    }
  }, {
    key: "rangeHasMark",
    value: function rangeHasMark(from, to, type) {
      var found = false;
      if (to > from) this.nodesBetween(from, to, function (node) {
        if (type.isInSet(node.marks)) found = true;
        return !found;
      });
      return found;
    }
  }, {
    key: "isBlock",
    get: function get() {
      return this.type.isBlock;
    }
  }, {
    key: "isTextblock",
    get: function get() {
      return this.type.isTextblock;
    }
  }, {
    key: "inlineContent",
    get: function get() {
      return this.type.inlineContent;
    }
  }, {
    key: "isInline",
    get: function get() {
      return this.type.isInline;
    }
  }, {
    key: "isText",
    get: function get() {
      return this.type.isText;
    }
  }, {
    key: "isLeaf",
    get: function get() {
      return this.type.isLeaf;
    }
  }, {
    key: "isAtom",
    get: function get() {
      return this.type.isAtom;
    }
  }, {
    key: "toString",
    value: function toString() {
      if (this.type.spec.toDebugString) return this.type.spec.toDebugString(this);
      var name = this.type.name;
      if (this.content.size) name += "(" + this.content.toStringInner() + ")";
      return wrapMarks(this.marks, name);
    }
  }, {
    key: "contentMatchAt",
    value: function contentMatchAt(index) {
      var match = this.type.contentMatch.matchFragment(this.content, 0, index);
      if (!match) throw new Error("Called contentMatchAt on a node with invalid content");
      return match;
    }
  }, {
    key: "canReplace",
    value: function canReplace(from, to) {
      var replacement = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : Fragment.empty;
      var start = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 0;
      var end = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : replacement.childCount;
      var one = this.contentMatchAt(from).matchFragment(replacement, start, end);
      var two = one && one.matchFragment(this.content, to);
      if (!two || !two.validEnd) return false;
      for (var i = start; i < end; i++) if (!this.type.allowsMarks(replacement.child(i).marks)) return false;
      return true;
    }
  }, {
    key: "canReplaceWith",
    value: function canReplaceWith(from, to, type, marks) {
      if (marks && !this.type.allowsMarks(marks)) return false;
      var start = this.contentMatchAt(from).matchType(type);
      var end = start && start.matchFragment(this.content, to);
      return end ? end.validEnd : false;
    }
  }, {
    key: "canAppend",
    value: function canAppend(other) {
      if (other.content.size) return this.canReplace(this.childCount, this.childCount, other.content);else return this.type.compatibleContent(other.type);
    }
  }, {
    key: "check",
    value: function check() {
      this.type.checkContent(this.content);
      this.type.checkAttrs(this.attrs);
      var copy = Mark.none;
      for (var i = 0; i < this.marks.length; i++) {
        var mark = this.marks[i];
        mark.type.checkAttrs(mark.attrs);
        copy = mark.addToSet(copy);
      }
      if (!Mark.sameSet(copy, this.marks)) throw new RangeError("Invalid collection of marks for node ".concat(this.type.name, ": ").concat(this.marks.map(function (m) {
        return m.type.name;
      })));
      this.content.forEach(function (node) {
        return node.check();
      });
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      var obj = {
        type: this.type.name
      };
      for (var _ in this.attrs) {
        obj.attrs = this.attrs;
        break;
      }
      if (this.content.size) obj.content = this.content.toJSON();
      if (this.marks.length) obj.marks = this.marks.map(function (n) {
        return n.toJSON();
      });
      return obj;
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (!json) throw new RangeError("Invalid input for Node.fromJSON");
      var marks = undefined;
      if (json.marks) {
        if (!Array.isArray(json.marks)) throw new RangeError("Invalid mark data for Node.fromJSON");
        marks = json.marks.map(schema.markFromJSON);
      }
      if (json.type == "text") {
        if (typeof json.text != "string") throw new RangeError("Invalid text node in JSON");
        return schema.text(json.text, marks);
      }
      var content = Fragment.fromJSON(schema, json.content);
      var node = schema.nodeType(json.type).create(json.attrs, content, marks);
      node.type.checkAttrs(node.attrs);
      return node;
    }
  }]);
  return Node;
}();
Node.prototype.text = undefined;
var TextNode = function (_Node) {
  _inherits(TextNode, _Node);
  var _super2 = _createSuper(TextNode);
  function TextNode(type, attrs, content, marks) {
    var _this;
    _classCallCheck(this, TextNode);
    _this = _super2.call(this, type, attrs, null, marks);
    if (!content) throw new RangeError("Empty text nodes are not allowed");
    _this.text = content;
    return _this;
  }
  _createClass(TextNode, [{
    key: "toString",
    value: function toString() {
      if (this.type.spec.toDebugString) return this.type.spec.toDebugString(this);
      return wrapMarks(this.marks, JSON.stringify(this.text));
    }
  }, {
    key: "textContent",
    get: function get() {
      return this.text;
    }
  }, {
    key: "textBetween",
    value: function textBetween(from, to) {
      return this.text.slice(from, to);
    }
  }, {
    key: "nodeSize",
    get: function get() {
      return this.text.length;
    }
  }, {
    key: "mark",
    value: function mark(marks) {
      return marks == this.marks ? this : new TextNode(this.type, this.attrs, this.text, marks);
    }
  }, {
    key: "withText",
    value: function withText(text) {
      if (text == this.text) return this;
      return new TextNode(this.type, this.attrs, text, this.marks);
    }
  }, {
    key: "cut",
    value: function cut() {
      var from = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;
      var to = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : this.text.length;
      if (from == 0 && to == this.text.length) return this;
      return this.withText(this.text.slice(from, to));
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return this.sameMarkup(other) && this.text == other.text;
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      var base = _get(_getPrototypeOf(TextNode.prototype), "toJSON", this).call(this);
      base.text = this.text;
      return base;
    }
  }]);
  return TextNode;
}(Node);
function wrapMarks(marks, str) {
  for (var i = marks.length - 1; i >= 0; i--) str = marks[i].type.name + "(" + str + ")";
  return str;
}
var ContentMatch = function () {
  function ContentMatch(validEnd) {
    _classCallCheck(this, ContentMatch);
    this.validEnd = validEnd;
    this.next = [];
    this.wrapCache = [];
  }
  _createClass(ContentMatch, [{
    key: "matchType",
    value: function matchType(type) {
      for (var i = 0; i < this.next.length; i++) if (this.next[i].type == type) return this.next[i].next;
      return null;
    }
  }, {
    key: "matchFragment",
    value: function matchFragment(frag) {
      var start = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
      var end = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : frag.childCount;
      var cur = this;
      for (var i = start; cur && i < end; i++) cur = cur.matchType(frag.child(i).type);
      return cur;
    }
  }, {
    key: "inlineContent",
    get: function get() {
      return this.next.length != 0 && this.next[0].type.isInline;
    }
  }, {
    key: "defaultType",
    get: function get() {
      for (var i = 0; i < this.next.length; i++) {
        var type = this.next[i].type;
        if (!(type.isText || type.hasRequiredAttrs())) return type;
      }
      return null;
    }
  }, {
    key: "compatible",
    value: function compatible(other) {
      for (var i = 0; i < this.next.length; i++) for (var j = 0; j < other.next.length; j++) if (this.next[i].type == other.next[j].type) return true;
      return false;
    }
  }, {
    key: "fillBefore",
    value: function fillBefore(after) {
      var toEnd = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
      var startIndex = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;
      var seen = [this];
      function search(match, types) {
        var finished = match.matchFragment(after, startIndex);
        if (finished && (!toEnd || finished.validEnd)) return Fragment.from(types.map(function (tp) {
          return tp.createAndFill();
        }));
        for (var i = 0; i < match.next.length; i++) {
          var _match$next$i = match.next[i],
            type = _match$next$i.type,
            next = _match$next$i.next;
          if (!(type.isText || type.hasRequiredAttrs()) && seen.indexOf(next) == -1) {
            seen.push(next);
            var _found = search(next, types.concat(type));
            if (_found) return _found;
          }
        }
        return null;
      }
      return search(this, []);
    }
  }, {
    key: "findWrapping",
    value: function findWrapping(target) {
      for (var i = 0; i < this.wrapCache.length; i += 2) if (this.wrapCache[i] == target) return this.wrapCache[i + 1];
      var computed = this.computeWrapping(target);
      this.wrapCache.push(target, computed);
      return computed;
    }
  }, {
    key: "computeWrapping",
    value: function computeWrapping(target) {
      var seen = Object.create(null),
        active = [{
          match: this,
          type: null,
          via: null
        }];
      while (active.length) {
        var current = active.shift(),
          match = current.match;
        if (match.matchType(target)) {
          var result = [];
          for (var obj = current; obj.type; obj = obj.via) result.push(obj.type);
          return result.reverse();
        }
        for (var i = 0; i < match.next.length; i++) {
          var _match$next$i2 = match.next[i],
            type = _match$next$i2.type,
            next = _match$next$i2.next;
          if (!type.isLeaf && !type.hasRequiredAttrs() && !(type.name in seen) && (!current.type || next.validEnd)) {
            active.push({
              match: type.contentMatch,
              type: type,
              via: current
            });
            seen[type.name] = true;
          }
        }
      }
      return null;
    }
  }, {
    key: "edgeCount",
    get: function get() {
      return this.next.length;
    }
  }, {
    key: "edge",
    value: function edge(n) {
      if (n >= this.next.length) throw new RangeError("There's no ".concat(n, "th edge in this content match"));
      return this.next[n];
    }
  }, {
    key: "toString",
    value: function toString() {
      var seen = [];
      function scan(m) {
        seen.push(m);
        for (var i = 0; i < m.next.length; i++) if (seen.indexOf(m.next[i].next) == -1) scan(m.next[i].next);
      }
      scan(this);
      return seen.map(function (m, i) {
        var out = i + (m.validEnd ? "*" : " ") + " ";
        for (var _i = 0; _i < m.next.length; _i++) out += (_i ? ", " : "") + m.next[_i].type.name + "->" + seen.indexOf(m.next[_i].next);
        return out;
      }).join("\n");
    }
  }], [{
    key: "parse",
    value: function parse(string, nodeTypes) {
      var stream = new TokenStream(string, nodeTypes);
      if (stream.next == null) return ContentMatch.empty;
      var expr = parseExpr(stream);
      if (stream.next) stream.err("Unexpected trailing text");
      var match = dfa(nfa(expr));
      checkForDeadEnds(match, stream);
      return match;
    }
  }]);
  return ContentMatch;
}();
ContentMatch.empty = new ContentMatch(true);
var TokenStream = function () {
  function TokenStream(string, nodeTypes) {
    _classCallCheck(this, TokenStream);
    this.string = string;
    this.nodeTypes = nodeTypes;
    this.inline = null;
    this.pos = 0;
    this.tokens = string.split(/\s*(?=\b|\W|$)/);
    if (this.tokens[this.tokens.length - 1] == "") this.tokens.pop();
    if (this.tokens[0] == "") this.tokens.shift();
  }
  _createClass(TokenStream, [{
    key: "next",
    get: function get() {
      return this.tokens[this.pos];
    }
  }, {
    key: "eat",
    value: function eat(tok) {
      return this.next == tok && (this.pos++ || true);
    }
  }, {
    key: "err",
    value: function err(str) {
      throw new SyntaxError(str + " (in content expression '" + this.string + "')");
    }
  }]);
  return TokenStream;
}();
function parseExpr(stream) {
  var exprs = [];
  do {
    exprs.push(parseExprSeq(stream));
  } while (stream.eat("|"));
  return exprs.length == 1 ? exprs[0] : {
    type: "choice",
    exprs: exprs
  };
}
function parseExprSeq(stream) {
  var exprs = [];
  do {
    exprs.push(parseExprSubscript(stream));
  } while (stream.next && stream.next != ")" && stream.next != "|");
  return exprs.length == 1 ? exprs[0] : {
    type: "seq",
    exprs: exprs
  };
}
function parseExprSubscript(stream) {
  var expr = parseExprAtom(stream);
  for (;;) {
    if (stream.eat("+")) expr = {
      type: "plus",
      expr: expr
    };else if (stream.eat("*")) expr = {
      type: "star",
      expr: expr
    };else if (stream.eat("?")) expr = {
      type: "opt",
      expr: expr
    };else if (stream.eat("{")) expr = parseExprRange(stream, expr);else break;
  }
  return expr;
}
function parseNum(stream) {
  if (/\D/.test(stream.next)) stream.err("Expected number, got '" + stream.next + "'");
  var result = Number(stream.next);
  stream.pos++;
  return result;
}
function parseExprRange(stream, expr) {
  var min = parseNum(stream),
    max = min;
  if (stream.eat(",")) {
    if (stream.next != "}") max = parseNum(stream);else max = -1;
  }
  if (!stream.eat("}")) stream.err("Unclosed braced range");
  return {
    type: "range",
    min: min,
    max: max,
    expr: expr
  };
}
function resolveName(stream, name) {
  var types = stream.nodeTypes,
    type = types[name];
  if (type) return [type];
  var result = [];
  for (var typeName in types) {
    var _type = types[typeName];
    if (_type.groups.indexOf(name) > -1) result.push(_type);
  }
  if (result.length == 0) stream.err("No node type or group '" + name + "' found");
  return result;
}
function parseExprAtom(stream) {
  if (stream.eat("(")) {
    var expr = parseExpr(stream);
    if (!stream.eat(")")) stream.err("Missing closing paren");
    return expr;
  } else if (!/\W/.test(stream.next)) {
    var exprs = resolveName(stream, stream.next).map(function (type) {
      if (stream.inline == null) stream.inline = type.isInline;else if (stream.inline != type.isInline) stream.err("Mixing inline and block content");
      return {
        type: "name",
        value: type
      };
    });
    stream.pos++;
    return exprs.length == 1 ? exprs[0] : {
      type: "choice",
      exprs: exprs
    };
  } else {
    stream.err("Unexpected token '" + stream.next + "'");
  }
}
function nfa(expr) {
  var nfa = [[]];
  connect(compile(expr, 0), node());
  return nfa;
  function node() {
    return nfa.push([]) - 1;
  }
  function edge(from, to, term) {
    var edge = {
      term: term,
      to: to
    };
    nfa[from].push(edge);
    return edge;
  }
  function connect(edges, to) {
    edges.forEach(function (edge) {
      return edge.to = to;
    });
  }
  function compile(expr, from) {
    if (expr.type == "choice") {
      return expr.exprs.reduce(function (out, expr) {
        return out.concat(compile(expr, from));
      }, []);
    } else if (expr.type == "seq") {
      for (var i = 0;; i++) {
        var next = compile(expr.exprs[i], from);
        if (i == expr.exprs.length - 1) return next;
        connect(next, from = node());
      }
    } else if (expr.type == "star") {
      var loop = node();
      edge(from, loop);
      connect(compile(expr.expr, loop), loop);
      return [edge(loop)];
    } else if (expr.type == "plus") {
      var _loop = node();
      connect(compile(expr.expr, from), _loop);
      connect(compile(expr.expr, _loop), _loop);
      return [edge(_loop)];
    } else if (expr.type == "opt") {
      return [edge(from)].concat(compile(expr.expr, from));
    } else if (expr.type == "range") {
      var cur = from;
      for (var _i2 = 0; _i2 < expr.min; _i2++) {
        var _next = node();
        connect(compile(expr.expr, cur), _next);
        cur = _next;
      }
      if (expr.max == -1) {
        connect(compile(expr.expr, cur), cur);
      } else {
        for (var _i3 = expr.min; _i3 < expr.max; _i3++) {
          var _next2 = node();
          edge(cur, _next2);
          connect(compile(expr.expr, cur), _next2);
          cur = _next2;
        }
      }
      return [edge(cur)];
    } else if (expr.type == "name") {
      return [edge(from, undefined, expr.value)];
    } else {
      throw new Error("Unknown expr type");
    }
  }
}
function cmp(a, b) {
  return b - a;
}
function nullFrom(nfa, node) {
  var result = [];
  scan(node);
  return result.sort(cmp);
  function scan(node) {
    var edges = nfa[node];
    if (edges.length == 1 && !edges[0].term) return scan(edges[0].to);
    result.push(node);
    for (var i = 0; i < edges.length; i++) {
      var _edges$i = edges[i],
        term = _edges$i.term,
        to = _edges$i.to;
      if (!term && result.indexOf(to) == -1) scan(to);
    }
  }
}
function dfa(nfa) {
  var labeled = Object.create(null);
  return explore(nullFrom(nfa, 0));
  function explore(states) {
    var out = [];
    states.forEach(function (node) {
      nfa[node].forEach(function (_ref) {
        var term = _ref.term,
          to = _ref.to;
        if (!term) return;
        var set;
        for (var i = 0; i < out.length; i++) if (out[i][0] == term) set = out[i][1];
        nullFrom(nfa, to).forEach(function (node) {
          if (!set) out.push([term, set = []]);
          if (set.indexOf(node) == -1) set.push(node);
        });
      });
    });
    var state = labeled[states.join(",")] = new ContentMatch(states.indexOf(nfa.length - 1) > -1);
    for (var i = 0; i < out.length; i++) {
      var _states = out[i][1].sort(cmp);
      state.next.push({
        type: out[i][0],
        next: labeled[_states.join(",")] || explore(_states)
      });
    }
    return state;
  }
}
function checkForDeadEnds(match, stream) {
  for (var i = 0, work = [match]; i < work.length; i++) {
    var state = work[i],
      dead = !state.validEnd,
      nodes = [];
    for (var j = 0; j < state.next.length; j++) {
      var _state$next$j = state.next[j],
        type = _state$next$j.type,
        next = _state$next$j.next;
      nodes.push(type.name);
      if (dead && !(type.isText || type.hasRequiredAttrs())) dead = false;
      if (work.indexOf(next) == -1) work.push(next);
    }
    if (dead) stream.err("Only non-generatable nodes (" + nodes.join(", ") + ") in a required position (see https://prosemirror.net/docs/guide/#generatable)");
  }
}
function defaultAttrs(attrs) {
  var defaults = Object.create(null);
  for (var attrName in attrs) {
    var attr = attrs[attrName];
    if (!attr.hasDefault) return null;
    defaults[attrName] = attr["default"];
  }
  return defaults;
}
function _computeAttrs(attrs, value) {
  var built = Object.create(null);
  for (var name in attrs) {
    var given = value && value[name];
    if (given === undefined) {
      var attr = attrs[name];
      if (attr.hasDefault) given = attr["default"];else throw new RangeError("No value supplied for attribute " + name);
    }
    built[name] = given;
  }
  return built;
}
function _checkAttrs(attrs, values, type, name) {
  for (var _name in values) if (!(_name in attrs)) throw new RangeError("Unsupported attribute ".concat(_name, " for ").concat(type, " of type ").concat(_name));
  for (var _name2 in attrs) {
    var attr = attrs[_name2];
    if (attr.validate) attr.validate(values[_name2]);
  }
}
function initAttrs(typeName, attrs) {
  var result = Object.create(null);
  if (attrs) for (var name in attrs) result[name] = new Attribute(typeName, name, attrs[name]);
  return result;
}
var NodeType = function () {
  function NodeType(name, schema, spec) {
    _classCallCheck(this, NodeType);
    this.name = name;
    this.schema = schema;
    this.spec = spec;
    this.markSet = null;
    this.groups = spec.group ? spec.group.split(" ") : [];
    this.attrs = initAttrs(name, spec.attrs);
    this.defaultAttrs = defaultAttrs(this.attrs);
    this.contentMatch = null;
    this.inlineContent = null;
    this.isBlock = !(spec.inline || name == "text");
    this.isText = name == "text";
  }
  _createClass(NodeType, [{
    key: "isInline",
    get: function get() {
      return !this.isBlock;
    }
  }, {
    key: "isTextblock",
    get: function get() {
      return this.isBlock && this.inlineContent;
    }
  }, {
    key: "isLeaf",
    get: function get() {
      return this.contentMatch == ContentMatch.empty;
    }
  }, {
    key: "isAtom",
    get: function get() {
      return this.isLeaf || !!this.spec.atom;
    }
  }, {
    key: "whitespace",
    get: function get() {
      return this.spec.whitespace || (this.spec.code ? "pre" : "normal");
    }
  }, {
    key: "hasRequiredAttrs",
    value: function hasRequiredAttrs() {
      for (var n in this.attrs) if (this.attrs[n].isRequired) return true;
      return false;
    }
  }, {
    key: "compatibleContent",
    value: function compatibleContent(other) {
      return this == other || this.contentMatch.compatible(other.contentMatch);
    }
  }, {
    key: "computeAttrs",
    value: function computeAttrs(attrs) {
      if (!attrs && this.defaultAttrs) return this.defaultAttrs;else return _computeAttrs(this.attrs, attrs);
    }
  }, {
    key: "create",
    value: function create() {
      var attrs = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : null;
      var content = arguments.length > 1 ? arguments[1] : undefined;
      var marks = arguments.length > 2 ? arguments[2] : undefined;
      if (this.isText) throw new Error("NodeType.create can't construct text nodes");
      return new Node(this, this.computeAttrs(attrs), Fragment.from(content), Mark.setFrom(marks));
    }
  }, {
    key: "createChecked",
    value: function createChecked() {
      var attrs = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : null;
      var content = arguments.length > 1 ? arguments[1] : undefined;
      var marks = arguments.length > 2 ? arguments[2] : undefined;
      content = Fragment.from(content);
      this.checkContent(content);
      return new Node(this, this.computeAttrs(attrs), content, Mark.setFrom(marks));
    }
  }, {
    key: "createAndFill",
    value: function createAndFill() {
      var attrs = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : null;
      var content = arguments.length > 1 ? arguments[1] : undefined;
      var marks = arguments.length > 2 ? arguments[2] : undefined;
      attrs = this.computeAttrs(attrs);
      content = Fragment.from(content);
      if (content.size) {
        var before = this.contentMatch.fillBefore(content);
        if (!before) return null;
        content = before.append(content);
      }
      var matched = this.contentMatch.matchFragment(content);
      var after = matched && matched.fillBefore(Fragment.empty, true);
      if (!after) return null;
      return new Node(this, attrs, content.append(after), Mark.setFrom(marks));
    }
  }, {
    key: "validContent",
    value: function validContent(content) {
      var result = this.contentMatch.matchFragment(content);
      if (!result || !result.validEnd) return false;
      for (var i = 0; i < content.childCount; i++) if (!this.allowsMarks(content.child(i).marks)) return false;
      return true;
    }
  }, {
    key: "checkContent",
    value: function checkContent(content) {
      if (!this.validContent(content)) throw new RangeError("Invalid content for node ".concat(this.name, ": ").concat(content.toString().slice(0, 50)));
    }
  }, {
    key: "checkAttrs",
    value: function checkAttrs(attrs) {
      _checkAttrs(this.attrs, attrs, "node", this.name);
    }
  }, {
    key: "allowsMarkType",
    value: function allowsMarkType(markType) {
      return this.markSet == null || this.markSet.indexOf(markType) > -1;
    }
  }, {
    key: "allowsMarks",
    value: function allowsMarks(marks) {
      if (this.markSet == null) return true;
      for (var i = 0; i < marks.length; i++) if (!this.allowsMarkType(marks[i].type)) return false;
      return true;
    }
  }, {
    key: "allowedMarks",
    value: function allowedMarks(marks) {
      if (this.markSet == null) return marks;
      var copy;
      for (var i = 0; i < marks.length; i++) {
        if (!this.allowsMarkType(marks[i].type)) {
          if (!copy) copy = marks.slice(0, i);
        } else if (copy) {
          copy.push(marks[i]);
        }
      }
      return !copy ? marks : copy.length ? copy : Mark.none;
    }
  }], [{
    key: "compile",
    value: function compile(nodes, schema) {
      var result = Object.create(null);
      nodes.forEach(function (name, spec) {
        return result[name] = new NodeType(name, schema, spec);
      });
      var topType = schema.spec.topNode || "doc";
      if (!result[topType]) throw new RangeError("Schema is missing its top node type ('" + topType + "')");
      if (!result.text) throw new RangeError("Every schema needs a 'text' type");
      for (var _ in result.text.attrs) throw new RangeError("The text node type should not have attributes");
      return result;
    }
  }]);
  return NodeType;
}();
function validateType(typeName, attrName, type) {
  var types = type.split("|");
  return function (value) {
    var name = value === null ? "null" : _typeof(value);
    if (types.indexOf(name) < 0) throw new RangeError("Expected value of type ".concat(types, " for attribute ").concat(attrName, " on type ").concat(typeName, ", got ").concat(name));
  };
}
var Attribute = function () {
  function Attribute(typeName, attrName, options) {
    _classCallCheck(this, Attribute);
    this.hasDefault = Object.prototype.hasOwnProperty.call(options, "default");
    this["default"] = options["default"];
    this.validate = typeof options.validate == "string" ? validateType(typeName, attrName, options.validate) : options.validate;
  }
  _createClass(Attribute, [{
    key: "isRequired",
    get: function get() {
      return !this.hasDefault;
    }
  }]);
  return Attribute;
}();
var MarkType = function () {
  function MarkType(name, rank, schema, spec) {
    _classCallCheck(this, MarkType);
    this.name = name;
    this.rank = rank;
    this.schema = schema;
    this.spec = spec;
    this.attrs = initAttrs(name, spec.attrs);
    this.excluded = null;
    var defaults = defaultAttrs(this.attrs);
    this.instance = defaults ? new Mark(this, defaults) : null;
  }
  _createClass(MarkType, [{
    key: "create",
    value: function create() {
      var attrs = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : null;
      if (!attrs && this.instance) return this.instance;
      return new Mark(this, _computeAttrs(this.attrs, attrs));
    }
  }, {
    key: "removeFromSet",
    value: function removeFromSet(set) {
      for (var i = 0; i < set.length; i++) if (set[i].type == this) {
        set = set.slice(0, i).concat(set.slice(i + 1));
        i--;
      }
      return set;
    }
  }, {
    key: "isInSet",
    value: function isInSet(set) {
      for (var i = 0; i < set.length; i++) if (set[i].type == this) return set[i];
    }
  }, {
    key: "checkAttrs",
    value: function checkAttrs(attrs) {
      _checkAttrs(this.attrs, attrs, "mark", this.name);
    }
  }, {
    key: "excludes",
    value: function excludes(other) {
      return this.excluded.indexOf(other) > -1;
    }
  }], [{
    key: "compile",
    value: function compile(marks, schema) {
      var result = Object.create(null),
        rank = 0;
      marks.forEach(function (name, spec) {
        return result[name] = new MarkType(name, rank++, schema, spec);
      });
      return result;
    }
  }]);
  return MarkType;
}();
var Schema = function () {
  function Schema(spec) {
    _classCallCheck(this, Schema);
    this.linebreakReplacement = null;
    this.cached = Object.create(null);
    var instanceSpec = this.spec = {};
    for (var prop in spec) instanceSpec[prop] = spec[prop];
    instanceSpec.nodes = OrderedMap.from(spec.nodes), instanceSpec.marks = OrderedMap.from(spec.marks || {}), this.nodes = NodeType.compile(this.spec.nodes, this);
    this.marks = MarkType.compile(this.spec.marks, this);
    var contentExprCache = Object.create(null);
    for (var _prop in this.nodes) {
      if (_prop in this.marks) throw new RangeError(_prop + " can not be both a node and a mark");
      var type = this.nodes[_prop],
        contentExpr = type.spec.content || "",
        markExpr = type.spec.marks;
      type.contentMatch = contentExprCache[contentExpr] || (contentExprCache[contentExpr] = ContentMatch.parse(contentExpr, this.nodes));
      type.inlineContent = type.contentMatch.inlineContent;
      if (type.spec.linebreakReplacement) {
        if (this.linebreakReplacement) throw new RangeError("Multiple linebreak nodes defined");
        if (!type.isInline || !type.isLeaf) throw new RangeError("Linebreak replacement nodes must be inline leaf nodes");
        this.linebreakReplacement = type;
      }
      type.markSet = markExpr == "_" ? null : markExpr ? gatherMarks(this, markExpr.split(" ")) : markExpr == "" || !type.inlineContent ? [] : null;
    }
    for (var _prop2 in this.marks) {
      var _type2 = this.marks[_prop2],
        excl = _type2.spec.excludes;
      _type2.excluded = excl == null ? [_type2] : excl == "" ? [] : gatherMarks(this, excl.split(" "));
    }
    this.nodeFromJSON = this.nodeFromJSON.bind(this);
    this.markFromJSON = this.markFromJSON.bind(this);
    this.topNodeType = this.nodes[this.spec.topNode || "doc"];
    this.cached.wrappings = Object.create(null);
  }
  _createClass(Schema, [{
    key: "node",
    value: function node(type) {
      var attrs = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
      var content = arguments.length > 2 ? arguments[2] : undefined;
      var marks = arguments.length > 3 ? arguments[3] : undefined;
      if (typeof type == "string") type = this.nodeType(type);else if (!(type instanceof NodeType)) throw new RangeError("Invalid node type: " + type);else if (type.schema != this) throw new RangeError("Node type from different schema used (" + type.name + ")");
      return type.createChecked(attrs, content, marks);
    }
  }, {
    key: "text",
    value: function text(_text, marks) {
      var type = this.nodes.text;
      return new TextNode(type, type.defaultAttrs, _text, Mark.setFrom(marks));
    }
  }, {
    key: "mark",
    value: function mark(type, attrs) {
      if (typeof type == "string") type = this.marks[type];
      return type.create(attrs);
    }
  }, {
    key: "nodeFromJSON",
    value: function nodeFromJSON(json) {
      return Node.fromJSON(this, json);
    }
  }, {
    key: "markFromJSON",
    value: function markFromJSON(json) {
      return Mark.fromJSON(this, json);
    }
  }, {
    key: "nodeType",
    value: function nodeType(name) {
      var found = this.nodes[name];
      if (!found) throw new RangeError("Unknown node type: " + name);
      return found;
    }
  }]);
  return Schema;
}();
function gatherMarks(schema, marks) {
  var found = [];
  for (var i = 0; i < marks.length; i++) {
    var name = marks[i],
      mark = schema.marks[name],
      ok = mark;
    if (mark) {
      found.push(mark);
    } else {
      for (var prop in schema.marks) {
        var _mark = schema.marks[prop];
        if (name == "_" || _mark.spec.group && _mark.spec.group.split(" ").indexOf(name) > -1) found.push(ok = _mark);
      }
    }
    if (!ok) throw new SyntaxError("Unknown mark type: '" + marks[i] + "'");
  }
  return found;
}
function isTagRule(rule) {
  return rule.tag != null;
}
function isStyleRule(rule) {
  return rule.style != null;
}
var DOMParser = function () {
  function DOMParser(schema, rules) {
    var _this2 = this;
    _classCallCheck(this, DOMParser);
    this.schema = schema;
    this.rules = rules;
    this.tags = [];
    this.styles = [];
    var matchedStyles = this.matchedStyles = [];
    rules.forEach(function (rule) {
      if (isTagRule(rule)) {
        _this2.tags.push(rule);
      } else if (isStyleRule(rule)) {
        var prop = /[^=]*/.exec(rule.style)[0];
        if (matchedStyles.indexOf(prop) < 0) matchedStyles.push(prop);
        _this2.styles.push(rule);
      }
    });
    this.normalizeLists = !this.tags.some(function (r) {
      if (!/^(ul|ol)\b/.test(r.tag) || !r.node) return false;
      var node = schema.nodes[r.node];
      return node.contentMatch.matchType(node);
    });
  }
  _createClass(DOMParser, [{
    key: "parse",
    value: function parse(dom) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var context = new ParseContext(this, options, false);
      context.addAll(dom, Mark.none, options.from, options.to);
      return context.finish();
    }
  }, {
    key: "parseSlice",
    value: function parseSlice(dom) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var context = new ParseContext(this, options, true);
      context.addAll(dom, Mark.none, options.from, options.to);
      return Slice.maxOpen(context.finish());
    }
  }, {
    key: "matchTag",
    value: function matchTag(dom, context, after) {
      for (var i = after ? this.tags.indexOf(after) + 1 : 0; i < this.tags.length; i++) {
        var rule = this.tags[i];
        if (matches(dom, rule.tag) && (rule.namespace === undefined || dom.namespaceURI == rule.namespace) && (!rule.context || context.matchesContext(rule.context))) {
          if (rule.getAttrs) {
            var result = rule.getAttrs(dom);
            if (result === false) continue;
            rule.attrs = result || undefined;
          }
          return rule;
        }
      }
    }
  }, {
    key: "matchStyle",
    value: function matchStyle(prop, value, context, after) {
      for (var i = after ? this.styles.indexOf(after) + 1 : 0; i < this.styles.length; i++) {
        var rule = this.styles[i],
          style = rule.style;
        if (style.indexOf(prop) != 0 || rule.context && !context.matchesContext(rule.context) || style.length > prop.length && (style.charCodeAt(prop.length) != 61 || style.slice(prop.length + 1) != value)) continue;
        if (rule.getAttrs) {
          var result = rule.getAttrs(value);
          if (result === false) continue;
          rule.attrs = result || undefined;
        }
        return rule;
      }
    }
  }], [{
    key: "schemaRules",
    value: function schemaRules(schema) {
      var result = [];
      function insert(rule) {
        var priority = rule.priority == null ? 50 : rule.priority,
          i = 0;
        for (; i < result.length; i++) {
          var next = result[i],
            nextPriority = next.priority == null ? 50 : next.priority;
          if (nextPriority < priority) break;
        }
        result.splice(i, 0, rule);
      }
      var _loop2 = function _loop2(name) {
        var rules = schema.marks[name].spec.parseDOM;
        if (rules) rules.forEach(function (rule) {
          insert(rule = copy(rule));
          if (!(rule.mark || rule.ignore || rule.clearMark)) rule.mark = name;
        });
      };
      for (var name in schema.marks) {
        _loop2(name);
      }
      var _loop3 = function _loop3(_name3) {
        var rules = schema.nodes[_name3].spec.parseDOM;
        if (rules) rules.forEach(function (rule) {
          insert(rule = copy(rule));
          if (!(rule.node || rule.ignore || rule.mark)) rule.node = _name3;
        });
      };
      for (var _name3 in schema.nodes) {
        _loop3(_name3);
      }
      return result;
    }
  }, {
    key: "fromSchema",
    value: function fromSchema(schema) {
      return schema.cached.domParser || (schema.cached.domParser = new DOMParser(schema, DOMParser.schemaRules(schema)));
    }
  }]);
  return DOMParser;
}();
var blockTags = {
  address: true,
  article: true,
  aside: true,
  blockquote: true,
  canvas: true,
  dd: true,
  div: true,
  dl: true,
  fieldset: true,
  figcaption: true,
  figure: true,
  footer: true,
  form: true,
  h1: true,
  h2: true,
  h3: true,
  h4: true,
  h5: true,
  h6: true,
  header: true,
  hgroup: true,
  hr: true,
  li: true,
  noscript: true,
  ol: true,
  output: true,
  p: true,
  pre: true,
  section: true,
  table: true,
  tfoot: true,
  ul: true
};
var ignoreTags = {
  head: true,
  noscript: true,
  object: true,
  script: true,
  style: true,
  title: true
};
var listTags = {
  ol: true,
  ul: true
};
var OPT_PRESERVE_WS = 1,
  OPT_PRESERVE_WS_FULL = 2,
  OPT_OPEN_LEFT = 4;
function wsOptionsFor(type, preserveWhitespace, base) {
  if (preserveWhitespace != null) return (preserveWhitespace ? OPT_PRESERVE_WS : 0) | (preserveWhitespace === "full" ? OPT_PRESERVE_WS_FULL : 0);
  return type && type.whitespace == "pre" ? OPT_PRESERVE_WS | OPT_PRESERVE_WS_FULL : base & ~OPT_OPEN_LEFT;
}
var NodeContext = function () {
  function NodeContext(type, attrs, marks, solid, match, options) {
    _classCallCheck(this, NodeContext);
    this.type = type;
    this.attrs = attrs;
    this.marks = marks;
    this.solid = solid;
    this.options = options;
    this.content = [];
    this.activeMarks = Mark.none;
    this.match = match || (options & OPT_OPEN_LEFT ? null : type.contentMatch);
  }
  _createClass(NodeContext, [{
    key: "findWrapping",
    value: function findWrapping(node) {
      if (!this.match) {
        if (!this.type) return [];
        var fill = this.type.contentMatch.fillBefore(Fragment.from(node));
        if (fill) {
          this.match = this.type.contentMatch.matchFragment(fill);
        } else {
          var start = this.type.contentMatch,
            wrap;
          if (wrap = start.findWrapping(node.type)) {
            this.match = start;
            return wrap;
          } else {
            return null;
          }
        }
      }
      return this.match.findWrapping(node.type);
    }
  }, {
    key: "finish",
    value: function finish(openEnd) {
      if (!(this.options & OPT_PRESERVE_WS)) {
        var last = this.content[this.content.length - 1],
          m;
        if (last && last.isText && (m = /[ \t\r\n\u000c]+$/.exec(last.text))) {
          var text = last;
          if (last.text.length == m[0].length) this.content.pop();else this.content[this.content.length - 1] = text.withText(text.text.slice(0, text.text.length - m[0].length));
        }
      }
      var content = Fragment.from(this.content);
      if (!openEnd && this.match) content = content.append(this.match.fillBefore(Fragment.empty, true));
      return this.type ? this.type.create(this.attrs, content, this.marks) : content;
    }
  }, {
    key: "inlineContext",
    value: function inlineContext(node) {
      if (this.type) return this.type.inlineContent;
      if (this.content.length) return this.content[0].isInline;
      return node.parentNode && !blockTags.hasOwnProperty(node.parentNode.nodeName.toLowerCase());
    }
  }]);
  return NodeContext;
}();
var ParseContext = function () {
  function ParseContext(parser, options, isOpen) {
    _classCallCheck(this, ParseContext);
    this.parser = parser;
    this.options = options;
    this.isOpen = isOpen;
    this.open = 0;
    var topNode = options.topNode,
      topContext;
    var topOptions = wsOptionsFor(null, options.preserveWhitespace, 0) | (isOpen ? OPT_OPEN_LEFT : 0);
    if (topNode) topContext = new NodeContext(topNode.type, topNode.attrs, Mark.none, true, options.topMatch || topNode.type.contentMatch, topOptions);else if (isOpen) topContext = new NodeContext(null, null, Mark.none, true, null, topOptions);else topContext = new NodeContext(parser.schema.topNodeType, null, Mark.none, true, null, topOptions);
    this.nodes = [topContext];
    this.find = options.findPositions;
    this.needsBlock = false;
  }
  _createClass(ParseContext, [{
    key: "top",
    get: function get() {
      return this.nodes[this.open];
    }
  }, {
    key: "addDOM",
    value: function addDOM(dom, marks) {
      if (dom.nodeType == 3) this.addTextNode(dom, marks);else if (dom.nodeType == 1) this.addElement(dom, marks);
    }
  }, {
    key: "addTextNode",
    value: function addTextNode(dom, marks) {
      var value = dom.nodeValue;
      var top = this.top;
      if (top.options & OPT_PRESERVE_WS_FULL || top.inlineContext(dom) || /[^ \t\r\n\u000c]/.test(value)) {
        if (!(top.options & OPT_PRESERVE_WS)) {
          value = value.replace(/[ \t\r\n\u000c]+/g, " ");
          if (/^[ \t\r\n\u000c]/.test(value) && this.open == this.nodes.length - 1) {
            var nodeBefore = top.content[top.content.length - 1];
            var domNodeBefore = dom.previousSibling;
            if (!nodeBefore || domNodeBefore && domNodeBefore.nodeName == 'BR' || nodeBefore.isText && /[ \t\r\n\u000c]$/.test(nodeBefore.text)) value = value.slice(1);
          }
        } else if (!(top.options & OPT_PRESERVE_WS_FULL)) {
          value = value.replace(/\r?\n|\r/g, " ");
        } else {
          value = value.replace(/\r\n?/g, "\n");
        }
        if (value) this.insertNode(this.parser.schema.text(value), marks);
        this.findInText(dom);
      } else {
        this.findInside(dom);
      }
    }
  }, {
    key: "addElement",
    value: function addElement(dom, marks, matchAfter) {
      var name = dom.nodeName.toLowerCase(),
        ruleID;
      if (listTags.hasOwnProperty(name) && this.parser.normalizeLists) normalizeList(dom);
      var rule = this.options.ruleFromNode && this.options.ruleFromNode(dom) || (ruleID = this.parser.matchTag(dom, this, matchAfter));
      if (rule ? rule.ignore : ignoreTags.hasOwnProperty(name)) {
        this.findInside(dom);
        this.ignoreFallback(dom, marks);
      } else if (!rule || rule.skip || rule.closeParent) {
        if (rule && rule.closeParent) this.open = Math.max(0, this.open - 1);else if (rule && rule.skip.nodeType) dom = rule.skip;
        var sync,
          top = this.top,
          oldNeedsBlock = this.needsBlock;
        if (blockTags.hasOwnProperty(name)) {
          if (top.content.length && top.content[0].isInline && this.open) {
            this.open--;
            top = this.top;
          }
          sync = true;
          if (!top.type) this.needsBlock = true;
        } else if (!dom.firstChild) {
          this.leafFallback(dom, marks);
          return;
        }
        var innerMarks = rule && rule.skip ? marks : this.readStyles(dom, marks);
        if (innerMarks) this.addAll(dom, innerMarks);
        if (sync) this.sync(top);
        this.needsBlock = oldNeedsBlock;
      } else {
        var _innerMarks = this.readStyles(dom, marks);
        if (_innerMarks) this.addElementByRule(dom, rule, _innerMarks, rule.consuming === false ? ruleID : undefined);
      }
    }
  }, {
    key: "leafFallback",
    value: function leafFallback(dom, marks) {
      if (dom.nodeName == "BR" && this.top.type && this.top.type.inlineContent) this.addTextNode(dom.ownerDocument.createTextNode("\n"), marks);
    }
  }, {
    key: "ignoreFallback",
    value: function ignoreFallback(dom, marks) {
      if (dom.nodeName == "BR" && (!this.top.type || !this.top.type.inlineContent)) this.findPlace(this.parser.schema.text("-"), marks);
    }
  }, {
    key: "readStyles",
    value: function readStyles(dom, marks) {
      var _this3 = this;
      var styles = dom.style;
      if (styles && styles.length) for (var i = 0; i < this.parser.matchedStyles.length; i++) {
        var name = this.parser.matchedStyles[i],
          value = styles.getPropertyValue(name);
        if (value) {
          var _loop4 = function _loop4(_after) {
              var rule = _this3.parser.matchStyle(name, value, _this3, _after);
              if (!rule) {
                after = _after;
                return 0;
              }
              if (rule.ignore) return {
                v: null
              };
              if (rule.clearMark) marks = marks.filter(function (m) {
                return !rule.clearMark(m);
              });else marks = marks.concat(_this3.parser.schema.marks[rule.mark].create(rule.attrs));
              if (rule.consuming === false) _after = rule;else {
                after = _after;
                return 0;
              }
              after = _after;
            },
            _ret;
          for (var after = undefined;;) {
            _ret = _loop4(after);
            if (_ret === 0) break;
            if (_ret) return _ret.v;
          }
        }
      }
      return marks;
    }
  }, {
    key: "addElementByRule",
    value: function addElementByRule(dom, rule, marks, continueAfter) {
      var _this4 = this;
      var sync, nodeType;
      if (rule.node) {
        nodeType = this.parser.schema.nodes[rule.node];
        if (!nodeType.isLeaf) {
          var inner = this.enter(nodeType, rule.attrs || null, marks, rule.preserveWhitespace);
          if (inner) {
            sync = true;
            marks = inner;
          }
        } else if (!this.insertNode(nodeType.create(rule.attrs), marks)) {
          this.leafFallback(dom, marks);
        }
      } else {
        var markType = this.parser.schema.marks[rule.mark];
        marks = marks.concat(markType.create(rule.attrs));
      }
      var startIn = this.top;
      if (nodeType && nodeType.isLeaf) {
        this.findInside(dom);
      } else if (continueAfter) {
        this.addElement(dom, marks, continueAfter);
      } else if (rule.getContent) {
        this.findInside(dom);
        rule.getContent(dom, this.parser.schema).forEach(function (node) {
          return _this4.insertNode(node, marks);
        });
      } else {
        var contentDOM = dom;
        if (typeof rule.contentElement == "string") contentDOM = dom.querySelector(rule.contentElement);else if (typeof rule.contentElement == "function") contentDOM = rule.contentElement(dom);else if (rule.contentElement) contentDOM = rule.contentElement;
        this.findAround(dom, contentDOM, true);
        this.addAll(contentDOM, marks);
      }
      if (sync && this.sync(startIn)) this.open--;
    }
  }, {
    key: "addAll",
    value: function addAll(parent, marks, startIndex, endIndex) {
      var index = startIndex || 0;
      for (var dom = startIndex ? parent.childNodes[startIndex] : parent.firstChild, end = endIndex == null ? null : parent.childNodes[endIndex]; dom != end; dom = dom.nextSibling, ++index) {
        this.findAtPoint(parent, index);
        this.addDOM(dom, marks);
      }
      this.findAtPoint(parent, index);
    }
  }, {
    key: "findPlace",
    value: function findPlace(node, marks) {
      var route, sync;
      for (var depth = this.open; depth >= 0; depth--) {
        var cx = this.nodes[depth];
        var _found2 = cx.findWrapping(node);
        if (_found2 && (!route || route.length > _found2.length)) {
          route = _found2;
          sync = cx;
          if (!_found2.length) break;
        }
        if (cx.solid) break;
      }
      if (!route) return null;
      this.sync(sync);
      for (var i = 0; i < route.length; i++) marks = this.enterInner(route[i], null, marks, false);
      return marks;
    }
  }, {
    key: "insertNode",
    value: function insertNode(node, marks) {
      if (node.isInline && this.needsBlock && !this.top.type) {
        var block = this.textblockFromContext();
        if (block) marks = this.enterInner(block, null, marks);
      }
      var innerMarks = this.findPlace(node, marks);
      if (innerMarks) {
        this.closeExtra();
        var top = this.top;
        if (top.match) top.match = top.match.matchType(node.type);
        var nodeMarks = Mark.none;
        var _iterator = _createForOfIteratorHelper(innerMarks.concat(node.marks)),
          _step;
        try {
          for (_iterator.s(); !(_step = _iterator.n()).done;) {
            var m = _step.value;
            if (top.type ? top.type.allowsMarkType(m.type) : markMayApply(m.type, node.type)) nodeMarks = m.addToSet(nodeMarks);
          }
        } catch (err) {
          _iterator.e(err);
        } finally {
          _iterator.f();
        }
        top.content.push(node.mark(nodeMarks));
        return true;
      }
      return false;
    }
  }, {
    key: "enter",
    value: function enter(type, attrs, marks, preserveWS) {
      var innerMarks = this.findPlace(type.create(attrs), marks);
      if (innerMarks) innerMarks = this.enterInner(type, attrs, marks, true, preserveWS);
      return innerMarks;
    }
  }, {
    key: "enterInner",
    value: function enterInner(type, attrs, marks) {
      var solid = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : false;
      var preserveWS = arguments.length > 4 ? arguments[4] : undefined;
      this.closeExtra();
      var top = this.top;
      top.match = top.match && top.match.matchType(type);
      var options = wsOptionsFor(type, preserveWS, top.options);
      if (top.options & OPT_OPEN_LEFT && top.content.length == 0) options |= OPT_OPEN_LEFT;
      var applyMarks = Mark.none;
      marks = marks.filter(function (m) {
        if (top.type ? top.type.allowsMarkType(m.type) : markMayApply(m.type, type)) {
          applyMarks = m.addToSet(applyMarks);
          return false;
        }
        return true;
      });
      this.nodes.push(new NodeContext(type, attrs, applyMarks, solid, null, options));
      this.open++;
      return marks;
    }
  }, {
    key: "closeExtra",
    value: function closeExtra() {
      var openEnd = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;
      var i = this.nodes.length - 1;
      if (i > this.open) {
        for (; i > this.open; i--) this.nodes[i - 1].content.push(this.nodes[i].finish(openEnd));
        this.nodes.length = this.open + 1;
      }
    }
  }, {
    key: "finish",
    value: function finish() {
      this.open = 0;
      this.closeExtra(this.isOpen);
      return this.nodes[0].finish(this.isOpen || this.options.topOpen);
    }
  }, {
    key: "sync",
    value: function sync(to) {
      for (var i = this.open; i >= 0; i--) if (this.nodes[i] == to) {
        this.open = i;
        return true;
      }
      return false;
    }
  }, {
    key: "currentPos",
    get: function get() {
      this.closeExtra();
      var pos = 0;
      for (var i = this.open; i >= 0; i--) {
        var content = this.nodes[i].content;
        for (var j = content.length - 1; j >= 0; j--) pos += content[j].nodeSize;
        if (i) pos++;
      }
      return pos;
    }
  }, {
    key: "findAtPoint",
    value: function findAtPoint(parent, offset) {
      if (this.find) for (var i = 0; i < this.find.length; i++) {
        if (this.find[i].node == parent && this.find[i].offset == offset) this.find[i].pos = this.currentPos;
      }
    }
  }, {
    key: "findInside",
    value: function findInside(parent) {
      if (this.find) for (var i = 0; i < this.find.length; i++) {
        if (this.find[i].pos == null && parent.nodeType == 1 && parent.contains(this.find[i].node)) this.find[i].pos = this.currentPos;
      }
    }
  }, {
    key: "findAround",
    value: function findAround(parent, content, before) {
      if (parent != content && this.find) for (var i = 0; i < this.find.length; i++) {
        if (this.find[i].pos == null && parent.nodeType == 1 && parent.contains(this.find[i].node)) {
          var pos = content.compareDocumentPosition(this.find[i].node);
          if (pos & (before ? 2 : 4)) this.find[i].pos = this.currentPos;
        }
      }
    }
  }, {
    key: "findInText",
    value: function findInText(textNode) {
      if (this.find) for (var i = 0; i < this.find.length; i++) {
        if (this.find[i].node == textNode) this.find[i].pos = this.currentPos - (textNode.nodeValue.length - this.find[i].offset);
      }
    }
  }, {
    key: "matchesContext",
    value: function matchesContext(context) {
      var _this5 = this;
      if (context.indexOf("|") > -1) return context.split(/\s*\|\s*/).some(this.matchesContext, this);
      var parts = context.split("/");
      var option = this.options.context;
      var useRoot = !this.isOpen && (!option || option.parent.type == this.nodes[0].type);
      var minDepth = -(option ? option.depth + 1 : 0) + (useRoot ? 0 : 1);
      var match = function match(i, depth) {
        for (; i >= 0; i--) {
          var part = parts[i];
          if (part == "") {
            if (i == parts.length - 1 || i == 0) continue;
            for (; depth >= minDepth; depth--) if (match(i - 1, depth)) return true;
            return false;
          } else {
            var next = depth > 0 || depth == 0 && useRoot ? _this5.nodes[depth].type : option && depth >= minDepth ? option.node(depth - minDepth).type : null;
            if (!next || next.name != part && next.groups.indexOf(part) == -1) return false;
            depth--;
          }
        }
        return true;
      };
      return match(parts.length - 1, this.open);
    }
  }, {
    key: "textblockFromContext",
    value: function textblockFromContext() {
      var $context = this.options.context;
      if ($context) for (var d = $context.depth; d >= 0; d--) {
        var deflt = $context.node(d).contentMatchAt($context.indexAfter(d)).defaultType;
        if (deflt && deflt.isTextblock && deflt.defaultAttrs) return deflt;
      }
      for (var name in this.parser.schema.nodes) {
        var type = this.parser.schema.nodes[name];
        if (type.isTextblock && type.defaultAttrs) return type;
      }
    }
  }]);
  return ParseContext;
}();
function normalizeList(dom) {
  for (var child = dom.firstChild, prevItem = null; child; child = child.nextSibling) {
    var name = child.nodeType == 1 ? child.nodeName.toLowerCase() : null;
    if (name && listTags.hasOwnProperty(name) && prevItem) {
      prevItem.appendChild(child);
      child = prevItem;
    } else if (name == "li") {
      prevItem = child;
    } else if (name) {
      prevItem = null;
    }
  }
}
function matches(dom, selector) {
  return (dom.matches || dom.msMatchesSelector || dom.webkitMatchesSelector || dom.mozMatchesSelector).call(dom, selector);
}
function copy(obj) {
  var copy = {};
  for (var prop in obj) copy[prop] = obj[prop];
  return copy;
}
function markMayApply(markType, nodeType) {
  var nodes = nodeType.schema.nodes;
  var _loop5 = function _loop5() {
      var parent = nodes[name];
      if (!parent.allowsMarkType(markType)) return 0;
      var seen = [],
        scan = function scan(match) {
          seen.push(match);
          for (var i = 0; i < match.edgeCount; i++) {
            var _match$edge = match.edge(i),
              type = _match$edge.type,
              next = _match$edge.next;
            if (type == nodeType) return true;
            if (seen.indexOf(next) < 0 && scan(next)) return true;
          }
        };
      if (scan(parent.contentMatch)) return {
        v: true
      };
    },
    _ret2;
  for (var name in nodes) {
    _ret2 = _loop5();
    if (_ret2 === 0) continue;
    if (_ret2) return _ret2.v;
  }
}
var DOMSerializer = function () {
  function DOMSerializer(nodes, marks) {
    _classCallCheck(this, DOMSerializer);
    this.nodes = nodes;
    this.marks = marks;
  }
  _createClass(DOMSerializer, [{
    key: "serializeFragment",
    value: function serializeFragment(fragment) {
      var _this6 = this;
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var target = arguments.length > 2 ? arguments[2] : undefined;
      if (!target) target = doc(options).createDocumentFragment();
      var top = target,
        active = [];
      fragment.forEach(function (node) {
        if (active.length || node.marks.length) {
          var keep = 0,
            rendered = 0;
          while (keep < active.length && rendered < node.marks.length) {
            var next = node.marks[rendered];
            if (!_this6.marks[next.type.name]) {
              rendered++;
              continue;
            }
            if (!next.eq(active[keep][0]) || next.type.spec.spanning === false) break;
            keep++;
            rendered++;
          }
          while (keep < active.length) top = active.pop()[1];
          while (rendered < node.marks.length) {
            var add = node.marks[rendered++];
            var markDOM = _this6.serializeMark(add, node.isInline, options);
            if (markDOM) {
              active.push([add, top]);
              top.appendChild(markDOM.dom);
              top = markDOM.contentDOM || markDOM.dom;
            }
          }
        }
        top.appendChild(_this6.serializeNodeInner(node, options));
      });
      return target;
    }
  }, {
    key: "serializeNodeInner",
    value: function serializeNodeInner(node, options) {
      var _renderSpec2 = _renderSpec(doc(options), this.nodes[node.type.name](node), null, node.attrs),
        dom = _renderSpec2.dom,
        contentDOM = _renderSpec2.contentDOM;
      if (contentDOM) {
        if (node.isLeaf) throw new RangeError("Content hole not allowed in a leaf node spec");
        this.serializeFragment(node.content, options, contentDOM);
      }
      return dom;
    }
  }, {
    key: "serializeNode",
    value: function serializeNode(node) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var dom = this.serializeNodeInner(node, options);
      for (var i = node.marks.length - 1; i >= 0; i--) {
        var wrap = this.serializeMark(node.marks[i], node.isInline, options);
        if (wrap) {
          (wrap.contentDOM || wrap.dom).appendChild(dom);
          dom = wrap.dom;
        }
      }
      return dom;
    }
  }, {
    key: "serializeMark",
    value: function serializeMark(mark, inline) {
      var options = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
      var toDOM = this.marks[mark.type.name];
      return toDOM && _renderSpec(doc(options), toDOM(mark, inline), null, mark.attrs);
    }
  }], [{
    key: "renderSpec",
    value: function renderSpec(doc, structure) {
      var xmlNS = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;
      var blockArraysIn = arguments.length > 3 ? arguments[3] : undefined;
      return _renderSpec(doc, structure, xmlNS, blockArraysIn);
    }
  }, {
    key: "fromSchema",
    value: function fromSchema(schema) {
      return schema.cached.domSerializer || (schema.cached.domSerializer = new DOMSerializer(this.nodesFromSchema(schema), this.marksFromSchema(schema)));
    }
  }, {
    key: "nodesFromSchema",
    value: function nodesFromSchema(schema) {
      var result = gatherToDOM(schema.nodes);
      if (!result.text) result.text = function (node) {
        return node.text;
      };
      return result;
    }
  }, {
    key: "marksFromSchema",
    value: function marksFromSchema(schema) {
      return gatherToDOM(schema.marks);
    }
  }]);
  return DOMSerializer;
}();
function gatherToDOM(obj) {
  var result = {};
  for (var name in obj) {
    var toDOM = obj[name].spec.toDOM;
    if (toDOM) result[name] = toDOM;
  }
  return result;
}
function doc(options) {
  return options.document || window.document;
}
var suspiciousAttributeCache = new WeakMap();
function suspiciousAttributes(attrs) {
  var value = suspiciousAttributeCache.get(attrs);
  if (value === undefined) suspiciousAttributeCache.set(attrs, value = suspiciousAttributesInner(attrs));
  return value;
}
function suspiciousAttributesInner(attrs) {
  var result = null;
  function scan(value) {
    if (value && _typeof(value) == "object") {
      if (Array.isArray(value)) {
        if (typeof value[0] == "string") {
          if (!result) result = [];
          result.push(value);
        } else {
          for (var i = 0; i < value.length; i++) scan(value[i]);
        }
      } else {
        for (var prop in value) scan(value[prop]);
      }
    }
  }
  scan(attrs);
  return result;
}
function _renderSpec(doc, structure, xmlNS, blockArraysIn) {
  if (typeof structure == "string") return {
    dom: doc.createTextNode(structure)
  };
  if (structure.nodeType != null) return {
    dom: structure
  };
  if (structure.dom && structure.dom.nodeType != null) return structure;
  var tagName = structure[0],
    suspicious;
  if (typeof tagName != "string") throw new RangeError("Invalid array passed to renderSpec");
  if (blockArraysIn && (suspicious = suspiciousAttributes(blockArraysIn)) && suspicious.indexOf(structure) > -1) throw new RangeError("Using an array from an attribute object as a DOM spec. This may be an attempted cross site scripting attack.");
  var space = tagName.indexOf(" ");
  if (space > 0) {
    xmlNS = tagName.slice(0, space);
    tagName = tagName.slice(space + 1);
  }
  var contentDOM;
  var dom = xmlNS ? doc.createElementNS(xmlNS, tagName) : doc.createElement(tagName);
  var attrs = structure[1],
    start = 1;
  if (attrs && _typeof(attrs) == "object" && attrs.nodeType == null && !Array.isArray(attrs)) {
    start = 2;
    for (var name in attrs) if (attrs[name] != null) {
      var _space = name.indexOf(" ");
      if (_space > 0) dom.setAttributeNS(name.slice(0, _space), name.slice(_space + 1), attrs[name]);else dom.setAttribute(name, attrs[name]);
    }
  }
  for (var i = start; i < structure.length; i++) {
    var child = structure[i];
    if (child === 0) {
      if (i < structure.length - 1 || i > start) throw new RangeError("Content hole must be the only child of its parent node");
      return {
        dom: dom,
        contentDOM: dom
      };
    } else {
      var _renderSpec3 = _renderSpec(doc, child, xmlNS, blockArraysIn),
        inner = _renderSpec3.dom,
        innerContent = _renderSpec3.contentDOM;
      dom.appendChild(inner);
      if (innerContent) {
        if (contentDOM) throw new RangeError("Multiple content holes");
        contentDOM = innerContent;
      }
    }
  }
  return {
    dom: dom,
    contentDOM: contentDOM
  };
}
exports.ContentMatch = ContentMatch;
exports.DOMParser = DOMParser;
exports.DOMSerializer = DOMSerializer;
exports.Fragment = Fragment;
exports.Mark = Mark;
exports.MarkType = MarkType;
exports.Node = Node;
exports.NodeRange = NodeRange;
exports.NodeType = NodeType;
exports.ReplaceError = ReplaceError;
exports.ResolvedPos = ResolvedPos;
exports.Schema = Schema;
exports.Slice = Slice;
