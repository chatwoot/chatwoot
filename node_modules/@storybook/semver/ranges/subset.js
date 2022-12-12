"use strict";

require("core-js/modules/es.symbol");

require("core-js/modules/es.symbol.description");

require("core-js/modules/es.symbol.iterator");

require("core-js/modules/es.array.from");

require("core-js/modules/es.array.is-array");

require("core-js/modules/es.array.iterator");

require("core-js/modules/es.array.slice");

require("core-js/modules/es.date.to-string");

require("core-js/modules/es.function.name");

require("core-js/modules/es.object.to-string");

require("core-js/modules/es.regexp.to-string");

require("core-js/modules/es.set");

require("core-js/modules/es.string.iterator");

require("core-js/modules/web.dom-collections.iterator");

function _createForOfIteratorHelper(o) { if (typeof Symbol === "undefined" || o[Symbol.iterator] == null) { if (Array.isArray(o) || (o = _unsupportedIterableToArray(o))) { var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e) { throw _e; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var it, normalCompletion = true, didErr = false, err; return { s: function s() { it = o[Symbol.iterator](); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e2) { didErr = true; err = _e2; }, f: function f() { try { if (!normalCompletion && it["return"] != null) it["return"](); } finally { if (didErr) throw err; } } }; }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

var Range = require('../classes/range.js');

var _require = require('../classes/comparator.js'),
    ANY = _require.ANY;

var satisfies = require('../functions/satisfies.js');

var compare = require('../functions/compare.js'); // Complex range `r1 || r2 || ...` is a subset of `R1 || R2 || ...` iff:
// - Every simple range `r1, r2, ...` is a subset of some `R1, R2, ...`
//
// Simple range `c1 c2 ...` is a subset of simple range `C1 C2 ...` iff:
// - If c is only the ANY comparator
//   - If C is only the ANY comparator, return true
//   - Else return false
// - Let EQ be the set of = comparators in c
// - If EQ is more than one, return true (null set)
// - Let GT be the highest > or >= comparator in c
// - Let LT be the lowest < or <= comparator in c
// - If GT and LT, and GT.semver > LT.semver, return true (null set)
// - If EQ
//   - If GT, and EQ does not satisfy GT, return true (null set)
//   - If LT, and EQ does not satisfy LT, return true (null set)
//   - If EQ satisfies every C, return true
//   - Else return false
// - If GT
//   - If GT is lower than any > or >= comp in C, return false
//   - If GT is >=, and GT.semver does not satisfy every C, return false
// - If LT
//   - If LT.semver is greater than that of any > comp in C, return false
//   - If LT is <=, and LT.semver does not satisfy every C, return false
// - If any C is a = range, and GT or LT are set, return false
// - Else return true


var subset = function subset(sub, dom, options) {
  sub = new Range(sub, options);
  dom = new Range(dom, options);
  var sawNonNull = false;

  var _iterator = _createForOfIteratorHelper(sub.set),
      _step;

  try {
    OUTER: for (_iterator.s(); !(_step = _iterator.n()).done;) {
      var simpleSub = _step.value;

      var _iterator2 = _createForOfIteratorHelper(dom.set),
          _step2;

      try {
        for (_iterator2.s(); !(_step2 = _iterator2.n()).done;) {
          var simpleDom = _step2.value;
          var isSub = simpleSubset(simpleSub, simpleDom, options);
          sawNonNull = sawNonNull || isSub !== null;
          if (isSub) continue OUTER;
        } // the null set is a subset of everything, but null simple ranges in
        // a complex range should be ignored.  so if we saw a non-null range,
        // then we know this isn't a subset, but if EVERY simple range was null,
        // then it is a subset.

      } catch (err) {
        _iterator2.e(err);
      } finally {
        _iterator2.f();
      }

      if (sawNonNull) return false;
    }
  } catch (err) {
    _iterator.e(err);
  } finally {
    _iterator.f();
  }

  return true;
};

var simpleSubset = function simpleSubset(sub, dom, options) {
  if (sub.length === 1 && sub[0].semver === ANY) return dom.length === 1 && dom[0].semver === ANY;
  var eqSet = new Set();
  var gt, lt;

  var _iterator3 = _createForOfIteratorHelper(sub),
      _step3;

  try {
    for (_iterator3.s(); !(_step3 = _iterator3.n()).done;) {
      var c = _step3.value;
      if (c.operator === '>' || c.operator === '>=') gt = higherGT(gt, c, options);else if (c.operator === '<' || c.operator === '<=') lt = lowerLT(lt, c, options);else eqSet.add(c.semver);
    }
  } catch (err) {
    _iterator3.e(err);
  } finally {
    _iterator3.f();
  }

  if (eqSet.size > 1) return null;
  var gtltComp;

  if (gt && lt) {
    gtltComp = compare(gt.semver, lt.semver, options);
    if (gtltComp > 0) return null;else if (gtltComp === 0 && (gt.operator !== '>=' || lt.operator !== '<=')) return null;
  } // will iterate one or zero times


  var _iterator4 = _createForOfIteratorHelper(eqSet),
      _step4;

  try {
    for (_iterator4.s(); !(_step4 = _iterator4.n()).done;) {
      var eq = _step4.value;
      if (gt && !satisfies(eq, String(gt), options)) return null;
      if (lt && !satisfies(eq, String(lt), options)) return null;

      var _iterator6 = _createForOfIteratorHelper(dom),
          _step6;

      try {
        for (_iterator6.s(); !(_step6 = _iterator6.n()).done;) {
          var _c = _step6.value;
          if (!satisfies(eq, String(_c), options)) return false;
        }
      } catch (err) {
        _iterator6.e(err);
      } finally {
        _iterator6.f();
      }

      return true;
    }
  } catch (err) {
    _iterator4.e(err);
  } finally {
    _iterator4.f();
  }

  var higher, lower;
  var hasDomLT, hasDomGT;

  var _iterator5 = _createForOfIteratorHelper(dom),
      _step5;

  try {
    for (_iterator5.s(); !(_step5 = _iterator5.n()).done;) {
      var _c2 = _step5.value;
      hasDomGT = hasDomGT || _c2.operator === '>' || _c2.operator === '>=';
      hasDomLT = hasDomLT || _c2.operator === '<' || _c2.operator === '<=';

      if (gt) {
        if (_c2.operator === '>' || _c2.operator === '>=') {
          higher = higherGT(gt, _c2, options);
          if (higher === _c2) return false;
        } else if (gt.operator === '>=' && !satisfies(gt.semver, String(_c2), options)) return false;
      }

      if (lt) {
        if (_c2.operator === '<' || _c2.operator === '<=') {
          lower = lowerLT(lt, _c2, options);
          if (lower === _c2) return false;
        } else if (lt.operator === '<=' && !satisfies(lt.semver, String(_c2), options)) return false;
      }

      if (!_c2.operator && (lt || gt) && gtltComp !== 0) return false;
    } // if there was a < or >, and nothing in the dom, then must be false
    // UNLESS it was limited by another range in the other direction.
    // Eg, >1.0.0 <1.0.1 is still a subset of <2.0.0

  } catch (err) {
    _iterator5.e(err);
  } finally {
    _iterator5.f();
  }

  if (gt && hasDomLT && !lt && gtltComp !== 0) return false;
  if (lt && hasDomGT && !gt && gtltComp !== 0) return false;
  return true;
}; // >=1.2.3 is lower than >1.2.3


var higherGT = function higherGT(a, b, options) {
  if (!a) return b;
  var comp = compare(a.semver, b.semver, options);
  return comp > 0 ? a : comp < 0 ? b : b.operator === '>' && a.operator === '>=' ? b : a;
}; // <=1.2.3 is higher than <1.2.3


var lowerLT = function lowerLT(a, b, options) {
  if (!a) return b;
  var comp = compare(a.semver, b.semver, options);
  return comp < 0 ? a : comp > 0 ? b : b.operator === '<' && a.operator === '<=' ? b : a;
};

module.exports = subset;