'use strict';

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }
function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }
function _iterableToArrayLimit(r, l) { var t = null == r ? null : "undefined" != typeof Symbol && r[Symbol.iterator] || r["@@iterator"]; if (null != t) { var e, n, i, u, a = [], f = !0, o = !1; try { if (i = (t = t.call(r)).next, 0 === l) { if (Object(t) !== t) return; f = !1; } else for (; !(f = (e = i.call(t)).done) && (a.push(e.value), a.length !== l); f = !0); } catch (r) { o = !0, n = r; } finally { try { if (!f && null != t["return"] && (u = t["return"](), Object(u) !== u)) return; } finally { if (o) throw n; } } return a; } }
function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }
function _createForOfIteratorHelper(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (!it) { if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e) { throw _e; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var normalCompletion = true, didErr = false, err; return { s: function s() { it = it.call(o); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e2) { didErr = true; err = _e2; }, f: function f() { try { if (!normalCompletion && it["return"] != null) it["return"](); } finally { if (didErr) throw err; } } }; }
function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }
function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) arr2[i] = arr[i]; return arr2; }
function _get() { if (typeof Reflect !== "undefined" && Reflect.get) { _get = Reflect.get.bind(); } else { _get = function _get(target, property, receiver) { var base = _superPropBase(target, property); if (!base) return; var desc = Object.getOwnPropertyDescriptor(base, property); if (desc.get) { return desc.get.call(arguments.length < 3 ? target : receiver); } return desc.value; }; } return _get.apply(this, arguments); }
function _superPropBase(object, property) { while (!Object.prototype.hasOwnProperty.call(object, property)) { object = _getPrototypeOf(object); if (object === null) break; } return object; }
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
var prosemirrorState = require('prosemirror-state');
var prosemirrorModel = require('prosemirror-model');
var prosemirrorTransform = require('prosemirror-transform');
var domIndex = function domIndex(node) {
  for (var index = 0;; index++) {
    node = node.previousSibling;
    if (!node) return index;
  }
};
var parentNode = function parentNode(node) {
  var parent = node.assignedSlot || node.parentNode;
  return parent && parent.nodeType == 11 ? parent.host : parent;
};
var reusedRange = null;
var textRange = function textRange(node, from, to) {
  var range = reusedRange || (reusedRange = document.createRange());
  range.setEnd(node, to == null ? node.nodeValue.length : to);
  range.setStart(node, from || 0);
  return range;
};
var clearReusedRange = function clearReusedRange() {
  reusedRange = null;
};
var isEquivalentPosition = function isEquivalentPosition(node, off, targetNode, targetOff) {
  return targetNode && (scanFor(node, off, targetNode, targetOff, -1) || scanFor(node, off, targetNode, targetOff, 1));
};
var atomElements = /^(img|br|input|textarea|hr)$/i;
function scanFor(node, off, targetNode, targetOff, dir) {
  for (;;) {
    if (node == targetNode && off == targetOff) return true;
    if (off == (dir < 0 ? 0 : nodeSize(node))) {
      var parent = node.parentNode;
      if (!parent || parent.nodeType != 1 || hasBlockDesc(node) || atomElements.test(node.nodeName) || node.contentEditable == "false") return false;
      off = domIndex(node) + (dir < 0 ? 0 : 1);
      node = parent;
    } else if (node.nodeType == 1) {
      node = node.childNodes[off + (dir < 0 ? -1 : 0)];
      if (node.contentEditable == "false") return false;
      off = dir < 0 ? nodeSize(node) : 0;
    } else {
      return false;
    }
  }
}
function nodeSize(node) {
  return node.nodeType == 3 ? node.nodeValue.length : node.childNodes.length;
}
function textNodeBefore$1(node, offset) {
  for (;;) {
    if (node.nodeType == 3 && offset) return node;
    if (node.nodeType == 1 && offset > 0) {
      if (node.contentEditable == "false") return null;
      node = node.childNodes[offset - 1];
      offset = nodeSize(node);
    } else if (node.parentNode && !hasBlockDesc(node)) {
      offset = domIndex(node);
      node = node.parentNode;
    } else {
      return null;
    }
  }
}
function textNodeAfter$1(node, offset) {
  for (;;) {
    if (node.nodeType == 3 && offset < node.nodeValue.length) return node;
    if (node.nodeType == 1 && offset < node.childNodes.length) {
      if (node.contentEditable == "false") return null;
      node = node.childNodes[offset];
      offset = 0;
    } else if (node.parentNode && !hasBlockDesc(node)) {
      offset = domIndex(node) + 1;
      node = node.parentNode;
    } else {
      return null;
    }
  }
}
function isOnEdge(node, offset, parent) {
  for (var atStart = offset == 0, atEnd = offset == nodeSize(node); atStart || atEnd;) {
    if (node == parent) return true;
    var index = domIndex(node);
    node = node.parentNode;
    if (!node) return false;
    atStart = atStart && index == 0;
    atEnd = atEnd && index == nodeSize(node);
  }
}
function hasBlockDesc(dom) {
  var desc;
  for (var cur = dom; cur; cur = cur.parentNode) if (desc = cur.pmViewDesc) break;
  return desc && desc.node && desc.node.isBlock && (desc.dom == dom || desc.contentDOM == dom);
}
var selectionCollapsed = function selectionCollapsed(domSel) {
  return domSel.focusNode && isEquivalentPosition(domSel.focusNode, domSel.focusOffset, domSel.anchorNode, domSel.anchorOffset);
};
function keyEvent(keyCode, key) {
  var event = document.createEvent("Event");
  event.initEvent("keydown", true, true);
  event.keyCode = keyCode;
  event.key = event.code = key;
  return event;
}
function deepActiveElement(doc) {
  var elt = doc.activeElement;
  while (elt && elt.shadowRoot) elt = elt.shadowRoot.activeElement;
  return elt;
}
function caretFromPoint(doc, x, y) {
  if (doc.caretPositionFromPoint) {
    try {
      var pos = doc.caretPositionFromPoint(x, y);
      if (pos) return {
        node: pos.offsetNode,
        offset: Math.min(nodeSize(pos.offsetNode), pos.offset)
      };
    } catch (_) {}
  }
  if (doc.caretRangeFromPoint) {
    var range = doc.caretRangeFromPoint(x, y);
    if (range) return {
      node: range.startContainer,
      offset: Math.min(nodeSize(range.startContainer), range.startOffset)
    };
  }
}
var nav = typeof navigator != "undefined" ? navigator : null;
var doc = typeof document != "undefined" ? document : null;
var agent = nav && nav.userAgent || "";
var ie_edge = /Edge\/(\d+)/.exec(agent);
var ie_upto10 = /MSIE \d/.exec(agent);
var ie_11up = /Trident\/(?:[7-9]|\d{2,})\..*rv:(\d+)/.exec(agent);
var ie = !!(ie_upto10 || ie_11up || ie_edge);
var ie_version = ie_upto10 ? document.documentMode : ie_11up ? +ie_11up[1] : ie_edge ? +ie_edge[1] : 0;
var gecko = !ie && /gecko\/(\d+)/i.test(agent);
gecko && +(/Firefox\/(\d+)/.exec(agent) || [0, 0])[1];
var _chrome = !ie && /Chrome\/(\d+)/.exec(agent);
var chrome = !!_chrome;
var chrome_version = _chrome ? +_chrome[1] : 0;
var safari = !ie && !!nav && /Apple Computer/.test(nav.vendor);
var ios = safari && (/Mobile\/\w+/.test(agent) || !!nav && nav.maxTouchPoints > 2);
var mac = ios || (nav ? /Mac/.test(nav.platform) : false);
var windows = nav ? /Win/.test(nav.platform) : false;
var android = /Android \d/.test(agent);
var webkit = !!doc && "webkitFontSmoothing" in doc.documentElement.style;
var webkit_version = webkit ? +(/\bAppleWebKit\/(\d+)/.exec(navigator.userAgent) || [0, 0])[1] : 0;
function windowRect(doc) {
  var vp = doc.defaultView && doc.defaultView.visualViewport;
  if (vp) return {
    left: 0,
    right: vp.width,
    top: 0,
    bottom: vp.height
  };
  return {
    left: 0,
    right: doc.documentElement.clientWidth,
    top: 0,
    bottom: doc.documentElement.clientHeight
  };
}
function getSide(value, side) {
  return typeof value == "number" ? value : value[side];
}
function clientRect(node) {
  var rect = node.getBoundingClientRect();
  var scaleX = rect.width / node.offsetWidth || 1;
  var scaleY = rect.height / node.offsetHeight || 1;
  return {
    left: rect.left,
    right: rect.left + node.clientWidth * scaleX,
    top: rect.top,
    bottom: rect.top + node.clientHeight * scaleY
  };
}
function scrollRectIntoView(view, rect, startDOM) {
  var scrollThreshold = view.someProp("scrollThreshold") || 0,
    scrollMargin = view.someProp("scrollMargin") || 5;
  var doc = view.dom.ownerDocument;
  for (var parent = startDOM || view.dom;; parent = parentNode(parent)) {
    if (!parent) break;
    if (parent.nodeType != 1) continue;
    var elt = parent;
    var atTop = elt == doc.body;
    var bounding = atTop ? windowRect(doc) : clientRect(elt);
    var moveX = 0,
      moveY = 0;
    if (rect.top < bounding.top + getSide(scrollThreshold, "top")) moveY = -(bounding.top - rect.top + getSide(scrollMargin, "top"));else if (rect.bottom > bounding.bottom - getSide(scrollThreshold, "bottom")) moveY = rect.bottom - rect.top > bounding.bottom - bounding.top ? rect.top + getSide(scrollMargin, "top") - bounding.top : rect.bottom - bounding.bottom + getSide(scrollMargin, "bottom");
    if (rect.left < bounding.left + getSide(scrollThreshold, "left")) moveX = -(bounding.left - rect.left + getSide(scrollMargin, "left"));else if (rect.right > bounding.right - getSide(scrollThreshold, "right")) moveX = rect.right - bounding.right + getSide(scrollMargin, "right");
    if (moveX || moveY) {
      if (atTop) {
        doc.defaultView.scrollBy(moveX, moveY);
      } else {
        var startX = elt.scrollLeft,
          startY = elt.scrollTop;
        if (moveY) elt.scrollTop += moveY;
        if (moveX) elt.scrollLeft += moveX;
        var dX = elt.scrollLeft - startX,
          dY = elt.scrollTop - startY;
        rect = {
          left: rect.left - dX,
          top: rect.top - dY,
          right: rect.right - dX,
          bottom: rect.bottom - dY
        };
      }
    }
    if (atTop || /^(fixed|sticky)$/.test(getComputedStyle(parent).position)) break;
  }
}
function storeScrollPos(view) {
  var rect = view.dom.getBoundingClientRect(),
    startY = Math.max(0, rect.top);
  var refDOM, refTop;
  for (var x = (rect.left + rect.right) / 2, y = startY + 1; y < Math.min(innerHeight, rect.bottom); y += 5) {
    var dom = view.root.elementFromPoint(x, y);
    if (!dom || dom == view.dom || !view.dom.contains(dom)) continue;
    var localRect = dom.getBoundingClientRect();
    if (localRect.top >= startY - 20) {
      refDOM = dom;
      refTop = localRect.top;
      break;
    }
  }
  return {
    refDOM: refDOM,
    refTop: refTop,
    stack: scrollStack(view.dom)
  };
}
function scrollStack(dom) {
  var stack = [],
    doc = dom.ownerDocument;
  for (var cur = dom; cur; cur = parentNode(cur)) {
    stack.push({
      dom: cur,
      top: cur.scrollTop,
      left: cur.scrollLeft
    });
    if (dom == doc) break;
  }
  return stack;
}
function resetScrollPos(_ref) {
  var refDOM = _ref.refDOM,
    refTop = _ref.refTop,
    stack = _ref.stack;
  var newRefTop = refDOM ? refDOM.getBoundingClientRect().top : 0;
  restoreScrollStack(stack, newRefTop == 0 ? 0 : newRefTop - refTop);
}
function restoreScrollStack(stack, dTop) {
  for (var i = 0; i < stack.length; i++) {
    var _stack$i = stack[i],
      dom = _stack$i.dom,
      top = _stack$i.top,
      left = _stack$i.left;
    if (dom.scrollTop != top + dTop) dom.scrollTop = top + dTop;
    if (dom.scrollLeft != left) dom.scrollLeft = left;
  }
}
var preventScrollSupported = null;
function focusPreventScroll(dom) {
  if (dom.setActive) return dom.setActive();
  if (preventScrollSupported) return dom.focus(preventScrollSupported);
  var stored = scrollStack(dom);
  dom.focus(preventScrollSupported == null ? {
    get preventScroll() {
      preventScrollSupported = {
        preventScroll: true
      };
      return true;
    }
  } : undefined);
  if (!preventScrollSupported) {
    preventScrollSupported = false;
    restoreScrollStack(stored, 0);
  }
}
function findOffsetInNode(node, coords) {
  var closest,
    dxClosest = 2e8,
    coordsClosest,
    offset = 0;
  var rowBot = coords.top,
    rowTop = coords.top;
  var firstBelow, coordsBelow;
  for (var child = node.firstChild, childIndex = 0; child; child = child.nextSibling, childIndex++) {
    var rects = void 0;
    if (child.nodeType == 1) rects = child.getClientRects();else if (child.nodeType == 3) rects = textRange(child).getClientRects();else continue;
    for (var i = 0; i < rects.length; i++) {
      var rect = rects[i];
      if (rect.top <= rowBot && rect.bottom >= rowTop) {
        rowBot = Math.max(rect.bottom, rowBot);
        rowTop = Math.min(rect.top, rowTop);
        var dx = rect.left > coords.left ? rect.left - coords.left : rect.right < coords.left ? coords.left - rect.right : 0;
        if (dx < dxClosest) {
          closest = child;
          dxClosest = dx;
          coordsClosest = dx && closest.nodeType == 3 ? {
            left: rect.right < coords.left ? rect.right : rect.left,
            top: coords.top
          } : coords;
          if (child.nodeType == 1 && dx) offset = childIndex + (coords.left >= (rect.left + rect.right) / 2 ? 1 : 0);
          continue;
        }
      } else if (rect.top > coords.top && !firstBelow && rect.left <= coords.left && rect.right >= coords.left) {
        firstBelow = child;
        coordsBelow = {
          left: Math.max(rect.left, Math.min(rect.right, coords.left)),
          top: rect.top
        };
      }
      if (!closest && (coords.left >= rect.right && coords.top >= rect.top || coords.left >= rect.left && coords.top >= rect.bottom)) offset = childIndex + 1;
    }
  }
  if (!closest && firstBelow) {
    closest = firstBelow;
    coordsClosest = coordsBelow;
    dxClosest = 0;
  }
  if (closest && closest.nodeType == 3) return findOffsetInText(closest, coordsClosest);
  if (!closest || dxClosest && closest.nodeType == 1) return {
    node: node,
    offset: offset
  };
  return findOffsetInNode(closest, coordsClosest);
}
function findOffsetInText(node, coords) {
  var len = node.nodeValue.length;
  var range = document.createRange();
  for (var i = 0; i < len; i++) {
    range.setEnd(node, i + 1);
    range.setStart(node, i);
    var rect = singleRect(range, 1);
    if (rect.top == rect.bottom) continue;
    if (inRect(coords, rect)) return {
      node: node,
      offset: i + (coords.left >= (rect.left + rect.right) / 2 ? 1 : 0)
    };
  }
  return {
    node: node,
    offset: 0
  };
}
function inRect(coords, rect) {
  return coords.left >= rect.left - 1 && coords.left <= rect.right + 1 && coords.top >= rect.top - 1 && coords.top <= rect.bottom + 1;
}
function targetKludge(dom, coords) {
  var parent = dom.parentNode;
  if (parent && /^li$/i.test(parent.nodeName) && coords.left < dom.getBoundingClientRect().left) return parent;
  return dom;
}
function posFromElement(view, elt, coords) {
  var _findOffsetInNode = findOffsetInNode(elt, coords),
    node = _findOffsetInNode.node,
    offset = _findOffsetInNode.offset,
    bias = -1;
  if (node.nodeType == 1 && !node.firstChild) {
    var rect = node.getBoundingClientRect();
    bias = rect.left != rect.right && coords.left > (rect.left + rect.right) / 2 ? 1 : -1;
  }
  return view.docView.posFromDOM(node, offset, bias);
}
function posFromCaret(view, node, offset, coords) {
  var outsideBlock = -1;
  for (var cur = node, sawBlock = false;;) {
    if (cur == view.dom) break;
    var desc = view.docView.nearestDesc(cur, true);
    if (!desc) return null;
    if (desc.dom.nodeType == 1 && (desc.node.isBlock && desc.parent || !desc.contentDOM)) {
      var rect = desc.dom.getBoundingClientRect();
      if (desc.node.isBlock && desc.parent) {
        if (!sawBlock && rect.left > coords.left || rect.top > coords.top) outsideBlock = desc.posBefore;else if (!sawBlock && rect.right < coords.left || rect.bottom < coords.top) outsideBlock = desc.posAfter;
        sawBlock = true;
      }
      if (!desc.contentDOM && outsideBlock < 0 && !desc.node.isText) {
        var before = desc.node.isBlock ? coords.top < (rect.top + rect.bottom) / 2 : coords.left < (rect.left + rect.right) / 2;
        return before ? desc.posBefore : desc.posAfter;
      }
    }
    cur = desc.dom.parentNode;
  }
  return outsideBlock > -1 ? outsideBlock : view.docView.posFromDOM(node, offset, -1);
}
function elementFromPoint(element, coords, box) {
  var len = element.childNodes.length;
  if (len && box.top < box.bottom) {
    for (var startI = Math.max(0, Math.min(len - 1, Math.floor(len * (coords.top - box.top) / (box.bottom - box.top)) - 2)), i = startI;;) {
      var child = element.childNodes[i];
      if (child.nodeType == 1) {
        var rects = child.getClientRects();
        for (var j = 0; j < rects.length; j++) {
          var rect = rects[j];
          if (inRect(coords, rect)) return elementFromPoint(child, coords, rect);
        }
      }
      if ((i = (i + 1) % len) == startI) break;
    }
  }
  return element;
}
function _posAtCoords(view, coords) {
  var doc = view.dom.ownerDocument,
    node,
    offset = 0;
  var caret = caretFromPoint(doc, coords.left, coords.top);
  if (caret) {
    node = caret.node;
    offset = caret.offset;
  }
  var elt = (view.root.elementFromPoint ? view.root : doc).elementFromPoint(coords.left, coords.top);
  var pos;
  if (!elt || !view.dom.contains(elt.nodeType != 1 ? elt.parentNode : elt)) {
    var box = view.dom.getBoundingClientRect();
    if (!inRect(coords, box)) return null;
    elt = elementFromPoint(view.dom, coords, box);
    if (!elt) return null;
  }
  if (safari) {
    for (var p = elt; node && p; p = parentNode(p)) if (p.draggable) node = undefined;
  }
  elt = targetKludge(elt, coords);
  if (node) {
    if (gecko && node.nodeType == 1) {
      offset = Math.min(offset, node.childNodes.length);
      if (offset < node.childNodes.length) {
        var next = node.childNodes[offset],
          _box;
        if (next.nodeName == "IMG" && (_box = next.getBoundingClientRect()).right <= coords.left && _box.bottom > coords.top) offset++;
      }
    }
    var prev;
    if (webkit && offset && node.nodeType == 1 && (prev = node.childNodes[offset - 1]).nodeType == 1 && prev.contentEditable == "false" && prev.getBoundingClientRect().top >= coords.top) offset--;
    if (node == view.dom && offset == node.childNodes.length - 1 && node.lastChild.nodeType == 1 && coords.top > node.lastChild.getBoundingClientRect().bottom) pos = view.state.doc.content.size;else if (offset == 0 || node.nodeType != 1 || node.childNodes[offset - 1].nodeName != "BR") pos = posFromCaret(view, node, offset, coords);
  }
  if (pos == null) pos = posFromElement(view, elt, coords);
  var desc = view.docView.nearestDesc(elt, true);
  return {
    pos: pos,
    inside: desc ? desc.posAtStart - desc.border : -1
  };
}
function nonZero(rect) {
  return rect.top < rect.bottom || rect.left < rect.right;
}
function singleRect(target, bias) {
  var rects = target.getClientRects();
  if (rects.length) {
    var first = rects[bias < 0 ? 0 : rects.length - 1];
    if (nonZero(first)) return first;
  }
  return Array.prototype.find.call(rects, nonZero) || target.getBoundingClientRect();
}
var BIDI = /[\u0590-\u05f4\u0600-\u06ff\u0700-\u08ac]/;
function _coordsAtPos(view, pos, side) {
  var _view$docView$domFrom = view.docView.domFromPos(pos, side < 0 ? -1 : 1),
    node = _view$docView$domFrom.node,
    offset = _view$docView$domFrom.offset,
    atom = _view$docView$domFrom.atom;
  var supportEmptyRange = webkit || gecko;
  if (node.nodeType == 3) {
    if (supportEmptyRange && (BIDI.test(node.nodeValue) || (side < 0 ? !offset : offset == node.nodeValue.length))) {
      var rect = singleRect(textRange(node, offset, offset), side);
      if (gecko && offset && /\s/.test(node.nodeValue[offset - 1]) && offset < node.nodeValue.length) {
        var rectBefore = singleRect(textRange(node, offset - 1, offset - 1), -1);
        if (rectBefore.top == rect.top) {
          var rectAfter = singleRect(textRange(node, offset, offset + 1), -1);
          if (rectAfter.top != rect.top) return flattenV(rectAfter, rectAfter.left < rectBefore.left);
        }
      }
      return rect;
    } else {
      var from = offset,
        to = offset,
        takeSide = side < 0 ? 1 : -1;
      if (side < 0 && !offset) {
        to++;
        takeSide = -1;
      } else if (side >= 0 && offset == node.nodeValue.length) {
        from--;
        takeSide = 1;
      } else if (side < 0) {
        from--;
      } else {
        to++;
      }
      return flattenV(singleRect(textRange(node, from, to), takeSide), takeSide < 0);
    }
  }
  var $dom = view.state.doc.resolve(pos - (atom || 0));
  if (!$dom.parent.inlineContent) {
    if (atom == null && offset && (side < 0 || offset == nodeSize(node))) {
      var before = node.childNodes[offset - 1];
      if (before.nodeType == 1) return flattenH(before.getBoundingClientRect(), false);
    }
    if (atom == null && offset < nodeSize(node)) {
      var after = node.childNodes[offset];
      if (after.nodeType == 1) return flattenH(after.getBoundingClientRect(), true);
    }
    return flattenH(node.getBoundingClientRect(), side >= 0);
  }
  if (atom == null && offset && (side < 0 || offset == nodeSize(node))) {
    var _before = node.childNodes[offset - 1];
    var target = _before.nodeType == 3 ? textRange(_before, nodeSize(_before) - (supportEmptyRange ? 0 : 1)) : _before.nodeType == 1 && (_before.nodeName != "BR" || !_before.nextSibling) ? _before : null;
    if (target) return flattenV(singleRect(target, 1), false);
  }
  if (atom == null && offset < nodeSize(node)) {
    var _after = node.childNodes[offset];
    while (_after.pmViewDesc && _after.pmViewDesc.ignoreForCoords) _after = _after.nextSibling;
    var _target = !_after ? null : _after.nodeType == 3 ? textRange(_after, 0, supportEmptyRange ? 0 : 1) : _after.nodeType == 1 ? _after : null;
    if (_target) return flattenV(singleRect(_target, -1), true);
  }
  return flattenV(singleRect(node.nodeType == 3 ? textRange(node) : node, -side), side >= 0);
}
function flattenV(rect, left) {
  if (rect.width == 0) return rect;
  var x = left ? rect.left : rect.right;
  return {
    top: rect.top,
    bottom: rect.bottom,
    left: x,
    right: x
  };
}
function flattenH(rect, top) {
  if (rect.height == 0) return rect;
  var y = top ? rect.top : rect.bottom;
  return {
    top: y,
    bottom: y,
    left: rect.left,
    right: rect.right
  };
}
function withFlushedState(view, state, f) {
  var viewState = view.state,
    active = view.root.activeElement;
  if (viewState != state) view.updateState(state);
  if (active != view.dom) view.focus();
  try {
    return f();
  } finally {
    if (viewState != state) view.updateState(viewState);
    if (active != view.dom && active) active.focus();
  }
}
function endOfTextblockVertical(view, state, dir) {
  var sel = state.selection;
  var $pos = dir == "up" ? sel.$from : sel.$to;
  return withFlushedState(view, state, function () {
    var _view$docView$domFrom2 = view.docView.domFromPos($pos.pos, dir == "up" ? -1 : 1),
      dom = _view$docView$domFrom2.node;
    for (;;) {
      var nearest = view.docView.nearestDesc(dom, true);
      if (!nearest) break;
      if (nearest.node.isBlock) {
        dom = nearest.contentDOM || nearest.dom;
        break;
      }
      dom = nearest.dom.parentNode;
    }
    var coords = _coordsAtPos(view, $pos.pos, 1);
    for (var child = dom.firstChild; child; child = child.nextSibling) {
      var boxes = void 0;
      if (child.nodeType == 1) boxes = child.getClientRects();else if (child.nodeType == 3) boxes = textRange(child, 0, child.nodeValue.length).getClientRects();else continue;
      for (var i = 0; i < boxes.length; i++) {
        var box = boxes[i];
        if (box.bottom > box.top + 1 && (dir == "up" ? coords.top - box.top > (box.bottom - coords.top) * 2 : box.bottom - coords.bottom > (coords.bottom - box.top) * 2)) return false;
      }
    }
    return true;
  });
}
var maybeRTL = /[\u0590-\u08ac]/;
function endOfTextblockHorizontal(view, state, dir) {
  var $head = state.selection.$head;
  if (!$head.parent.isTextblock) return false;
  var offset = $head.parentOffset,
    atStart = !offset,
    atEnd = offset == $head.parent.content.size;
  var sel = view.domSelection();
  if (!sel) return $head.pos == $head.start() || $head.pos == $head.end();
  if (!maybeRTL.test($head.parent.textContent) || !sel.modify) return dir == "left" || dir == "backward" ? atStart : atEnd;
  return withFlushedState(view, state, function () {
    var _view$domSelectionRan = view.domSelectionRange(),
      oldNode = _view$domSelectionRan.focusNode,
      oldOff = _view$domSelectionRan.focusOffset,
      anchorNode = _view$domSelectionRan.anchorNode,
      anchorOffset = _view$domSelectionRan.anchorOffset;
    var oldBidiLevel = sel.caretBidiLevel;
    sel.modify("move", dir, "character");
    var parentDOM = $head.depth ? view.docView.domAfterPos($head.before()) : view.dom;
    var _view$domSelectionRan2 = view.domSelectionRange(),
      newNode = _view$domSelectionRan2.focusNode,
      newOff = _view$domSelectionRan2.focusOffset;
    var result = newNode && !parentDOM.contains(newNode.nodeType == 1 ? newNode : newNode.parentNode) || oldNode == newNode && oldOff == newOff;
    try {
      sel.collapse(anchorNode, anchorOffset);
      if (oldNode && (oldNode != anchorNode || oldOff != anchorOffset) && sel.extend) sel.extend(oldNode, oldOff);
    } catch (_) {}
    if (oldBidiLevel != null) sel.caretBidiLevel = oldBidiLevel;
    return result;
  });
}
var cachedState = null;
var cachedDir = null;
var cachedResult = false;
function _endOfTextblock(view, state, dir) {
  if (cachedState == state && cachedDir == dir) return cachedResult;
  cachedState = state;
  cachedDir = dir;
  return cachedResult = dir == "up" || dir == "down" ? endOfTextblockVertical(view, state, dir) : endOfTextblockHorizontal(view, state, dir);
}
var NOT_DIRTY = 0,
  CHILD_DIRTY = 1,
  CONTENT_DIRTY = 2,
  NODE_DIRTY = 3;
var ViewDesc = function () {
  function ViewDesc(parent, children, dom, contentDOM) {
    _classCallCheck(this, ViewDesc);
    this.parent = parent;
    this.children = children;
    this.dom = dom;
    this.contentDOM = contentDOM;
    this.dirty = NOT_DIRTY;
    dom.pmViewDesc = this;
  }
  _createClass(ViewDesc, [{
    key: "matchesWidget",
    value: function matchesWidget(widget) {
      return false;
    }
  }, {
    key: "matchesMark",
    value: function matchesMark(mark) {
      return false;
    }
  }, {
    key: "matchesNode",
    value: function matchesNode(node, outerDeco, innerDeco) {
      return false;
    }
  }, {
    key: "matchesHack",
    value: function matchesHack(nodeName) {
      return false;
    }
  }, {
    key: "parseRule",
    value: function parseRule() {
      return null;
    }
  }, {
    key: "stopEvent",
    value: function stopEvent(event) {
      return false;
    }
  }, {
    key: "size",
    get: function get() {
      var size = 0;
      for (var i = 0; i < this.children.length; i++) size += this.children[i].size;
      return size;
    }
  }, {
    key: "border",
    get: function get() {
      return 0;
    }
  }, {
    key: "destroy",
    value: function destroy() {
      this.parent = undefined;
      if (this.dom.pmViewDesc == this) this.dom.pmViewDesc = undefined;
      for (var i = 0; i < this.children.length; i++) this.children[i].destroy();
    }
  }, {
    key: "posBeforeChild",
    value: function posBeforeChild(child) {
      for (var i = 0, pos = this.posAtStart;; i++) {
        var cur = this.children[i];
        if (cur == child) return pos;
        pos += cur.size;
      }
    }
  }, {
    key: "posBefore",
    get: function get() {
      return this.parent.posBeforeChild(this);
    }
  }, {
    key: "posAtStart",
    get: function get() {
      return this.parent ? this.parent.posBeforeChild(this) + this.border : 0;
    }
  }, {
    key: "posAfter",
    get: function get() {
      return this.posBefore + this.size;
    }
  }, {
    key: "posAtEnd",
    get: function get() {
      return this.posAtStart + this.size - 2 * this.border;
    }
  }, {
    key: "localPosFromDOM",
    value: function localPosFromDOM(dom, offset, bias) {
      if (this.contentDOM && this.contentDOM.contains(dom.nodeType == 1 ? dom : dom.parentNode)) {
        if (bias < 0) {
          var domBefore, desc;
          if (dom == this.contentDOM) {
            domBefore = dom.childNodes[offset - 1];
          } else {
            while (dom.parentNode != this.contentDOM) dom = dom.parentNode;
            domBefore = dom.previousSibling;
          }
          while (domBefore && !((desc = domBefore.pmViewDesc) && desc.parent == this)) domBefore = domBefore.previousSibling;
          return domBefore ? this.posBeforeChild(desc) + desc.size : this.posAtStart;
        } else {
          var domAfter, _desc;
          if (dom == this.contentDOM) {
            domAfter = dom.childNodes[offset];
          } else {
            while (dom.parentNode != this.contentDOM) dom = dom.parentNode;
            domAfter = dom.nextSibling;
          }
          while (domAfter && !((_desc = domAfter.pmViewDesc) && _desc.parent == this)) domAfter = domAfter.nextSibling;
          return domAfter ? this.posBeforeChild(_desc) : this.posAtEnd;
        }
      }
      var atEnd;
      if (dom == this.dom && this.contentDOM) {
        atEnd = offset > domIndex(this.contentDOM);
      } else if (this.contentDOM && this.contentDOM != this.dom && this.dom.contains(this.contentDOM)) {
        atEnd = dom.compareDocumentPosition(this.contentDOM) & 2;
      } else if (this.dom.firstChild) {
        if (offset == 0) for (var search = dom;; search = search.parentNode) {
          if (search == this.dom) {
            atEnd = false;
            break;
          }
          if (search.previousSibling) break;
        }
        if (atEnd == null && offset == dom.childNodes.length) for (var _search = dom;; _search = _search.parentNode) {
          if (_search == this.dom) {
            atEnd = true;
            break;
          }
          if (_search.nextSibling) break;
        }
      }
      return (atEnd == null ? bias > 0 : atEnd) ? this.posAtEnd : this.posAtStart;
    }
  }, {
    key: "nearestDesc",
    value: function nearestDesc(dom) {
      var onlyNodes = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
      for (var first = true, cur = dom; cur; cur = cur.parentNode) {
        var desc = this.getDesc(cur),
          nodeDOM = void 0;
        if (desc && (!onlyNodes || desc.node)) {
          if (first && (nodeDOM = desc.nodeDOM) && !(nodeDOM.nodeType == 1 ? nodeDOM.contains(dom.nodeType == 1 ? dom : dom.parentNode) : nodeDOM == dom)) first = false;else return desc;
        }
      }
    }
  }, {
    key: "getDesc",
    value: function getDesc(dom) {
      var desc = dom.pmViewDesc;
      for (var cur = desc; cur; cur = cur.parent) if (cur == this) return desc;
    }
  }, {
    key: "posFromDOM",
    value: function posFromDOM(dom, offset, bias) {
      for (var scan = dom; scan; scan = scan.parentNode) {
        var desc = this.getDesc(scan);
        if (desc) return desc.localPosFromDOM(dom, offset, bias);
      }
      return -1;
    }
  }, {
    key: "descAt",
    value: function descAt(pos) {
      for (var i = 0, offset = 0; i < this.children.length; i++) {
        var child = this.children[i],
          end = offset + child.size;
        if (offset == pos && end != offset) {
          while (!child.border && child.children.length) child = child.children[0];
          return child;
        }
        if (pos < end) return child.descAt(pos - offset - child.border);
        offset = end;
      }
    }
  }, {
    key: "domFromPos",
    value: function domFromPos(pos, side) {
      if (!this.contentDOM) return {
        node: this.dom,
        offset: 0,
        atom: pos + 1
      };
      var i = 0,
        offset = 0;
      for (var curPos = 0; i < this.children.length; i++) {
        var child = this.children[i],
          end = curPos + child.size;
        if (end > pos || child instanceof TrailingHackViewDesc) {
          offset = pos - curPos;
          break;
        }
        curPos = end;
      }
      if (offset) return this.children[i].domFromPos(offset - this.children[i].border, side);
      for (var prev; i && !(prev = this.children[i - 1]).size && prev instanceof WidgetViewDesc && prev.side >= 0; i--) {}
      if (side <= 0) {
        var _prev,
          enter = true;
        for (;; i--, enter = false) {
          _prev = i ? this.children[i - 1] : null;
          if (!_prev || _prev.dom.parentNode == this.contentDOM) break;
        }
        if (_prev && side && enter && !_prev.border && !_prev.domAtom) return _prev.domFromPos(_prev.size, side);
        return {
          node: this.contentDOM,
          offset: _prev ? domIndex(_prev.dom) + 1 : 0
        };
      } else {
        var next,
          _enter = true;
        for (;; i++, _enter = false) {
          next = i < this.children.length ? this.children[i] : null;
          if (!next || next.dom.parentNode == this.contentDOM) break;
        }
        if (next && _enter && !next.border && !next.domAtom) return next.domFromPos(0, side);
        return {
          node: this.contentDOM,
          offset: next ? domIndex(next.dom) : this.contentDOM.childNodes.length
        };
      }
    }
  }, {
    key: "parseRange",
    value: function parseRange(from, to) {
      var base = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;
      if (this.children.length == 0) return {
        node: this.contentDOM,
        from: from,
        to: to,
        fromOffset: 0,
        toOffset: this.contentDOM.childNodes.length
      };
      var fromOffset = -1,
        toOffset = -1;
      for (var offset = base, i = 0;; i++) {
        var child = this.children[i],
          end = offset + child.size;
        if (fromOffset == -1 && from <= end) {
          var childBase = offset + child.border;
          if (from >= childBase && to <= end - child.border && child.node && child.contentDOM && this.contentDOM.contains(child.contentDOM)) return child.parseRange(from, to, childBase);
          from = offset;
          for (var j = i; j > 0; j--) {
            var prev = this.children[j - 1];
            if (prev.size && prev.dom.parentNode == this.contentDOM && !prev.emptyChildAt(1)) {
              fromOffset = domIndex(prev.dom) + 1;
              break;
            }
            from -= prev.size;
          }
          if (fromOffset == -1) fromOffset = 0;
        }
        if (fromOffset > -1 && (end > to || i == this.children.length - 1)) {
          to = end;
          for (var _j = i + 1; _j < this.children.length; _j++) {
            var next = this.children[_j];
            if (next.size && next.dom.parentNode == this.contentDOM && !next.emptyChildAt(-1)) {
              toOffset = domIndex(next.dom);
              break;
            }
            to += next.size;
          }
          if (toOffset == -1) toOffset = this.contentDOM.childNodes.length;
          break;
        }
        offset = end;
      }
      return {
        node: this.contentDOM,
        from: from,
        to: to,
        fromOffset: fromOffset,
        toOffset: toOffset
      };
    }
  }, {
    key: "emptyChildAt",
    value: function emptyChildAt(side) {
      if (this.border || !this.contentDOM || !this.children.length) return false;
      var child = this.children[side < 0 ? 0 : this.children.length - 1];
      return child.size == 0 || child.emptyChildAt(side);
    }
  }, {
    key: "domAfterPos",
    value: function domAfterPos(pos) {
      var _this$domFromPos = this.domFromPos(pos, 0),
        node = _this$domFromPos.node,
        offset = _this$domFromPos.offset;
      if (node.nodeType != 1 || offset == node.childNodes.length) throw new RangeError("No node after pos " + pos);
      return node.childNodes[offset];
    }
  }, {
    key: "setSelection",
    value: function setSelection(anchor, head, root) {
      var force = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : false;
      var from = Math.min(anchor, head),
        to = Math.max(anchor, head);
      for (var i = 0, offset = 0; i < this.children.length; i++) {
        var child = this.children[i],
          end = offset + child.size;
        if (from > offset && to < end) return child.setSelection(anchor - offset - child.border, head - offset - child.border, root, force);
        offset = end;
      }
      var anchorDOM = this.domFromPos(anchor, anchor ? -1 : 1);
      var headDOM = head == anchor ? anchorDOM : this.domFromPos(head, head ? -1 : 1);
      var domSel = root.getSelection();
      var brKludge = false;
      if ((gecko || safari) && anchor == head) {
        var _anchorDOM = anchorDOM,
          node = _anchorDOM.node,
          _offset = _anchorDOM.offset;
        if (node.nodeType == 3) {
          brKludge = !!(_offset && node.nodeValue[_offset - 1] == "\n");
          if (brKludge && _offset == node.nodeValue.length) {
            for (var scan = node, after; scan; scan = scan.parentNode) {
              if (after = scan.nextSibling) {
                if (after.nodeName == "BR") anchorDOM = headDOM = {
                  node: after.parentNode,
                  offset: domIndex(after) + 1
                };
                break;
              }
              var desc = scan.pmViewDesc;
              if (desc && desc.node && desc.node.isBlock) break;
            }
          }
        } else {
          var prev = node.childNodes[_offset - 1];
          brKludge = prev && (prev.nodeName == "BR" || prev.contentEditable == "false");
        }
      }
      if (gecko && domSel.focusNode && domSel.focusNode != headDOM.node && domSel.focusNode.nodeType == 1) {
        var _after2 = domSel.focusNode.childNodes[domSel.focusOffset];
        if (_after2 && _after2.contentEditable == "false") force = true;
      }
      if (!(force || brKludge && safari) && isEquivalentPosition(anchorDOM.node, anchorDOM.offset, domSel.anchorNode, domSel.anchorOffset) && isEquivalentPosition(headDOM.node, headDOM.offset, domSel.focusNode, domSel.focusOffset)) return;
      var domSelExtended = false;
      if ((domSel.extend || anchor == head) && !brKludge) {
        domSel.collapse(anchorDOM.node, anchorDOM.offset);
        try {
          if (anchor != head) domSel.extend(headDOM.node, headDOM.offset);
          domSelExtended = true;
        } catch (_) {}
      }
      if (!domSelExtended) {
        if (anchor > head) {
          var tmp = anchorDOM;
          anchorDOM = headDOM;
          headDOM = tmp;
        }
        var range = document.createRange();
        range.setEnd(headDOM.node, headDOM.offset);
        range.setStart(anchorDOM.node, anchorDOM.offset);
        domSel.removeAllRanges();
        domSel.addRange(range);
      }
    }
  }, {
    key: "ignoreMutation",
    value: function ignoreMutation(mutation) {
      return !this.contentDOM && mutation.type != "selection";
    }
  }, {
    key: "contentLost",
    get: function get() {
      return this.contentDOM && this.contentDOM != this.dom && !this.dom.contains(this.contentDOM);
    }
  }, {
    key: "markDirty",
    value: function markDirty(from, to) {
      for (var offset = 0, i = 0; i < this.children.length; i++) {
        var child = this.children[i],
          end = offset + child.size;
        if (offset == end ? from <= end && to >= offset : from < end && to > offset) {
          var startInside = offset + child.border,
            endInside = end - child.border;
          if (from >= startInside && to <= endInside) {
            this.dirty = from == offset || to == end ? CONTENT_DIRTY : CHILD_DIRTY;
            if (from == startInside && to == endInside && (child.contentLost || child.dom.parentNode != this.contentDOM)) child.dirty = NODE_DIRTY;else child.markDirty(from - startInside, to - startInside);
            return;
          } else {
            child.dirty = child.dom == child.contentDOM && child.dom.parentNode == this.contentDOM && !child.children.length ? CONTENT_DIRTY : NODE_DIRTY;
          }
        }
        offset = end;
      }
      this.dirty = CONTENT_DIRTY;
    }
  }, {
    key: "markParentsDirty",
    value: function markParentsDirty() {
      var level = 1;
      for (var node = this.parent; node; node = node.parent, level++) {
        var dirty = level == 1 ? CONTENT_DIRTY : CHILD_DIRTY;
        if (node.dirty < dirty) node.dirty = dirty;
      }
    }
  }, {
    key: "domAtom",
    get: function get() {
      return false;
    }
  }, {
    key: "ignoreForCoords",
    get: function get() {
      return false;
    }
  }, {
    key: "isText",
    value: function isText(text) {
      return false;
    }
  }]);
  return ViewDesc;
}();
var WidgetViewDesc = function (_ViewDesc) {
  _inherits(WidgetViewDesc, _ViewDesc);
  var _super = _createSuper(WidgetViewDesc);
  function WidgetViewDesc(parent, widget, view, pos) {
    var _this;
    _classCallCheck(this, WidgetViewDesc);
    var self,
      dom = widget.type.toDOM;
    if (typeof dom == "function") dom = dom(view, function () {
      if (!self) return pos;
      if (self.parent) return self.parent.posBeforeChild(self);
    });
    if (!widget.type.spec.raw) {
      if (dom.nodeType != 1) {
        var wrap = document.createElement("span");
        wrap.appendChild(dom);
        dom = wrap;
      }
      dom.contentEditable = "false";
      dom.classList.add("ProseMirror-widget");
    }
    _this = _super.call(this, parent, [], dom, null);
    _this.widget = widget;
    _this.widget = widget;
    self = _assertThisInitialized(_this);
    return _this;
  }
  _createClass(WidgetViewDesc, [{
    key: "matchesWidget",
    value: function matchesWidget(widget) {
      return this.dirty == NOT_DIRTY && widget.type.eq(this.widget.type);
    }
  }, {
    key: "parseRule",
    value: function parseRule() {
      return {
        ignore: true
      };
    }
  }, {
    key: "stopEvent",
    value: function stopEvent(event) {
      var stop = this.widget.spec.stopEvent;
      return stop ? stop(event) : false;
    }
  }, {
    key: "ignoreMutation",
    value: function ignoreMutation(mutation) {
      return mutation.type != "selection" || this.widget.spec.ignoreSelection;
    }
  }, {
    key: "destroy",
    value: function destroy() {
      this.widget.type.destroy(this.dom);
      _get(_getPrototypeOf(WidgetViewDesc.prototype), "destroy", this).call(this);
    }
  }, {
    key: "domAtom",
    get: function get() {
      return true;
    }
  }, {
    key: "side",
    get: function get() {
      return this.widget.type.side;
    }
  }]);
  return WidgetViewDesc;
}(ViewDesc);
var CompositionViewDesc = function (_ViewDesc2) {
  _inherits(CompositionViewDesc, _ViewDesc2);
  var _super2 = _createSuper(CompositionViewDesc);
  function CompositionViewDesc(parent, dom, textDOM, text) {
    var _this2;
    _classCallCheck(this, CompositionViewDesc);
    _this2 = _super2.call(this, parent, [], dom, null);
    _this2.textDOM = textDOM;
    _this2.text = text;
    return _this2;
  }
  _createClass(CompositionViewDesc, [{
    key: "size",
    get: function get() {
      return this.text.length;
    }
  }, {
    key: "localPosFromDOM",
    value: function localPosFromDOM(dom, offset) {
      if (dom != this.textDOM) return this.posAtStart + (offset ? this.size : 0);
      return this.posAtStart + offset;
    }
  }, {
    key: "domFromPos",
    value: function domFromPos(pos) {
      return {
        node: this.textDOM,
        offset: pos
      };
    }
  }, {
    key: "ignoreMutation",
    value: function ignoreMutation(mut) {
      return mut.type === 'characterData' && mut.target.nodeValue == mut.oldValue;
    }
  }]);
  return CompositionViewDesc;
}(ViewDesc);
var MarkViewDesc = function (_ViewDesc3) {
  _inherits(MarkViewDesc, _ViewDesc3);
  var _super3 = _createSuper(MarkViewDesc);
  function MarkViewDesc(parent, mark, dom, contentDOM) {
    var _this3;
    _classCallCheck(this, MarkViewDesc);
    _this3 = _super3.call(this, parent, [], dom, contentDOM);
    _this3.mark = mark;
    return _this3;
  }
  _createClass(MarkViewDesc, [{
    key: "parseRule",
    value: function parseRule() {
      if (this.dirty & NODE_DIRTY || this.mark.type.spec.reparseInView) return null;
      return {
        mark: this.mark.type.name,
        attrs: this.mark.attrs,
        contentElement: this.contentDOM
      };
    }
  }, {
    key: "matchesMark",
    value: function matchesMark(mark) {
      return this.dirty != NODE_DIRTY && this.mark.eq(mark);
    }
  }, {
    key: "markDirty",
    value: function markDirty(from, to) {
      _get(_getPrototypeOf(MarkViewDesc.prototype), "markDirty", this).call(this, from, to);
      if (this.dirty != NOT_DIRTY) {
        var parent = this.parent;
        while (!parent.node) parent = parent.parent;
        if (parent.dirty < this.dirty) parent.dirty = this.dirty;
        this.dirty = NOT_DIRTY;
      }
    }
  }, {
    key: "slice",
    value: function slice(from, to, view) {
      var copy = MarkViewDesc.create(this.parent, this.mark, true, view);
      var nodes = this.children,
        size = this.size;
      if (to < size) nodes = replaceNodes(nodes, to, size, view);
      if (from > 0) nodes = replaceNodes(nodes, 0, from, view);
      for (var i = 0; i < nodes.length; i++) nodes[i].parent = copy;
      copy.children = nodes;
      return copy;
    }
  }], [{
    key: "create",
    value: function create(parent, mark, inline, view) {
      var custom = view.nodeViews[mark.type.name];
      var spec = custom && custom(mark, view, inline);
      if (!spec || !spec.dom) spec = prosemirrorModel.DOMSerializer.renderSpec(document, mark.type.spec.toDOM(mark, inline), null, mark.attrs);
      return new MarkViewDesc(parent, mark, spec.dom, spec.contentDOM || spec.dom);
    }
  }]);
  return MarkViewDesc;
}(ViewDesc);
var NodeViewDesc = function (_ViewDesc4) {
  _inherits(NodeViewDesc, _ViewDesc4);
  var _super4 = _createSuper(NodeViewDesc);
  function NodeViewDesc(parent, node, outerDeco, innerDeco, dom, contentDOM, nodeDOM, view, pos) {
    var _this4;
    _classCallCheck(this, NodeViewDesc);
    _this4 = _super4.call(this, parent, [], dom, contentDOM);
    _this4.node = node;
    _this4.outerDeco = outerDeco;
    _this4.innerDeco = innerDeco;
    _this4.nodeDOM = nodeDOM;
    return _this4;
  }
  _createClass(NodeViewDesc, [{
    key: "parseRule",
    value: function parseRule() {
      var _this5 = this;
      if (this.node.type.spec.reparseInView) return null;
      var rule = {
        node: this.node.type.name,
        attrs: this.node.attrs
      };
      if (this.node.type.whitespace == "pre") rule.preserveWhitespace = "full";
      if (!this.contentDOM) {
        rule.getContent = function () {
          return _this5.node.content;
        };
      } else if (!this.contentLost) {
        rule.contentElement = this.contentDOM;
      } else {
        for (var i = this.children.length - 1; i >= 0; i--) {
          var child = this.children[i];
          if (this.dom.contains(child.dom.parentNode)) {
            rule.contentElement = child.dom.parentNode;
            break;
          }
        }
        if (!rule.contentElement) rule.getContent = function () {
          return prosemirrorModel.Fragment.empty;
        };
      }
      return rule;
    }
  }, {
    key: "matchesNode",
    value: function matchesNode(node, outerDeco, innerDeco) {
      return this.dirty == NOT_DIRTY && node.eq(this.node) && sameOuterDeco(outerDeco, this.outerDeco) && innerDeco.eq(this.innerDeco);
    }
  }, {
    key: "size",
    get: function get() {
      return this.node.nodeSize;
    }
  }, {
    key: "border",
    get: function get() {
      return this.node.isLeaf ? 0 : 1;
    }
  }, {
    key: "updateChildren",
    value: function updateChildren(view, pos) {
      var _this6 = this;
      var inline = this.node.inlineContent,
        off = pos;
      var composition = view.composing ? this.localCompositionInfo(view, pos) : null;
      var localComposition = composition && composition.pos > -1 ? composition : null;
      var compositionInChild = composition && composition.pos < 0;
      var updater = new ViewTreeUpdater(this, localComposition && localComposition.node, view);
      iterDeco(this.node, this.innerDeco, function (widget, i, insideNode) {
        if (widget.spec.marks) updater.syncToMarks(widget.spec.marks, inline, view);else if (widget.type.side >= 0 && !insideNode) updater.syncToMarks(i == _this6.node.childCount ? prosemirrorModel.Mark.none : _this6.node.child(i).marks, inline, view);
        updater.placeWidget(widget, view, off);
      }, function (child, outerDeco, innerDeco, i) {
        updater.syncToMarks(child.marks, inline, view);
        var compIndex;
        if (updater.findNodeMatch(child, outerDeco, innerDeco, i)) ;else if (compositionInChild && view.state.selection.from > off && view.state.selection.to < off + child.nodeSize && (compIndex = updater.findIndexWithChild(composition.node)) > -1 && updater.updateNodeAt(child, outerDeco, innerDeco, compIndex, view)) ;else if (updater.updateNextNode(child, outerDeco, innerDeco, view, i, off)) ;else {
          updater.addNode(child, outerDeco, innerDeco, view, off);
        }
        off += child.nodeSize;
      });
      updater.syncToMarks([], inline, view);
      if (this.node.isTextblock) updater.addTextblockHacks();
      updater.destroyRest();
      if (updater.changed || this.dirty == CONTENT_DIRTY) {
        if (localComposition) this.protectLocalComposition(view, localComposition);
        renderDescs(this.contentDOM, this.children, view);
        if (ios) iosHacks(this.dom);
      }
    }
  }, {
    key: "localCompositionInfo",
    value: function localCompositionInfo(view, pos) {
      var _view$state$selection = view.state.selection,
        from = _view$state$selection.from,
        to = _view$state$selection.to;
      if (!(view.state.selection instanceof prosemirrorState.TextSelection) || from < pos || to > pos + this.node.content.size) return null;
      var textNode = view.input.compositionNode;
      if (!textNode || !this.dom.contains(textNode.parentNode)) return null;
      if (this.node.inlineContent) {
        var text = textNode.nodeValue;
        var textPos = findTextInFragment(this.node.content, text, from - pos, to - pos);
        return textPos < 0 ? null : {
          node: textNode,
          pos: textPos,
          text: text
        };
      } else {
        return {
          node: textNode,
          pos: -1,
          text: ""
        };
      }
    }
  }, {
    key: "protectLocalComposition",
    value: function protectLocalComposition(view, _ref2) {
      var node = _ref2.node,
        pos = _ref2.pos,
        text = _ref2.text;
      if (this.getDesc(node)) return;
      var topNode = node;
      for (;; topNode = topNode.parentNode) {
        if (topNode.parentNode == this.contentDOM) break;
        while (topNode.previousSibling) topNode.parentNode.removeChild(topNode.previousSibling);
        while (topNode.nextSibling) topNode.parentNode.removeChild(topNode.nextSibling);
        if (topNode.pmViewDesc) topNode.pmViewDesc = undefined;
      }
      var desc = new CompositionViewDesc(this, topNode, node, text);
      view.input.compositionNodes.push(desc);
      this.children = replaceNodes(this.children, pos, pos + text.length, view, desc);
    }
  }, {
    key: "update",
    value: function update(node, outerDeco, innerDeco, view) {
      if (this.dirty == NODE_DIRTY || !node.sameMarkup(this.node)) return false;
      this.updateInner(node, outerDeco, innerDeco, view);
      return true;
    }
  }, {
    key: "updateInner",
    value: function updateInner(node, outerDeco, innerDeco, view) {
      this.updateOuterDeco(outerDeco);
      this.node = node;
      this.innerDeco = innerDeco;
      if (this.contentDOM) this.updateChildren(view, this.posAtStart);
      this.dirty = NOT_DIRTY;
    }
  }, {
    key: "updateOuterDeco",
    value: function updateOuterDeco(outerDeco) {
      if (sameOuterDeco(outerDeco, this.outerDeco)) return;
      var needsWrap = this.nodeDOM.nodeType != 1;
      var oldDOM = this.dom;
      this.dom = patchOuterDeco(this.dom, this.nodeDOM, computeOuterDeco(this.outerDeco, this.node, needsWrap), computeOuterDeco(outerDeco, this.node, needsWrap));
      if (this.dom != oldDOM) {
        oldDOM.pmViewDesc = undefined;
        this.dom.pmViewDesc = this;
      }
      this.outerDeco = outerDeco;
    }
  }, {
    key: "selectNode",
    value: function selectNode() {
      if (this.nodeDOM.nodeType == 1) this.nodeDOM.classList.add("ProseMirror-selectednode");
      if (this.contentDOM || !this.node.type.spec.draggable) this.dom.draggable = true;
    }
  }, {
    key: "deselectNode",
    value: function deselectNode() {
      if (this.nodeDOM.nodeType == 1) {
        this.nodeDOM.classList.remove("ProseMirror-selectednode");
        if (this.contentDOM || !this.node.type.spec.draggable) this.dom.removeAttribute("draggable");
      }
    }
  }, {
    key: "domAtom",
    get: function get() {
      return this.node.isAtom;
    }
  }], [{
    key: "create",
    value: function create(parent, node, outerDeco, innerDeco, view, pos) {
      var custom = view.nodeViews[node.type.name],
        descObj;
      var spec = custom && custom(node, view, function () {
        if (!descObj) return pos;
        if (descObj.parent) return descObj.parent.posBeforeChild(descObj);
      }, outerDeco, innerDeco);
      var dom = spec && spec.dom,
        contentDOM = spec && spec.contentDOM;
      if (node.isText) {
        if (!dom) dom = document.createTextNode(node.text);else if (dom.nodeType != 3) throw new RangeError("Text must be rendered as a DOM text node");
      } else if (!dom) {
        var _spec = prosemirrorModel.DOMSerializer.renderSpec(document, node.type.spec.toDOM(node), null, node.attrs);
        dom = _spec.dom;
        contentDOM = _spec.contentDOM;
      }
      if (!contentDOM && !node.isText && dom.nodeName != "BR") {
        if (!dom.hasAttribute("contenteditable")) dom.contentEditable = "false";
        if (node.type.spec.draggable) dom.draggable = true;
      }
      var nodeDOM = dom;
      dom = applyOuterDeco(dom, outerDeco, node);
      if (spec) return descObj = new CustomNodeViewDesc(parent, node, outerDeco, innerDeco, dom, contentDOM || null, nodeDOM, spec, view, pos + 1);else if (node.isText) return new TextViewDesc(parent, node, outerDeco, innerDeco, dom, nodeDOM, view);else return new NodeViewDesc(parent, node, outerDeco, innerDeco, dom, contentDOM || null, nodeDOM, view, pos + 1);
    }
  }]);
  return NodeViewDesc;
}(ViewDesc);
function docViewDesc(doc, outerDeco, innerDeco, dom, view) {
  applyOuterDeco(dom, outerDeco, doc);
  var docView = new NodeViewDesc(undefined, doc, outerDeco, innerDeco, dom, dom, dom, view, 0);
  if (docView.contentDOM) docView.updateChildren(view, 0);
  return docView;
}
var TextViewDesc = function (_NodeViewDesc) {
  _inherits(TextViewDesc, _NodeViewDesc);
  var _super5 = _createSuper(TextViewDesc);
  function TextViewDesc(parent, node, outerDeco, innerDeco, dom, nodeDOM, view) {
    _classCallCheck(this, TextViewDesc);
    return _super5.call(this, parent, node, outerDeco, innerDeco, dom, null, nodeDOM, view, 0);
  }
  _createClass(TextViewDesc, [{
    key: "parseRule",
    value: function parseRule() {
      var skip = this.nodeDOM.parentNode;
      while (skip && skip != this.dom && !skip.pmIsDeco) skip = skip.parentNode;
      return {
        skip: skip || true
      };
    }
  }, {
    key: "update",
    value: function update(node, outerDeco, innerDeco, view) {
      if (this.dirty == NODE_DIRTY || this.dirty != NOT_DIRTY && !this.inParent() || !node.sameMarkup(this.node)) return false;
      this.updateOuterDeco(outerDeco);
      if ((this.dirty != NOT_DIRTY || node.text != this.node.text) && node.text != this.nodeDOM.nodeValue) {
        this.nodeDOM.nodeValue = node.text;
        if (view.trackWrites == this.nodeDOM) view.trackWrites = null;
      }
      this.node = node;
      this.dirty = NOT_DIRTY;
      return true;
    }
  }, {
    key: "inParent",
    value: function inParent() {
      var parentDOM = this.parent.contentDOM;
      for (var n = this.nodeDOM; n; n = n.parentNode) if (n == parentDOM) return true;
      return false;
    }
  }, {
    key: "domFromPos",
    value: function domFromPos(pos) {
      return {
        node: this.nodeDOM,
        offset: pos
      };
    }
  }, {
    key: "localPosFromDOM",
    value: function localPosFromDOM(dom, offset, bias) {
      if (dom == this.nodeDOM) return this.posAtStart + Math.min(offset, this.node.text.length);
      return _get(_getPrototypeOf(TextViewDesc.prototype), "localPosFromDOM", this).call(this, dom, offset, bias);
    }
  }, {
    key: "ignoreMutation",
    value: function ignoreMutation(mutation) {
      return mutation.type != "characterData" && mutation.type != "selection";
    }
  }, {
    key: "slice",
    value: function slice(from, to, view) {
      var node = this.node.cut(from, to),
        dom = document.createTextNode(node.text);
      return new TextViewDesc(this.parent, node, this.outerDeco, this.innerDeco, dom, dom, view);
    }
  }, {
    key: "markDirty",
    value: function markDirty(from, to) {
      _get(_getPrototypeOf(TextViewDesc.prototype), "markDirty", this).call(this, from, to);
      if (this.dom != this.nodeDOM && (from == 0 || to == this.nodeDOM.nodeValue.length)) this.dirty = NODE_DIRTY;
    }
  }, {
    key: "domAtom",
    get: function get() {
      return false;
    }
  }, {
    key: "isText",
    value: function isText(text) {
      return this.node.text == text;
    }
  }]);
  return TextViewDesc;
}(NodeViewDesc);
var TrailingHackViewDesc = function (_ViewDesc5) {
  _inherits(TrailingHackViewDesc, _ViewDesc5);
  var _super6 = _createSuper(TrailingHackViewDesc);
  function TrailingHackViewDesc() {
    _classCallCheck(this, TrailingHackViewDesc);
    return _super6.apply(this, arguments);
  }
  _createClass(TrailingHackViewDesc, [{
    key: "parseRule",
    value: function parseRule() {
      return {
        ignore: true
      };
    }
  }, {
    key: "matchesHack",
    value: function matchesHack(nodeName) {
      return this.dirty == NOT_DIRTY && this.dom.nodeName == nodeName;
    }
  }, {
    key: "domAtom",
    get: function get() {
      return true;
    }
  }, {
    key: "ignoreForCoords",
    get: function get() {
      return this.dom.nodeName == "IMG";
    }
  }]);
  return TrailingHackViewDesc;
}(ViewDesc);
var CustomNodeViewDesc = function (_NodeViewDesc2) {
  _inherits(CustomNodeViewDesc, _NodeViewDesc2);
  var _super7 = _createSuper(CustomNodeViewDesc);
  function CustomNodeViewDesc(parent, node, outerDeco, innerDeco, dom, contentDOM, nodeDOM, spec, view, pos) {
    var _this7;
    _classCallCheck(this, CustomNodeViewDesc);
    _this7 = _super7.call(this, parent, node, outerDeco, innerDeco, dom, contentDOM, nodeDOM, view, pos);
    _this7.spec = spec;
    return _this7;
  }
  _createClass(CustomNodeViewDesc, [{
    key: "update",
    value: function update(node, outerDeco, innerDeco, view) {
      if (this.dirty == NODE_DIRTY) return false;
      if (this.spec.update) {
        var result = this.spec.update(node, outerDeco, innerDeco);
        if (result) this.updateInner(node, outerDeco, innerDeco, view);
        return result;
      } else if (!this.contentDOM && !node.isLeaf) {
        return false;
      } else {
        return _get(_getPrototypeOf(CustomNodeViewDesc.prototype), "update", this).call(this, node, outerDeco, innerDeco, view);
      }
    }
  }, {
    key: "selectNode",
    value: function selectNode() {
      this.spec.selectNode ? this.spec.selectNode() : _get(_getPrototypeOf(CustomNodeViewDesc.prototype), "selectNode", this).call(this);
    }
  }, {
    key: "deselectNode",
    value: function deselectNode() {
      this.spec.deselectNode ? this.spec.deselectNode() : _get(_getPrototypeOf(CustomNodeViewDesc.prototype), "deselectNode", this).call(this);
    }
  }, {
    key: "setSelection",
    value: function setSelection(anchor, head, root, force) {
      this.spec.setSelection ? this.spec.setSelection(anchor, head, root) : _get(_getPrototypeOf(CustomNodeViewDesc.prototype), "setSelection", this).call(this, anchor, head, root, force);
    }
  }, {
    key: "destroy",
    value: function destroy() {
      if (this.spec.destroy) this.spec.destroy();
      _get(_getPrototypeOf(CustomNodeViewDesc.prototype), "destroy", this).call(this);
    }
  }, {
    key: "stopEvent",
    value: function stopEvent(event) {
      return this.spec.stopEvent ? this.spec.stopEvent(event) : false;
    }
  }, {
    key: "ignoreMutation",
    value: function ignoreMutation(mutation) {
      return this.spec.ignoreMutation ? this.spec.ignoreMutation(mutation) : _get(_getPrototypeOf(CustomNodeViewDesc.prototype), "ignoreMutation", this).call(this, mutation);
    }
  }]);
  return CustomNodeViewDesc;
}(NodeViewDesc);
function renderDescs(parentDOM, descs, view) {
  var dom = parentDOM.firstChild,
    written = false;
  for (var i = 0; i < descs.length; i++) {
    var desc = descs[i],
      childDOM = desc.dom;
    if (childDOM.parentNode == parentDOM) {
      while (childDOM != dom) {
        dom = rm(dom);
        written = true;
      }
      dom = dom.nextSibling;
    } else {
      written = true;
      parentDOM.insertBefore(childDOM, dom);
    }
    if (desc instanceof MarkViewDesc) {
      var pos = dom ? dom.previousSibling : parentDOM.lastChild;
      renderDescs(desc.contentDOM, desc.children, view);
      dom = pos ? pos.nextSibling : parentDOM.firstChild;
    }
  }
  while (dom) {
    dom = rm(dom);
    written = true;
  }
  if (written && view.trackWrites == parentDOM) view.trackWrites = null;
}
var OuterDecoLevel = function OuterDecoLevel(nodeName) {
  if (nodeName) this.nodeName = nodeName;
};
OuterDecoLevel.prototype = Object.create(null);
var noDeco = [new OuterDecoLevel()];
function computeOuterDeco(outerDeco, node, needsWrap) {
  if (outerDeco.length == 0) return noDeco;
  var top = needsWrap ? noDeco[0] : new OuterDecoLevel(),
    result = [top];
  for (var i = 0; i < outerDeco.length; i++) {
    var attrs = outerDeco[i].type.attrs;
    if (!attrs) continue;
    if (attrs.nodeName) result.push(top = new OuterDecoLevel(attrs.nodeName));
    for (var name in attrs) {
      var val = attrs[name];
      if (val == null) continue;
      if (needsWrap && result.length == 1) result.push(top = new OuterDecoLevel(node.isInline ? "span" : "div"));
      if (name == "class") top["class"] = (top["class"] ? top["class"] + " " : "") + val;else if (name == "style") top.style = (top.style ? top.style + ";" : "") + val;else if (name != "nodeName") top[name] = val;
    }
  }
  return result;
}
function patchOuterDeco(outerDOM, nodeDOM, prevComputed, curComputed) {
  if (prevComputed == noDeco && curComputed == noDeco) return nodeDOM;
  var curDOM = nodeDOM;
  for (var i = 0; i < curComputed.length; i++) {
    var deco = curComputed[i],
      prev = prevComputed[i];
    if (i) {
      var parent = void 0;
      if (prev && prev.nodeName == deco.nodeName && curDOM != outerDOM && (parent = curDOM.parentNode) && parent.nodeName.toLowerCase() == deco.nodeName) {
        curDOM = parent;
      } else {
        parent = document.createElement(deco.nodeName);
        parent.pmIsDeco = true;
        parent.appendChild(curDOM);
        prev = noDeco[0];
        curDOM = parent;
      }
    }
    patchAttributes(curDOM, prev || noDeco[0], deco);
  }
  return curDOM;
}
function patchAttributes(dom, prev, cur) {
  for (var name in prev) if (name != "class" && name != "style" && name != "nodeName" && !(name in cur)) dom.removeAttribute(name);
  for (var _name in cur) if (_name != "class" && _name != "style" && _name != "nodeName" && cur[_name] != prev[_name]) dom.setAttribute(_name, cur[_name]);
  if (prev["class"] != cur["class"]) {
    var prevList = prev["class"] ? prev["class"].split(" ").filter(Boolean) : [];
    var curList = cur["class"] ? cur["class"].split(" ").filter(Boolean) : [];
    for (var i = 0; i < prevList.length; i++) if (curList.indexOf(prevList[i]) == -1) dom.classList.remove(prevList[i]);
    for (var _i = 0; _i < curList.length; _i++) if (prevList.indexOf(curList[_i]) == -1) dom.classList.add(curList[_i]);
    if (dom.classList.length == 0) dom.removeAttribute("class");
  }
  if (prev.style != cur.style) {
    if (prev.style) {
      var prop = /\s*([\w\-\xa1-\uffff]+)\s*:(?:"(?:\\.|[^"])*"|'(?:\\.|[^'])*'|\(.*?\)|[^;])*/g,
        m;
      while (m = prop.exec(prev.style)) dom.style.removeProperty(m[1]);
    }
    if (cur.style) dom.style.cssText += cur.style;
  }
}
function applyOuterDeco(dom, deco, node) {
  return patchOuterDeco(dom, dom, noDeco, computeOuterDeco(deco, node, dom.nodeType != 1));
}
function sameOuterDeco(a, b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) if (!a[i].type.eq(b[i].type)) return false;
  return true;
}
function rm(dom) {
  var next = dom.nextSibling;
  dom.parentNode.removeChild(dom);
  return next;
}
var ViewTreeUpdater = function () {
  function ViewTreeUpdater(top, lock, view) {
    _classCallCheck(this, ViewTreeUpdater);
    this.lock = lock;
    this.view = view;
    this.index = 0;
    this.stack = [];
    this.changed = false;
    this.top = top;
    this.preMatch = preMatch(top.node.content, top);
  }
  _createClass(ViewTreeUpdater, [{
    key: "destroyBetween",
    value: function destroyBetween(start, end) {
      if (start == end) return;
      for (var i = start; i < end; i++) this.top.children[i].destroy();
      this.top.children.splice(start, end - start);
      this.changed = true;
    }
  }, {
    key: "destroyRest",
    value: function destroyRest() {
      this.destroyBetween(this.index, this.top.children.length);
    }
  }, {
    key: "syncToMarks",
    value: function syncToMarks(marks, inline, view) {
      var keep = 0,
        depth = this.stack.length >> 1;
      var maxKeep = Math.min(depth, marks.length);
      while (keep < maxKeep && (keep == depth - 1 ? this.top : this.stack[keep + 1 << 1]).matchesMark(marks[keep]) && marks[keep].type.spec.spanning !== false) keep++;
      while (keep < depth) {
        this.destroyRest();
        this.top.dirty = NOT_DIRTY;
        this.index = this.stack.pop();
        this.top = this.stack.pop();
        depth--;
      }
      while (depth < marks.length) {
        this.stack.push(this.top, this.index + 1);
        var found = -1;
        for (var i = this.index; i < Math.min(this.index + 3, this.top.children.length); i++) {
          var next = this.top.children[i];
          if (next.matchesMark(marks[depth]) && !this.isLocked(next.dom)) {
            found = i;
            break;
          }
        }
        if (found > -1) {
          if (found > this.index) {
            this.changed = true;
            this.destroyBetween(this.index, found);
          }
          this.top = this.top.children[this.index];
        } else {
          var markDesc = MarkViewDesc.create(this.top, marks[depth], inline, view);
          this.top.children.splice(this.index, 0, markDesc);
          this.top = markDesc;
          this.changed = true;
        }
        this.index = 0;
        depth++;
      }
    }
  }, {
    key: "findNodeMatch",
    value: function findNodeMatch(node, outerDeco, innerDeco, index) {
      var found = -1,
        targetDesc;
      if (index >= this.preMatch.index && (targetDesc = this.preMatch.matches[index - this.preMatch.index]).parent == this.top && targetDesc.matchesNode(node, outerDeco, innerDeco)) {
        found = this.top.children.indexOf(targetDesc, this.index);
      } else {
        for (var i = this.index, e = Math.min(this.top.children.length, i + 5); i < e; i++) {
          var child = this.top.children[i];
          if (child.matchesNode(node, outerDeco, innerDeco) && !this.preMatch.matched.has(child)) {
            found = i;
            break;
          }
        }
      }
      if (found < 0) return false;
      this.destroyBetween(this.index, found);
      this.index++;
      return true;
    }
  }, {
    key: "updateNodeAt",
    value: function updateNodeAt(node, outerDeco, innerDeco, index, view) {
      var child = this.top.children[index];
      if (child.dirty == NODE_DIRTY && child.dom == child.contentDOM) child.dirty = CONTENT_DIRTY;
      if (!child.update(node, outerDeco, innerDeco, view)) return false;
      this.destroyBetween(this.index, index);
      this.index++;
      return true;
    }
  }, {
    key: "findIndexWithChild",
    value: function findIndexWithChild(domNode) {
      for (;;) {
        var parent = domNode.parentNode;
        if (!parent) return -1;
        if (parent == this.top.contentDOM) {
          var desc = domNode.pmViewDesc;
          if (desc) for (var i = this.index; i < this.top.children.length; i++) {
            if (this.top.children[i] == desc) return i;
          }
          return -1;
        }
        domNode = parent;
      }
    }
  }, {
    key: "updateNextNode",
    value: function updateNextNode(node, outerDeco, innerDeco, view, index, pos) {
      for (var i = this.index; i < this.top.children.length; i++) {
        var next = this.top.children[i];
        if (next instanceof NodeViewDesc) {
          var _preMatch = this.preMatch.matched.get(next);
          if (_preMatch != null && _preMatch != index) return false;
          var nextDOM = next.dom,
            updated = void 0;
          var locked = this.isLocked(nextDOM) && !(node.isText && next.node && next.node.isText && next.nodeDOM.nodeValue == node.text && next.dirty != NODE_DIRTY && sameOuterDeco(outerDeco, next.outerDeco));
          if (!locked && next.update(node, outerDeco, innerDeco, view)) {
            this.destroyBetween(this.index, i);
            if (next.dom != nextDOM) this.changed = true;
            this.index++;
            return true;
          } else if (!locked && (updated = this.recreateWrapper(next, node, outerDeco, innerDeco, view, pos))) {
            this.top.children[this.index] = updated;
            if (updated.contentDOM) {
              updated.dirty = CONTENT_DIRTY;
              updated.updateChildren(view, pos + 1);
              updated.dirty = NOT_DIRTY;
            }
            this.changed = true;
            this.index++;
            return true;
          }
          break;
        }
      }
      return false;
    }
  }, {
    key: "recreateWrapper",
    value: function recreateWrapper(next, node, outerDeco, innerDeco, view, pos) {
      if (next.dirty || node.isAtom || !next.children.length || !next.node.content.eq(node.content)) return null;
      var wrapper = NodeViewDesc.create(this.top, node, outerDeco, innerDeco, view, pos);
      if (wrapper.contentDOM) {
        wrapper.children = next.children;
        next.children = [];
        var _iterator = _createForOfIteratorHelper(wrapper.children),
          _step;
        try {
          for (_iterator.s(); !(_step = _iterator.n()).done;) {
            var ch = _step.value;
            ch.parent = wrapper;
          }
        } catch (err) {
          _iterator.e(err);
        } finally {
          _iterator.f();
        }
      }
      next.destroy();
      return wrapper;
    }
  }, {
    key: "addNode",
    value: function addNode(node, outerDeco, innerDeco, view, pos) {
      var desc = NodeViewDesc.create(this.top, node, outerDeco, innerDeco, view, pos);
      if (desc.contentDOM) desc.updateChildren(view, pos + 1);
      this.top.children.splice(this.index++, 0, desc);
      this.changed = true;
    }
  }, {
    key: "placeWidget",
    value: function placeWidget(widget, view, pos) {
      var next = this.index < this.top.children.length ? this.top.children[this.index] : null;
      if (next && next.matchesWidget(widget) && (widget == next.widget || !next.widget.type.toDOM.parentNode)) {
        this.index++;
      } else {
        var desc = new WidgetViewDesc(this.top, widget, view, pos);
        this.top.children.splice(this.index++, 0, desc);
        this.changed = true;
      }
    }
  }, {
    key: "addTextblockHacks",
    value: function addTextblockHacks() {
      var lastChild = this.top.children[this.index - 1],
        parent = this.top;
      while (lastChild instanceof MarkViewDesc) {
        parent = lastChild;
        lastChild = parent.children[parent.children.length - 1];
      }
      if (!lastChild || !(lastChild instanceof TextViewDesc) || /\n$/.test(lastChild.node.text) || this.view.requiresGeckoHackNode && /\s$/.test(lastChild.node.text)) {
        if ((safari || chrome) && lastChild && lastChild.dom.contentEditable == "false") this.addHackNode("IMG", parent);
        this.addHackNode("BR", this.top);
      }
    }
  }, {
    key: "addHackNode",
    value: function addHackNode(nodeName, parent) {
      if (parent == this.top && this.index < parent.children.length && parent.children[this.index].matchesHack(nodeName)) {
        this.index++;
      } else {
        var dom = document.createElement(nodeName);
        if (nodeName == "IMG") {
          dom.className = "ProseMirror-separator";
          dom.alt = "";
        }
        if (nodeName == "BR") dom.className = "ProseMirror-trailingBreak";
        var hack = new TrailingHackViewDesc(this.top, [], dom, null);
        if (parent != this.top) parent.children.push(hack);else parent.children.splice(this.index++, 0, hack);
        this.changed = true;
      }
    }
  }, {
    key: "isLocked",
    value: function isLocked(node) {
      return this.lock && (node == this.lock || node.nodeType == 1 && node.contains(this.lock.parentNode));
    }
  }]);
  return ViewTreeUpdater;
}();
function preMatch(frag, parentDesc) {
  var curDesc = parentDesc,
    descI = curDesc.children.length;
  var fI = frag.childCount,
    matched = new Map(),
    matches = [];
  outer: while (fI > 0) {
    var desc = void 0;
    for (;;) {
      if (descI) {
        var next = curDesc.children[descI - 1];
        if (next instanceof MarkViewDesc) {
          curDesc = next;
          descI = next.children.length;
        } else {
          desc = next;
          descI--;
          break;
        }
      } else if (curDesc == parentDesc) {
        break outer;
      } else {
        descI = curDesc.parent.children.indexOf(curDesc);
        curDesc = curDesc.parent;
      }
    }
    var node = desc.node;
    if (!node) continue;
    if (node != frag.child(fI - 1)) break;
    --fI;
    matched.set(desc, fI);
    matches.push(desc);
  }
  return {
    index: fI,
    matched: matched,
    matches: matches.reverse()
  };
}
function compareSide(a, b) {
  return a.type.side - b.type.side;
}
function iterDeco(parent, deco, onWidget, onNode) {
  var locals = deco.locals(parent),
    offset = 0;
  if (locals.length == 0) {
    for (var i = 0; i < parent.childCount; i++) {
      var child = parent.child(i);
      onNode(child, locals, deco.forChild(offset, child), i);
      offset += child.nodeSize;
    }
    return;
  }
  var decoIndex = 0,
    active = [],
    restNode = null;
  for (var parentIndex = 0;;) {
    var widget = void 0,
      widgets = void 0;
    while (decoIndex < locals.length && locals[decoIndex].to == offset) {
      var next = locals[decoIndex++];
      if (next.widget) {
        if (!widget) widget = next;else (widgets || (widgets = [widget])).push(next);
      }
    }
    if (widget) {
      if (widgets) {
        widgets.sort(compareSide);
        for (var _i2 = 0; _i2 < widgets.length; _i2++) onWidget(widgets[_i2], parentIndex, !!restNode);
      } else {
        onWidget(widget, parentIndex, !!restNode);
      }
    }
    var _child = void 0,
      index = void 0;
    if (restNode) {
      index = -1;
      _child = restNode;
      restNode = null;
    } else if (parentIndex < parent.childCount) {
      index = parentIndex;
      _child = parent.child(parentIndex++);
    } else {
      break;
    }
    for (var _i3 = 0; _i3 < active.length; _i3++) if (active[_i3].to <= offset) active.splice(_i3--, 1);
    while (decoIndex < locals.length && locals[decoIndex].from <= offset && locals[decoIndex].to > offset) active.push(locals[decoIndex++]);
    var end = offset + _child.nodeSize;
    if (_child.isText) {
      var cutAt = end;
      if (decoIndex < locals.length && locals[decoIndex].from < cutAt) cutAt = locals[decoIndex].from;
      for (var _i4 = 0; _i4 < active.length; _i4++) if (active[_i4].to < cutAt) cutAt = active[_i4].to;
      if (cutAt < end) {
        restNode = _child.cut(cutAt - offset);
        _child = _child.cut(0, cutAt - offset);
        end = cutAt;
        index = -1;
      }
    } else {
      while (decoIndex < locals.length && locals[decoIndex].to < end) decoIndex++;
    }
    var outerDeco = _child.isInline && !_child.isLeaf ? active.filter(function (d) {
      return !d.inline;
    }) : active.slice();
    onNode(_child, outerDeco, deco.forChild(offset, _child), index);
    offset = end;
  }
}
function iosHacks(dom) {
  if (dom.nodeName == "UL" || dom.nodeName == "OL") {
    var oldCSS = dom.style.cssText;
    dom.style.cssText = oldCSS + "; list-style: square !important";
    window.getComputedStyle(dom).listStyle;
    dom.style.cssText = oldCSS;
  }
}
function findTextInFragment(frag, text, from, to) {
  for (var i = 0, pos = 0; i < frag.childCount && pos <= to;) {
    var child = frag.child(i++),
      childStart = pos;
    pos += child.nodeSize;
    if (!child.isText) continue;
    var str = child.text;
    while (i < frag.childCount) {
      var next = frag.child(i++);
      pos += next.nodeSize;
      if (!next.isText) break;
      str += next.text;
    }
    if (pos >= from) {
      if (pos >= to && str.slice(to - text.length - childStart, to - childStart) == text) return to - text.length;
      var found = childStart < to ? str.lastIndexOf(text, to - childStart - 1) : -1;
      if (found >= 0 && found + text.length + childStart >= from) return childStart + found;
      if (from == to && str.length >= to + text.length - childStart && str.slice(to - childStart, to - childStart + text.length) == text) return to;
    }
  }
  return -1;
}
function replaceNodes(nodes, from, to, view, replacement) {
  var result = [];
  for (var i = 0, off = 0; i < nodes.length; i++) {
    var child = nodes[i],
      start = off,
      end = off += child.size;
    if (start >= to || end <= from) {
      result.push(child);
    } else {
      if (start < from) result.push(child.slice(0, from - start, view));
      if (replacement) {
        result.push(replacement);
        replacement = undefined;
      }
      if (end > to) result.push(child.slice(to - start, child.size, view));
    }
  }
  return result;
}
function selectionFromDOM(view) {
  var origin = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
  var domSel = view.domSelectionRange(),
    doc = view.state.doc;
  if (!domSel.focusNode) return null;
  var nearestDesc = view.docView.nearestDesc(domSel.focusNode),
    inWidget = nearestDesc && nearestDesc.size == 0;
  var head = view.docView.posFromDOM(domSel.focusNode, domSel.focusOffset, 1);
  if (head < 0) return null;
  var $head = doc.resolve(head),
    $anchor,
    selection;
  if (selectionCollapsed(domSel)) {
    $anchor = $head;
    while (nearestDesc && !nearestDesc.node) nearestDesc = nearestDesc.parent;
    var nearestDescNode = nearestDesc.node;
    if (nearestDesc && nearestDescNode.isAtom && prosemirrorState.NodeSelection.isSelectable(nearestDescNode) && nearestDesc.parent && !(nearestDescNode.isInline && isOnEdge(domSel.focusNode, domSel.focusOffset, nearestDesc.dom))) {
      var pos = nearestDesc.posBefore;
      selection = new prosemirrorState.NodeSelection(head == pos ? $head : doc.resolve(pos));
    }
  } else {
    var anchor = view.docView.posFromDOM(domSel.anchorNode, domSel.anchorOffset, 1);
    if (anchor < 0) return null;
    $anchor = doc.resolve(anchor);
  }
  if (!selection) {
    var bias = origin == "pointer" || view.state.selection.head < $head.pos && !inWidget ? 1 : -1;
    selection = selectionBetween(view, $anchor, $head, bias);
  }
  return selection;
}
function editorOwnsSelection(view) {
  return view.editable ? view.hasFocus() : hasSelection(view) && document.activeElement && document.activeElement.contains(view.dom);
}
function selectionToDOM(view) {
  var force = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
  var sel = view.state.selection;
  syncNodeSelection(view, sel);
  if (!editorOwnsSelection(view)) return;
  if (!force && view.input.mouseDown && view.input.mouseDown.allowDefault && chrome) {
    var domSel = view.domSelectionRange(),
      curSel = view.domObserver.currentSelection;
    if (domSel.anchorNode && curSel.anchorNode && isEquivalentPosition(domSel.anchorNode, domSel.anchorOffset, curSel.anchorNode, curSel.anchorOffset)) {
      view.input.mouseDown.delayedSelectionSync = true;
      view.domObserver.setCurSelection();
      return;
    }
  }
  view.domObserver.disconnectSelection();
  if (view.cursorWrapper) {
    selectCursorWrapper(view);
  } else {
    var anchor = sel.anchor,
      head = sel.head,
      resetEditableFrom,
      resetEditableTo;
    if (brokenSelectBetweenUneditable && !(sel instanceof prosemirrorState.TextSelection)) {
      if (!sel.$from.parent.inlineContent) resetEditableFrom = temporarilyEditableNear(view, sel.from);
      if (!sel.empty && !sel.$from.parent.inlineContent) resetEditableTo = temporarilyEditableNear(view, sel.to);
    }
    view.docView.setSelection(anchor, head, view.root, force);
    if (brokenSelectBetweenUneditable) {
      if (resetEditableFrom) resetEditable(resetEditableFrom);
      if (resetEditableTo) resetEditable(resetEditableTo);
    }
    if (sel.visible) {
      view.dom.classList.remove("ProseMirror-hideselection");
    } else {
      view.dom.classList.add("ProseMirror-hideselection");
      if ("onselectionchange" in document) removeClassOnSelectionChange(view);
    }
  }
  view.domObserver.setCurSelection();
  view.domObserver.connectSelection();
}
var brokenSelectBetweenUneditable = safari || chrome && chrome_version < 63;
function temporarilyEditableNear(view, pos) {
  var _view$docView$domFrom3 = view.docView.domFromPos(pos, 0),
    node = _view$docView$domFrom3.node,
    offset = _view$docView$domFrom3.offset;
  var after = offset < node.childNodes.length ? node.childNodes[offset] : null;
  var before = offset ? node.childNodes[offset - 1] : null;
  if (safari && after && after.contentEditable == "false") return setEditable(after);
  if ((!after || after.contentEditable == "false") && (!before || before.contentEditable == "false")) {
    if (after) return setEditable(after);else if (before) return setEditable(before);
  }
}
function setEditable(element) {
  element.contentEditable = "true";
  if (safari && element.draggable) {
    element.draggable = false;
    element.wasDraggable = true;
  }
  return element;
}
function resetEditable(element) {
  element.contentEditable = "false";
  if (element.wasDraggable) {
    element.draggable = true;
    element.wasDraggable = null;
  }
}
function removeClassOnSelectionChange(view) {
  var doc = view.dom.ownerDocument;
  doc.removeEventListener("selectionchange", view.input.hideSelectionGuard);
  var domSel = view.domSelectionRange();
  var node = domSel.anchorNode,
    offset = domSel.anchorOffset;
  doc.addEventListener("selectionchange", view.input.hideSelectionGuard = function () {
    if (domSel.anchorNode != node || domSel.anchorOffset != offset) {
      doc.removeEventListener("selectionchange", view.input.hideSelectionGuard);
      setTimeout(function () {
        if (!editorOwnsSelection(view) || view.state.selection.visible) view.dom.classList.remove("ProseMirror-hideselection");
      }, 20);
    }
  });
}
function selectCursorWrapper(view) {
  var domSel = view.domSelection(),
    range = document.createRange();
  if (!domSel) return;
  var node = view.cursorWrapper.dom,
    img = node.nodeName == "IMG";
  if (img) range.setStart(node.parentNode, domIndex(node) + 1);else range.setStart(node, 0);
  range.collapse(true);
  domSel.removeAllRanges();
  domSel.addRange(range);
  if (!img && !view.state.selection.visible && ie && ie_version <= 11) {
    node.disabled = true;
    node.disabled = false;
  }
}
function syncNodeSelection(view, sel) {
  if (sel instanceof prosemirrorState.NodeSelection) {
    var desc = view.docView.descAt(sel.from);
    if (desc != view.lastSelectedViewDesc) {
      clearNodeSelection(view);
      if (desc) desc.selectNode();
      view.lastSelectedViewDesc = desc;
    }
  } else {
    clearNodeSelection(view);
  }
}
function clearNodeSelection(view) {
  if (view.lastSelectedViewDesc) {
    if (view.lastSelectedViewDesc.parent) view.lastSelectedViewDesc.deselectNode();
    view.lastSelectedViewDesc = undefined;
  }
}
function selectionBetween(view, $anchor, $head, bias) {
  return view.someProp("createSelectionBetween", function (f) {
    return f(view, $anchor, $head);
  }) || prosemirrorState.TextSelection.between($anchor, $head, bias);
}
function hasFocusAndSelection(view) {
  if (view.editable && !view.hasFocus()) return false;
  return hasSelection(view);
}
function hasSelection(view) {
  var sel = view.domSelectionRange();
  if (!sel.anchorNode) return false;
  try {
    return view.dom.contains(sel.anchorNode.nodeType == 3 ? sel.anchorNode.parentNode : sel.anchorNode) && (view.editable || view.dom.contains(sel.focusNode.nodeType == 3 ? sel.focusNode.parentNode : sel.focusNode));
  } catch (_) {
    return false;
  }
}
function anchorInRightPlace(view) {
  var anchorDOM = view.docView.domFromPos(view.state.selection.anchor, 0);
  var domSel = view.domSelectionRange();
  return isEquivalentPosition(anchorDOM.node, anchorDOM.offset, domSel.anchorNode, domSel.anchorOffset);
}
function moveSelectionBlock(state, dir) {
  var _state$selection = state.selection,
    $anchor = _state$selection.$anchor,
    $head = _state$selection.$head;
  var $side = dir > 0 ? $anchor.max($head) : $anchor.min($head);
  var $start = !$side.parent.inlineContent ? $side : $side.depth ? state.doc.resolve(dir > 0 ? $side.after() : $side.before()) : null;
  return $start && prosemirrorState.Selection.findFrom($start, dir);
}
function apply(view, sel) {
  view.dispatch(view.state.tr.setSelection(sel).scrollIntoView());
  return true;
}
function selectHorizontally(view, dir, mods) {
  var sel = view.state.selection;
  if (sel instanceof prosemirrorState.TextSelection) {
    if (mods.indexOf("s") > -1) {
      var $head = sel.$head,
        node = $head.textOffset ? null : dir < 0 ? $head.nodeBefore : $head.nodeAfter;
      if (!node || node.isText || !node.isLeaf) return false;
      var $newHead = view.state.doc.resolve($head.pos + node.nodeSize * (dir < 0 ? -1 : 1));
      return apply(view, new prosemirrorState.TextSelection(sel.$anchor, $newHead));
    } else if (!sel.empty) {
      return false;
    } else if (view.endOfTextblock(dir > 0 ? "forward" : "backward")) {
      var next = moveSelectionBlock(view.state, dir);
      if (next && next instanceof prosemirrorState.NodeSelection) return apply(view, next);
      return false;
    } else if (!(mac && mods.indexOf("m") > -1)) {
      var _$head = sel.$head,
        _node = _$head.textOffset ? null : dir < 0 ? _$head.nodeBefore : _$head.nodeAfter,
        desc;
      if (!_node || _node.isText) return false;
      var nodePos = dir < 0 ? _$head.pos - _node.nodeSize : _$head.pos;
      if (!(_node.isAtom || (desc = view.docView.descAt(nodePos)) && !desc.contentDOM)) return false;
      if (prosemirrorState.NodeSelection.isSelectable(_node)) {
        return apply(view, new prosemirrorState.NodeSelection(dir < 0 ? view.state.doc.resolve(_$head.pos - _node.nodeSize) : _$head));
      } else if (webkit) {
        return apply(view, new prosemirrorState.TextSelection(view.state.doc.resolve(dir < 0 ? nodePos : nodePos + _node.nodeSize)));
      } else {
        return false;
      }
    }
  } else if (sel instanceof prosemirrorState.NodeSelection && sel.node.isInline) {
    return apply(view, new prosemirrorState.TextSelection(dir > 0 ? sel.$to : sel.$from));
  } else {
    var _next = moveSelectionBlock(view.state, dir);
    if (_next) return apply(view, _next);
    return false;
  }
}
function nodeLen(node) {
  return node.nodeType == 3 ? node.nodeValue.length : node.childNodes.length;
}
function isIgnorable(dom, dir) {
  var desc = dom.pmViewDesc;
  return desc && desc.size == 0 && (dir < 0 || dom.nextSibling || dom.nodeName != "BR");
}
function skipIgnoredNodes(view, dir) {
  return dir < 0 ? skipIgnoredNodesBefore(view) : skipIgnoredNodesAfter(view);
}
function skipIgnoredNodesBefore(view) {
  var sel = view.domSelectionRange();
  var node = sel.focusNode,
    offset = sel.focusOffset;
  if (!node) return;
  var moveNode,
    moveOffset,
    force = false;
  if (gecko && node.nodeType == 1 && offset < nodeLen(node) && isIgnorable(node.childNodes[offset], -1)) force = true;
  for (;;) {
    if (offset > 0) {
      if (node.nodeType != 1) {
        break;
      } else {
        var before = node.childNodes[offset - 1];
        if (isIgnorable(before, -1)) {
          moveNode = node;
          moveOffset = --offset;
        } else if (before.nodeType == 3) {
          node = before;
          offset = node.nodeValue.length;
        } else break;
      }
    } else if (isBlockNode(node)) {
      break;
    } else {
      var prev = node.previousSibling;
      while (prev && isIgnorable(prev, -1)) {
        moveNode = node.parentNode;
        moveOffset = domIndex(prev);
        prev = prev.previousSibling;
      }
      if (!prev) {
        node = node.parentNode;
        if (node == view.dom) break;
        offset = 0;
      } else {
        node = prev;
        offset = nodeLen(node);
      }
    }
  }
  if (force) setSelFocus(view, node, offset);else if (moveNode) setSelFocus(view, moveNode, moveOffset);
}
function skipIgnoredNodesAfter(view) {
  var sel = view.domSelectionRange();
  var node = sel.focusNode,
    offset = sel.focusOffset;
  if (!node) return;
  var len = nodeLen(node);
  var moveNode, moveOffset;
  for (;;) {
    if (offset < len) {
      if (node.nodeType != 1) break;
      var after = node.childNodes[offset];
      if (isIgnorable(after, 1)) {
        moveNode = node;
        moveOffset = ++offset;
      } else break;
    } else if (isBlockNode(node)) {
      break;
    } else {
      var next = node.nextSibling;
      while (next && isIgnorable(next, 1)) {
        moveNode = next.parentNode;
        moveOffset = domIndex(next) + 1;
        next = next.nextSibling;
      }
      if (!next) {
        node = node.parentNode;
        if (node == view.dom) break;
        offset = len = 0;
      } else {
        node = next;
        offset = 0;
        len = nodeLen(node);
      }
    }
  }
  if (moveNode) setSelFocus(view, moveNode, moveOffset);
}
function isBlockNode(dom) {
  var desc = dom.pmViewDesc;
  return desc && desc.node && desc.node.isBlock;
}
function textNodeAfter(node, offset) {
  while (node && offset == node.childNodes.length && !hasBlockDesc(node)) {
    offset = domIndex(node) + 1;
    node = node.parentNode;
  }
  while (node && offset < node.childNodes.length) {
    var next = node.childNodes[offset];
    if (next.nodeType == 3) return next;
    if (next.nodeType == 1 && next.contentEditable == "false") break;
    node = next;
    offset = 0;
  }
}
function textNodeBefore(node, offset) {
  while (node && !offset && !hasBlockDesc(node)) {
    offset = domIndex(node);
    node = node.parentNode;
  }
  while (node && offset) {
    var next = node.childNodes[offset - 1];
    if (next.nodeType == 3) return next;
    if (next.nodeType == 1 && next.contentEditable == "false") break;
    node = next;
    offset = node.childNodes.length;
  }
}
function setSelFocus(view, node, offset) {
  if (node.nodeType != 3) {
    var before, after;
    if (after = textNodeAfter(node, offset)) {
      node = after;
      offset = 0;
    } else if (before = textNodeBefore(node, offset)) {
      node = before;
      offset = before.nodeValue.length;
    }
  }
  var sel = view.domSelection();
  if (!sel) return;
  if (selectionCollapsed(sel)) {
    var range = document.createRange();
    range.setEnd(node, offset);
    range.setStart(node, offset);
    sel.removeAllRanges();
    sel.addRange(range);
  } else if (sel.extend) {
    sel.extend(node, offset);
  }
  view.domObserver.setCurSelection();
  var state = view.state;
  setTimeout(function () {
    if (view.state == state) selectionToDOM(view);
  }, 50);
}
function findDirection(view, pos) {
  var $pos = view.state.doc.resolve(pos);
  if (!(chrome || windows) && $pos.parent.inlineContent) {
    var coords = view.coordsAtPos(pos);
    if (pos > $pos.start()) {
      var before = view.coordsAtPos(pos - 1);
      var mid = (before.top + before.bottom) / 2;
      if (mid > coords.top && mid < coords.bottom && Math.abs(before.left - coords.left) > 1) return before.left < coords.left ? "ltr" : "rtl";
    }
    if (pos < $pos.end()) {
      var after = view.coordsAtPos(pos + 1);
      var _mid = (after.top + after.bottom) / 2;
      if (_mid > coords.top && _mid < coords.bottom && Math.abs(after.left - coords.left) > 1) return after.left > coords.left ? "ltr" : "rtl";
    }
  }
  var computed = getComputedStyle(view.dom).direction;
  return computed == "rtl" ? "rtl" : "ltr";
}
function selectVertically(view, dir, mods) {
  var sel = view.state.selection;
  if (sel instanceof prosemirrorState.TextSelection && !sel.empty || mods.indexOf("s") > -1) return false;
  if (mac && mods.indexOf("m") > -1) return false;
  var $from = sel.$from,
    $to = sel.$to;
  if (!$from.parent.inlineContent || view.endOfTextblock(dir < 0 ? "up" : "down")) {
    var next = moveSelectionBlock(view.state, dir);
    if (next && next instanceof prosemirrorState.NodeSelection) return apply(view, next);
  }
  if (!$from.parent.inlineContent) {
    var side = dir < 0 ? $from : $to;
    var beyond = sel instanceof prosemirrorState.AllSelection ? prosemirrorState.Selection.near(side, dir) : prosemirrorState.Selection.findFrom(side, dir);
    return beyond ? apply(view, beyond) : false;
  }
  return false;
}
function stopNativeHorizontalDelete(view, dir) {
  if (!(view.state.selection instanceof prosemirrorState.TextSelection)) return true;
  var _view$state$selection2 = view.state.selection,
    $head = _view$state$selection2.$head,
    $anchor = _view$state$selection2.$anchor,
    empty = _view$state$selection2.empty;
  if (!$head.sameParent($anchor)) return true;
  if (!empty) return false;
  if (view.endOfTextblock(dir > 0 ? "forward" : "backward")) return true;
  var nextNode = !$head.textOffset && (dir < 0 ? $head.nodeBefore : $head.nodeAfter);
  if (nextNode && !nextNode.isText) {
    var tr = view.state.tr;
    if (dir < 0) tr["delete"]($head.pos - nextNode.nodeSize, $head.pos);else tr["delete"]($head.pos, $head.pos + nextNode.nodeSize);
    view.dispatch(tr);
    return true;
  }
  return false;
}
function switchEditable(view, node, state) {
  view.domObserver.stop();
  node.contentEditable = state;
  view.domObserver.start();
}
function safariDownArrowBug(view) {
  if (!safari || view.state.selection.$head.parentOffset > 0) return false;
  var _view$domSelectionRan3 = view.domSelectionRange(),
    focusNode = _view$domSelectionRan3.focusNode,
    focusOffset = _view$domSelectionRan3.focusOffset;
  if (focusNode && focusNode.nodeType == 1 && focusOffset == 0 && focusNode.firstChild && focusNode.firstChild.contentEditable == "false") {
    var child = focusNode.firstChild;
    switchEditable(view, child, "true");
    setTimeout(function () {
      return switchEditable(view, child, "false");
    }, 20);
  }
  return false;
}
function getMods(event) {
  var result = "";
  if (event.ctrlKey) result += "c";
  if (event.metaKey) result += "m";
  if (event.altKey) result += "a";
  if (event.shiftKey) result += "s";
  return result;
}
function captureKeyDown(view, event) {
  var code = event.keyCode,
    mods = getMods(event);
  if (code == 8 || mac && code == 72 && mods == "c") {
    return stopNativeHorizontalDelete(view, -1) || skipIgnoredNodes(view, -1);
  } else if (code == 46 && !event.shiftKey || mac && code == 68 && mods == "c") {
    return stopNativeHorizontalDelete(view, 1) || skipIgnoredNodes(view, 1);
  } else if (code == 13 || code == 27) {
    return true;
  } else if (code == 37 || mac && code == 66 && mods == "c") {
    var dir = code == 37 ? findDirection(view, view.state.selection.from) == "ltr" ? -1 : 1 : -1;
    return selectHorizontally(view, dir, mods) || skipIgnoredNodes(view, dir);
  } else if (code == 39 || mac && code == 70 && mods == "c") {
    var _dir = code == 39 ? findDirection(view, view.state.selection.from) == "ltr" ? 1 : -1 : 1;
    return selectHorizontally(view, _dir, mods) || skipIgnoredNodes(view, _dir);
  } else if (code == 38 || mac && code == 80 && mods == "c") {
    return selectVertically(view, -1, mods) || skipIgnoredNodes(view, -1);
  } else if (code == 40 || mac && code == 78 && mods == "c") {
    return safariDownArrowBug(view) || selectVertically(view, 1, mods) || skipIgnoredNodes(view, 1);
  } else if (mods == (mac ? "m" : "c") && (code == 66 || code == 73 || code == 89 || code == 90)) {
    return true;
  }
  return false;
}
function serializeForClipboard(view, slice) {
  view.someProp("transformCopied", function (f) {
    slice = f(slice, view);
  });
  var context = [],
    _slice = slice,
    content = _slice.content,
    openStart = _slice.openStart,
    openEnd = _slice.openEnd;
  while (openStart > 1 && openEnd > 1 && content.childCount == 1 && content.firstChild.childCount == 1) {
    openStart--;
    openEnd--;
    var node = content.firstChild;
    context.push(node.type.name, node.attrs != node.type.defaultAttrs ? node.attrs : null);
    content = node.content;
  }
  var serializer = view.someProp("clipboardSerializer") || prosemirrorModel.DOMSerializer.fromSchema(view.state.schema);
  var doc = detachedDoc(),
    wrap = doc.createElement("div");
  wrap.appendChild(serializer.serializeFragment(content, {
    document: doc
  }));
  var firstChild = wrap.firstChild,
    needsWrap,
    wrappers = 0;
  while (firstChild && firstChild.nodeType == 1 && (needsWrap = wrapMap[firstChild.nodeName.toLowerCase()])) {
    for (var i = needsWrap.length - 1; i >= 0; i--) {
      var wrapper = doc.createElement(needsWrap[i]);
      while (wrap.firstChild) wrapper.appendChild(wrap.firstChild);
      wrap.appendChild(wrapper);
      wrappers++;
    }
    firstChild = wrap.firstChild;
  }
  if (firstChild && firstChild.nodeType == 1) firstChild.setAttribute("data-pm-slice", "".concat(openStart, " ").concat(openEnd).concat(wrappers ? " -".concat(wrappers) : "", " ").concat(JSON.stringify(context)));
  var text = view.someProp("clipboardTextSerializer", function (f) {
    return f(slice, view);
  }) || slice.content.textBetween(0, slice.content.size, "\n\n");
  return {
    dom: wrap,
    text: text,
    slice: slice
  };
}
function parseFromClipboard(view, text, html, plainText, $context) {
  var inCode = $context.parent.type.spec.code;
  var dom, slice;
  if (!html && !text) return null;
  var asText = text && (plainText || inCode || !html);
  if (asText) {
    view.someProp("transformPastedText", function (f) {
      text = f(text, inCode || plainText, view);
    });
    if (inCode) return text ? new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(view.state.schema.text(text.replace(/\r\n?/g, "\n"))), 0, 0) : prosemirrorModel.Slice.empty;
    var parsed = view.someProp("clipboardTextParser", function (f) {
      return f(text, $context, plainText, view);
    });
    if (parsed) {
      slice = parsed;
    } else {
      var marks = $context.marks();
      var schema = view.state.schema,
        serializer = prosemirrorModel.DOMSerializer.fromSchema(schema);
      dom = document.createElement("div");
      text.split(/(?:\r\n?|\n)+/).forEach(function (block) {
        var p = dom.appendChild(document.createElement("p"));
        if (block) p.appendChild(serializer.serializeNode(schema.text(block, marks)));
      });
    }
  } else {
    view.someProp("transformPastedHTML", function (f) {
      html = f(html, view);
    });
    dom = readHTML(html);
    if (webkit) restoreReplacedSpaces(dom);
  }
  var contextNode = dom && dom.querySelector("[data-pm-slice]");
  var sliceData = contextNode && /^(\d+) (\d+)(?: -(\d+))? (.*)/.exec(contextNode.getAttribute("data-pm-slice") || "");
  if (sliceData && sliceData[3]) for (var i = +sliceData[3]; i > 0; i--) {
    var child = dom.firstChild;
    while (child && child.nodeType != 1) child = child.nextSibling;
    if (!child) break;
    dom = child;
  }
  if (!slice) {
    var parser = view.someProp("clipboardParser") || view.someProp("domParser") || prosemirrorModel.DOMParser.fromSchema(view.state.schema);
    slice = parser.parseSlice(dom, {
      preserveWhitespace: !!(asText || sliceData),
      context: $context,
      ruleFromNode: function ruleFromNode(dom) {
        if (dom.nodeName == "BR" && !dom.nextSibling && dom.parentNode && !inlineParents.test(dom.parentNode.nodeName)) return {
          ignore: true
        };
        return null;
      }
    });
  }
  if (sliceData) {
    slice = addContext(closeSlice(slice, +sliceData[1], +sliceData[2]), sliceData[4]);
  } else {
    slice = prosemirrorModel.Slice.maxOpen(normalizeSiblings(slice.content, $context), true);
    if (slice.openStart || slice.openEnd) {
      var openStart = 0,
        openEnd = 0;
      for (var node = slice.content.firstChild; openStart < slice.openStart && !node.type.spec.isolating; openStart++, node = node.firstChild) {}
      for (var _node2 = slice.content.lastChild; openEnd < slice.openEnd && !_node2.type.spec.isolating; openEnd++, _node2 = _node2.lastChild) {}
      slice = closeSlice(slice, openStart, openEnd);
    }
  }
  view.someProp("transformPasted", function (f) {
    slice = f(slice, view);
  });
  return slice;
}
var inlineParents = /^(a|abbr|acronym|b|cite|code|del|em|i|ins|kbd|label|output|q|ruby|s|samp|span|strong|sub|sup|time|u|tt|var)$/i;
function normalizeSiblings(fragment, $context) {
  if (fragment.childCount < 2) return fragment;
  var _loop = function _loop() {
      var parent = $context.node(d);
      var match = parent.contentMatchAt($context.index(d));
      var lastWrap,
        result = [];
      fragment.forEach(function (node) {
        if (!result) return;
        var wrap = match.findWrapping(node.type),
          inLast;
        if (!wrap) return result = null;
        if (inLast = result.length && lastWrap.length && addToSibling(wrap, lastWrap, node, result[result.length - 1], 0)) {
          result[result.length - 1] = inLast;
        } else {
          if (result.length) result[result.length - 1] = closeRight(result[result.length - 1], lastWrap.length);
          var wrapped = withWrappers(node, wrap);
          result.push(wrapped);
          match = match.matchType(wrapped.type);
          lastWrap = wrap;
        }
      });
      if (result) return {
        v: prosemirrorModel.Fragment.from(result)
      };
    },
    _ret;
  for (var d = $context.depth; d >= 0; d--) {
    _ret = _loop();
    if (_ret) return _ret.v;
  }
  return fragment;
}
function withWrappers(node, wrap) {
  var from = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;
  for (var i = wrap.length - 1; i >= from; i--) node = wrap[i].create(null, prosemirrorModel.Fragment.from(node));
  return node;
}
function addToSibling(wrap, lastWrap, node, sibling, depth) {
  if (depth < wrap.length && depth < lastWrap.length && wrap[depth] == lastWrap[depth]) {
    var inner = addToSibling(wrap, lastWrap, node, sibling.lastChild, depth + 1);
    if (inner) return sibling.copy(sibling.content.replaceChild(sibling.childCount - 1, inner));
    var match = sibling.contentMatchAt(sibling.childCount);
    if (match.matchType(depth == wrap.length - 1 ? node.type : wrap[depth + 1])) return sibling.copy(sibling.content.append(prosemirrorModel.Fragment.from(withWrappers(node, wrap, depth + 1))));
  }
}
function closeRight(node, depth) {
  if (depth == 0) return node;
  var fragment = node.content.replaceChild(node.childCount - 1, closeRight(node.lastChild, depth - 1));
  var fill = node.contentMatchAt(node.childCount).fillBefore(prosemirrorModel.Fragment.empty, true);
  return node.copy(fragment.append(fill));
}
function closeRange(fragment, side, from, to, depth, openEnd) {
  var node = side < 0 ? fragment.firstChild : fragment.lastChild,
    inner = node.content;
  if (fragment.childCount > 1) openEnd = 0;
  if (depth < to - 1) inner = closeRange(inner, side, from, to, depth + 1, openEnd);
  if (depth >= from) inner = side < 0 ? node.contentMatchAt(0).fillBefore(inner, openEnd <= depth).append(inner) : inner.append(node.contentMatchAt(node.childCount).fillBefore(prosemirrorModel.Fragment.empty, true));
  return fragment.replaceChild(side < 0 ? 0 : fragment.childCount - 1, node.copy(inner));
}
function closeSlice(slice, openStart, openEnd) {
  if (openStart < slice.openStart) slice = new prosemirrorModel.Slice(closeRange(slice.content, -1, openStart, slice.openStart, 0, slice.openEnd), openStart, slice.openEnd);
  if (openEnd < slice.openEnd) slice = new prosemirrorModel.Slice(closeRange(slice.content, 1, openEnd, slice.openEnd, 0, 0), slice.openStart, openEnd);
  return slice;
}
var wrapMap = {
  thead: ["table"],
  tbody: ["table"],
  tfoot: ["table"],
  caption: ["table"],
  colgroup: ["table"],
  col: ["table", "colgroup"],
  tr: ["table", "tbody"],
  td: ["table", "tbody", "tr"],
  th: ["table", "tbody", "tr"]
};
var _detachedDoc = null;
function detachedDoc() {
  return _detachedDoc || (_detachedDoc = document.implementation.createHTMLDocument("title"));
}
function readHTML(html) {
  var metas = /^(\s*<meta [^>]*>)*/.exec(html);
  if (metas) html = html.slice(metas[0].length);
  var elt = detachedDoc().createElement("div");
  var firstTag = /<([a-z][^>\s]+)/i.exec(html),
    wrap;
  if (wrap = firstTag && wrapMap[firstTag[1].toLowerCase()]) html = wrap.map(function (n) {
    return "<" + n + ">";
  }).join("") + html + wrap.map(function (n) {
    return "</" + n + ">";
  }).reverse().join("");
  elt.innerHTML = html;
  if (wrap) for (var i = 0; i < wrap.length; i++) elt = elt.querySelector(wrap[i]) || elt;
  return elt;
}
function restoreReplacedSpaces(dom) {
  var nodes = dom.querySelectorAll(chrome ? "span:not([class]):not([style])" : "span.Apple-converted-space");
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    if (node.childNodes.length == 1 && node.textContent == "\xA0" && node.parentNode) node.parentNode.replaceChild(dom.ownerDocument.createTextNode(" "), node);
  }
}
function addContext(slice, context) {
  if (!slice.size) return slice;
  var schema = slice.content.firstChild.type.schema,
    array;
  try {
    array = JSON.parse(context);
  } catch (e) {
    return slice;
  }
  var content = slice.content,
    openStart = slice.openStart,
    openEnd = slice.openEnd;
  for (var i = array.length - 2; i >= 0; i -= 2) {
    var type = schema.nodes[array[i]];
    if (!type || type.hasRequiredAttrs()) break;
    content = prosemirrorModel.Fragment.from(type.create(array[i + 1], content));
    openStart++;
    openEnd++;
  }
  return new prosemirrorModel.Slice(content, openStart, openEnd);
}
var handlers = {};
var editHandlers = {};
var passiveHandlers = {
  touchstart: true,
  touchmove: true
};
var InputState = _createClass(function InputState() {
  _classCallCheck(this, InputState);
  this.shiftKey = false;
  this.mouseDown = null;
  this.lastKeyCode = null;
  this.lastKeyCodeTime = 0;
  this.lastClick = {
    time: 0,
    x: 0,
    y: 0,
    type: ""
  };
  this.lastSelectionOrigin = null;
  this.lastSelectionTime = 0;
  this.lastIOSEnter = 0;
  this.lastIOSEnterFallbackTimeout = -1;
  this.lastFocus = 0;
  this.lastTouch = 0;
  this.lastAndroidDelete = 0;
  this.composing = false;
  this.compositionNode = null;
  this.composingTimeout = -1;
  this.compositionNodes = [];
  this.compositionEndedAt = -2e8;
  this.compositionID = 1;
  this.compositionPendingChanges = 0;
  this.domChangeCount = 0;
  this.eventHandlers = Object.create(null);
  this.hideSelectionGuard = null;
});
function initInput(view) {
  var _loop2 = function _loop2() {
    var handler = handlers[event];
    view.dom.addEventListener(event, view.input.eventHandlers[event] = function (event) {
      if (eventBelongsToView(view, event) && !runCustomHandler(view, event) && (view.editable || !(event.type in editHandlers))) handler(view, event);
    }, passiveHandlers[event] ? {
      passive: true
    } : undefined);
  };
  for (var event in handlers) {
    _loop2();
  }
  if (safari) view.dom.addEventListener("input", function () {
    return null;
  });
  ensureListeners(view);
}
function setSelectionOrigin(view, origin) {
  view.input.lastSelectionOrigin = origin;
  view.input.lastSelectionTime = Date.now();
}
function destroyInput(view) {
  view.domObserver.stop();
  for (var type in view.input.eventHandlers) view.dom.removeEventListener(type, view.input.eventHandlers[type]);
  clearTimeout(view.input.composingTimeout);
  clearTimeout(view.input.lastIOSEnterFallbackTimeout);
}
function ensureListeners(view) {
  view.someProp("handleDOMEvents", function (currentHandlers) {
    for (var type in currentHandlers) if (!view.input.eventHandlers[type]) view.dom.addEventListener(type, view.input.eventHandlers[type] = function (event) {
      return runCustomHandler(view, event);
    });
  });
}
function runCustomHandler(view, event) {
  return view.someProp("handleDOMEvents", function (handlers) {
    var handler = handlers[event.type];
    return handler ? handler(view, event) || event.defaultPrevented : false;
  });
}
function eventBelongsToView(view, event) {
  if (!event.bubbles) return true;
  if (event.defaultPrevented) return false;
  for (var node = event.target; node != view.dom; node = node.parentNode) if (!node || node.nodeType == 11 || node.pmViewDesc && node.pmViewDesc.stopEvent(event)) return false;
  return true;
}
function _dispatchEvent(view, event) {
  if (!runCustomHandler(view, event) && handlers[event.type] && (view.editable || !(event.type in editHandlers))) handlers[event.type](view, event);
}
editHandlers.keydown = function (view, _event) {
  var event = _event;
  view.input.shiftKey = event.keyCode == 16 || event.shiftKey;
  if (inOrNearComposition(view, event)) return;
  view.input.lastKeyCode = event.keyCode;
  view.input.lastKeyCodeTime = Date.now();
  if (android && chrome && event.keyCode == 13) return;
  if (event.keyCode != 229) view.domObserver.forceFlush();
  if (ios && event.keyCode == 13 && !event.ctrlKey && !event.altKey && !event.metaKey) {
    var now = Date.now();
    view.input.lastIOSEnter = now;
    view.input.lastIOSEnterFallbackTimeout = setTimeout(function () {
      if (view.input.lastIOSEnter == now) {
        view.someProp("handleKeyDown", function (f) {
          return f(view, keyEvent(13, "Enter"));
        });
        view.input.lastIOSEnter = 0;
      }
    }, 200);
  } else if (view.someProp("handleKeyDown", function (f) {
    return f(view, event);
  }) || captureKeyDown(view, event)) {
    event.preventDefault();
  } else {
    setSelectionOrigin(view, "key");
  }
};
editHandlers.keyup = function (view, event) {
  if (event.keyCode == 16) view.input.shiftKey = false;
};
editHandlers.keypress = function (view, _event) {
  var event = _event;
  if (inOrNearComposition(view, event) || !event.charCode || event.ctrlKey && !event.altKey || mac && event.metaKey) return;
  if (view.someProp("handleKeyPress", function (f) {
    return f(view, event);
  })) {
    event.preventDefault();
    return;
  }
  var sel = view.state.selection;
  if (!(sel instanceof prosemirrorState.TextSelection) || !sel.$from.sameParent(sel.$to)) {
    var text = String.fromCharCode(event.charCode);
    if (!/[\r\n]/.test(text) && !view.someProp("handleTextInput", function (f) {
      return f(view, sel.$from.pos, sel.$to.pos, text);
    })) view.dispatch(view.state.tr.insertText(text).scrollIntoView());
    event.preventDefault();
  }
};
function eventCoords(event) {
  return {
    left: event.clientX,
    top: event.clientY
  };
}
function isNear(event, click) {
  var dx = click.x - event.clientX,
    dy = click.y - event.clientY;
  return dx * dx + dy * dy < 100;
}
function runHandlerOnContext(view, propName, pos, inside, event) {
  if (inside == -1) return false;
  var $pos = view.state.doc.resolve(inside);
  var _loop3 = function _loop3(i) {
      if (view.someProp(propName, function (f) {
        return i > $pos.depth ? f(view, pos, $pos.nodeAfter, $pos.before(i), event, true) : f(view, pos, $pos.node(i), $pos.before(i), event, false);
      })) return {
        v: true
      };
    },
    _ret2;
  for (var i = $pos.depth + 1; i > 0; i--) {
    _ret2 = _loop3(i);
    if (_ret2) return _ret2.v;
  }
  return false;
}
function updateSelection(view, selection, origin) {
  if (!view.focused) view.focus();
  if (view.state.selection.eq(selection)) return;
  var tr = view.state.tr.setSelection(selection);
  if (origin == "pointer") tr.setMeta("pointer", true);
  view.dispatch(tr);
}
function selectClickedLeaf(view, inside) {
  if (inside == -1) return false;
  var $pos = view.state.doc.resolve(inside),
    node = $pos.nodeAfter;
  if (node && node.isAtom && prosemirrorState.NodeSelection.isSelectable(node)) {
    updateSelection(view, new prosemirrorState.NodeSelection($pos), "pointer");
    return true;
  }
  return false;
}
function selectClickedNode(view, inside) {
  if (inside == -1) return false;
  var sel = view.state.selection,
    selectedNode,
    selectAt;
  if (sel instanceof prosemirrorState.NodeSelection) selectedNode = sel.node;
  var $pos = view.state.doc.resolve(inside);
  for (var i = $pos.depth + 1; i > 0; i--) {
    var node = i > $pos.depth ? $pos.nodeAfter : $pos.node(i);
    if (prosemirrorState.NodeSelection.isSelectable(node)) {
      if (selectedNode && sel.$from.depth > 0 && i >= sel.$from.depth && $pos.before(sel.$from.depth + 1) == sel.$from.pos) selectAt = $pos.before(sel.$from.depth);else selectAt = $pos.before(i);
      break;
    }
  }
  if (selectAt != null) {
    updateSelection(view, prosemirrorState.NodeSelection.create(view.state.doc, selectAt), "pointer");
    return true;
  } else {
    return false;
  }
}
function handleSingleClick(view, pos, inside, event, selectNode) {
  return runHandlerOnContext(view, "handleClickOn", pos, inside, event) || view.someProp("handleClick", function (f) {
    return f(view, pos, event);
  }) || (selectNode ? selectClickedNode(view, inside) : selectClickedLeaf(view, inside));
}
function handleDoubleClick(view, pos, inside, event) {
  return runHandlerOnContext(view, "handleDoubleClickOn", pos, inside, event) || view.someProp("handleDoubleClick", function (f) {
    return f(view, pos, event);
  });
}
function handleTripleClick(view, pos, inside, event) {
  return runHandlerOnContext(view, "handleTripleClickOn", pos, inside, event) || view.someProp("handleTripleClick", function (f) {
    return f(view, pos, event);
  }) || defaultTripleClick(view, inside, event);
}
function defaultTripleClick(view, inside, event) {
  if (event.button != 0) return false;
  var doc = view.state.doc;
  if (inside == -1) {
    if (doc.inlineContent) {
      updateSelection(view, prosemirrorState.TextSelection.create(doc, 0, doc.content.size), "pointer");
      return true;
    }
    return false;
  }
  var $pos = doc.resolve(inside);
  for (var i = $pos.depth + 1; i > 0; i--) {
    var node = i > $pos.depth ? $pos.nodeAfter : $pos.node(i);
    var nodePos = $pos.before(i);
    if (node.inlineContent) updateSelection(view, prosemirrorState.TextSelection.create(doc, nodePos + 1, nodePos + 1 + node.content.size), "pointer");else if (prosemirrorState.NodeSelection.isSelectable(node)) updateSelection(view, prosemirrorState.NodeSelection.create(doc, nodePos), "pointer");else continue;
    return true;
  }
}
function forceDOMFlush(view) {
  return endComposition(view);
}
var selectNodeModifier = mac ? "metaKey" : "ctrlKey";
handlers.mousedown = function (view, _event) {
  var event = _event;
  view.input.shiftKey = event.shiftKey;
  var flushed = forceDOMFlush(view);
  var now = Date.now(),
    type = "singleClick";
  if (now - view.input.lastClick.time < 500 && isNear(event, view.input.lastClick) && !event[selectNodeModifier]) {
    if (view.input.lastClick.type == "singleClick") type = "doubleClick";else if (view.input.lastClick.type == "doubleClick") type = "tripleClick";
  }
  view.input.lastClick = {
    time: now,
    x: event.clientX,
    y: event.clientY,
    type: type
  };
  var pos = view.posAtCoords(eventCoords(event));
  if (!pos) return;
  if (type == "singleClick") {
    if (view.input.mouseDown) view.input.mouseDown.done();
    view.input.mouseDown = new MouseDown(view, pos, event, !!flushed);
  } else if ((type == "doubleClick" ? handleDoubleClick : handleTripleClick)(view, pos.pos, pos.inside, event)) {
    event.preventDefault();
  } else {
    setSelectionOrigin(view, "pointer");
  }
};
var MouseDown = function () {
  function MouseDown(view, pos, event, flushed) {
    var _this8 = this;
    _classCallCheck(this, MouseDown);
    this.view = view;
    this.pos = pos;
    this.event = event;
    this.flushed = flushed;
    this.delayedSelectionSync = false;
    this.mightDrag = null;
    this.startDoc = view.state.doc;
    this.selectNode = !!event[selectNodeModifier];
    this.allowDefault = event.shiftKey;
    var targetNode, targetPos;
    if (pos.inside > -1) {
      targetNode = view.state.doc.nodeAt(pos.inside);
      targetPos = pos.inside;
    } else {
      var $pos = view.state.doc.resolve(pos.pos);
      targetNode = $pos.parent;
      targetPos = $pos.depth ? $pos.before() : 0;
    }
    var target = flushed ? null : event.target;
    var targetDesc = target ? view.docView.nearestDesc(target, true) : null;
    this.target = targetDesc && targetDesc.dom.nodeType == 1 ? targetDesc.dom : null;
    var selection = view.state.selection;
    if (event.button == 0 && targetNode.type.spec.draggable && targetNode.type.spec.selectable !== false || selection instanceof prosemirrorState.NodeSelection && selection.from <= targetPos && selection.to > targetPos) this.mightDrag = {
      node: targetNode,
      pos: targetPos,
      addAttr: !!(this.target && !this.target.draggable),
      setUneditable: !!(this.target && gecko && !this.target.hasAttribute("contentEditable"))
    };
    if (this.target && this.mightDrag && (this.mightDrag.addAttr || this.mightDrag.setUneditable)) {
      this.view.domObserver.stop();
      if (this.mightDrag.addAttr) this.target.draggable = true;
      if (this.mightDrag.setUneditable) setTimeout(function () {
        if (_this8.view.input.mouseDown == _this8) _this8.target.setAttribute("contentEditable", "false");
      }, 20);
      this.view.domObserver.start();
    }
    view.root.addEventListener("mouseup", this.up = this.up.bind(this));
    view.root.addEventListener("mousemove", this.move = this.move.bind(this));
    setSelectionOrigin(view, "pointer");
  }
  _createClass(MouseDown, [{
    key: "done",
    value: function done() {
      var _this9 = this;
      this.view.root.removeEventListener("mouseup", this.up);
      this.view.root.removeEventListener("mousemove", this.move);
      if (this.mightDrag && this.target) {
        this.view.domObserver.stop();
        if (this.mightDrag.addAttr) this.target.removeAttribute("draggable");
        if (this.mightDrag.setUneditable) this.target.removeAttribute("contentEditable");
        this.view.domObserver.start();
      }
      if (this.delayedSelectionSync) setTimeout(function () {
        return selectionToDOM(_this9.view);
      });
      this.view.input.mouseDown = null;
    }
  }, {
    key: "up",
    value: function up(event) {
      this.done();
      if (!this.view.dom.contains(event.target)) return;
      var pos = this.pos;
      if (this.view.state.doc != this.startDoc) pos = this.view.posAtCoords(eventCoords(event));
      this.updateAllowDefault(event);
      if (this.allowDefault || !pos) {
        setSelectionOrigin(this.view, "pointer");
      } else if (handleSingleClick(this.view, pos.pos, pos.inside, event, this.selectNode)) {
        event.preventDefault();
      } else if (event.button == 0 && (this.flushed || safari && this.mightDrag && !this.mightDrag.node.isAtom || chrome && !this.view.state.selection.visible && Math.min(Math.abs(pos.pos - this.view.state.selection.from), Math.abs(pos.pos - this.view.state.selection.to)) <= 2)) {
        updateSelection(this.view, prosemirrorState.Selection.near(this.view.state.doc.resolve(pos.pos)), "pointer");
        event.preventDefault();
      } else {
        setSelectionOrigin(this.view, "pointer");
      }
    }
  }, {
    key: "move",
    value: function move(event) {
      this.updateAllowDefault(event);
      setSelectionOrigin(this.view, "pointer");
      if (event.buttons == 0) this.done();
    }
  }, {
    key: "updateAllowDefault",
    value: function updateAllowDefault(event) {
      if (!this.allowDefault && (Math.abs(this.event.x - event.clientX) > 4 || Math.abs(this.event.y - event.clientY) > 4)) this.allowDefault = true;
    }
  }]);
  return MouseDown;
}();
handlers.touchstart = function (view) {
  view.input.lastTouch = Date.now();
  forceDOMFlush(view);
  setSelectionOrigin(view, "pointer");
};
handlers.touchmove = function (view) {
  view.input.lastTouch = Date.now();
  setSelectionOrigin(view, "pointer");
};
handlers.contextmenu = function (view) {
  return forceDOMFlush(view);
};
function inOrNearComposition(view, event) {
  if (view.composing) return true;
  if (safari && Math.abs(event.timeStamp - view.input.compositionEndedAt) < 500) {
    view.input.compositionEndedAt = -2e8;
    return true;
  }
  return false;
}
var timeoutComposition = android ? 5000 : -1;
editHandlers.compositionstart = editHandlers.compositionupdate = function (view) {
  if (!view.composing) {
    view.domObserver.flush();
    var state = view.state,
      $pos = state.selection.$to;
    if (state.selection instanceof prosemirrorState.TextSelection && (state.storedMarks || !$pos.textOffset && $pos.parentOffset && $pos.nodeBefore.marks.some(function (m) {
      return m.type.spec.inclusive === false;
    }))) {
      view.markCursor = view.state.storedMarks || $pos.marks();
      endComposition(view, true);
      view.markCursor = null;
    } else {
      endComposition(view, !state.selection.empty);
      if (gecko && state.selection.empty && $pos.parentOffset && !$pos.textOffset && $pos.nodeBefore.marks.length) {
        var sel = view.domSelectionRange();
        for (var node = sel.focusNode, offset = sel.focusOffset; node && node.nodeType == 1 && offset != 0;) {
          var before = offset < 0 ? node.lastChild : node.childNodes[offset - 1];
          if (!before) break;
          if (before.nodeType == 3) {
            var _sel = view.domSelection();
            if (_sel) _sel.collapse(before, before.nodeValue.length);
            break;
          } else {
            node = before;
            offset = -1;
          }
        }
      }
    }
    view.input.composing = true;
  }
  scheduleComposeEnd(view, timeoutComposition);
};
editHandlers.compositionend = function (view, event) {
  if (view.composing) {
    view.input.composing = false;
    view.input.compositionEndedAt = event.timeStamp;
    view.input.compositionPendingChanges = view.domObserver.pendingRecords().length ? view.input.compositionID : 0;
    view.input.compositionNode = null;
    if (view.input.compositionPendingChanges) Promise.resolve().then(function () {
      return view.domObserver.flush();
    });
    view.input.compositionID++;
    scheduleComposeEnd(view, 20);
  }
};
function scheduleComposeEnd(view, delay) {
  clearTimeout(view.input.composingTimeout);
  if (delay > -1) view.input.composingTimeout = setTimeout(function () {
    return endComposition(view);
  }, delay);
}
function clearComposition(view) {
  if (view.composing) {
    view.input.composing = false;
    view.input.compositionEndedAt = timestampFromCustomEvent();
  }
  while (view.input.compositionNodes.length > 0) view.input.compositionNodes.pop().markParentsDirty();
}
function findCompositionNode(view) {
  var sel = view.domSelectionRange();
  if (!sel.focusNode) return null;
  var textBefore = textNodeBefore$1(sel.focusNode, sel.focusOffset);
  var textAfter = textNodeAfter$1(sel.focusNode, sel.focusOffset);
  if (textBefore && textAfter && textBefore != textAfter) {
    var descAfter = textAfter.pmViewDesc,
      lastChanged = view.domObserver.lastChangedTextNode;
    if (textBefore == lastChanged || textAfter == lastChanged) return lastChanged;
    if (!descAfter || !descAfter.isText(textAfter.nodeValue)) {
      return textAfter;
    } else if (view.input.compositionNode == textAfter) {
      var descBefore = textBefore.pmViewDesc;
      if (!(!descBefore || !descBefore.isText(textBefore.nodeValue))) return textAfter;
    }
  }
  return textBefore || textAfter;
}
function timestampFromCustomEvent() {
  var event = document.createEvent("Event");
  event.initEvent("event", true, true);
  return event.timeStamp;
}
function endComposition(view) {
  var restarting = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
  if (android && view.domObserver.flushingSoon >= 0) return;
  view.domObserver.forceFlush();
  clearComposition(view);
  if (restarting || view.docView && view.docView.dirty) {
    var sel = selectionFromDOM(view);
    if (sel && !sel.eq(view.state.selection)) view.dispatch(view.state.tr.setSelection(sel));else if ((view.markCursor || restarting) && !view.state.selection.empty) view.dispatch(view.state.tr.deleteSelection());else view.updateState(view.state);
    return true;
  }
  return false;
}
function captureCopy(view, dom) {
  if (!view.dom.parentNode) return;
  var wrap = view.dom.parentNode.appendChild(document.createElement("div"));
  wrap.appendChild(dom);
  wrap.style.cssText = "position: fixed; left: -10000px; top: 10px";
  var sel = getSelection(),
    range = document.createRange();
  range.selectNodeContents(dom);
  view.dom.blur();
  sel.removeAllRanges();
  sel.addRange(range);
  setTimeout(function () {
    if (wrap.parentNode) wrap.parentNode.removeChild(wrap);
    view.focus();
  }, 50);
}
var brokenClipboardAPI = ie && ie_version < 15 || ios && webkit_version < 604;
handlers.copy = editHandlers.cut = function (view, _event) {
  var event = _event;
  var sel = view.state.selection,
    cut = event.type == "cut";
  if (sel.empty) return;
  var data = brokenClipboardAPI ? null : event.clipboardData;
  var slice = sel.content(),
    _serializeForClipboar = serializeForClipboard(view, slice),
    dom = _serializeForClipboar.dom,
    text = _serializeForClipboar.text;
  if (data) {
    event.preventDefault();
    data.clearData();
    data.setData("text/html", dom.innerHTML);
    data.setData("text/plain", text);
  } else {
    captureCopy(view, dom);
  }
  if (cut) view.dispatch(view.state.tr.deleteSelection().scrollIntoView().setMeta("uiEvent", "cut"));
};
function sliceSingleNode(slice) {
  return slice.openStart == 0 && slice.openEnd == 0 && slice.content.childCount == 1 ? slice.content.firstChild : null;
}
function capturePaste(view, event) {
  if (!view.dom.parentNode) return;
  var plainText = view.input.shiftKey || view.state.selection.$from.parent.type.spec.code;
  var target = view.dom.parentNode.appendChild(document.createElement(plainText ? "textarea" : "div"));
  if (!plainText) target.contentEditable = "true";
  target.style.cssText = "position: fixed; left: -10000px; top: 10px";
  target.focus();
  var plain = view.input.shiftKey && view.input.lastKeyCode != 45;
  setTimeout(function () {
    view.focus();
    if (target.parentNode) target.parentNode.removeChild(target);
    if (plainText) doPaste(view, target.value, null, plain, event);else doPaste(view, target.textContent, target.innerHTML, plain, event);
  }, 50);
}
function doPaste(view, text, html, preferPlain, event) {
  var slice = parseFromClipboard(view, text, html, preferPlain, view.state.selection.$from);
  if (view.someProp("handlePaste", function (f) {
    return f(view, event, slice || prosemirrorModel.Slice.empty);
  })) return true;
  if (!slice) return false;
  var singleNode = sliceSingleNode(slice);
  var tr = singleNode ? view.state.tr.replaceSelectionWith(singleNode, preferPlain) : view.state.tr.replaceSelection(slice);
  view.dispatch(tr.scrollIntoView().setMeta("paste", true).setMeta("uiEvent", "paste"));
  return true;
}
function getText(clipboardData) {
  var text = clipboardData.getData("text/plain") || clipboardData.getData("Text");
  if (text) return text;
  var uris = clipboardData.getData("text/uri-list");
  return uris ? uris.replace(/\r?\n/g, " ") : "";
}
editHandlers.paste = function (view, _event) {
  var event = _event;
  if (view.composing && !android) return;
  var data = brokenClipboardAPI ? null : event.clipboardData;
  var plain = view.input.shiftKey && view.input.lastKeyCode != 45;
  if (data && doPaste(view, getText(data), data.getData("text/html"), plain, event)) event.preventDefault();else capturePaste(view, event);
};
var Dragging = _createClass(function Dragging(slice, move, node) {
  _classCallCheck(this, Dragging);
  this.slice = slice;
  this.move = move;
  this.node = node;
});
var dragCopyModifier = mac ? "altKey" : "ctrlKey";
handlers.dragstart = function (view, _event) {
  var event = _event;
  var mouseDown = view.input.mouseDown;
  if (mouseDown) mouseDown.done();
  if (!event.dataTransfer) return;
  var sel = view.state.selection;
  var pos = sel.empty ? null : view.posAtCoords(eventCoords(event));
  var node;
  if (pos && pos.pos >= sel.from && pos.pos <= (sel instanceof prosemirrorState.NodeSelection ? sel.to - 1 : sel.to)) ;else if (mouseDown && mouseDown.mightDrag) {
    node = prosemirrorState.NodeSelection.create(view.state.doc, mouseDown.mightDrag.pos);
  } else if (event.target && event.target.nodeType == 1) {
    var desc = view.docView.nearestDesc(event.target, true);
    if (desc && desc.node.type.spec.draggable && desc != view.docView) node = prosemirrorState.NodeSelection.create(view.state.doc, desc.posBefore);
  }
  var draggedSlice = (node || view.state.selection).content();
  var _serializeForClipboar2 = serializeForClipboard(view, draggedSlice),
    dom = _serializeForClipboar2.dom,
    text = _serializeForClipboar2.text,
    slice = _serializeForClipboar2.slice;
  if (!event.dataTransfer.files.length || !chrome || chrome_version > 120) event.dataTransfer.clearData();
  event.dataTransfer.setData(brokenClipboardAPI ? "Text" : "text/html", dom.innerHTML);
  event.dataTransfer.effectAllowed = "copyMove";
  if (!brokenClipboardAPI) event.dataTransfer.setData("text/plain", text);
  view.dragging = new Dragging(slice, !event[dragCopyModifier], node);
};
handlers.dragend = function (view) {
  var dragging = view.dragging;
  window.setTimeout(function () {
    if (view.dragging == dragging) view.dragging = null;
  }, 50);
};
editHandlers.dragover = editHandlers.dragenter = function (_, e) {
  return e.preventDefault();
};
editHandlers.drop = function (view, _event) {
  var event = _event;
  var dragging = view.dragging;
  view.dragging = null;
  if (!event.dataTransfer) return;
  var eventPos = view.posAtCoords(eventCoords(event));
  if (!eventPos) return;
  var $mouse = view.state.doc.resolve(eventPos.pos);
  var slice = dragging && dragging.slice;
  if (slice) {
    view.someProp("transformPasted", function (f) {
      slice = f(slice, view);
    });
  } else {
    slice = parseFromClipboard(view, getText(event.dataTransfer), brokenClipboardAPI ? null : event.dataTransfer.getData("text/html"), false, $mouse);
  }
  var move = !!(dragging && !event[dragCopyModifier]);
  if (view.someProp("handleDrop", function (f) {
    return f(view, event, slice || prosemirrorModel.Slice.empty, move);
  })) {
    event.preventDefault();
    return;
  }
  if (!slice) return;
  event.preventDefault();
  var insertPos = slice ? prosemirrorTransform.dropPoint(view.state.doc, $mouse.pos, slice) : $mouse.pos;
  if (insertPos == null) insertPos = $mouse.pos;
  var tr = view.state.tr;
  if (move) {
    var node = dragging.node;
    if (node) node.replace(tr);else tr.deleteSelection();
  }
  var pos = tr.mapping.map(insertPos);
  var isNode = slice.openStart == 0 && slice.openEnd == 0 && slice.content.childCount == 1;
  var beforeInsert = tr.doc;
  if (isNode) tr.replaceRangeWith(pos, pos, slice.content.firstChild);else tr.replaceRange(pos, pos, slice);
  if (tr.doc.eq(beforeInsert)) return;
  var $pos = tr.doc.resolve(pos);
  if (isNode && prosemirrorState.NodeSelection.isSelectable(slice.content.firstChild) && $pos.nodeAfter && $pos.nodeAfter.sameMarkup(slice.content.firstChild)) {
    tr.setSelection(new prosemirrorState.NodeSelection($pos));
  } else {
    var end = tr.mapping.map(insertPos);
    tr.mapping.maps[tr.mapping.maps.length - 1].forEach(function (_from, _to, _newFrom, newTo) {
      return end = newTo;
    });
    tr.setSelection(selectionBetween(view, $pos, tr.doc.resolve(end)));
  }
  view.focus();
  view.dispatch(tr.setMeta("uiEvent", "drop"));
};
handlers.focus = function (view) {
  view.input.lastFocus = Date.now();
  if (!view.focused) {
    view.domObserver.stop();
    view.dom.classList.add("ProseMirror-focused");
    view.domObserver.start();
    view.focused = true;
    setTimeout(function () {
      if (view.docView && view.hasFocus() && !view.domObserver.currentSelection.eq(view.domSelectionRange())) selectionToDOM(view);
    }, 20);
  }
};
handlers.blur = function (view, _event) {
  var event = _event;
  if (view.focused) {
    view.domObserver.stop();
    view.dom.classList.remove("ProseMirror-focused");
    view.domObserver.start();
    if (event.relatedTarget && view.dom.contains(event.relatedTarget)) view.domObserver.currentSelection.clear();
    view.focused = false;
  }
};
handlers.beforeinput = function (view, _event) {
  var event = _event;
  if (chrome && android && event.inputType == "deleteContentBackward") {
    view.domObserver.flushSoon();
    var domChangeCount = view.input.domChangeCount;
    setTimeout(function () {
      if (view.input.domChangeCount != domChangeCount) return;
      view.dom.blur();
      view.focus();
      if (view.someProp("handleKeyDown", function (f) {
        return f(view, keyEvent(8, "Backspace"));
      })) return;
      var $cursor = view.state.selection.$cursor;
      if ($cursor && $cursor.pos > 0) view.dispatch(view.state.tr["delete"]($cursor.pos - 1, $cursor.pos).scrollIntoView());
    }, 50);
  }
};
for (var prop in editHandlers) handlers[prop] = editHandlers[prop];
function compareObjs(a, b) {
  if (a == b) return true;
  for (var p in a) if (a[p] !== b[p]) return false;
  for (var _p in b) if (!(_p in a)) return false;
  return true;
}
var WidgetType = function () {
  function WidgetType(toDOM, spec) {
    _classCallCheck(this, WidgetType);
    this.toDOM = toDOM;
    this.spec = spec || noSpec;
    this.side = this.spec.side || 0;
  }
  _createClass(WidgetType, [{
    key: "map",
    value: function map(mapping, span, offset, oldOffset) {
      var _mapping$mapResult = mapping.mapResult(span.from + oldOffset, this.side < 0 ? -1 : 1),
        pos = _mapping$mapResult.pos,
        deleted = _mapping$mapResult.deleted;
      return deleted ? null : new Decoration(pos - offset, pos - offset, this);
    }
  }, {
    key: "valid",
    value: function valid() {
      return true;
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return this == other || other instanceof WidgetType && (this.spec.key && this.spec.key == other.spec.key || this.toDOM == other.toDOM && compareObjs(this.spec, other.spec));
    }
  }, {
    key: "destroy",
    value: function destroy(node) {
      if (this.spec.destroy) this.spec.destroy(node);
    }
  }]);
  return WidgetType;
}();
var InlineType = function () {
  function InlineType(attrs, spec) {
    _classCallCheck(this, InlineType);
    this.attrs = attrs;
    this.spec = spec || noSpec;
  }
  _createClass(InlineType, [{
    key: "map",
    value: function map(mapping, span, offset, oldOffset) {
      var from = mapping.map(span.from + oldOffset, this.spec.inclusiveStart ? -1 : 1) - offset;
      var to = mapping.map(span.to + oldOffset, this.spec.inclusiveEnd ? 1 : -1) - offset;
      return from >= to ? null : new Decoration(from, to, this);
    }
  }, {
    key: "valid",
    value: function valid(_, span) {
      return span.from < span.to;
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return this == other || other instanceof InlineType && compareObjs(this.attrs, other.attrs) && compareObjs(this.spec, other.spec);
    }
  }, {
    key: "destroy",
    value: function destroy() {}
  }], [{
    key: "is",
    value: function is(span) {
      return span.type instanceof InlineType;
    }
  }]);
  return InlineType;
}();
var NodeType = function () {
  function NodeType(attrs, spec) {
    _classCallCheck(this, NodeType);
    this.attrs = attrs;
    this.spec = spec || noSpec;
  }
  _createClass(NodeType, [{
    key: "map",
    value: function map(mapping, span, offset, oldOffset) {
      var from = mapping.mapResult(span.from + oldOffset, 1);
      if (from.deleted) return null;
      var to = mapping.mapResult(span.to + oldOffset, -1);
      if (to.deleted || to.pos <= from.pos) return null;
      return new Decoration(from.pos - offset, to.pos - offset, this);
    }
  }, {
    key: "valid",
    value: function valid(node, span) {
      var _node$content$findInd = node.content.findIndex(span.from),
        index = _node$content$findInd.index,
        offset = _node$content$findInd.offset,
        child;
      return offset == span.from && !(child = node.child(index)).isText && offset + child.nodeSize == span.to;
    }
  }, {
    key: "eq",
    value: function eq(other) {
      return this == other || other instanceof NodeType && compareObjs(this.attrs, other.attrs) && compareObjs(this.spec, other.spec);
    }
  }, {
    key: "destroy",
    value: function destroy() {}
  }]);
  return NodeType;
}();
var Decoration = function () {
  function Decoration(from, to, type) {
    _classCallCheck(this, Decoration);
    this.from = from;
    this.to = to;
    this.type = type;
  }
  _createClass(Decoration, [{
    key: "copy",
    value: function copy(from, to) {
      return new Decoration(from, to, this.type);
    }
  }, {
    key: "eq",
    value: function eq(other) {
      var offset = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
      return this.type.eq(other.type) && this.from + offset == other.from && this.to + offset == other.to;
    }
  }, {
    key: "map",
    value: function map(mapping, offset, oldOffset) {
      return this.type.map(mapping, this, offset, oldOffset);
    }
  }, {
    key: "spec",
    get: function get() {
      return this.type.spec;
    }
  }, {
    key: "inline",
    get: function get() {
      return this.type instanceof InlineType;
    }
  }, {
    key: "widget",
    get: function get() {
      return this.type instanceof WidgetType;
    }
  }], [{
    key: "widget",
    value: function widget(pos, toDOM, spec) {
      return new Decoration(pos, pos, new WidgetType(toDOM, spec));
    }
  }, {
    key: "inline",
    value: function inline(from, to, attrs, spec) {
      return new Decoration(from, to, new InlineType(attrs, spec));
    }
  }, {
    key: "node",
    value: function node(from, to, attrs, spec) {
      return new Decoration(from, to, new NodeType(attrs, spec));
    }
  }]);
  return Decoration;
}();
var none = [],
  noSpec = {};
var DecorationSet = function () {
  function DecorationSet(local, children) {
    _classCallCheck(this, DecorationSet);
    this.local = local.length ? local : none;
    this.children = children.length ? children : none;
  }
  _createClass(DecorationSet, [{
    key: "find",
    value: function find(start, end, predicate) {
      var result = [];
      this.findInner(start == null ? 0 : start, end == null ? 1e9 : end, result, 0, predicate);
      return result;
    }
  }, {
    key: "findInner",
    value: function findInner(start, end, result, offset, predicate) {
      for (var i = 0; i < this.local.length; i++) {
        var span = this.local[i];
        if (span.from <= end && span.to >= start && (!predicate || predicate(span.spec))) result.push(span.copy(span.from + offset, span.to + offset));
      }
      for (var _i5 = 0; _i5 < this.children.length; _i5 += 3) {
        if (this.children[_i5] < end && this.children[_i5 + 1] > start) {
          var childOff = this.children[_i5] + 1;
          this.children[_i5 + 2].findInner(start - childOff, end - childOff, result, offset + childOff, predicate);
        }
      }
    }
  }, {
    key: "map",
    value: function map(mapping, doc, options) {
      if (this == empty || mapping.maps.length == 0) return this;
      return this.mapInner(mapping, doc, 0, 0, options || noSpec);
    }
  }, {
    key: "mapInner",
    value: function mapInner(mapping, node, offset, oldOffset, options) {
      var newLocal;
      for (var i = 0; i < this.local.length; i++) {
        var mapped = this.local[i].map(mapping, offset, oldOffset);
        if (mapped && mapped.type.valid(node, mapped)) (newLocal || (newLocal = [])).push(mapped);else if (options.onRemove) options.onRemove(this.local[i].spec);
      }
      if (this.children.length) return mapChildren(this.children, newLocal || [], mapping, node, offset, oldOffset, options);else return newLocal ? new DecorationSet(newLocal.sort(byPos), none) : empty;
    }
  }, {
    key: "add",
    value: function add(doc, decorations) {
      if (!decorations.length) return this;
      if (this == empty) return DecorationSet.create(doc, decorations);
      return this.addInner(doc, decorations, 0);
    }
  }, {
    key: "addInner",
    value: function addInner(doc, decorations, offset) {
      var _this10 = this;
      var children,
        childIndex = 0;
      doc.forEach(function (childNode, childOffset) {
        var baseOffset = childOffset + offset,
          found;
        if (!(found = takeSpansForNode(decorations, childNode, baseOffset))) return;
        if (!children) children = _this10.children.slice();
        while (childIndex < children.length && children[childIndex] < childOffset) childIndex += 3;
        if (children[childIndex] == childOffset) children[childIndex + 2] = children[childIndex + 2].addInner(childNode, found, baseOffset + 1);else children.splice(childIndex, 0, childOffset, childOffset + childNode.nodeSize, buildTree(found, childNode, baseOffset + 1, noSpec));
        childIndex += 3;
      });
      var local = moveSpans(childIndex ? withoutNulls(decorations) : decorations, -offset);
      for (var i = 0; i < local.length; i++) if (!local[i].type.valid(doc, local[i])) local.splice(i--, 1);
      return new DecorationSet(local.length ? this.local.concat(local).sort(byPos) : this.local, children || this.children);
    }
  }, {
    key: "remove",
    value: function remove(decorations) {
      if (decorations.length == 0 || this == empty) return this;
      return this.removeInner(decorations, 0);
    }
  }, {
    key: "removeInner",
    value: function removeInner(decorations, offset) {
      var children = this.children,
        local = this.local;
      for (var i = 0; i < children.length; i += 3) {
        var found = void 0;
        var from = children[i] + offset,
          to = children[i + 1] + offset;
        for (var j = 0, span; j < decorations.length; j++) if (span = decorations[j]) {
          if (span.from > from && span.to < to) {
            decorations[j] = null;
            (found || (found = [])).push(span);
          }
        }
        if (!found) continue;
        if (children == this.children) children = this.children.slice();
        var removed = children[i + 2].removeInner(found, from + 1);
        if (removed != empty) {
          children[i + 2] = removed;
        } else {
          children.splice(i, 3);
          i -= 3;
        }
      }
      if (local.length) for (var _i6 = 0, _span; _i6 < decorations.length; _i6++) if (_span = decorations[_i6]) {
        for (var _j2 = 0; _j2 < local.length; _j2++) if (local[_j2].eq(_span, offset)) {
          if (local == this.local) local = this.local.slice();
          local.splice(_j2--, 1);
        }
      }
      if (children == this.children && local == this.local) return this;
      return local.length || children.length ? new DecorationSet(local, children) : empty;
    }
  }, {
    key: "forChild",
    value: function forChild(offset, node) {
      if (this == empty) return this;
      if (node.isLeaf) return DecorationSet.empty;
      var child, local;
      for (var i = 0; i < this.children.length; i += 3) if (this.children[i] >= offset) {
        if (this.children[i] == offset) child = this.children[i + 2];
        break;
      }
      var start = offset + 1,
        end = start + node.content.size;
      for (var _i7 = 0; _i7 < this.local.length; _i7++) {
        var dec = this.local[_i7];
        if (dec.from < end && dec.to > start && dec.type instanceof InlineType) {
          var from = Math.max(start, dec.from) - start,
            to = Math.min(end, dec.to) - start;
          if (from < to) (local || (local = [])).push(dec.copy(from, to));
        }
      }
      if (local) {
        var localSet = new DecorationSet(local.sort(byPos), none);
        return child ? new DecorationGroup([localSet, child]) : localSet;
      }
      return child || empty;
    }
  }, {
    key: "eq",
    value: function eq(other) {
      if (this == other) return true;
      if (!(other instanceof DecorationSet) || this.local.length != other.local.length || this.children.length != other.children.length) return false;
      for (var i = 0; i < this.local.length; i++) if (!this.local[i].eq(other.local[i])) return false;
      for (var _i8 = 0; _i8 < this.children.length; _i8 += 3) if (this.children[_i8] != other.children[_i8] || this.children[_i8 + 1] != other.children[_i8 + 1] || !this.children[_i8 + 2].eq(other.children[_i8 + 2])) return false;
      return true;
    }
  }, {
    key: "locals",
    value: function locals(node) {
      return removeOverlap(this.localsInner(node));
    }
  }, {
    key: "localsInner",
    value: function localsInner(node) {
      if (this == empty) return none;
      if (node.inlineContent || !this.local.some(InlineType.is)) return this.local;
      var result = [];
      for (var i = 0; i < this.local.length; i++) {
        if (!(this.local[i].type instanceof InlineType)) result.push(this.local[i]);
      }
      return result;
    }
  }, {
    key: "forEachSet",
    value: function forEachSet(f) {
      f(this);
    }
  }], [{
    key: "create",
    value: function create(doc, decorations) {
      return decorations.length ? buildTree(decorations, doc, 0, noSpec) : empty;
    }
  }]);
  return DecorationSet;
}();
DecorationSet.empty = new DecorationSet([], []);
DecorationSet.removeOverlap = removeOverlap;
var empty = DecorationSet.empty;
var DecorationGroup = function () {
  function DecorationGroup(members) {
    _classCallCheck(this, DecorationGroup);
    this.members = members;
  }
  _createClass(DecorationGroup, [{
    key: "map",
    value: function map(mapping, doc) {
      var mappedDecos = this.members.map(function (member) {
        return member.map(mapping, doc, noSpec);
      });
      return DecorationGroup.from(mappedDecos);
    }
  }, {
    key: "forChild",
    value: function forChild(offset, child) {
      if (child.isLeaf) return DecorationSet.empty;
      var found = [];
      for (var i = 0; i < this.members.length; i++) {
        var result = this.members[i].forChild(offset, child);
        if (result == empty) continue;
        if (result instanceof DecorationGroup) found = found.concat(result.members);else found.push(result);
      }
      return DecorationGroup.from(found);
    }
  }, {
    key: "eq",
    value: function eq(other) {
      if (!(other instanceof DecorationGroup) || other.members.length != this.members.length) return false;
      for (var i = 0; i < this.members.length; i++) if (!this.members[i].eq(other.members[i])) return false;
      return true;
    }
  }, {
    key: "locals",
    value: function locals(node) {
      var result,
        sorted = true;
      for (var i = 0; i < this.members.length; i++) {
        var locals = this.members[i].localsInner(node);
        if (!locals.length) continue;
        if (!result) {
          result = locals;
        } else {
          if (sorted) {
            result = result.slice();
            sorted = false;
          }
          for (var j = 0; j < locals.length; j++) result.push(locals[j]);
        }
      }
      return result ? removeOverlap(sorted ? result : result.sort(byPos)) : none;
    }
  }, {
    key: "forEachSet",
    value: function forEachSet(f) {
      for (var i = 0; i < this.members.length; i++) this.members[i].forEachSet(f);
    }
  }], [{
    key: "from",
    value: function from(members) {
      switch (members.length) {
        case 0:
          return empty;
        case 1:
          return members[0];
        default:
          return new DecorationGroup(members.every(function (m) {
            return m instanceof DecorationSet;
          }) ? members : members.reduce(function (r, m) {
            return r.concat(m instanceof DecorationSet ? m : m.members);
          }, []));
      }
    }
  }]);
  return DecorationGroup;
}();
function mapChildren(oldChildren, newLocal, mapping, node, offset, oldOffset, options) {
  var children = oldChildren.slice();
  var _loop4 = function _loop4(_baseOffset) {
    var moved = 0;
    mapping.maps[i].forEach(function (oldStart, oldEnd, newStart, newEnd) {
      var dSize = newEnd - newStart - (oldEnd - oldStart);
      for (var _i12 = 0; _i12 < children.length; _i12 += 3) {
        var end = children[_i12 + 1];
        if (end < 0 || oldStart > end + _baseOffset - moved) continue;
        var start = children[_i12] + _baseOffset - moved;
        if (oldEnd >= start) {
          children[_i12 + 1] = oldStart <= start ? -2 : -1;
        } else if (oldStart >= _baseOffset && dSize) {
          children[_i12] += dSize;
          children[_i12 + 1] += dSize;
        }
      }
      moved += dSize;
    });
    _baseOffset = mapping.maps[i].map(_baseOffset, -1);
    baseOffset = _baseOffset;
  };
  for (var i = 0, baseOffset = oldOffset; i < mapping.maps.length; i++) {
    _loop4(baseOffset);
  }
  var mustRebuild = false;
  for (var _i9 = 0; _i9 < children.length; _i9 += 3) if (children[_i9 + 1] < 0) {
    if (children[_i9 + 1] == -2) {
      mustRebuild = true;
      children[_i9 + 1] = -1;
      continue;
    }
    var from = mapping.map(oldChildren[_i9] + oldOffset),
      fromLocal = from - offset;
    if (fromLocal < 0 || fromLocal >= node.content.size) {
      mustRebuild = true;
      continue;
    }
    var to = mapping.map(oldChildren[_i9 + 1] + oldOffset, -1),
      toLocal = to - offset;
    var _node$content$findInd2 = node.content.findIndex(fromLocal),
      index = _node$content$findInd2.index,
      childOffset = _node$content$findInd2.offset;
    var childNode = node.maybeChild(index);
    if (childNode && childOffset == fromLocal && childOffset + childNode.nodeSize == toLocal) {
      var mapped = children[_i9 + 2].mapInner(mapping, childNode, from + 1, oldChildren[_i9] + oldOffset + 1, options);
      if (mapped != empty) {
        children[_i9] = fromLocal;
        children[_i9 + 1] = toLocal;
        children[_i9 + 2] = mapped;
      } else {
        children[_i9 + 1] = -2;
        mustRebuild = true;
      }
    } else {
      mustRebuild = true;
    }
  }
  if (mustRebuild) {
    var decorations = mapAndGatherRemainingDecorations(children, oldChildren, newLocal, mapping, offset, oldOffset, options);
    var built = buildTree(decorations, node, 0, options);
    newLocal = built.local;
    for (var _i10 = 0; _i10 < children.length; _i10 += 3) if (children[_i10 + 1] < 0) {
      children.splice(_i10, 3);
      _i10 -= 3;
    }
    for (var _i11 = 0, j = 0; _i11 < built.children.length; _i11 += 3) {
      var _from2 = built.children[_i11];
      while (j < children.length && children[j] < _from2) j += 3;
      children.splice(j, 0, built.children[_i11], built.children[_i11 + 1], built.children[_i11 + 2]);
    }
  }
  return new DecorationSet(newLocal.sort(byPos), children);
}
function moveSpans(spans, offset) {
  if (!offset || !spans.length) return spans;
  var result = [];
  for (var i = 0; i < spans.length; i++) {
    var span = spans[i];
    result.push(new Decoration(span.from + offset, span.to + offset, span.type));
  }
  return result;
}
function mapAndGatherRemainingDecorations(children, oldChildren, decorations, mapping, offset, oldOffset, options) {
  function gather(set, oldOffset) {
    for (var i = 0; i < set.local.length; i++) {
      var mapped = set.local[i].map(mapping, offset, oldOffset);
      if (mapped) decorations.push(mapped);else if (options.onRemove) options.onRemove(set.local[i].spec);
    }
    for (var _i13 = 0; _i13 < set.children.length; _i13 += 3) gather(set.children[_i13 + 2], set.children[_i13] + oldOffset + 1);
  }
  for (var i = 0; i < children.length; i += 3) if (children[i + 1] == -1) gather(children[i + 2], oldChildren[i] + oldOffset + 1);
  return decorations;
}
function takeSpansForNode(spans, node, offset) {
  if (node.isLeaf) return null;
  var end = offset + node.nodeSize,
    found = null;
  for (var i = 0, span; i < spans.length; i++) {
    if ((span = spans[i]) && span.from > offset && span.to < end) {
      (found || (found = [])).push(span);
      spans[i] = null;
    }
  }
  return found;
}
function withoutNulls(array) {
  var result = [];
  for (var i = 0; i < array.length; i++) if (array[i] != null) result.push(array[i]);
  return result;
}
function buildTree(spans, node, offset, options) {
  var children = [],
    hasNulls = false;
  node.forEach(function (childNode, localStart) {
    var found = takeSpansForNode(spans, childNode, localStart + offset);
    if (found) {
      hasNulls = true;
      var subtree = buildTree(found, childNode, offset + localStart + 1, options);
      if (subtree != empty) children.push(localStart, localStart + childNode.nodeSize, subtree);
    }
  });
  var locals = moveSpans(hasNulls ? withoutNulls(spans) : spans, -offset).sort(byPos);
  for (var i = 0; i < locals.length; i++) if (!locals[i].type.valid(node, locals[i])) {
    if (options.onRemove) options.onRemove(locals[i].spec);
    locals.splice(i--, 1);
  }
  return locals.length || children.length ? new DecorationSet(locals, children) : empty;
}
function byPos(a, b) {
  return a.from - b.from || a.to - b.to;
}
function removeOverlap(spans) {
  var working = spans;
  for (var i = 0; i < working.length - 1; i++) {
    var span = working[i];
    if (span.from != span.to) for (var j = i + 1; j < working.length; j++) {
      var next = working[j];
      if (next.from == span.from) {
        if (next.to != span.to) {
          if (working == spans) working = spans.slice();
          working[j] = next.copy(next.from, span.to);
          insertAhead(working, j + 1, next.copy(span.to, next.to));
        }
        continue;
      } else {
        if (next.from < span.to) {
          if (working == spans) working = spans.slice();
          working[i] = span.copy(span.from, next.from);
          insertAhead(working, j, span.copy(next.from, span.to));
        }
        break;
      }
    }
  }
  return working;
}
function insertAhead(array, i, deco) {
  while (i < array.length && byPos(deco, array[i]) > 0) i++;
  array.splice(i, 0, deco);
}
function viewDecorations(view) {
  var found = [];
  view.someProp("decorations", function (f) {
    var result = f(view.state);
    if (result && result != empty) found.push(result);
  });
  if (view.cursorWrapper) found.push(DecorationSet.create(view.state.doc, [view.cursorWrapper.deco]));
  return DecorationGroup.from(found);
}
var observeOptions = {
  childList: true,
  characterData: true,
  characterDataOldValue: true,
  attributes: true,
  attributeOldValue: true,
  subtree: true
};
var useCharData = ie && ie_version <= 11;
var SelectionState = function () {
  function SelectionState() {
    _classCallCheck(this, SelectionState);
    this.anchorNode = null;
    this.anchorOffset = 0;
    this.focusNode = null;
    this.focusOffset = 0;
  }
  _createClass(SelectionState, [{
    key: "set",
    value: function set(sel) {
      this.anchorNode = sel.anchorNode;
      this.anchorOffset = sel.anchorOffset;
      this.focusNode = sel.focusNode;
      this.focusOffset = sel.focusOffset;
    }
  }, {
    key: "clear",
    value: function clear() {
      this.anchorNode = this.focusNode = null;
    }
  }, {
    key: "eq",
    value: function eq(sel) {
      return sel.anchorNode == this.anchorNode && sel.anchorOffset == this.anchorOffset && sel.focusNode == this.focusNode && sel.focusOffset == this.focusOffset;
    }
  }]);
  return SelectionState;
}();
var DOMObserver = function () {
  function DOMObserver(view, handleDOMChange) {
    var _this11 = this;
    _classCallCheck(this, DOMObserver);
    this.view = view;
    this.handleDOMChange = handleDOMChange;
    this.queue = [];
    this.flushingSoon = -1;
    this.observer = null;
    this.currentSelection = new SelectionState();
    this.onCharData = null;
    this.suppressingSelectionUpdates = false;
    this.lastChangedTextNode = null;
    this.observer = window.MutationObserver && new window.MutationObserver(function (mutations) {
      for (var i = 0; i < mutations.length; i++) _this11.queue.push(mutations[i]);
      if (ie && ie_version <= 11 && mutations.some(function (m) {
        return m.type == "childList" && m.removedNodes.length || m.type == "characterData" && m.oldValue.length > m.target.nodeValue.length;
      })) _this11.flushSoon();else _this11.flush();
    });
    if (useCharData) {
      this.onCharData = function (e) {
        _this11.queue.push({
          target: e.target,
          type: "characterData",
          oldValue: e.prevValue
        });
        _this11.flushSoon();
      };
    }
    this.onSelectionChange = this.onSelectionChange.bind(this);
  }
  _createClass(DOMObserver, [{
    key: "flushSoon",
    value: function flushSoon() {
      var _this12 = this;
      if (this.flushingSoon < 0) this.flushingSoon = window.setTimeout(function () {
        _this12.flushingSoon = -1;
        _this12.flush();
      }, 20);
    }
  }, {
    key: "forceFlush",
    value: function forceFlush() {
      if (this.flushingSoon > -1) {
        window.clearTimeout(this.flushingSoon);
        this.flushingSoon = -1;
        this.flush();
      }
    }
  }, {
    key: "start",
    value: function start() {
      if (this.observer) {
        this.observer.takeRecords();
        this.observer.observe(this.view.dom, observeOptions);
      }
      if (this.onCharData) this.view.dom.addEventListener("DOMCharacterDataModified", this.onCharData);
      this.connectSelection();
    }
  }, {
    key: "stop",
    value: function stop() {
      var _this13 = this;
      if (this.observer) {
        var take = this.observer.takeRecords();
        if (take.length) {
          for (var i = 0; i < take.length; i++) this.queue.push(take[i]);
          window.setTimeout(function () {
            return _this13.flush();
          }, 20);
        }
        this.observer.disconnect();
      }
      if (this.onCharData) this.view.dom.removeEventListener("DOMCharacterDataModified", this.onCharData);
      this.disconnectSelection();
    }
  }, {
    key: "connectSelection",
    value: function connectSelection() {
      this.view.dom.ownerDocument.addEventListener("selectionchange", this.onSelectionChange);
    }
  }, {
    key: "disconnectSelection",
    value: function disconnectSelection() {
      this.view.dom.ownerDocument.removeEventListener("selectionchange", this.onSelectionChange);
    }
  }, {
    key: "suppressSelectionUpdates",
    value: function suppressSelectionUpdates() {
      var _this14 = this;
      this.suppressingSelectionUpdates = true;
      setTimeout(function () {
        return _this14.suppressingSelectionUpdates = false;
      }, 50);
    }
  }, {
    key: "onSelectionChange",
    value: function onSelectionChange() {
      if (!hasFocusAndSelection(this.view)) return;
      if (this.suppressingSelectionUpdates) return selectionToDOM(this.view);
      if (ie && ie_version <= 11 && !this.view.state.selection.empty) {
        var sel = this.view.domSelectionRange();
        if (sel.focusNode && isEquivalentPosition(sel.focusNode, sel.focusOffset, sel.anchorNode, sel.anchorOffset)) return this.flushSoon();
      }
      this.flush();
    }
  }, {
    key: "setCurSelection",
    value: function setCurSelection() {
      this.currentSelection.set(this.view.domSelectionRange());
    }
  }, {
    key: "ignoreSelectionChange",
    value: function ignoreSelectionChange(sel) {
      if (!sel.focusNode) return true;
      var ancestors = new Set(),
        container;
      for (var scan = sel.focusNode; scan; scan = parentNode(scan)) ancestors.add(scan);
      for (var _scan = sel.anchorNode; _scan; _scan = parentNode(_scan)) if (ancestors.has(_scan)) {
        container = _scan;
        break;
      }
      var desc = container && this.view.docView.nearestDesc(container);
      if (desc && desc.ignoreMutation({
        type: "selection",
        target: container.nodeType == 3 ? container.parentNode : container
      })) {
        this.setCurSelection();
        return true;
      }
    }
  }, {
    key: "pendingRecords",
    value: function pendingRecords() {
      if (this.observer) {
        var _iterator2 = _createForOfIteratorHelper(this.observer.takeRecords()),
          _step2;
        try {
          for (_iterator2.s(); !(_step2 = _iterator2.n()).done;) {
            var mut = _step2.value;
            this.queue.push(mut);
          }
        } catch (err) {
          _iterator2.e(err);
        } finally {
          _iterator2.f();
        }
      }
      return this.queue;
    }
  }, {
    key: "flush",
    value: function flush() {
      var view = this.view;
      if (!view.docView || this.flushingSoon > -1) return;
      var mutations = this.pendingRecords();
      if (mutations.length) this.queue = [];
      var sel = view.domSelectionRange();
      var newSel = !this.suppressingSelectionUpdates && !this.currentSelection.eq(sel) && hasFocusAndSelection(view) && !this.ignoreSelectionChange(sel);
      var from = -1,
        to = -1,
        typeOver = false,
        added = [];
      if (view.editable) {
        for (var i = 0; i < mutations.length; i++) {
          var result = this.registerMutation(mutations[i], added);
          if (result) {
            from = from < 0 ? result.from : Math.min(result.from, from);
            to = to < 0 ? result.to : Math.max(result.to, to);
            if (result.typeOver) typeOver = true;
          }
        }
      }
      if (gecko && added.length) {
        var brs = added.filter(function (n) {
          return n.nodeName == "BR";
        });
        if (brs.length == 2) {
          var _brs = _slicedToArray(brs, 2),
            a = _brs[0],
            b = _brs[1];
          if (a.parentNode && a.parentNode.parentNode == b.parentNode) b.remove();else a.remove();
        } else {
          var focusNode = this.currentSelection.focusNode;
          var _iterator3 = _createForOfIteratorHelper(brs),
            _step3;
          try {
            for (_iterator3.s(); !(_step3 = _iterator3.n()).done;) {
              var br = _step3.value;
              var parent = br.parentNode;
              if (parent && parent.nodeName == "LI" && (!focusNode || blockParent(view, focusNode) != parent)) br.remove();
            }
          } catch (err) {
            _iterator3.e(err);
          } finally {
            _iterator3.f();
          }
        }
      }
      var readSel = null;
      if (from < 0 && newSel && view.input.lastFocus > Date.now() - 200 && Math.max(view.input.lastTouch, view.input.lastClick.time) < Date.now() - 300 && selectionCollapsed(sel) && (readSel = selectionFromDOM(view)) && readSel.eq(prosemirrorState.Selection.near(view.state.doc.resolve(0), 1))) {
        view.input.lastFocus = 0;
        selectionToDOM(view);
        this.currentSelection.set(sel);
        view.scrollToSelection();
      } else if (from > -1 || newSel) {
        if (from > -1) {
          view.docView.markDirty(from, to);
          checkCSS(view);
        }
        this.handleDOMChange(from, to, typeOver, added);
        if (view.docView && view.docView.dirty) view.updateState(view.state);else if (!this.currentSelection.eq(sel)) selectionToDOM(view);
        this.currentSelection.set(sel);
      }
    }
  }, {
    key: "registerMutation",
    value: function registerMutation(mut, added) {
      if (added.indexOf(mut.target) > -1) return null;
      var desc = this.view.docView.nearestDesc(mut.target);
      if (mut.type == "attributes" && (desc == this.view.docView || mut.attributeName == "contenteditable" || mut.attributeName == "style" && !mut.oldValue && !mut.target.getAttribute("style"))) return null;
      if (!desc || desc.ignoreMutation(mut)) return null;
      if (mut.type == "childList") {
        for (var i = 0; i < mut.addedNodes.length; i++) {
          var node = mut.addedNodes[i];
          added.push(node);
          if (node.nodeType == 3) this.lastChangedTextNode = node;
        }
        if (desc.contentDOM && desc.contentDOM != desc.dom && !desc.contentDOM.contains(mut.target)) return {
          from: desc.posBefore,
          to: desc.posAfter
        };
        var prev = mut.previousSibling,
          next = mut.nextSibling;
        if (ie && ie_version <= 11 && mut.addedNodes.length) {
          for (var _i14 = 0; _i14 < mut.addedNodes.length; _i14++) {
            var _mut$addedNodes$_i = mut.addedNodes[_i14],
              previousSibling = _mut$addedNodes$_i.previousSibling,
              nextSibling = _mut$addedNodes$_i.nextSibling;
            if (!previousSibling || Array.prototype.indexOf.call(mut.addedNodes, previousSibling) < 0) prev = previousSibling;
            if (!nextSibling || Array.prototype.indexOf.call(mut.addedNodes, nextSibling) < 0) next = nextSibling;
          }
        }
        var fromOffset = prev && prev.parentNode == mut.target ? domIndex(prev) + 1 : 0;
        var from = desc.localPosFromDOM(mut.target, fromOffset, -1);
        var toOffset = next && next.parentNode == mut.target ? domIndex(next) : mut.target.childNodes.length;
        var to = desc.localPosFromDOM(mut.target, toOffset, 1);
        return {
          from: from,
          to: to
        };
      } else if (mut.type == "attributes") {
        return {
          from: desc.posAtStart - desc.border,
          to: desc.posAtEnd + desc.border
        };
      } else {
        this.lastChangedTextNode = mut.target;
        return {
          from: desc.posAtStart,
          to: desc.posAtEnd,
          typeOver: mut.target.nodeValue == mut.oldValue
        };
      }
    }
  }]);
  return DOMObserver;
}();
var cssChecked = new WeakMap();
var cssCheckWarned = false;
function checkCSS(view) {
  if (cssChecked.has(view)) return;
  cssChecked.set(view, null);
  if (['normal', 'nowrap', 'pre-line'].indexOf(getComputedStyle(view.dom).whiteSpace) !== -1) {
    view.requiresGeckoHackNode = gecko;
    if (cssCheckWarned) return;
    console["warn"]("ProseMirror expects the CSS white-space property to be set, preferably to 'pre-wrap'. It is recommended to load style/prosemirror.css from the prosemirror-view package.");
    cssCheckWarned = true;
  }
}
function rangeToSelectionRange(view, range) {
  var anchorNode = range.startContainer,
    anchorOffset = range.startOffset;
  var focusNode = range.endContainer,
    focusOffset = range.endOffset;
  var currentAnchor = view.domAtPos(view.state.selection.anchor);
  if (isEquivalentPosition(currentAnchor.node, currentAnchor.offset, focusNode, focusOffset)) {
    var _ref3 = [focusNode, focusOffset, anchorNode, anchorOffset];
    anchorNode = _ref3[0];
    anchorOffset = _ref3[1];
    focusNode = _ref3[2];
    focusOffset = _ref3[3];
  }
  return {
    anchorNode: anchorNode,
    anchorOffset: anchorOffset,
    focusNode: focusNode,
    focusOffset: focusOffset
  };
}
function safariShadowSelectionRange(view, selection) {
  if (selection.getComposedRanges) {
    var range = selection.getComposedRanges(view.root)[0];
    if (range) return rangeToSelectionRange(view, range);
  }
  var found;
  function read(event) {
    event.preventDefault();
    event.stopImmediatePropagation();
    found = event.getTargetRanges()[0];
  }
  view.dom.addEventListener("beforeinput", read, true);
  document.execCommand("indent");
  view.dom.removeEventListener("beforeinput", read, true);
  return found ? rangeToSelectionRange(view, found) : null;
}
function blockParent(view, node) {
  for (var p = node.parentNode; p && p != view.dom; p = p.parentNode) {
    var desc = view.docView.nearestDesc(p, true);
    if (desc && desc.node.isBlock) return p;
  }
  return null;
}
function parseBetween(view, from_, to_) {
  var _view$docView$parseRa = view.docView.parseRange(from_, to_),
    parent = _view$docView$parseRa.node,
    fromOffset = _view$docView$parseRa.fromOffset,
    toOffset = _view$docView$parseRa.toOffset,
    from = _view$docView$parseRa.from,
    to = _view$docView$parseRa.to;
  var domSel = view.domSelectionRange();
  var find;
  var anchor = domSel.anchorNode;
  if (anchor && view.dom.contains(anchor.nodeType == 1 ? anchor : anchor.parentNode)) {
    find = [{
      node: anchor,
      offset: domSel.anchorOffset
    }];
    if (!selectionCollapsed(domSel)) find.push({
      node: domSel.focusNode,
      offset: domSel.focusOffset
    });
  }
  if (chrome && view.input.lastKeyCode === 8) {
    for (var off = toOffset; off > fromOffset; off--) {
      var node = parent.childNodes[off - 1],
        desc = node.pmViewDesc;
      if (node.nodeName == "BR" && !desc) {
        toOffset = off;
        break;
      }
      if (!desc || desc.size) break;
    }
  }
  var startDoc = view.state.doc;
  var parser = view.someProp("domParser") || prosemirrorModel.DOMParser.fromSchema(view.state.schema);
  var $from = startDoc.resolve(from);
  var sel = null,
    doc = parser.parse(parent, {
      topNode: $from.parent,
      topMatch: $from.parent.contentMatchAt($from.index()),
      topOpen: true,
      from: fromOffset,
      to: toOffset,
      preserveWhitespace: $from.parent.type.whitespace == "pre" ? "full" : true,
      findPositions: find,
      ruleFromNode: ruleFromNode,
      context: $from
    });
  if (find && find[0].pos != null) {
    var _anchor = find[0].pos,
      head = find[1] && find[1].pos;
    if (head == null) head = _anchor;
    sel = {
      anchor: _anchor + from,
      head: head + from
    };
  }
  return {
    doc: doc,
    sel: sel,
    from: from,
    to: to
  };
}
function ruleFromNode(dom) {
  var desc = dom.pmViewDesc;
  if (desc) {
    return desc.parseRule();
  } else if (dom.nodeName == "BR" && dom.parentNode) {
    if (safari && /^(ul|ol)$/i.test(dom.parentNode.nodeName)) {
      var skip = document.createElement("div");
      skip.appendChild(document.createElement("li"));
      return {
        skip: skip
      };
    } else if (dom.parentNode.lastChild == dom || safari && /^(tr|table)$/i.test(dom.parentNode.nodeName)) {
      return {
        ignore: true
      };
    }
  } else if (dom.nodeName == "IMG" && dom.getAttribute("mark-placeholder")) {
    return {
      ignore: true
    };
  }
  return null;
}
var isInline = /^(a|abbr|acronym|b|bd[io]|big|br|button|cite|code|data(list)?|del|dfn|em|i|ins|kbd|label|map|mark|meter|output|q|ruby|s|samp|small|span|strong|su[bp]|time|u|tt|var)$/i;
function readDOMChange(view, from, to, typeOver, addedNodes) {
  var compositionID = view.input.compositionPendingChanges || (view.composing ? view.input.compositionID : 0);
  view.input.compositionPendingChanges = 0;
  if (from < 0) {
    var origin = view.input.lastSelectionTime > Date.now() - 50 ? view.input.lastSelectionOrigin : null;
    var newSel = selectionFromDOM(view, origin);
    if (newSel && !view.state.selection.eq(newSel)) {
      if (chrome && android && view.input.lastKeyCode === 13 && Date.now() - 100 < view.input.lastKeyCodeTime && view.someProp("handleKeyDown", function (f) {
        return f(view, keyEvent(13, "Enter"));
      })) return;
      var _tr = view.state.tr.setSelection(newSel);
      if (origin == "pointer") _tr.setMeta("pointer", true);else if (origin == "key") _tr.scrollIntoView();
      if (compositionID) _tr.setMeta("composition", compositionID);
      view.dispatch(_tr);
    }
    return;
  }
  var $before = view.state.doc.resolve(from);
  var shared = $before.sharedDepth(to);
  from = $before.before(shared + 1);
  to = view.state.doc.resolve(to).after(shared + 1);
  var sel = view.state.selection;
  var parse = parseBetween(view, from, to);
  var doc = view.state.doc,
    compare = doc.slice(parse.from, parse.to);
  var preferredPos, preferredSide;
  if (view.input.lastKeyCode === 8 && Date.now() - 100 < view.input.lastKeyCodeTime) {
    preferredPos = view.state.selection.to;
    preferredSide = "end";
  } else {
    preferredPos = view.state.selection.from;
    preferredSide = "start";
  }
  view.input.lastKeyCode = null;
  var change = findDiff(compare.content, parse.doc.content, parse.from, preferredPos, preferredSide);
  if (change) view.input.domChangeCount++;
  if ((ios && view.input.lastIOSEnter > Date.now() - 225 || android) && addedNodes.some(function (n) {
    return n.nodeType == 1 && !isInline.test(n.nodeName);
  }) && (!change || change.endA >= change.endB) && view.someProp("handleKeyDown", function (f) {
    return f(view, keyEvent(13, "Enter"));
  })) {
    view.input.lastIOSEnter = 0;
    return;
  }
  if (!change) {
    if (typeOver && sel instanceof prosemirrorState.TextSelection && !sel.empty && sel.$head.sameParent(sel.$anchor) && !view.composing && !(parse.sel && parse.sel.anchor != parse.sel.head)) {
      change = {
        start: sel.from,
        endA: sel.to,
        endB: sel.to
      };
    } else {
      if (parse.sel) {
        var _sel2 = resolveSelection(view, view.state.doc, parse.sel);
        if (_sel2 && !_sel2.eq(view.state.selection)) {
          var _tr2 = view.state.tr.setSelection(_sel2);
          if (compositionID) _tr2.setMeta("composition", compositionID);
          view.dispatch(_tr2);
        }
      }
      return;
    }
  }
  if (view.state.selection.from < view.state.selection.to && change.start == change.endB && view.state.selection instanceof prosemirrorState.TextSelection) {
    if (change.start > view.state.selection.from && change.start <= view.state.selection.from + 2 && view.state.selection.from >= parse.from) {
      change.start = view.state.selection.from;
    } else if (change.endA < view.state.selection.to && change.endA >= view.state.selection.to - 2 && view.state.selection.to <= parse.to) {
      change.endB += view.state.selection.to - change.endA;
      change.endA = view.state.selection.to;
    }
  }
  if (ie && ie_version <= 11 && change.endB == change.start + 1 && change.endA == change.start && change.start > parse.from && parse.doc.textBetween(change.start - parse.from - 1, change.start - parse.from + 1) == " \xA0") {
    change.start--;
    change.endA--;
    change.endB--;
  }
  var $from = parse.doc.resolveNoCache(change.start - parse.from);
  var $to = parse.doc.resolveNoCache(change.endB - parse.from);
  var $fromA = doc.resolve(change.start);
  var inlineChange = $from.sameParent($to) && $from.parent.inlineContent && $fromA.end() >= change.endA;
  var nextSel;
  if ((ios && view.input.lastIOSEnter > Date.now() - 225 && (!inlineChange || addedNodes.some(function (n) {
    return n.nodeName == "DIV" || n.nodeName == "P";
  })) || !inlineChange && $from.pos < parse.doc.content.size && !$from.sameParent($to) && (nextSel = prosemirrorState.Selection.findFrom(parse.doc.resolve($from.pos + 1), 1, true)) && nextSel.head == $to.pos) && view.someProp("handleKeyDown", function (f) {
    return f(view, keyEvent(13, "Enter"));
  })) {
    view.input.lastIOSEnter = 0;
    return;
  }
  if (view.state.selection.anchor > change.start && looksLikeBackspace(doc, change.start, change.endA, $from, $to) && view.someProp("handleKeyDown", function (f) {
    return f(view, keyEvent(8, "Backspace"));
  })) {
    if (android && chrome) view.domObserver.suppressSelectionUpdates();
    return;
  }
  if (chrome && android && change.endB == change.start) view.input.lastAndroidDelete = Date.now();
  if (android && !inlineChange && $from.start() != $to.start() && $to.parentOffset == 0 && $from.depth == $to.depth && parse.sel && parse.sel.anchor == parse.sel.head && parse.sel.head == change.endA) {
    change.endB -= 2;
    $to = parse.doc.resolveNoCache(change.endB - parse.from);
    setTimeout(function () {
      view.someProp("handleKeyDown", function (f) {
        return f(view, keyEvent(13, "Enter"));
      });
    }, 20);
  }
  var chFrom = change.start,
    chTo = change.endA;
  var tr, storedMarks, markChange;
  if (inlineChange) {
    if ($from.pos == $to.pos) {
      if (ie && ie_version <= 11 && $from.parentOffset == 0) {
        view.domObserver.suppressSelectionUpdates();
        setTimeout(function () {
          return selectionToDOM(view);
        }, 20);
      }
      tr = view.state.tr["delete"](chFrom, chTo);
      storedMarks = doc.resolve(change.start).marksAcross(doc.resolve(change.endA));
    } else if (change.endA == change.endB && (markChange = isMarkChange($from.parent.content.cut($from.parentOffset, $to.parentOffset), $fromA.parent.content.cut($fromA.parentOffset, change.endA - $fromA.start())))) {
      tr = view.state.tr;
      if (markChange.type == "add") tr.addMark(chFrom, chTo, markChange.mark);else tr.removeMark(chFrom, chTo, markChange.mark);
    } else if ($from.parent.child($from.index()).isText && $from.index() == $to.index() - ($to.textOffset ? 0 : 1)) {
      var text = $from.parent.textBetween($from.parentOffset, $to.parentOffset);
      if (view.someProp("handleTextInput", function (f) {
        return f(view, chFrom, chTo, text);
      })) return;
      tr = view.state.tr.insertText(text, chFrom, chTo);
    }
  }
  if (!tr) tr = view.state.tr.replace(chFrom, chTo, parse.doc.slice(change.start - parse.from, change.endB - parse.from));
  if (parse.sel) {
    var _sel3 = resolveSelection(view, tr.doc, parse.sel);
    if (_sel3 && !(chrome && android && view.composing && _sel3.empty && (change.start != change.endB || view.input.lastAndroidDelete < Date.now() - 100) && (_sel3.head == chFrom || _sel3.head == tr.mapping.map(chTo) - 1) || ie && _sel3.empty && _sel3.head == chFrom)) tr.setSelection(_sel3);
  }
  if (storedMarks) tr.ensureMarks(storedMarks);
  if (compositionID) tr.setMeta("composition", compositionID);
  view.dispatch(tr.scrollIntoView());
}
function resolveSelection(view, doc, parsedSel) {
  if (Math.max(parsedSel.anchor, parsedSel.head) > doc.content.size) return null;
  return selectionBetween(view, doc.resolve(parsedSel.anchor), doc.resolve(parsedSel.head));
}
function isMarkChange(cur, prev) {
  var curMarks = cur.firstChild.marks,
    prevMarks = prev.firstChild.marks;
  var added = curMarks,
    removed = prevMarks,
    type,
    mark,
    update;
  for (var i = 0; i < prevMarks.length; i++) added = prevMarks[i].removeFromSet(added);
  for (var _i15 = 0; _i15 < curMarks.length; _i15++) removed = curMarks[_i15].removeFromSet(removed);
  if (added.length == 1 && removed.length == 0) {
    mark = added[0];
    type = "add";
    update = function update(node) {
      return node.mark(mark.addToSet(node.marks));
    };
  } else if (added.length == 0 && removed.length == 1) {
    mark = removed[0];
    type = "remove";
    update = function update(node) {
      return node.mark(mark.removeFromSet(node.marks));
    };
  } else {
    return null;
  }
  var updated = [];
  for (var _i16 = 0; _i16 < prev.childCount; _i16++) updated.push(update(prev.child(_i16)));
  if (prosemirrorModel.Fragment.from(updated).eq(cur)) return {
    mark: mark,
    type: type
  };
}
function looksLikeBackspace(old, start, end, $newStart, $newEnd) {
  if (end - start <= $newEnd.pos - $newStart.pos || skipClosingAndOpening($newStart, true, false) < $newEnd.pos) return false;
  var $start = old.resolve(start);
  if (!$newStart.parent.isTextblock) {
    var after = $start.nodeAfter;
    return after != null && end == start + after.nodeSize;
  }
  if ($start.parentOffset < $start.parent.content.size || !$start.parent.isTextblock) return false;
  var $next = old.resolve(skipClosingAndOpening($start, true, true));
  if (!$next.parent.isTextblock || $next.pos > end || skipClosingAndOpening($next, true, false) < end) return false;
  return $newStart.parent.content.cut($newStart.parentOffset).eq($next.parent.content);
}
function skipClosingAndOpening($pos, fromEnd, mayOpen) {
  var depth = $pos.depth,
    end = fromEnd ? $pos.end() : $pos.pos;
  while (depth > 0 && (fromEnd || $pos.indexAfter(depth) == $pos.node(depth).childCount)) {
    depth--;
    end++;
    fromEnd = false;
  }
  if (mayOpen) {
    var next = $pos.node(depth).maybeChild($pos.indexAfter(depth));
    while (next && !next.isLeaf) {
      next = next.firstChild;
      end++;
    }
  }
  return end;
}
function findDiff(a, b, pos, preferredPos, preferredSide) {
  var start = a.findDiffStart(b, pos);
  if (start == null) return null;
  var _a$findDiffEnd = a.findDiffEnd(b, pos + a.size, pos + b.size),
    endA = _a$findDiffEnd.a,
    endB = _a$findDiffEnd.b;
  if (preferredSide == "end") {
    var adjust = Math.max(0, start - Math.min(endA, endB));
    preferredPos -= endA + adjust - start;
  }
  if (endA < start && a.size < b.size) {
    var move = preferredPos <= start && preferredPos >= endA ? start - preferredPos : 0;
    start -= move;
    if (start && start < b.size && isSurrogatePair(b.textBetween(start - 1, start + 1))) start += move ? 1 : -1;
    endB = start + (endB - endA);
    endA = start;
  } else if (endB < start) {
    var _move = preferredPos <= start && preferredPos >= endB ? start - preferredPos : 0;
    start -= _move;
    if (start && start < a.size && isSurrogatePair(a.textBetween(start - 1, start + 1))) start += _move ? 1 : -1;
    endA = start + (endA - endB);
    endB = start;
  }
  return {
    start: start,
    endA: endA,
    endB: endB
  };
}
function isSurrogatePair(str) {
  if (str.length != 2) return false;
  var a = str.charCodeAt(0),
    b = str.charCodeAt(1);
  return a >= 0xDC00 && a <= 0xDFFF && b >= 0xD800 && b <= 0xDBFF;
}
var __serializeForClipboard = serializeForClipboard;
var __parseFromClipboard = parseFromClipboard;
var __endComposition = endComposition;
var EditorView = function () {
  function EditorView(place, props) {
    var _this15 = this;
    _classCallCheck(this, EditorView);
    this._root = null;
    this.focused = false;
    this.trackWrites = null;
    this.mounted = false;
    this.markCursor = null;
    this.cursorWrapper = null;
    this.lastSelectedViewDesc = undefined;
    this.input = new InputState();
    this.prevDirectPlugins = [];
    this.pluginViews = [];
    this.requiresGeckoHackNode = false;
    this.dragging = null;
    this._props = props;
    this.state = props.state;
    this.directPlugins = props.plugins || [];
    this.directPlugins.forEach(checkStateComponent);
    this.dispatch = this.dispatch.bind(this);
    this.dom = place && place.mount || document.createElement("div");
    if (place) {
      if (place.appendChild) place.appendChild(this.dom);else if (typeof place == "function") place(this.dom);else if (place.mount) this.mounted = true;
    }
    this.editable = getEditable(this);
    updateCursorWrapper(this);
    this.nodeViews = buildNodeViews(this);
    this.docView = docViewDesc(this.state.doc, computeDocDeco(this), viewDecorations(this), this.dom, this);
    this.domObserver = new DOMObserver(this, function (from, to, typeOver, added) {
      return readDOMChange(_this15, from, to, typeOver, added);
    });
    this.domObserver.start();
    initInput(this);
    this.updatePluginViews();
  }
  _createClass(EditorView, [{
    key: "composing",
    get: function get() {
      return this.input.composing;
    }
  }, {
    key: "props",
    get: function get() {
      if (this._props.state != this.state) {
        var prev = this._props;
        this._props = {};
        for (var name in prev) this._props[name] = prev[name];
        this._props.state = this.state;
      }
      return this._props;
    }
  }, {
    key: "update",
    value: function update(props) {
      if (props.handleDOMEvents != this._props.handleDOMEvents) ensureListeners(this);
      var prevProps = this._props;
      this._props = props;
      if (props.plugins) {
        props.plugins.forEach(checkStateComponent);
        this.directPlugins = props.plugins;
      }
      this.updateStateInner(props.state, prevProps);
    }
  }, {
    key: "setProps",
    value: function setProps(props) {
      var updated = {};
      for (var name in this._props) updated[name] = this._props[name];
      updated.state = this.state;
      for (var _name2 in props) updated[_name2] = props[_name2];
      this.update(updated);
    }
  }, {
    key: "updateState",
    value: function updateState(state) {
      this.updateStateInner(state, this._props);
    }
  }, {
    key: "updateStateInner",
    value: function updateStateInner(state, prevProps) {
      var _a;
      var prev = this.state,
        redraw = false,
        updateSel = false;
      if (state.storedMarks && this.composing) {
        clearComposition(this);
        updateSel = true;
      }
      this.state = state;
      var pluginsChanged = prev.plugins != state.plugins || this._props.plugins != prevProps.plugins;
      if (pluginsChanged || this._props.plugins != prevProps.plugins || this._props.nodeViews != prevProps.nodeViews) {
        var nodeViews = buildNodeViews(this);
        if (changedNodeViews(nodeViews, this.nodeViews)) {
          this.nodeViews = nodeViews;
          redraw = true;
        }
      }
      if (pluginsChanged || prevProps.handleDOMEvents != this._props.handleDOMEvents) {
        ensureListeners(this);
      }
      this.editable = getEditable(this);
      updateCursorWrapper(this);
      var innerDeco = viewDecorations(this),
        outerDeco = computeDocDeco(this);
      var scroll = prev.plugins != state.plugins && !prev.doc.eq(state.doc) ? "reset" : state.scrollToSelection > prev.scrollToSelection ? "to selection" : "preserve";
      var updateDoc = redraw || !this.docView.matchesNode(state.doc, outerDeco, innerDeco);
      if (updateDoc || !state.selection.eq(prev.selection)) updateSel = true;
      var oldScrollPos = scroll == "preserve" && updateSel && this.dom.style.overflowAnchor == null && storeScrollPos(this);
      if (updateSel) {
        this.domObserver.stop();
        var forceSelUpdate = updateDoc && (ie || chrome) && !this.composing && !prev.selection.empty && !state.selection.empty && selectionContextChanged(prev.selection, state.selection);
        if (updateDoc) {
          var chromeKludge = chrome ? this.trackWrites = this.domSelectionRange().focusNode : null;
          if (this.composing) this.input.compositionNode = findCompositionNode(this);
          if (redraw || !this.docView.update(state.doc, outerDeco, innerDeco, this)) {
            this.docView.updateOuterDeco(outerDeco);
            this.docView.destroy();
            this.docView = docViewDesc(state.doc, outerDeco, innerDeco, this.dom, this);
          }
          if (chromeKludge && !this.trackWrites) forceSelUpdate = true;
        }
        if (forceSelUpdate || !(this.input.mouseDown && this.domObserver.currentSelection.eq(this.domSelectionRange()) && anchorInRightPlace(this))) {
          selectionToDOM(this, forceSelUpdate);
        } else {
          syncNodeSelection(this, state.selection);
          this.domObserver.setCurSelection();
        }
        this.domObserver.start();
      }
      this.updatePluginViews(prev);
      if (((_a = this.dragging) === null || _a === void 0 ? void 0 : _a.node) && !prev.doc.eq(state.doc)) this.updateDraggedNode(this.dragging, prev);
      if (scroll == "reset") {
        this.dom.scrollTop = 0;
      } else if (scroll == "to selection") {
        this.scrollToSelection();
      } else if (oldScrollPos) {
        resetScrollPos(oldScrollPos);
      }
    }
  }, {
    key: "scrollToSelection",
    value: function scrollToSelection() {
      var _this16 = this;
      var startDOM = this.domSelectionRange().focusNode;
      if (this.someProp("handleScrollToSelection", function (f) {
        return f(_this16);
      })) ;else if (this.state.selection instanceof prosemirrorState.NodeSelection) {
        var target = this.docView.domAfterPos(this.state.selection.from);
        if (target.nodeType == 1) scrollRectIntoView(this, target.getBoundingClientRect(), startDOM);
      } else {
        scrollRectIntoView(this, this.coordsAtPos(this.state.selection.head, 1), startDOM);
      }
    }
  }, {
    key: "destroyPluginViews",
    value: function destroyPluginViews() {
      var view;
      while (view = this.pluginViews.pop()) if (view.destroy) view.destroy();
    }
  }, {
    key: "updatePluginViews",
    value: function updatePluginViews(prevState) {
      if (!prevState || prevState.plugins != this.state.plugins || this.directPlugins != this.prevDirectPlugins) {
        this.prevDirectPlugins = this.directPlugins;
        this.destroyPluginViews();
        for (var i = 0; i < this.directPlugins.length; i++) {
          var plugin = this.directPlugins[i];
          if (plugin.spec.view) this.pluginViews.push(plugin.spec.view(this));
        }
        for (var _i17 = 0; _i17 < this.state.plugins.length; _i17++) {
          var _plugin = this.state.plugins[_i17];
          if (_plugin.spec.view) this.pluginViews.push(_plugin.spec.view(this));
        }
      } else {
        for (var _i18 = 0; _i18 < this.pluginViews.length; _i18++) {
          var pluginView = this.pluginViews[_i18];
          if (pluginView.update) pluginView.update(this, prevState);
        }
      }
    }
  }, {
    key: "updateDraggedNode",
    value: function updateDraggedNode(dragging, prev) {
      var sel = dragging.node,
        found = -1;
      if (this.state.doc.nodeAt(sel.from) == sel.node) {
        found = sel.from;
      } else {
        var movedPos = sel.from + (this.state.doc.content.size - prev.doc.content.size);
        var moved = movedPos > 0 && this.state.doc.nodeAt(movedPos);
        if (moved == sel.node) found = movedPos;
      }
      this.dragging = new Dragging(dragging.slice, dragging.move, found < 0 ? undefined : prosemirrorState.NodeSelection.create(this.state.doc, found));
    }
  }, {
    key: "someProp",
    value: function someProp(propName, f) {
      var prop = this._props && this._props[propName],
        value;
      if (prop != null && (value = f ? f(prop) : prop)) return value;
      for (var i = 0; i < this.directPlugins.length; i++) {
        var _prop = this.directPlugins[i].props[propName];
        if (_prop != null && (value = f ? f(_prop) : _prop)) return value;
      }
      var plugins = this.state.plugins;
      if (plugins) for (var _i19 = 0; _i19 < plugins.length; _i19++) {
        var _prop2 = plugins[_i19].props[propName];
        if (_prop2 != null && (value = f ? f(_prop2) : _prop2)) return value;
      }
    }
  }, {
    key: "hasFocus",
    value: function hasFocus() {
      if (ie) {
        var node = this.root.activeElement;
        if (node == this.dom) return true;
        if (!node || !this.dom.contains(node)) return false;
        while (node && this.dom != node && this.dom.contains(node)) {
          if (node.contentEditable == 'false') return false;
          node = node.parentElement;
        }
        return true;
      }
      return this.root.activeElement == this.dom;
    }
  }, {
    key: "focus",
    value: function focus() {
      this.domObserver.stop();
      if (this.editable) focusPreventScroll(this.dom);
      selectionToDOM(this);
      this.domObserver.start();
    }
  }, {
    key: "root",
    get: function get() {
      var _this17 = this;
      var cached = this._root;
      if (cached == null) {
        var _loop5 = function _loop5(search) {
            if (search.nodeType == 9 || search.nodeType == 11 && search.host) {
              if (!search.getSelection) Object.getPrototypeOf(search).getSelection = function () {
                return search.ownerDocument.getSelection();
              };
              return {
                v: _this17._root = search
              };
            }
          },
          _ret3;
        for (var search = this.dom.parentNode; search; search = search.parentNode) {
          _ret3 = _loop5(search);
          if (_ret3) return _ret3.v;
        }
      }
      return cached || document;
    }
  }, {
    key: "updateRoot",
    value: function updateRoot() {
      this._root = null;
    }
  }, {
    key: "posAtCoords",
    value: function posAtCoords(coords) {
      return _posAtCoords(this, coords);
    }
  }, {
    key: "coordsAtPos",
    value: function coordsAtPos(pos) {
      var side = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;
      return _coordsAtPos(this, pos, side);
    }
  }, {
    key: "domAtPos",
    value: function domAtPos(pos) {
      var side = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
      return this.docView.domFromPos(pos, side);
    }
  }, {
    key: "nodeDOM",
    value: function nodeDOM(pos) {
      var desc = this.docView.descAt(pos);
      return desc ? desc.nodeDOM : null;
    }
  }, {
    key: "posAtDOM",
    value: function posAtDOM(node, offset) {
      var bias = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : -1;
      var pos = this.docView.posFromDOM(node, offset, bias);
      if (pos == null) throw new RangeError("DOM position not inside the editor");
      return pos;
    }
  }, {
    key: "endOfTextblock",
    value: function endOfTextblock(dir, state) {
      return _endOfTextblock(this, state || this.state, dir);
    }
  }, {
    key: "pasteHTML",
    value: function pasteHTML(html, event) {
      return doPaste(this, "", html, false, event || new ClipboardEvent("paste"));
    }
  }, {
    key: "pasteText",
    value: function pasteText(text, event) {
      return doPaste(this, text, null, true, event || new ClipboardEvent("paste"));
    }
  }, {
    key: "destroy",
    value: function destroy() {
      if (!this.docView) return;
      destroyInput(this);
      this.destroyPluginViews();
      if (this.mounted) {
        this.docView.update(this.state.doc, [], viewDecorations(this), this);
        this.dom.textContent = "";
      } else if (this.dom.parentNode) {
        this.dom.parentNode.removeChild(this.dom);
      }
      this.docView.destroy();
      this.docView = null;
      clearReusedRange();
    }
  }, {
    key: "isDestroyed",
    get: function get() {
      return this.docView == null;
    }
  }, {
    key: "dispatchEvent",
    value: function dispatchEvent(event) {
      return _dispatchEvent(this, event);
    }
  }, {
    key: "dispatch",
    value: function dispatch(tr) {
      var dispatchTransaction = this._props.dispatchTransaction;
      if (dispatchTransaction) dispatchTransaction.call(this, tr);else this.updateState(this.state.apply(tr));
    }
  }, {
    key: "domSelectionRange",
    value: function domSelectionRange() {
      var sel = this.domSelection();
      if (!sel) return {
        focusNode: null,
        focusOffset: 0,
        anchorNode: null,
        anchorOffset: 0
      };
      return safari && this.root.nodeType === 11 && deepActiveElement(this.dom.ownerDocument) == this.dom && safariShadowSelectionRange(this, sel) || sel;
    }
  }, {
    key: "domSelection",
    value: function domSelection() {
      return this.root.getSelection();
    }
  }]);
  return EditorView;
}();
function computeDocDeco(view) {
  var attrs = Object.create(null);
  attrs["class"] = "ProseMirror";
  attrs.contenteditable = String(view.editable);
  view.someProp("attributes", function (value) {
    if (typeof value == "function") value = value(view.state);
    if (value) for (var attr in value) {
      if (attr == "class") attrs["class"] += " " + value[attr];else if (attr == "style") attrs.style = (attrs.style ? attrs.style + ";" : "") + value[attr];else if (!attrs[attr] && attr != "contenteditable" && attr != "nodeName") attrs[attr] = String(value[attr]);
    }
  });
  if (!attrs.translate) attrs.translate = "no";
  return [Decoration.node(0, view.state.doc.content.size, attrs)];
}
function updateCursorWrapper(view) {
  if (view.markCursor) {
    var dom = document.createElement("img");
    dom.className = "ProseMirror-separator";
    dom.setAttribute("mark-placeholder", "true");
    dom.setAttribute("alt", "");
    view.cursorWrapper = {
      dom: dom,
      deco: Decoration.widget(view.state.selection.from, dom, {
        raw: true,
        marks: view.markCursor
      })
    };
  } else {
    view.cursorWrapper = null;
  }
}
function getEditable(view) {
  return !view.someProp("editable", function (value) {
    return value(view.state) === false;
  });
}
function selectionContextChanged(sel1, sel2) {
  var depth = Math.min(sel1.$anchor.sharedDepth(sel1.head), sel2.$anchor.sharedDepth(sel2.head));
  return sel1.$anchor.start(depth) != sel2.$anchor.start(depth);
}
function buildNodeViews(view) {
  var result = Object.create(null);
  function add(obj) {
    for (var _prop3 in obj) if (!Object.prototype.hasOwnProperty.call(result, _prop3)) result[_prop3] = obj[_prop3];
  }
  view.someProp("nodeViews", add);
  view.someProp("markViews", add);
  return result;
}
function changedNodeViews(a, b) {
  var nA = 0,
    nB = 0;
  for (var _prop4 in a) {
    if (a[_prop4] != b[_prop4]) return true;
    nA++;
  }
  for (var _ in b) nB++;
  return nA != nB;
}
function checkStateComponent(plugin) {
  if (plugin.spec.state || plugin.spec.filterTransaction || plugin.spec.appendTransaction) throw new RangeError("Plugins passed directly to the view must not have a state component");
}
exports.Decoration = Decoration;
exports.DecorationSet = DecorationSet;
exports.EditorView = EditorView;
exports.__endComposition = __endComposition;
exports.__parseFromClipboard = __parseFromClipboard;
exports.__serializeForClipboard = __serializeForClipboard;
