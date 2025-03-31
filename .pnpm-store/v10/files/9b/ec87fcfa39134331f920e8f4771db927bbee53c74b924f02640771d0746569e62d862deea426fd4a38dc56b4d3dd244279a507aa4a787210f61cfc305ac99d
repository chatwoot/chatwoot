'use strict';

var prosemirrorTransform = require('prosemirror-transform');
var prosemirrorModel = require('prosemirror-model');
var prosemirrorState = require('prosemirror-state');
var olDOM = ["ol", 0],
  ulDOM = ["ul", 0],
  liDOM = ["li", 0];
var orderedList = {
  attrs: {
    order: {
      "default": 1,
      validate: "number"
    }
  },
  parseDOM: [{
    tag: "ol",
    getAttrs: function getAttrs(dom) {
      return {
        order: dom.hasAttribute("start") ? +dom.getAttribute("start") : 1
      };
    }
  }],
  toDOM: function toDOM(node) {
    return node.attrs.order == 1 ? olDOM : ["ol", {
      start: node.attrs.order
    }, 0];
  }
};
var bulletList = {
  parseDOM: [{
    tag: "ul"
  }],
  toDOM: function toDOM() {
    return ulDOM;
  }
};
var listItem = {
  parseDOM: [{
    tag: "li"
  }],
  toDOM: function toDOM() {
    return liDOM;
  },
  defining: true
};
function add(obj, props) {
  var copy = {};
  for (var prop in obj) copy[prop] = obj[prop];
  for (var _prop in props) copy[_prop] = props[_prop];
  return copy;
}
function addListNodes(nodes, itemContent, listGroup) {
  return nodes.append({
    ordered_list: add(orderedList, {
      content: "list_item+",
      group: listGroup
    }),
    bullet_list: add(bulletList, {
      content: "list_item+",
      group: listGroup
    }),
    list_item: add(listItem, {
      content: itemContent
    })
  });
}
function wrapInList(listType) {
  var attrs = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
  return function (state, dispatch) {
    var _state$selection = state.selection,
      $from = _state$selection.$from,
      $to = _state$selection.$to;
    var range = $from.blockRange($to),
      doJoin = false,
      outerRange = range;
    if (!range) return false;
    if (range.depth >= 2 && $from.node(range.depth - 1).type.compatibleContent(listType) && range.startIndex == 0) {
      if ($from.index(range.depth - 1) == 0) return false;
      var $insert = state.doc.resolve(range.start - 2);
      outerRange = new prosemirrorModel.NodeRange($insert, $insert, range.depth);
      if (range.endIndex < range.parent.childCount) range = new prosemirrorModel.NodeRange($from, state.doc.resolve($to.end(range.depth)), range.depth);
      doJoin = true;
    }
    var wrap = prosemirrorTransform.findWrapping(outerRange, listType, attrs, range);
    if (!wrap) return false;
    if (dispatch) dispatch(doWrapInList(state.tr, range, wrap, doJoin, listType).scrollIntoView());
    return true;
  };
}
function doWrapInList(tr, range, wrappers, joinBefore, listType) {
  var content = prosemirrorModel.Fragment.empty;
  for (var i = wrappers.length - 1; i >= 0; i--) content = prosemirrorModel.Fragment.from(wrappers[i].type.create(wrappers[i].attrs, content));
  tr.step(new prosemirrorTransform.ReplaceAroundStep(range.start - (joinBefore ? 2 : 0), range.end, range.start, range.end, new prosemirrorModel.Slice(content, 0, 0), wrappers.length, true));
  var found = 0;
  for (var _i = 0; _i < wrappers.length; _i++) if (wrappers[_i].type == listType) found = _i + 1;
  var splitDepth = wrappers.length - found;
  var splitPos = range.start + wrappers.length - (joinBefore ? 2 : 0),
    parent = range.parent;
  for (var _i2 = range.startIndex, e = range.endIndex, first = true; _i2 < e; _i2++, first = false) {
    if (!first && prosemirrorTransform.canSplit(tr.doc, splitPos, splitDepth)) {
      tr.split(splitPos, splitDepth);
      splitPos += 2 * splitDepth;
    }
    splitPos += parent.child(_i2).nodeSize;
  }
  return tr;
}
function splitListItem(itemType, itemAttrs) {
  return function (state, dispatch) {
    var _state$selection2 = state.selection,
      $from = _state$selection2.$from,
      $to = _state$selection2.$to,
      node = _state$selection2.node;
    if (node && node.isBlock || $from.depth < 2 || !$from.sameParent($to)) return false;
    var grandParent = $from.node(-1);
    if (grandParent.type != itemType) return false;
    if ($from.parent.content.size == 0 && $from.node(-1).childCount == $from.indexAfter(-1)) {
      if ($from.depth == 3 || $from.node(-3).type != itemType || $from.index(-2) != $from.node(-2).childCount - 1) return false;
      if (dispatch) {
        var wrap = prosemirrorModel.Fragment.empty;
        var depthBefore = $from.index(-1) ? 1 : $from.index(-2) ? 2 : 3;
        for (var d = $from.depth - depthBefore; d >= $from.depth - 3; d--) wrap = prosemirrorModel.Fragment.from($from.node(d).copy(wrap));
        var depthAfter = $from.indexAfter(-1) < $from.node(-2).childCount ? 1 : $from.indexAfter(-2) < $from.node(-3).childCount ? 2 : 3;
        wrap = wrap.append(prosemirrorModel.Fragment.from(itemType.createAndFill()));
        var start = $from.before($from.depth - (depthBefore - 1));
        var _tr = state.tr.replace(start, $from.after(-depthAfter), new prosemirrorModel.Slice(wrap, 4 - depthBefore, 0));
        var sel = -1;
        _tr.doc.nodesBetween(start, _tr.doc.content.size, function (node, pos) {
          if (sel > -1) return false;
          if (node.isTextblock && node.content.size == 0) sel = pos + 1;
        });
        if (sel > -1) _tr.setSelection(prosemirrorState.Selection.near(_tr.doc.resolve(sel)));
        dispatch(_tr.scrollIntoView());
      }
      return true;
    }
    var nextType = $to.pos == $from.end() ? grandParent.contentMatchAt(0).defaultType : null;
    var tr = state.tr["delete"]($from.pos, $to.pos);
    var types = nextType ? [itemAttrs ? {
      type: itemType,
      attrs: itemAttrs
    } : null, {
      type: nextType
    }] : undefined;
    if (!prosemirrorTransform.canSplit(tr.doc, $from.pos, 2, types)) return false;
    if (dispatch) dispatch(tr.split($from.pos, 2, types).scrollIntoView());
    return true;
  };
}
function splitListItemKeepMarks(itemType, itemAttrs) {
  var split = splitListItem(itemType, itemAttrs);
  return function (state, dispatch) {
    return split(state, dispatch && function (tr) {
      var marks = state.storedMarks || state.selection.$to.parentOffset && state.selection.$from.marks();
      if (marks) tr.ensureMarks(marks);
      dispatch(tr);
    });
  };
}
function liftListItem(itemType) {
  return function (state, dispatch) {
    var _state$selection3 = state.selection,
      $from = _state$selection3.$from,
      $to = _state$selection3.$to;
    var range = $from.blockRange($to, function (node) {
      return node.childCount > 0 && node.firstChild.type == itemType;
    });
    if (!range) return false;
    if (!dispatch) return true;
    if ($from.node(range.depth - 1).type == itemType) return liftToOuterList(state, dispatch, itemType, range);else return liftOutOfList(state, dispatch, range);
  };
}
function liftToOuterList(state, dispatch, itemType, range) {
  var tr = state.tr,
    end = range.end,
    endOfList = range.$to.end(range.depth);
  if (end < endOfList) {
    tr.step(new prosemirrorTransform.ReplaceAroundStep(end - 1, endOfList, end, endOfList, new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(itemType.create(null, range.parent.copy())), 1, 0), 1, true));
    range = new prosemirrorModel.NodeRange(tr.doc.resolve(range.$from.pos), tr.doc.resolve(endOfList), range.depth);
  }
  var target = prosemirrorTransform.liftTarget(range);
  if (target == null) return false;
  tr.lift(range, target);
  var after = tr.mapping.map(end, -1) - 1;
  if (prosemirrorTransform.canJoin(tr.doc, after)) tr.join(after);
  dispatch(tr.scrollIntoView());
  return true;
}
function liftOutOfList(state, dispatch, range) {
  var tr = state.tr,
    list = range.parent;
  for (var pos = range.end, i = range.endIndex - 1, e = range.startIndex; i > e; i--) {
    pos -= list.child(i).nodeSize;
    tr["delete"](pos - 1, pos + 1);
  }
  var $start = tr.doc.resolve(range.start),
    item = $start.nodeAfter;
  if (tr.mapping.map(range.end) != range.start + $start.nodeAfter.nodeSize) return false;
  var atStart = range.startIndex == 0,
    atEnd = range.endIndex == list.childCount;
  var parent = $start.node(-1),
    indexBefore = $start.index(-1);
  if (!parent.canReplace(indexBefore + (atStart ? 0 : 1), indexBefore + 1, item.content.append(atEnd ? prosemirrorModel.Fragment.empty : prosemirrorModel.Fragment.from(list)))) return false;
  var start = $start.pos,
    end = start + item.nodeSize;
  tr.step(new prosemirrorTransform.ReplaceAroundStep(start - (atStart ? 1 : 0), end + (atEnd ? 1 : 0), start + 1, end - 1, new prosemirrorModel.Slice((atStart ? prosemirrorModel.Fragment.empty : prosemirrorModel.Fragment.from(list.copy(prosemirrorModel.Fragment.empty))).append(atEnd ? prosemirrorModel.Fragment.empty : prosemirrorModel.Fragment.from(list.copy(prosemirrorModel.Fragment.empty))), atStart ? 0 : 1, atEnd ? 0 : 1), atStart ? 0 : 1));
  dispatch(tr.scrollIntoView());
  return true;
}
function sinkListItem(itemType) {
  return function (state, dispatch) {
    var _state$selection4 = state.selection,
      $from = _state$selection4.$from,
      $to = _state$selection4.$to;
    var range = $from.blockRange($to, function (node) {
      return node.childCount > 0 && node.firstChild.type == itemType;
    });
    if (!range) return false;
    var startIndex = range.startIndex;
    if (startIndex == 0) return false;
    var parent = range.parent,
      nodeBefore = parent.child(startIndex - 1);
    if (nodeBefore.type != itemType) return false;
    if (dispatch) {
      var nestedBefore = nodeBefore.lastChild && nodeBefore.lastChild.type == parent.type;
      var inner = prosemirrorModel.Fragment.from(nestedBefore ? itemType.create() : null);
      var slice = new prosemirrorModel.Slice(prosemirrorModel.Fragment.from(itemType.create(null, prosemirrorModel.Fragment.from(parent.type.create(null, inner)))), nestedBefore ? 3 : 1, 0);
      var before = range.start,
        after = range.end;
      dispatch(state.tr.step(new prosemirrorTransform.ReplaceAroundStep(before - (nestedBefore ? 3 : 1), after, before, after, slice, 1, true)).scrollIntoView());
    }
    return true;
  };
}
exports.addListNodes = addListNodes;
exports.bulletList = bulletList;
exports.liftListItem = liftListItem;
exports.listItem = listItem;
exports.orderedList = orderedList;
exports.sinkListItem = sinkListItem;
exports.splitListItem = splitListItem;
exports.splitListItemKeepMarks = splitListItemKeepMarks;
exports.wrapInList = wrapInList;
