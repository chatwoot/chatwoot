'use strict';

function _wrapNativeSuper(Class) { var _cache = typeof Map === "function" ? new Map() : undefined; _wrapNativeSuper = function _wrapNativeSuper(Class) { if (Class === null || !_isNativeFunction(Class)) return Class; if (typeof Class !== "function") { throw new TypeError("Super expression must either be null or a function"); } if (typeof _cache !== "undefined") { if (_cache.has(Class)) return _cache.get(Class); _cache.set(Class, Wrapper); } function Wrapper() { return _construct(Class, arguments, _getPrototypeOf(this).constructor); } Wrapper.prototype = Object.create(Class.prototype, { constructor: { value: Wrapper, enumerable: false, writable: true, configurable: true } }); return _setPrototypeOf(Wrapper, Class); }; return _wrapNativeSuper(Class); }
function _construct(Parent, args, Class) { if (_isNativeReflectConstruct()) { _construct = Reflect.construct.bind(); } else { _construct = function _construct(Parent, args, Class) { var a = [null]; a.push.apply(a, args); var Constructor = Function.bind.apply(Parent, a); var instance = new Constructor(); if (Class) _setPrototypeOf(instance, Class.prototype); return instance; }; } return _construct.apply(null, arguments); }
function _isNativeFunction(fn) { try { return Function.toString.call(fn).indexOf("[native code]") !== -1; } catch (e) { return typeof fn === "function"; } }
function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }
function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }
function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }
function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }
function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }
function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }
function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }
function _typeof(o) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (o) { return typeof o; } : function (o) { return o && "function" == typeof Symbol && o.constructor === Symbol && o !== Symbol.prototype ? "symbol" : typeof o; }, _typeof(o); }
function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, _toPropertyKey(descriptor.key), descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
function _toPropertyKey(arg) { var key = _toPrimitive(arg, "string"); return _typeof(key) === "symbol" ? key : String(key); }
function _toPrimitive(input, hint) { if (_typeof(input) !== "object" || input === null) return input; var prim = input[Symbol.toPrimitive]; if (prim !== undefined) { var res = prim.call(input, hint || "default"); if (_typeof(res) !== "object") return res; throw new TypeError("@@toPrimitive must return a primitive value."); } return (hint === "string" ? String : Number)(input); }
var prosemirrorModel = require('prosemirror-model');
var lower16 = 0xffff;
var factor16 = Math.pow(2, 16);
function makeRecover(index, offset) {
  return index + offset * factor16;
}
function recoverIndex(value) {
  return value & lower16;
}
function recoverOffset(value) {
  return (value - (value & lower16)) / factor16;
}
var DEL_BEFORE = 1,
  DEL_AFTER = 2,
  DEL_ACROSS = 4,
  DEL_SIDE = 8;
var MapResult = function () {
  function MapResult(pos, delInfo, recover) {
    _classCallCheck(this, MapResult);
    this.pos = pos;
    this.delInfo = delInfo;
    this.recover = recover;
  }
  _createClass(MapResult, [{
    key: "deleted",
    get: function get() {
      return (this.delInfo & DEL_SIDE) > 0;
    }
  }, {
    key: "deletedBefore",
    get: function get() {
      return (this.delInfo & (DEL_BEFORE | DEL_ACROSS)) > 0;
    }
  }, {
    key: "deletedAfter",
    get: function get() {
      return (this.delInfo & (DEL_AFTER | DEL_ACROSS)) > 0;
    }
  }, {
    key: "deletedAcross",
    get: function get() {
      return (this.delInfo & DEL_ACROSS) > 0;
    }
  }]);
  return MapResult;
}();
var StepMap = function () {
  function StepMap(ranges) {
    var inverted = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
    _classCallCheck(this, StepMap);
    this.ranges = ranges;
    this.inverted = inverted;
    if (!ranges.length && StepMap.empty) return StepMap.empty;
  }
  _createClass(StepMap, [{
    key: "recover",
    value: function recover(value) {
      var diff = 0,
        index = recoverIndex(value);
      if (!this.inverted) for (var i = 0; i < index; i++) diff += this.ranges[i * 3 + 2] - this.ranges[i * 3 + 1];
      return this.ranges[index * 3] + diff + recoverOffset(value);
    }
  }, {
    key: "mapResult",
    value: function mapResult(pos) {
      var assoc = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;
      return this._map(pos, assoc, false);
    }
  }, {
    key: "map",
    value: function map(pos) {
      var assoc = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;
      return this._map(pos, assoc, true);
    }
  }, {
    key: "_map",
    value: function _map(pos, assoc, simple) {
      var diff = 0,
        oldIndex = this.inverted ? 2 : 1,
        newIndex = this.inverted ? 1 : 2;
      for (var i = 0; i < this.ranges.length; i += 3) {
        var start = this.ranges[i] - (this.inverted ? diff : 0);
        if (start > pos) break;
        var oldSize = this.ranges[i + oldIndex],
          newSize = this.ranges[i + newIndex],
          end = start + oldSize;
        if (pos <= end) {
          var side = !oldSize ? assoc : pos == start ? -1 : pos == end ? 1 : assoc;
          var result = start + diff + (side < 0 ? 0 : newSize);
          if (simple) return result;
          var recover = pos == (assoc < 0 ? start : end) ? null : makeRecover(i / 3, pos - start);
          var del = pos == start ? DEL_AFTER : pos == end ? DEL_BEFORE : DEL_ACROSS;
          if (assoc < 0 ? pos != start : pos != end) del |= DEL_SIDE;
          return new MapResult(result, del, recover);
        }
        diff += newSize - oldSize;
      }
      return simple ? pos + diff : new MapResult(pos + diff, 0, null);
    }
  }, {
    key: "touches",
    value: function touches(pos, recover) {
      var diff = 0,
        index = recoverIndex(recover);
      var oldIndex = this.inverted ? 2 : 1,
        newIndex = this.inverted ? 1 : 2;
      for (var i = 0; i < this.ranges.length; i += 3) {
        var start = this.ranges[i] - (this.inverted ? diff : 0);
        if (start > pos) break;
        var oldSize = this.ranges[i + oldIndex],
          end = start + oldSize;
        if (pos <= end && i == index * 3) return true;
        diff += this.ranges[i + newIndex] - oldSize;
      }
      return false;
    }
  }, {
    key: "forEach",
    value: function forEach(f) {
      var oldIndex = this.inverted ? 2 : 1,
        newIndex = this.inverted ? 1 : 2;
      for (var i = 0, diff = 0; i < this.ranges.length; i += 3) {
        var start = this.ranges[i],
          oldStart = start - (this.inverted ? diff : 0),
          newStart = start + (this.inverted ? 0 : diff);
        var oldSize = this.ranges[i + oldIndex],
          newSize = this.ranges[i + newIndex];
        f(oldStart, oldStart + oldSize, newStart, newStart + newSize);
        diff += newSize - oldSize;
      }
    }
  }, {
    key: "invert",
    value: function invert() {
      return new StepMap(this.ranges, !this.inverted);
    }
  }, {
    key: "toString",
    value: function toString() {
      return (this.inverted ? "-" : "") + JSON.stringify(this.ranges);
    }
  }], [{
    key: "offset",
    value: function offset(n) {
      return n == 0 ? StepMap.empty : new StepMap(n < 0 ? [0, -n, 0] : [0, 0, n]);
    }
  }]);
  return StepMap;
}();
StepMap.empty = new StepMap([]);
var Mapping = function () {
  function Mapping() {
    var maps = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : [];
    var mirror = arguments.length > 1 ? arguments[1] : undefined;
    var from = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;
    var to = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : maps.length;
    _classCallCheck(this, Mapping);
    this.maps = maps;
    this.mirror = mirror;
    this.from = from;
    this.to = to;
  }
  _createClass(Mapping, [{
    key: "slice",
    value: function slice() {
      var from = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;
      var to = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : this.maps.length;
      return new Mapping(this.maps, this.mirror, from, to);
    }
  }, {
    key: "copy",
    value: function copy() {
      return new Mapping(this.maps.slice(), this.mirror && this.mirror.slice(), this.from, this.to);
    }
  }, {
    key: "appendMap",
    value: function appendMap(map, mirrors) {
      this.to = this.maps.push(map);
      if (mirrors != null) this.setMirror(this.maps.length - 1, mirrors);
    }
  }, {
    key: "appendMapping",
    value: function appendMapping(mapping) {
      for (var i = 0, startSize = this.maps.length; i < mapping.maps.length; i++) {
        var mirr = mapping.getMirror(i);
        this.appendMap(mapping.maps[i], mirr != null && mirr < i ? startSize + mirr : undefined);
      }
    }
  }, {
    key: "getMirror",
    value: function getMirror(n) {
      if (this.mirror) for (var i = 0; i < this.mirror.length; i++) if (this.mirror[i] == n) return this.mirror[i + (i % 2 ? -1 : 1)];
    }
  }, {
    key: "setMirror",
    value: function setMirror(n, m) {
      if (!this.mirror) this.mirror = [];
      this.mirror.push(n, m);
    }
  }, {
    key: "appendMappingInverted",
    value: function appendMappingInverted(mapping) {
      for (var i = mapping.maps.length - 1, totalSize = this.maps.length + mapping.maps.length; i >= 0; i--) {
        var mirr = mapping.getMirror(i);
        this.appendMap(mapping.maps[i].invert(), mirr != null && mirr > i ? totalSize - mirr - 1 : undefined);
      }
    }
  }, {
    key: "invert",
    value: function invert() {
      var inverse = new Mapping();
      inverse.appendMappingInverted(this);
      return inverse;
    }
  }, {
    key: "map",
    value: function map(pos) {
      var assoc = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;
      if (this.mirror) return this._map(pos, assoc, true);
      for (var i = this.from; i < this.to; i++) pos = this.maps[i].map(pos, assoc);
      return pos;
    }
  }, {
    key: "mapResult",
    value: function mapResult(pos) {
      var assoc = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;
      return this._map(pos, assoc, false);
    }
  }, {
    key: "_map",
    value: function _map(pos, assoc, simple) {
      var delInfo = 0;
      for (var i = this.from; i < this.to; i++) {
        var map = this.maps[i],
          result = map.mapResult(pos, assoc);
        if (result.recover != null) {
          var corr = this.getMirror(i);
          if (corr != null && corr > i && corr < this.to) {
            i = corr;
            pos = this.maps[corr].recover(result.recover);
            continue;
          }
        }
        delInfo |= result.delInfo;
        pos = result.pos;
      }
      return simple ? pos : new MapResult(pos, delInfo, null);
    }
  }]);
  return Mapping;
}();
var stepsByID = Object.create(null);
var Step = function () {
  function Step() {
    _classCallCheck(this, Step);
  }
  _createClass(Step, [{
    key: "getMap",
    value: function getMap() {
      return StepMap.empty;
    }
  }, {
    key: "merge",
    value: function merge(other) {
      return null;
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (!json || !json.stepType) throw new RangeError("Invalid input for Step.fromJSON");
      var type = stepsByID[json.stepType];
      if (!type) throw new RangeError("No step type ".concat(json.stepType, " defined"));
      return type.fromJSON(schema, json);
    }
  }, {
    key: "jsonID",
    value: function jsonID(id, stepClass) {
      if (id in stepsByID) throw new RangeError("Duplicate use of step JSON ID " + id);
      stepsByID[id] = stepClass;
      stepClass.prototype.jsonID = id;
      return stepClass;
    }
  }]);
  return Step;
}();
var StepResult = function () {
  function StepResult(doc, failed) {
    _classCallCheck(this, StepResult);
    this.doc = doc;
    this.failed = failed;
  }
  _createClass(StepResult, null, [{
    key: "ok",
    value: function ok(doc) {
      return new StepResult(doc, null);
    }
  }, {
    key: "fail",
    value: function fail(message) {
      return new StepResult(null, message);
    }
  }, {
    key: "fromReplace",
    value: function fromReplace(doc, from, to, slice) {
      try {
        return StepResult.ok(doc.replace(from, to, slice));
      } catch (e) {
        if (e instanceof prosemirrorModel.ReplaceError) return StepResult.fail(e.message);
        throw e;
      }
    }
  }]);
  return StepResult;
}();
function mapFragment(fragment, f, parent) {
  var mapped = [];
  for (var i = 0; i < fragment.childCount; i++) {
    var child = fragment.child(i);
    if (child.content.size) child = child.copy(mapFragment(child.content, f, child));
    if (child.isInline) child = f(child, parent, i);
    mapped.push(child);
  }
  return prosemirrorModel.Fragment.fromArray(mapped);
}
var AddMarkStep = function (_Step) {
  _inherits(AddMarkStep, _Step);
  var _super = _createSuper(AddMarkStep);
  function AddMarkStep(from, to, mark) {
    var _this;
    _classCallCheck(this, AddMarkStep);
    _this = _super.call(this);
    _this.from = from;
    _this.to = to;
    _this.mark = mark;
    return _this;
  }
  _createClass(AddMarkStep, [{
    key: "apply",
    value: function apply(doc) {
      var _this2 = this;
      var oldSlice = doc.slice(this.from, this.to),
        $from = doc.resolve(this.from);
      var parent = $from.node($from.sharedDepth(this.to));
      var slice = new prosemirrorModel.Slice(mapFragment(oldSlice.content, function (node, parent) {
        if (!node.isAtom || !parent.type.allowsMarkType(_this2.mark.type)) return node;
        return node.mark(_this2.mark.addToSet(node.marks));
      }, parent), oldSlice.openStart, oldSlice.openEnd);
      return StepResult.fromReplace(doc, this.from, this.to, slice);
    }
  }, {
    key: "invert",
    value: function invert() {
      return new RemoveMarkStep(this.from, this.to, this.mark);
    }
  }, {
    key: "map",
    value: function map(mapping) {
      var from = mapping.mapResult(this.from, 1),
        to = mapping.mapResult(this.to, -1);
      if (from.deleted && to.deleted || from.pos >= to.pos) return null;
      return new AddMarkStep(from.pos, to.pos, this.mark);
    }
  }, {
    key: "merge",
    value: function merge(other) {
      if (other instanceof AddMarkStep && other.mark.eq(this.mark) && this.from <= other.to && this.to >= other.from) return new AddMarkStep(Math.min(this.from, other.from), Math.max(this.to, other.to), this.mark);
      return null;
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        stepType: "addMark",
        mark: this.mark.toJSON(),
        from: this.from,
        to: this.to
      };
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (typeof json.from != "number" || typeof json.to != "number") throw new RangeError("Invalid input for AddMarkStep.fromJSON");
      return new AddMarkStep(json.from, json.to, schema.markFromJSON(json.mark));
    }
  }]);
  return AddMarkStep;
}(Step);
Step.jsonID("addMark", AddMarkStep);
var RemoveMarkStep = function (_Step2) {
  _inherits(RemoveMarkStep, _Step2);
  var _super2 = _createSuper(RemoveMarkStep);
  function RemoveMarkStep(from, to, mark) {
    var _this3;
    _classCallCheck(this, RemoveMarkStep);
    _this3 = _super2.call(this);
    _this3.from = from;
    _this3.to = to;
    _this3.mark = mark;
    return _this3;
  }
  _createClass(RemoveMarkStep, [{
    key: "apply",
    value: function apply(doc) {
      var _this4 = this;
      var oldSlice = doc.slice(this.from, this.to);
      var slice = new prosemirrorModel.Slice(mapFragment(oldSlice.content, function (node) {
        return node.mark(_this4.mark.removeFromSet(node.marks));
      }, doc), oldSlice.openStart, oldSlice.openEnd);
      return StepResult.fromReplace(doc, this.from, this.to, slice);
    }
  }, {
    key: "invert",
    value: function invert() {
      return new AddMarkStep(this.from, this.to, this.mark);
    }
  }, {
    key: "map",
    value: function map(mapping) {
      var from = mapping.mapResult(this.from, 1),
        to = mapping.mapResult(this.to, -1);
      if (from.deleted && to.deleted || from.pos >= to.pos) return null;
      return new RemoveMarkStep(from.pos, to.pos, this.mark);
    }
  }, {
    key: "merge",
    value: function merge(other) {
      if (other instanceof RemoveMarkStep && other.mark.eq(this.mark) && this.from <= other.to && this.to >= other.from) return new RemoveMarkStep(Math.min(this.from, other.from), Math.max(this.to, other.to), this.mark);
      return null;
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        stepType: "removeMark",
        mark: this.mark.toJSON(),
        from: this.from,
        to: this.to
      };
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (typeof json.from != "number" || typeof json.to != "number") throw new RangeError("Invalid input for RemoveMarkStep.fromJSON");
      return new RemoveMarkStep(json.from, json.to, schema.markFromJSON(json.mark));
    }
  }]);
  return RemoveMarkStep;
}(Step);
Step.jsonID("removeMark", RemoveMarkStep);
var AddNodeMarkStep = function (_Step3) {
  _inherits(AddNodeMarkStep, _Step3);
  var _super3 = _createSuper(AddNodeMarkStep);
  function AddNodeMarkStep(pos, mark) {
    var _this5;
    _classCallCheck(this, AddNodeMarkStep);
    _this5 = _super3.call(this);
    _this5.pos = pos;
    _this5.mark = mark;
    return _this5;
  }
  _createClass(AddNodeMarkStep, [{
    key: "apply",
    value: function apply(doc) {
      var node = doc.nodeAt(this.pos);
      if (!node) return StepResult.fail("No node at mark step's position");
      var updated = node.type.create(node.attrs, null, this.mark.addToSet(node.marks));
      return StepResult.fromReplace(doc, this.pos, this.pos + 1, new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(updated), 0, node.isLeaf ? 0 : 1));
    }
  }, {
    key: "invert",
    value: function invert(doc) {
      var node = doc.nodeAt(this.pos);
      if (node) {
        var newSet = this.mark.addToSet(node.marks);
        if (newSet.length == node.marks.length) {
          for (var i = 0; i < node.marks.length; i++) if (!node.marks[i].isInSet(newSet)) return new AddNodeMarkStep(this.pos, node.marks[i]);
          return new AddNodeMarkStep(this.pos, this.mark);
        }
      }
      return new RemoveNodeMarkStep(this.pos, this.mark);
    }
  }, {
    key: "map",
    value: function map(mapping) {
      var pos = mapping.mapResult(this.pos, 1);
      return pos.deletedAfter ? null : new AddNodeMarkStep(pos.pos, this.mark);
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        stepType: "addNodeMark",
        pos: this.pos,
        mark: this.mark.toJSON()
      };
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (typeof json.pos != "number") throw new RangeError("Invalid input for AddNodeMarkStep.fromJSON");
      return new AddNodeMarkStep(json.pos, schema.markFromJSON(json.mark));
    }
  }]);
  return AddNodeMarkStep;
}(Step);
Step.jsonID("addNodeMark", AddNodeMarkStep);
var RemoveNodeMarkStep = function (_Step4) {
  _inherits(RemoveNodeMarkStep, _Step4);
  var _super4 = _createSuper(RemoveNodeMarkStep);
  function RemoveNodeMarkStep(pos, mark) {
    var _this6;
    _classCallCheck(this, RemoveNodeMarkStep);
    _this6 = _super4.call(this);
    _this6.pos = pos;
    _this6.mark = mark;
    return _this6;
  }
  _createClass(RemoveNodeMarkStep, [{
    key: "apply",
    value: function apply(doc) {
      var node = doc.nodeAt(this.pos);
      if (!node) return StepResult.fail("No node at mark step's position");
      var updated = node.type.create(node.attrs, null, this.mark.removeFromSet(node.marks));
      return StepResult.fromReplace(doc, this.pos, this.pos + 1, new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(updated), 0, node.isLeaf ? 0 : 1));
    }
  }, {
    key: "invert",
    value: function invert(doc) {
      var node = doc.nodeAt(this.pos);
      if (!node || !this.mark.isInSet(node.marks)) return this;
      return new AddNodeMarkStep(this.pos, this.mark);
    }
  }, {
    key: "map",
    value: function map(mapping) {
      var pos = mapping.mapResult(this.pos, 1);
      return pos.deletedAfter ? null : new RemoveNodeMarkStep(pos.pos, this.mark);
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        stepType: "removeNodeMark",
        pos: this.pos,
        mark: this.mark.toJSON()
      };
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (typeof json.pos != "number") throw new RangeError("Invalid input for RemoveNodeMarkStep.fromJSON");
      return new RemoveNodeMarkStep(json.pos, schema.markFromJSON(json.mark));
    }
  }]);
  return RemoveNodeMarkStep;
}(Step);
Step.jsonID("removeNodeMark", RemoveNodeMarkStep);
var ReplaceStep = function (_Step5) {
  _inherits(ReplaceStep, _Step5);
  var _super5 = _createSuper(ReplaceStep);
  function ReplaceStep(from, to, slice) {
    var _this7;
    var structure = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : false;
    _classCallCheck(this, ReplaceStep);
    _this7 = _super5.call(this);
    _this7.from = from;
    _this7.to = to;
    _this7.slice = slice;
    _this7.structure = structure;
    return _this7;
  }
  _createClass(ReplaceStep, [{
    key: "apply",
    value: function apply(doc) {
      if (this.structure && contentBetween(doc, this.from, this.to)) return StepResult.fail("Structure replace would overwrite content");
      return StepResult.fromReplace(doc, this.from, this.to, this.slice);
    }
  }, {
    key: "getMap",
    value: function getMap() {
      return new StepMap([this.from, this.to - this.from, this.slice.size]);
    }
  }, {
    key: "invert",
    value: function invert(doc) {
      return new ReplaceStep(this.from, this.from + this.slice.size, doc.slice(this.from, this.to));
    }
  }, {
    key: "map",
    value: function map(mapping) {
      var from = mapping.mapResult(this.from, 1),
        to = mapping.mapResult(this.to, -1);
      if (from.deletedAcross && to.deletedAcross) return null;
      return new ReplaceStep(from.pos, Math.max(from.pos, to.pos), this.slice);
    }
  }, {
    key: "merge",
    value: function merge(other) {
      if (!(other instanceof ReplaceStep) || other.structure || this.structure) return null;
      if (this.from + this.slice.size == other.from && !this.slice.openEnd && !other.slice.openStart) {
        var slice = this.slice.size + other.slice.size == 0 ? prosemirrorModel.Slice.empty : new prosemirrorModel.Slice(this.slice.content.append(other.slice.content), this.slice.openStart, other.slice.openEnd);
        return new ReplaceStep(this.from, this.to + (other.to - other.from), slice, this.structure);
      } else if (other.to == this.from && !this.slice.openStart && !other.slice.openEnd) {
        var _slice = this.slice.size + other.slice.size == 0 ? prosemirrorModel.Slice.empty : new prosemirrorModel.Slice(other.slice.content.append(this.slice.content), other.slice.openStart, this.slice.openEnd);
        return new ReplaceStep(other.from, this.to, _slice, this.structure);
      } else {
        return null;
      }
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      var json = {
        stepType: "replace",
        from: this.from,
        to: this.to
      };
      if (this.slice.size) json.slice = this.slice.toJSON();
      if (this.structure) json.structure = true;
      return json;
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (typeof json.from != "number" || typeof json.to != "number") throw new RangeError("Invalid input for ReplaceStep.fromJSON");
      return new ReplaceStep(json.from, json.to, prosemirrorModel.Slice.fromJSON(schema, json.slice), !!json.structure);
    }
  }]);
  return ReplaceStep;
}(Step);
Step.jsonID("replace", ReplaceStep);
var ReplaceAroundStep = function (_Step6) {
  _inherits(ReplaceAroundStep, _Step6);
  var _super6 = _createSuper(ReplaceAroundStep);
  function ReplaceAroundStep(from, to, gapFrom, gapTo, slice, insert) {
    var _this8;
    var structure = arguments.length > 6 && arguments[6] !== undefined ? arguments[6] : false;
    _classCallCheck(this, ReplaceAroundStep);
    _this8 = _super6.call(this);
    _this8.from = from;
    _this8.to = to;
    _this8.gapFrom = gapFrom;
    _this8.gapTo = gapTo;
    _this8.slice = slice;
    _this8.insert = insert;
    _this8.structure = structure;
    return _this8;
  }
  _createClass(ReplaceAroundStep, [{
    key: "apply",
    value: function apply(doc) {
      if (this.structure && (contentBetween(doc, this.from, this.gapFrom) || contentBetween(doc, this.gapTo, this.to))) return StepResult.fail("Structure gap-replace would overwrite content");
      var gap = doc.slice(this.gapFrom, this.gapTo);
      if (gap.openStart || gap.openEnd) return StepResult.fail("Gap is not a flat range");
      var inserted = this.slice.insertAt(this.insert, gap.content);
      if (!inserted) return StepResult.fail("Content does not fit in gap");
      return StepResult.fromReplace(doc, this.from, this.to, inserted);
    }
  }, {
    key: "getMap",
    value: function getMap() {
      return new StepMap([this.from, this.gapFrom - this.from, this.insert, this.gapTo, this.to - this.gapTo, this.slice.size - this.insert]);
    }
  }, {
    key: "invert",
    value: function invert(doc) {
      var gap = this.gapTo - this.gapFrom;
      return new ReplaceAroundStep(this.from, this.from + this.slice.size + gap, this.from + this.insert, this.from + this.insert + gap, doc.slice(this.from, this.to).removeBetween(this.gapFrom - this.from, this.gapTo - this.from), this.gapFrom - this.from, this.structure);
    }
  }, {
    key: "map",
    value: function map(mapping) {
      var from = mapping.mapResult(this.from, 1),
        to = mapping.mapResult(this.to, -1);
      var gapFrom = this.from == this.gapFrom ? from.pos : mapping.map(this.gapFrom, -1);
      var gapTo = this.to == this.gapTo ? to.pos : mapping.map(this.gapTo, 1);
      if (from.deletedAcross && to.deletedAcross || gapFrom < from.pos || gapTo > to.pos) return null;
      return new ReplaceAroundStep(from.pos, to.pos, gapFrom, gapTo, this.slice, this.insert, this.structure);
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      var json = {
        stepType: "replaceAround",
        from: this.from,
        to: this.to,
        gapFrom: this.gapFrom,
        gapTo: this.gapTo,
        insert: this.insert
      };
      if (this.slice.size) json.slice = this.slice.toJSON();
      if (this.structure) json.structure = true;
      return json;
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (typeof json.from != "number" || typeof json.to != "number" || typeof json.gapFrom != "number" || typeof json.gapTo != "number" || typeof json.insert != "number") throw new RangeError("Invalid input for ReplaceAroundStep.fromJSON");
      return new ReplaceAroundStep(json.from, json.to, json.gapFrom, json.gapTo, prosemirrorModel.Slice.fromJSON(schema, json.slice), json.insert, !!json.structure);
    }
  }]);
  return ReplaceAroundStep;
}(Step);
Step.jsonID("replaceAround", ReplaceAroundStep);
function contentBetween(doc, from, to) {
  var $from = doc.resolve(from),
    dist = to - from,
    depth = $from.depth;
  while (dist > 0 && depth > 0 && $from.indexAfter(depth) == $from.node(depth).childCount) {
    depth--;
    dist--;
  }
  if (dist > 0) {
    var next = $from.node(depth).maybeChild($from.indexAfter(depth));
    while (dist > 0) {
      if (!next || next.isLeaf) return true;
      next = next.firstChild;
      dist--;
    }
  }
  return false;
}
function _addMark(tr, from, to, mark) {
  var removed = [],
    added = [];
  var removing, adding;
  tr.doc.nodesBetween(from, to, function (node, pos, parent) {
    if (!node.isInline) return;
    var marks = node.marks;
    if (!mark.isInSet(marks) && parent.type.allowsMarkType(mark.type)) {
      var start = Math.max(pos, from),
        end = Math.min(pos + node.nodeSize, to);
      var newSet = mark.addToSet(marks);
      for (var i = 0; i < marks.length; i++) {
        if (!marks[i].isInSet(newSet)) {
          if (removing && removing.to == start && removing.mark.eq(marks[i])) removing.to = end;else removed.push(removing = new RemoveMarkStep(start, end, marks[i]));
        }
      }
      if (adding && adding.to == start) adding.to = end;else added.push(adding = new AddMarkStep(start, end, mark));
    }
  });
  removed.forEach(function (s) {
    return tr.step(s);
  });
  added.forEach(function (s) {
    return tr.step(s);
  });
}
function _removeMark(tr, from, to, mark) {
  var matched = [],
    step = 0;
  tr.doc.nodesBetween(from, to, function (node, pos) {
    if (!node.isInline) return;
    step++;
    var toRemove = null;
    if (mark instanceof prosemirrorModel.MarkType) {
      var set = node.marks,
        found;
      while (found = mark.isInSet(set)) {
        (toRemove || (toRemove = [])).push(found);
        set = found.removeFromSet(set);
      }
    } else if (mark) {
      if (mark.isInSet(node.marks)) toRemove = [mark];
    } else {
      toRemove = node.marks;
    }
    if (toRemove && toRemove.length) {
      var end = Math.min(pos + node.nodeSize, to);
      for (var i = 0; i < toRemove.length; i++) {
        var style = toRemove[i],
          _found = void 0;
        for (var j = 0; j < matched.length; j++) {
          var m = matched[j];
          if (m.step == step - 1 && style.eq(matched[j].style)) _found = m;
        }
        if (_found) {
          _found.to = end;
          _found.step = step;
        } else {
          matched.push({
            style: style,
            from: Math.max(pos, from),
            to: end,
            step: step
          });
        }
      }
    }
  });
  matched.forEach(function (m) {
    return tr.step(new RemoveMarkStep(m.from, m.to, m.style));
  });
}
function _clearIncompatible(tr, pos, parentType) {
  var match = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : parentType.contentMatch;
  var clearNewlines = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : true;
  var node = tr.doc.nodeAt(pos);
  var replSteps = [],
    cur = pos + 1;
  for (var i = 0; i < node.childCount; i++) {
    var child = node.child(i),
      end = cur + child.nodeSize;
    var allowed = match.matchType(child.type);
    if (!allowed) {
      replSteps.push(new ReplaceStep(cur, end, prosemirrorModel.Slice.empty));
    } else {
      match = allowed;
      for (var j = 0; j < child.marks.length; j++) if (!parentType.allowsMarkType(child.marks[j].type)) tr.step(new RemoveMarkStep(cur, end, child.marks[j]));
      if (clearNewlines && child.isText && parentType.whitespace != "pre") {
        var m = void 0,
          newline = /\r?\n|\r/g,
          slice = void 0;
        while (m = newline.exec(child.text)) {
          if (!slice) slice = new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(parentType.schema.text(" ", parentType.allowedMarks(child.marks))), 0, 0);
          replSteps.push(new ReplaceStep(cur + m.index, cur + m.index + m[0].length, slice));
        }
      }
    }
    cur = end;
  }
  if (!match.validEnd) {
    var fill = match.fillBefore(prosemirrorModel.Fragment.empty, true);
    tr.replace(cur, cur, new prosemirrorModel.Slice(fill, 0, 0));
  }
  for (var _i = replSteps.length - 1; _i >= 0; _i--) tr.step(replSteps[_i]);
}
function canCut(node, start, end) {
  return (start == 0 || node.canReplace(start, node.childCount)) && (end == node.childCount || node.canReplace(0, end));
}
function liftTarget(range) {
  var parent = range.parent;
  var content = parent.content.cutByIndex(range.startIndex, range.endIndex);
  for (var depth = range.depth;; --depth) {
    var node = range.$from.node(depth);
    var index = range.$from.index(depth),
      endIndex = range.$to.indexAfter(depth);
    if (depth < range.depth && node.canReplace(index, endIndex, content)) return depth;
    if (depth == 0 || node.type.spec.isolating || !canCut(node, index, endIndex)) break;
  }
  return null;
}
function _lift(tr, range, target) {
  var $from = range.$from,
    $to = range.$to,
    depth = range.depth;
  var gapStart = $from.before(depth + 1),
    gapEnd = $to.after(depth + 1);
  var start = gapStart,
    end = gapEnd;
  var before = prosemirrorModel.Fragment.empty,
    openStart = 0;
  for (var d = depth, splitting = false; d > target; d--) if (splitting || $from.index(d) > 0) {
    splitting = true;
    before = prosemirrorModel.Fragment.from($from.node(d).copy(before));
    openStart++;
  } else {
    start--;
  }
  var after = prosemirrorModel.Fragment.empty,
    openEnd = 0;
  for (var _d = depth, _splitting = false; _d > target; _d--) if (_splitting || $to.after(_d + 1) < $to.end(_d)) {
    _splitting = true;
    after = prosemirrorModel.Fragment.from($to.node(_d).copy(after));
    openEnd++;
  } else {
    end++;
  }
  tr.step(new ReplaceAroundStep(start, end, gapStart, gapEnd, new prosemirrorModel.Slice(before.append(after), openStart, openEnd), before.size - openStart, true));
}
function findWrapping(range, nodeType) {
  var attrs = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;
  var innerRange = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : range;
  var around = findWrappingOutside(range, nodeType);
  var inner = around && findWrappingInside(innerRange, nodeType);
  if (!inner) return null;
  return around.map(withAttrs).concat({
    type: nodeType,
    attrs: attrs
  }).concat(inner.map(withAttrs));
}
function withAttrs(type) {
  return {
    type: type,
    attrs: null
  };
}
function findWrappingOutside(range, type) {
  var parent = range.parent,
    startIndex = range.startIndex,
    endIndex = range.endIndex;
  var around = parent.contentMatchAt(startIndex).findWrapping(type);
  if (!around) return null;
  var outer = around.length ? around[0] : type;
  return parent.canReplaceWith(startIndex, endIndex, outer) ? around : null;
}
function findWrappingInside(range, type) {
  var parent = range.parent,
    startIndex = range.startIndex,
    endIndex = range.endIndex;
  var inner = parent.child(startIndex);
  var inside = type.contentMatch.findWrapping(inner.type);
  if (!inside) return null;
  var lastType = inside.length ? inside[inside.length - 1] : type;
  var innerMatch = lastType.contentMatch;
  for (var i = startIndex; innerMatch && i < endIndex; i++) innerMatch = innerMatch.matchType(parent.child(i).type);
  if (!innerMatch || !innerMatch.validEnd) return null;
  return inside;
}
function _wrap2(tr, range, wrappers) {
  var content = prosemirrorModel.Fragment.empty;
  for (var i = wrappers.length - 1; i >= 0; i--) {
    if (content.size) {
      var match = wrappers[i].type.contentMatch.matchFragment(content);
      if (!match || !match.validEnd) throw new RangeError("Wrapper type given to Transform.wrap does not form valid content of its parent wrapper");
    }
    content = prosemirrorModel.Fragment.from(wrappers[i].type.create(wrappers[i].attrs, content));
  }
  var start = range.start,
    end = range.end;
  tr.step(new ReplaceAroundStep(start, end, start, end, new prosemirrorModel.Slice(content, 0, 0), wrappers.length, true));
}
function _setBlockType(tr, from, to, type, attrs) {
  if (!type.isTextblock) throw new RangeError("Type given to setBlockType should be a textblock");
  var mapFrom = tr.steps.length;
  tr.doc.nodesBetween(from, to, function (node, pos) {
    var attrsHere = typeof attrs == "function" ? attrs(node) : attrs;
    if (node.isTextblock && !node.hasMarkup(type, attrsHere) && canChangeType(tr.doc, tr.mapping.slice(mapFrom).map(pos), type)) {
      var convertNewlines = null;
      if (type.schema.linebreakReplacement) {
        var pre = type.whitespace == "pre",
          supportLinebreak = !!type.contentMatch.matchType(type.schema.linebreakReplacement);
        if (pre && !supportLinebreak) convertNewlines = false;else if (!pre && supportLinebreak) convertNewlines = true;
      }
      if (convertNewlines === false) replaceLinebreaks(tr, node, pos, mapFrom);
      _clearIncompatible(tr, tr.mapping.slice(mapFrom).map(pos, 1), type, undefined, convertNewlines === null);
      var mapping = tr.mapping.slice(mapFrom);
      var startM = mapping.map(pos, 1),
        endM = mapping.map(pos + node.nodeSize, 1);
      tr.step(new ReplaceAroundStep(startM, endM, startM + 1, endM - 1, new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(type.create(attrsHere, null, node.marks)), 0, 0), 1, true));
      if (convertNewlines === true) replaceNewlines(tr, node, pos, mapFrom);
      return false;
    }
  });
}
function replaceNewlines(tr, node, pos, mapFrom) {
  node.forEach(function (child, offset) {
    if (child.isText) {
      var m,
        newline = /\r?\n|\r/g;
      while (m = newline.exec(child.text)) {
        var start = tr.mapping.slice(mapFrom).map(pos + 1 + offset + m.index);
        tr.replaceWith(start, start + 1, node.type.schema.linebreakReplacement.create());
      }
    }
  });
}
function replaceLinebreaks(tr, node, pos, mapFrom) {
  node.forEach(function (child, offset) {
    if (child.type == child.type.schema.linebreakReplacement) {
      var start = tr.mapping.slice(mapFrom).map(pos + 1 + offset);
      tr.replaceWith(start, start + 1, node.type.schema.text("\n"));
    }
  });
}
function canChangeType(doc, pos, type) {
  var $pos = doc.resolve(pos),
    index = $pos.index();
  return $pos.parent.canReplaceWith(index, index + 1, type);
}
function _setNodeMarkup(tr, pos, type, attrs, marks) {
  var node = tr.doc.nodeAt(pos);
  if (!node) throw new RangeError("No node at given position");
  if (!type) type = node.type;
  var newNode = type.create(attrs, null, marks || node.marks);
  if (node.isLeaf) return tr.replaceWith(pos, pos + node.nodeSize, newNode);
  if (!type.validContent(node.content)) throw new RangeError("Invalid content for node type " + type.name);
  tr.step(new ReplaceAroundStep(pos, pos + node.nodeSize, pos + 1, pos + node.nodeSize - 1, new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(newNode), 0, 0), 1, true));
}
function canSplit(doc, pos) {
  var depth = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 1;
  var typesAfter = arguments.length > 3 ? arguments[3] : undefined;
  var $pos = doc.resolve(pos),
    base = $pos.depth - depth;
  var innerType = typesAfter && typesAfter[typesAfter.length - 1] || $pos.parent;
  if (base < 0 || $pos.parent.type.spec.isolating || !$pos.parent.canReplace($pos.index(), $pos.parent.childCount) || !innerType.type.validContent($pos.parent.content.cutByIndex($pos.index(), $pos.parent.childCount))) return false;
  for (var d = $pos.depth - 1, i = depth - 2; d > base; d--, i--) {
    var node = $pos.node(d),
      _index = $pos.index(d);
    if (node.type.spec.isolating) return false;
    var rest = node.content.cutByIndex(_index, node.childCount);
    var overrideChild = typesAfter && typesAfter[i + 1];
    if (overrideChild) rest = rest.replaceChild(0, overrideChild.type.create(overrideChild.attrs));
    var after = typesAfter && typesAfter[i] || node;
    if (!node.canReplace(_index + 1, node.childCount) || !after.type.validContent(rest)) return false;
  }
  var index = $pos.indexAfter(base);
  var baseType = typesAfter && typesAfter[0];
  return $pos.node(base).canReplaceWith(index, index, baseType ? baseType.type : $pos.node(base + 1).type);
}
function _split(tr, pos) {
  var depth = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 1;
  var typesAfter = arguments.length > 3 ? arguments[3] : undefined;
  var $pos = tr.doc.resolve(pos),
    before = prosemirrorModel.Fragment.empty,
    after = prosemirrorModel.Fragment.empty;
  for (var d = $pos.depth, e = $pos.depth - depth, i = depth - 1; d > e; d--, i--) {
    before = prosemirrorModel.Fragment.from($pos.node(d).copy(before));
    var typeAfter = typesAfter && typesAfter[i];
    after = prosemirrorModel.Fragment.from(typeAfter ? typeAfter.type.create(typeAfter.attrs, after) : $pos.node(d).copy(after));
  }
  tr.step(new ReplaceStep(pos, pos, new prosemirrorModel.Slice(before.append(after), depth, depth), true));
}
function canJoin(doc, pos) {
  var $pos = doc.resolve(pos),
    index = $pos.index();
  return joinable($pos.nodeBefore, $pos.nodeAfter) && $pos.parent.canReplace(index, index + 1);
}
function joinable(a, b) {
  return !!(a && b && !a.isLeaf && a.canAppend(b));
}
function joinPoint(doc, pos) {
  var dir = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : -1;
  var $pos = doc.resolve(pos);
  for (var d = $pos.depth;; d--) {
    var before = void 0,
      after = void 0,
      index = $pos.index(d);
    if (d == $pos.depth) {
      before = $pos.nodeBefore;
      after = $pos.nodeAfter;
    } else if (dir > 0) {
      before = $pos.node(d + 1);
      index++;
      after = $pos.node(d).maybeChild(index);
    } else {
      before = $pos.node(d).maybeChild(index - 1);
      after = $pos.node(d + 1);
    }
    if (before && !before.isTextblock && joinable(before, after) && $pos.node(d).canReplace(index, index + 1)) return pos;
    if (d == 0) break;
    pos = dir < 0 ? $pos.before(d) : $pos.after(d);
  }
}
function _join(tr, pos, depth) {
  var step = new ReplaceStep(pos - depth, pos + depth, prosemirrorModel.Slice.empty, true);
  tr.step(step);
}
function insertPoint(doc, pos, nodeType) {
  var $pos = doc.resolve(pos);
  if ($pos.parent.canReplaceWith($pos.index(), $pos.index(), nodeType)) return pos;
  if ($pos.parentOffset == 0) for (var d = $pos.depth - 1; d >= 0; d--) {
    var index = $pos.index(d);
    if ($pos.node(d).canReplaceWith(index, index, nodeType)) return $pos.before(d + 1);
    if (index > 0) return null;
  }
  if ($pos.parentOffset == $pos.parent.content.size) for (var _d2 = $pos.depth - 1; _d2 >= 0; _d2--) {
    var _index2 = $pos.indexAfter(_d2);
    if ($pos.node(_d2).canReplaceWith(_index2, _index2, nodeType)) return $pos.after(_d2 + 1);
    if (_index2 < $pos.node(_d2).childCount) return null;
  }
  return null;
}
function dropPoint(doc, pos, slice) {
  var $pos = doc.resolve(pos);
  if (!slice.content.size) return pos;
  var content = slice.content;
  for (var i = 0; i < slice.openStart; i++) content = content.firstChild.content;
  for (var pass = 1; pass <= (slice.openStart == 0 && slice.size ? 2 : 1); pass++) {
    for (var d = $pos.depth; d >= 0; d--) {
      var bias = d == $pos.depth ? 0 : $pos.pos <= ($pos.start(d + 1) + $pos.end(d + 1)) / 2 ? -1 : 1;
      var insertPos = $pos.index(d) + (bias > 0 ? 1 : 0);
      var parent = $pos.node(d),
        fits = false;
      if (pass == 1) {
        fits = parent.canReplace(insertPos, insertPos, content);
      } else {
        var wrapping = parent.contentMatchAt(insertPos).findWrapping(content.firstChild.type);
        fits = wrapping && parent.canReplaceWith(insertPos, insertPos, wrapping[0]);
      }
      if (fits) return bias == 0 ? $pos.pos : bias < 0 ? $pos.before(d + 1) : $pos.after(d + 1);
    }
  }
  return null;
}
function replaceStep(doc, from) {
  var to = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : from;
  var slice = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : prosemirrorModel.Slice.empty;
  if (from == to && !slice.size) return null;
  var $from = doc.resolve(from),
    $to = doc.resolve(to);
  if (fitsTrivially($from, $to, slice)) return new ReplaceStep(from, to, slice);
  return new Fitter($from, $to, slice).fit();
}
function fitsTrivially($from, $to, slice) {
  return !slice.openStart && !slice.openEnd && $from.start() == $to.start() && $from.parent.canReplace($from.index(), $to.index(), slice.content);
}
var Fitter = function () {
  function Fitter($from, $to, unplaced) {
    _classCallCheck(this, Fitter);
    this.$from = $from;
    this.$to = $to;
    this.unplaced = unplaced;
    this.frontier = [];
    this.placed = prosemirrorModel.Fragment.empty;
    for (var i = 0; i <= $from.depth; i++) {
      var node = $from.node(i);
      this.frontier.push({
        type: node.type,
        match: node.contentMatchAt($from.indexAfter(i))
      });
    }
    for (var _i2 = $from.depth; _i2 > 0; _i2--) this.placed = prosemirrorModel.Fragment.from($from.node(_i2).copy(this.placed));
  }
  _createClass(Fitter, [{
    key: "depth",
    get: function get() {
      return this.frontier.length - 1;
    }
  }, {
    key: "fit",
    value: function fit() {
      while (this.unplaced.size) {
        var fit = this.findFittable();
        if (fit) this.placeNodes(fit);else this.openMore() || this.dropNode();
      }
      var moveInline = this.mustMoveInline(),
        placedSize = this.placed.size - this.depth - this.$from.depth;
      var $from = this.$from,
        $to = this.close(moveInline < 0 ? this.$to : $from.doc.resolve(moveInline));
      if (!$to) return null;
      var content = this.placed,
        openStart = $from.depth,
        openEnd = $to.depth;
      while (openStart && openEnd && content.childCount == 1) {
        content = content.firstChild.content;
        openStart--;
        openEnd--;
      }
      var slice = new prosemirrorModel.Slice(content, openStart, openEnd);
      if (moveInline > -1) return new ReplaceAroundStep($from.pos, moveInline, this.$to.pos, this.$to.end(), slice, placedSize);
      if (slice.size || $from.pos != this.$to.pos) return new ReplaceStep($from.pos, $to.pos, slice);
      return null;
    }
  }, {
    key: "findFittable",
    value: function findFittable() {
      var startDepth = this.unplaced.openStart;
      for (var cur = this.unplaced.content, d = 0, openEnd = this.unplaced.openEnd; d < startDepth; d++) {
        var node = cur.firstChild;
        if (cur.childCount > 1) openEnd = 0;
        if (node.type.spec.isolating && openEnd <= d) {
          startDepth = d;
          break;
        }
        cur = node.content;
      }
      for (var pass = 1; pass <= 2; pass++) {
        for (var sliceDepth = pass == 1 ? startDepth : this.unplaced.openStart; sliceDepth >= 0; sliceDepth--) {
          var fragment = void 0,
            parent = null;
          if (sliceDepth) {
            parent = contentAt(this.unplaced.content, sliceDepth - 1).firstChild;
            fragment = parent.content;
          } else {
            fragment = this.unplaced.content;
          }
          var first = fragment.firstChild;
          for (var frontierDepth = this.depth; frontierDepth >= 0; frontierDepth--) {
            var _this$frontier$fronti = this.frontier[frontierDepth],
              type = _this$frontier$fronti.type,
              match = _this$frontier$fronti.match,
              _wrap = void 0,
              inject = null;
            if (pass == 1 && (first ? match.matchType(first.type) || (inject = match.fillBefore(prosemirrorModel.Fragment.from(first), false)) : parent && type.compatibleContent(parent.type))) return {
              sliceDepth: sliceDepth,
              frontierDepth: frontierDepth,
              parent: parent,
              inject: inject
            };else if (pass == 2 && first && (_wrap = match.findWrapping(first.type))) return {
              sliceDepth: sliceDepth,
              frontierDepth: frontierDepth,
              parent: parent,
              wrap: _wrap
            };
            if (parent && match.matchType(parent.type)) break;
          }
        }
      }
    }
  }, {
    key: "openMore",
    value: function openMore() {
      var _this$unplaced = this.unplaced,
        content = _this$unplaced.content,
        openStart = _this$unplaced.openStart,
        openEnd = _this$unplaced.openEnd;
      var inner = contentAt(content, openStart);
      if (!inner.childCount || inner.firstChild.isLeaf) return false;
      this.unplaced = new prosemirrorModel.Slice(content, openStart + 1, Math.max(openEnd, inner.size + openStart >= content.size - openEnd ? openStart + 1 : 0));
      return true;
    }
  }, {
    key: "dropNode",
    value: function dropNode() {
      var _this$unplaced2 = this.unplaced,
        content = _this$unplaced2.content,
        openStart = _this$unplaced2.openStart,
        openEnd = _this$unplaced2.openEnd;
      var inner = contentAt(content, openStart);
      if (inner.childCount <= 1 && openStart > 0) {
        var openAtEnd = content.size - openStart <= openStart + inner.size;
        this.unplaced = new prosemirrorModel.Slice(dropFromFragment(content, openStart - 1, 1), openStart - 1, openAtEnd ? openStart - 1 : openEnd);
      } else {
        this.unplaced = new prosemirrorModel.Slice(dropFromFragment(content, openStart, 1), openStart, openEnd);
      }
    }
  }, {
    key: "placeNodes",
    value: function placeNodes(_ref) {
      var sliceDepth = _ref.sliceDepth,
        frontierDepth = _ref.frontierDepth,
        parent = _ref.parent,
        inject = _ref.inject,
        wrap = _ref.wrap;
      while (this.depth > frontierDepth) this.closeFrontierNode();
      if (wrap) for (var i = 0; i < wrap.length; i++) this.openFrontierNode(wrap[i]);
      var slice = this.unplaced,
        fragment = parent ? parent.content : slice.content;
      var openStart = slice.openStart - sliceDepth;
      var taken = 0,
        add = [];
      var _this$frontier$fronti2 = this.frontier[frontierDepth],
        match = _this$frontier$fronti2.match,
        type = _this$frontier$fronti2.type;
      if (inject) {
        for (var _i3 = 0; _i3 < inject.childCount; _i3++) add.push(inject.child(_i3));
        match = match.matchFragment(inject);
      }
      var openEndCount = fragment.size + sliceDepth - (slice.content.size - slice.openEnd);
      while (taken < fragment.childCount) {
        var next = fragment.child(taken),
          matches = match.matchType(next.type);
        if (!matches) break;
        taken++;
        if (taken > 1 || openStart == 0 || next.content.size) {
          match = matches;
          add.push(closeNodeStart(next.mark(type.allowedMarks(next.marks)), taken == 1 ? openStart : 0, taken == fragment.childCount ? openEndCount : -1));
        }
      }
      var toEnd = taken == fragment.childCount;
      if (!toEnd) openEndCount = -1;
      this.placed = addToFragment(this.placed, frontierDepth, prosemirrorModel.Fragment.from(add));
      this.frontier[frontierDepth].match = match;
      if (toEnd && openEndCount < 0 && parent && parent.type == this.frontier[this.depth].type && this.frontier.length > 1) this.closeFrontierNode();
      for (var _i4 = 0, cur = fragment; _i4 < openEndCount; _i4++) {
        var node = cur.lastChild;
        this.frontier.push({
          type: node.type,
          match: node.contentMatchAt(node.childCount)
        });
        cur = node.content;
      }
      this.unplaced = !toEnd ? new prosemirrorModel.Slice(dropFromFragment(slice.content, sliceDepth, taken), slice.openStart, slice.openEnd) : sliceDepth == 0 ? prosemirrorModel.Slice.empty : new prosemirrorModel.Slice(dropFromFragment(slice.content, sliceDepth - 1, 1), sliceDepth - 1, openEndCount < 0 ? slice.openEnd : sliceDepth - 1);
    }
  }, {
    key: "mustMoveInline",
    value: function mustMoveInline() {
      if (!this.$to.parent.isTextblock) return -1;
      var top = this.frontier[this.depth],
        level;
      if (!top.type.isTextblock || !contentAfterFits(this.$to, this.$to.depth, top.type, top.match, false) || this.$to.depth == this.depth && (level = this.findCloseLevel(this.$to)) && level.depth == this.depth) return -1;
      var depth = this.$to.depth,
        after = this.$to.after(depth);
      while (depth > 1 && after == this.$to.end(--depth)) ++after;
      return after;
    }
  }, {
    key: "findCloseLevel",
    value: function findCloseLevel($to) {
      scan: for (var i = Math.min(this.depth, $to.depth); i >= 0; i--) {
        var _this$frontier$i = this.frontier[i],
          match = _this$frontier$i.match,
          type = _this$frontier$i.type;
        var dropInner = i < $to.depth && $to.end(i + 1) == $to.pos + ($to.depth - (i + 1));
        var fit = contentAfterFits($to, i, type, match, dropInner);
        if (!fit) continue;
        for (var d = i - 1; d >= 0; d--) {
          var _this$frontier$d = this.frontier[d],
            _match = _this$frontier$d.match,
            _type = _this$frontier$d.type;
          var matches = contentAfterFits($to, d, _type, _match, true);
          if (!matches || matches.childCount) continue scan;
        }
        return {
          depth: i,
          fit: fit,
          move: dropInner ? $to.doc.resolve($to.after(i + 1)) : $to
        };
      }
    }
  }, {
    key: "close",
    value: function close($to) {
      var close = this.findCloseLevel($to);
      if (!close) return null;
      while (this.depth > close.depth) this.closeFrontierNode();
      if (close.fit.childCount) this.placed = addToFragment(this.placed, close.depth, close.fit);
      $to = close.move;
      for (var d = close.depth + 1; d <= $to.depth; d++) {
        var node = $to.node(d),
          add = node.type.contentMatch.fillBefore(node.content, true, $to.index(d));
        this.openFrontierNode(node.type, node.attrs, add);
      }
      return $to;
    }
  }, {
    key: "openFrontierNode",
    value: function openFrontierNode(type) {
      var attrs = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
      var content = arguments.length > 2 ? arguments[2] : undefined;
      var top = this.frontier[this.depth];
      top.match = top.match.matchType(type);
      this.placed = addToFragment(this.placed, this.depth, prosemirrorModel.Fragment.from(type.create(attrs, content)));
      this.frontier.push({
        type: type,
        match: type.contentMatch
      });
    }
  }, {
    key: "closeFrontierNode",
    value: function closeFrontierNode() {
      var open = this.frontier.pop();
      var add = open.match.fillBefore(prosemirrorModel.Fragment.empty, true);
      if (add.childCount) this.placed = addToFragment(this.placed, this.frontier.length, add);
    }
  }]);
  return Fitter;
}();
function dropFromFragment(fragment, depth, count) {
  if (depth == 0) return fragment.cutByIndex(count, fragment.childCount);
  return fragment.replaceChild(0, fragment.firstChild.copy(dropFromFragment(fragment.firstChild.content, depth - 1, count)));
}
function addToFragment(fragment, depth, content) {
  if (depth == 0) return fragment.append(content);
  return fragment.replaceChild(fragment.childCount - 1, fragment.lastChild.copy(addToFragment(fragment.lastChild.content, depth - 1, content)));
}
function contentAt(fragment, depth) {
  for (var i = 0; i < depth; i++) fragment = fragment.firstChild.content;
  return fragment;
}
function closeNodeStart(node, openStart, openEnd) {
  if (openStart <= 0) return node;
  var frag = node.content;
  if (openStart > 1) frag = frag.replaceChild(0, closeNodeStart(frag.firstChild, openStart - 1, frag.childCount == 1 ? openEnd - 1 : 0));
  if (openStart > 0) {
    frag = node.type.contentMatch.fillBefore(frag).append(frag);
    if (openEnd <= 0) frag = frag.append(node.type.contentMatch.matchFragment(frag).fillBefore(prosemirrorModel.Fragment.empty, true));
  }
  return node.copy(frag);
}
function contentAfterFits($to, depth, type, match, open) {
  var node = $to.node(depth),
    index = open ? $to.indexAfter(depth) : $to.index(depth);
  if (index == node.childCount && !type.compatibleContent(node.type)) return null;
  var fit = match.fillBefore(node.content, true, index);
  return fit && !invalidMarks(type, node.content, index) ? fit : null;
}
function invalidMarks(type, fragment, start) {
  for (var i = start; i < fragment.childCount; i++) if (!type.allowsMarks(fragment.child(i).marks)) return true;
  return false;
}
function definesContent(type) {
  return type.spec.defining || type.spec.definingForContent;
}
function _replaceRange(tr, from, to, slice) {
  if (!slice.size) return tr.deleteRange(from, to);
  var $from = tr.doc.resolve(from),
    $to = tr.doc.resolve(to);
  if (fitsTrivially($from, $to, slice)) return tr.step(new ReplaceStep(from, to, slice));
  var targetDepths = coveredDepths($from, tr.doc.resolve(to));
  if (targetDepths[targetDepths.length - 1] == 0) targetDepths.pop();
  var preferredTarget = -($from.depth + 1);
  targetDepths.unshift(preferredTarget);
  for (var d = $from.depth, pos = $from.pos - 1; d > 0; d--, pos--) {
    var spec = $from.node(d).type.spec;
    if (spec.defining || spec.definingAsContext || spec.isolating) break;
    if (targetDepths.indexOf(d) > -1) preferredTarget = d;else if ($from.before(d) == pos) targetDepths.splice(1, 0, -d);
  }
  var preferredTargetIndex = targetDepths.indexOf(preferredTarget);
  var leftNodes = [],
    preferredDepth = slice.openStart;
  for (var content = slice.content, i = 0;; i++) {
    var node = content.firstChild;
    leftNodes.push(node);
    if (i == slice.openStart) break;
    content = node.content;
  }
  for (var _d3 = preferredDepth - 1; _d3 >= 0; _d3--) {
    var leftNode = leftNodes[_d3],
      def = definesContent(leftNode.type);
    if (def && !leftNode.sameMarkup($from.node(Math.abs(preferredTarget) - 1))) preferredDepth = _d3;else if (def || !leftNode.type.isTextblock) break;
  }
  for (var j = slice.openStart; j >= 0; j--) {
    var openDepth = (j + preferredDepth + 1) % (slice.openStart + 1);
    var insert = leftNodes[openDepth];
    if (!insert) continue;
    for (var _i5 = 0; _i5 < targetDepths.length; _i5++) {
      var targetDepth = targetDepths[(_i5 + preferredTargetIndex) % targetDepths.length],
        expand = true;
      if (targetDepth < 0) {
        expand = false;
        targetDepth = -targetDepth;
      }
      var parent = $from.node(targetDepth - 1),
        index = $from.index(targetDepth - 1);
      if (parent.canReplaceWith(index, index, insert.type, insert.marks)) return tr.replace($from.before(targetDepth), expand ? $to.after(targetDepth) : to, new prosemirrorModel.Slice(closeFragment(slice.content, 0, slice.openStart, openDepth), openDepth, slice.openEnd));
    }
  }
  var startSteps = tr.steps.length;
  for (var _i6 = targetDepths.length - 1; _i6 >= 0; _i6--) {
    tr.replace(from, to, slice);
    if (tr.steps.length > startSteps) break;
    var depth = targetDepths[_i6];
    if (depth < 0) continue;
    from = $from.before(depth);
    to = $to.after(depth);
  }
}
function closeFragment(fragment, depth, oldOpen, newOpen, parent) {
  if (depth < oldOpen) {
    var first = fragment.firstChild;
    fragment = fragment.replaceChild(0, first.copy(closeFragment(first.content, depth + 1, oldOpen, newOpen, first)));
  }
  if (depth > newOpen) {
    var match = parent.contentMatchAt(0);
    var start = match.fillBefore(fragment).append(fragment);
    fragment = start.append(match.matchFragment(start).fillBefore(prosemirrorModel.Fragment.empty, true));
  }
  return fragment;
}
function _replaceRangeWith(tr, from, to, node) {
  if (!node.isInline && from == to && tr.doc.resolve(from).parent.content.size) {
    var point = insertPoint(tr.doc, from, node.type);
    if (point != null) from = to = point;
  }
  tr.replaceRange(from, to, new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(node), 0, 0));
}
function _deleteRange(tr, from, to) {
  var $from = tr.doc.resolve(from),
    $to = tr.doc.resolve(to);
  var covered = coveredDepths($from, $to);
  for (var i = 0; i < covered.length; i++) {
    var depth = covered[i],
      last = i == covered.length - 1;
    if (last && depth == 0 || $from.node(depth).type.contentMatch.validEnd) return tr["delete"]($from.start(depth), $to.end(depth));
    if (depth > 0 && (last || $from.node(depth - 1).canReplace($from.index(depth - 1), $to.indexAfter(depth - 1)))) return tr["delete"]($from.before(depth), $to.after(depth));
  }
  for (var d = 1; d <= $from.depth && d <= $to.depth; d++) {
    if (from - $from.start(d) == $from.depth - d && to > $from.end(d) && $to.end(d) - to != $to.depth - d) return tr["delete"]($from.before(d), to);
  }
  tr["delete"](from, to);
}
function coveredDepths($from, $to) {
  var result = [],
    minDepth = Math.min($from.depth, $to.depth);
  for (var d = minDepth; d >= 0; d--) {
    var start = $from.start(d);
    if (start < $from.pos - ($from.depth - d) || $to.end(d) > $to.pos + ($to.depth - d) || $from.node(d).type.spec.isolating || $to.node(d).type.spec.isolating) break;
    if (start == $to.start(d) || d == $from.depth && d == $to.depth && $from.parent.inlineContent && $to.parent.inlineContent && d && $to.start(d - 1) == start - 1) result.push(d);
  }
  return result;
}
var AttrStep = function (_Step7) {
  _inherits(AttrStep, _Step7);
  var _super7 = _createSuper(AttrStep);
  function AttrStep(pos, attr, value) {
    var _this9;
    _classCallCheck(this, AttrStep);
    _this9 = _super7.call(this);
    _this9.pos = pos;
    _this9.attr = attr;
    _this9.value = value;
    return _this9;
  }
  _createClass(AttrStep, [{
    key: "apply",
    value: function apply(doc) {
      var node = doc.nodeAt(this.pos);
      if (!node) return StepResult.fail("No node at attribute step's position");
      var attrs = Object.create(null);
      for (var name in node.attrs) attrs[name] = node.attrs[name];
      attrs[this.attr] = this.value;
      var updated = node.type.create(attrs, null, node.marks);
      return StepResult.fromReplace(doc, this.pos, this.pos + 1, new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(updated), 0, node.isLeaf ? 0 : 1));
    }
  }, {
    key: "getMap",
    value: function getMap() {
      return StepMap.empty;
    }
  }, {
    key: "invert",
    value: function invert(doc) {
      return new AttrStep(this.pos, this.attr, doc.nodeAt(this.pos).attrs[this.attr]);
    }
  }, {
    key: "map",
    value: function map(mapping) {
      var pos = mapping.mapResult(this.pos, 1);
      return pos.deletedAfter ? null : new AttrStep(pos.pos, this.attr, this.value);
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        stepType: "attr",
        pos: this.pos,
        attr: this.attr,
        value: this.value
      };
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (typeof json.pos != "number" || typeof json.attr != "string") throw new RangeError("Invalid input for AttrStep.fromJSON");
      return new AttrStep(json.pos, json.attr, json.value);
    }
  }]);
  return AttrStep;
}(Step);
Step.jsonID("attr", AttrStep);
var DocAttrStep = function (_Step8) {
  _inherits(DocAttrStep, _Step8);
  var _super8 = _createSuper(DocAttrStep);
  function DocAttrStep(attr, value) {
    var _this10;
    _classCallCheck(this, DocAttrStep);
    _this10 = _super8.call(this);
    _this10.attr = attr;
    _this10.value = value;
    return _this10;
  }
  _createClass(DocAttrStep, [{
    key: "apply",
    value: function apply(doc) {
      var attrs = Object.create(null);
      for (var name in doc.attrs) attrs[name] = doc.attrs[name];
      attrs[this.attr] = this.value;
      var updated = doc.type.create(attrs, doc.content, doc.marks);
      return StepResult.ok(updated);
    }
  }, {
    key: "getMap",
    value: function getMap() {
      return StepMap.empty;
    }
  }, {
    key: "invert",
    value: function invert(doc) {
      return new DocAttrStep(this.attr, doc.attrs[this.attr]);
    }
  }, {
    key: "map",
    value: function map(mapping) {
      return this;
    }
  }, {
    key: "toJSON",
    value: function toJSON() {
      return {
        stepType: "docAttr",
        attr: this.attr,
        value: this.value
      };
    }
  }], [{
    key: "fromJSON",
    value: function fromJSON(schema, json) {
      if (typeof json.attr != "string") throw new RangeError("Invalid input for DocAttrStep.fromJSON");
      return new DocAttrStep(json.attr, json.value);
    }
  }]);
  return DocAttrStep;
}(Step);
Step.jsonID("docAttr", DocAttrStep);
exports.TransformError = function (_Error) {
  _inherits(TransformError, _Error);
  var _super9 = _createSuper(TransformError);
  function TransformError() {
    _classCallCheck(this, TransformError);
    return _super9.apply(this, arguments);
  }
  return _createClass(TransformError);
}(_wrapNativeSuper(Error));
exports.TransformError = function TransformError(message) {
  var err = Error.call(this, message);
  err.__proto__ = TransformError.prototype;
  return err;
};
exports.TransformError.prototype = Object.create(Error.prototype);
exports.TransformError.prototype.constructor = exports.TransformError;
exports.TransformError.prototype.name = "TransformError";
var Transform = function () {
  function Transform(doc) {
    _classCallCheck(this, Transform);
    this.doc = doc;
    this.steps = [];
    this.docs = [];
    this.mapping = new Mapping();
  }
  _createClass(Transform, [{
    key: "before",
    get: function get() {
      return this.docs.length ? this.docs[0] : this.doc;
    }
  }, {
    key: "step",
    value: function step(_step) {
      var result = this.maybeStep(_step);
      if (result.failed) throw new exports.TransformError(result.failed);
      return this;
    }
  }, {
    key: "maybeStep",
    value: function maybeStep(step) {
      var result = step.apply(this.doc);
      if (!result.failed) this.addStep(step, result.doc);
      return result;
    }
  }, {
    key: "docChanged",
    get: function get() {
      return this.steps.length > 0;
    }
  }, {
    key: "addStep",
    value: function addStep(step, doc) {
      this.docs.push(this.doc);
      this.steps.push(step);
      this.mapping.appendMap(step.getMap());
      this.doc = doc;
    }
  }, {
    key: "replace",
    value: function replace(from) {
      var to = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : from;
      var slice = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : prosemirrorModel.Slice.empty;
      var step = replaceStep(this.doc, from, to, slice);
      if (step) this.step(step);
      return this;
    }
  }, {
    key: "replaceWith",
    value: function replaceWith(from, to, content) {
      return this.replace(from, to, new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(content), 0, 0));
    }
  }, {
    key: "delete",
    value: function _delete(from, to) {
      return this.replace(from, to, prosemirrorModel.Slice.empty);
    }
  }, {
    key: "insert",
    value: function insert(pos, content) {
      return this.replaceWith(pos, pos, content);
    }
  }, {
    key: "replaceRange",
    value: function replaceRange(from, to, slice) {
      _replaceRange(this, from, to, slice);
      return this;
    }
  }, {
    key: "replaceRangeWith",
    value: function replaceRangeWith(from, to, node) {
      _replaceRangeWith(this, from, to, node);
      return this;
    }
  }, {
    key: "deleteRange",
    value: function deleteRange(from, to) {
      _deleteRange(this, from, to);
      return this;
    }
  }, {
    key: "lift",
    value: function lift(range, target) {
      _lift(this, range, target);
      return this;
    }
  }, {
    key: "join",
    value: function join(pos) {
      var depth = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;
      _join(this, pos, depth);
      return this;
    }
  }, {
    key: "wrap",
    value: function wrap(range, wrappers) {
      _wrap2(this, range, wrappers);
      return this;
    }
  }, {
    key: "setBlockType",
    value: function setBlockType(from) {
      var to = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : from;
      var type = arguments.length > 2 ? arguments[2] : undefined;
      var attrs = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : null;
      _setBlockType(this, from, to, type, attrs);
      return this;
    }
  }, {
    key: "setNodeMarkup",
    value: function setNodeMarkup(pos, type) {
      var attrs = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;
      var marks = arguments.length > 3 ? arguments[3] : undefined;
      _setNodeMarkup(this, pos, type, attrs, marks);
      return this;
    }
  }, {
    key: "setNodeAttribute",
    value: function setNodeAttribute(pos, attr, value) {
      this.step(new AttrStep(pos, attr, value));
      return this;
    }
  }, {
    key: "setDocAttribute",
    value: function setDocAttribute(attr, value) {
      this.step(new DocAttrStep(attr, value));
      return this;
    }
  }, {
    key: "addNodeMark",
    value: function addNodeMark(pos, mark) {
      this.step(new AddNodeMarkStep(pos, mark));
      return this;
    }
  }, {
    key: "removeNodeMark",
    value: function removeNodeMark(pos, mark) {
      if (!(mark instanceof prosemirrorModel.Mark)) {
        var node = this.doc.nodeAt(pos);
        if (!node) throw new RangeError("No node at position " + pos);
        mark = mark.isInSet(node.marks);
        if (!mark) return this;
      }
      this.step(new RemoveNodeMarkStep(pos, mark));
      return this;
    }
  }, {
    key: "split",
    value: function split(pos) {
      var depth = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;
      var typesAfter = arguments.length > 2 ? arguments[2] : undefined;
      _split(this, pos, depth, typesAfter);
      return this;
    }
  }, {
    key: "addMark",
    value: function addMark(from, to, mark) {
      _addMark(this, from, to, mark);
      return this;
    }
  }, {
    key: "removeMark",
    value: function removeMark(from, to, mark) {
      _removeMark(this, from, to, mark);
      return this;
    }
  }, {
    key: "clearIncompatible",
    value: function clearIncompatible(pos, parentType, match) {
      _clearIncompatible(this, pos, parentType, match);
      return this;
    }
  }]);
  return Transform;
}();
exports.AddMarkStep = AddMarkStep;
exports.AddNodeMarkStep = AddNodeMarkStep;
exports.AttrStep = AttrStep;
exports.DocAttrStep = DocAttrStep;
exports.MapResult = MapResult;
exports.Mapping = Mapping;
exports.RemoveMarkStep = RemoveMarkStep;
exports.RemoveNodeMarkStep = RemoveNodeMarkStep;
exports.ReplaceAroundStep = ReplaceAroundStep;
exports.ReplaceStep = ReplaceStep;
exports.Step = Step;
exports.StepMap = StepMap;
exports.StepResult = StepResult;
exports.Transform = Transform;
exports.canJoin = canJoin;
exports.canSplit = canSplit;
exports.dropPoint = dropPoint;
exports.findWrapping = findWrapping;
exports.insertPoint = insertPoint;
exports.joinPoint = joinPoint;
exports.liftTarget = liftTarget;
exports.replaceStep = replaceStep;
