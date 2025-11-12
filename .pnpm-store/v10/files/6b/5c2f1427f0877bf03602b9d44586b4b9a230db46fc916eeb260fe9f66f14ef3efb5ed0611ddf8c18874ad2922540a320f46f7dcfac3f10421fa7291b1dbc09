'use strict';

var prosemirrorTransform = require('prosemirror-transform');
var prosemirrorModel = require('prosemirror-model');
var prosemirrorState = require('prosemirror-state');
var deleteSelection = function deleteSelection(state, dispatch) {
  if (state.selection.empty) return false;
  if (dispatch) dispatch(state.tr.deleteSelection().scrollIntoView());
  return true;
};
function atBlockStart(state, view) {
  var $cursor = state.selection.$cursor;
  if (!$cursor || (view ? !view.endOfTextblock("backward", state) : $cursor.parentOffset > 0)) return null;
  return $cursor;
}
var joinBackward = function joinBackward(state, dispatch, view) {
  var $cursor = atBlockStart(state, view);
  if (!$cursor) return false;
  var $cut = findCutBefore($cursor);
  if (!$cut) {
    var range = $cursor.blockRange(),
      target = range && prosemirrorTransform.liftTarget(range);
    if (target == null) return false;
    if (dispatch) dispatch(state.tr.lift(range, target).scrollIntoView());
    return true;
  }
  var before = $cut.nodeBefore;
  if (deleteBarrier(state, $cut, dispatch, -1)) return true;
  if ($cursor.parent.content.size == 0 && (textblockAt(before, "end") || prosemirrorState.NodeSelection.isSelectable(before))) {
    for (var depth = $cursor.depth;; depth--) {
      var delStep = prosemirrorTransform.replaceStep(state.doc, $cursor.before(depth), $cursor.after(depth), prosemirrorModel.Slice.empty);
      if (delStep && delStep.slice.size < delStep.to - delStep.from) {
        if (dispatch) {
          var tr = state.tr.step(delStep);
          tr.setSelection(textblockAt(before, "end") ? prosemirrorState.Selection.findFrom(tr.doc.resolve(tr.mapping.map($cut.pos, -1)), -1) : prosemirrorState.NodeSelection.create(tr.doc, $cut.pos - before.nodeSize));
          dispatch(tr.scrollIntoView());
        }
        return true;
      }
      if (depth == 1 || $cursor.node(depth - 1).childCount > 1) break;
    }
  }
  if (before.isAtom && $cut.depth == $cursor.depth - 1) {
    if (dispatch) dispatch(state.tr["delete"]($cut.pos - before.nodeSize, $cut.pos).scrollIntoView());
    return true;
  }
  return false;
};
var joinTextblockBackward = function joinTextblockBackward(state, dispatch, view) {
  var $cursor = atBlockStart(state, view);
  if (!$cursor) return false;
  var $cut = findCutBefore($cursor);
  return $cut ? joinTextblocksAround(state, $cut, dispatch) : false;
};
var joinTextblockForward = function joinTextblockForward(state, dispatch, view) {
  var $cursor = atBlockEnd(state, view);
  if (!$cursor) return false;
  var $cut = findCutAfter($cursor);
  return $cut ? joinTextblocksAround(state, $cut, dispatch) : false;
};
function joinTextblocksAround(state, $cut, dispatch) {
  var before = $cut.nodeBefore,
    beforeText = before,
    beforePos = $cut.pos - 1;
  for (; !beforeText.isTextblock; beforePos--) {
    if (beforeText.type.spec.isolating) return false;
    var child = beforeText.lastChild;
    if (!child) return false;
    beforeText = child;
  }
  var after = $cut.nodeAfter,
    afterText = after,
    afterPos = $cut.pos + 1;
  for (; !afterText.isTextblock; afterPos++) {
    if (afterText.type.spec.isolating) return false;
    var _child = afterText.firstChild;
    if (!_child) return false;
    afterText = _child;
  }
  var step = prosemirrorTransform.replaceStep(state.doc, beforePos, afterPos, prosemirrorModel.Slice.empty);
  if (!step || step.from != beforePos || step instanceof prosemirrorTransform.ReplaceStep && step.slice.size >= afterPos - beforePos) return false;
  if (dispatch) {
    var tr = state.tr.step(step);
    tr.setSelection(prosemirrorState.TextSelection.create(tr.doc, beforePos));
    dispatch(tr.scrollIntoView());
  }
  return true;
}
function textblockAt(node, side) {
  var only = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
  for (var scan = node; scan; scan = side == "start" ? scan.firstChild : scan.lastChild) {
    if (scan.isTextblock) return true;
    if (only && scan.childCount != 1) return false;
  }
  return false;
}
var selectNodeBackward = function selectNodeBackward(state, dispatch, view) {
  var _state$selection = state.selection,
    $head = _state$selection.$head,
    empty = _state$selection.empty,
    $cut = $head;
  if (!empty) return false;
  if ($head.parent.isTextblock) {
    if (view ? !view.endOfTextblock("backward", state) : $head.parentOffset > 0) return false;
    $cut = findCutBefore($head);
  }
  var node = $cut && $cut.nodeBefore;
  if (!node || !prosemirrorState.NodeSelection.isSelectable(node)) return false;
  if (dispatch) dispatch(state.tr.setSelection(prosemirrorState.NodeSelection.create(state.doc, $cut.pos - node.nodeSize)).scrollIntoView());
  return true;
};
function findCutBefore($pos) {
  if (!$pos.parent.type.spec.isolating) for (var i = $pos.depth - 1; i >= 0; i--) {
    if ($pos.index(i) > 0) return $pos.doc.resolve($pos.before(i + 1));
    if ($pos.node(i).type.spec.isolating) break;
  }
  return null;
}
function atBlockEnd(state, view) {
  var $cursor = state.selection.$cursor;
  if (!$cursor || (view ? !view.endOfTextblock("forward", state) : $cursor.parentOffset < $cursor.parent.content.size)) return null;
  return $cursor;
}
var joinForward = function joinForward(state, dispatch, view) {
  var $cursor = atBlockEnd(state, view);
  if (!$cursor) return false;
  var $cut = findCutAfter($cursor);
  if (!$cut) return false;
  var after = $cut.nodeAfter;
  if (deleteBarrier(state, $cut, dispatch, 1)) return true;
  if ($cursor.parent.content.size == 0 && (textblockAt(after, "start") || prosemirrorState.NodeSelection.isSelectable(after))) {
    var delStep = prosemirrorTransform.replaceStep(state.doc, $cursor.before(), $cursor.after(), prosemirrorModel.Slice.empty);
    if (delStep && delStep.slice.size < delStep.to - delStep.from) {
      if (dispatch) {
        var tr = state.tr.step(delStep);
        tr.setSelection(textblockAt(after, "start") ? prosemirrorState.Selection.findFrom(tr.doc.resolve(tr.mapping.map($cut.pos)), 1) : prosemirrorState.NodeSelection.create(tr.doc, tr.mapping.map($cut.pos)));
        dispatch(tr.scrollIntoView());
      }
      return true;
    }
  }
  if (after.isAtom && $cut.depth == $cursor.depth - 1) {
    if (dispatch) dispatch(state.tr["delete"]($cut.pos, $cut.pos + after.nodeSize).scrollIntoView());
    return true;
  }
  return false;
};
var selectNodeForward = function selectNodeForward(state, dispatch, view) {
  var _state$selection2 = state.selection,
    $head = _state$selection2.$head,
    empty = _state$selection2.empty,
    $cut = $head;
  if (!empty) return false;
  if ($head.parent.isTextblock) {
    if (view ? !view.endOfTextblock("forward", state) : $head.parentOffset < $head.parent.content.size) return false;
    $cut = findCutAfter($head);
  }
  var node = $cut && $cut.nodeAfter;
  if (!node || !prosemirrorState.NodeSelection.isSelectable(node)) return false;
  if (dispatch) dispatch(state.tr.setSelection(prosemirrorState.NodeSelection.create(state.doc, $cut.pos)).scrollIntoView());
  return true;
};
function findCutAfter($pos) {
  if (!$pos.parent.type.spec.isolating) for (var i = $pos.depth - 1; i >= 0; i--) {
    var parent = $pos.node(i);
    if ($pos.index(i) + 1 < parent.childCount) return $pos.doc.resolve($pos.after(i + 1));
    if (parent.type.spec.isolating) break;
  }
  return null;
}
var joinUp = function joinUp(state, dispatch) {
  var sel = state.selection,
    nodeSel = sel instanceof prosemirrorState.NodeSelection,
    point;
  if (nodeSel) {
    if (sel.node.isTextblock || !prosemirrorTransform.canJoin(state.doc, sel.from)) return false;
    point = sel.from;
  } else {
    point = prosemirrorTransform.joinPoint(state.doc, sel.from, -1);
    if (point == null) return false;
  }
  if (dispatch) {
    var tr = state.tr.join(point);
    if (nodeSel) tr.setSelection(prosemirrorState.NodeSelection.create(tr.doc, point - state.doc.resolve(point).nodeBefore.nodeSize));
    dispatch(tr.scrollIntoView());
  }
  return true;
};
var joinDown = function joinDown(state, dispatch) {
  var sel = state.selection,
    point;
  if (sel instanceof prosemirrorState.NodeSelection) {
    if (sel.node.isTextblock || !prosemirrorTransform.canJoin(state.doc, sel.to)) return false;
    point = sel.to;
  } else {
    point = prosemirrorTransform.joinPoint(state.doc, sel.to, 1);
    if (point == null) return false;
  }
  if (dispatch) dispatch(state.tr.join(point).scrollIntoView());
  return true;
};
var lift = function lift(state, dispatch) {
  var _state$selection3 = state.selection,
    $from = _state$selection3.$from,
    $to = _state$selection3.$to;
  var range = $from.blockRange($to),
    target = range && prosemirrorTransform.liftTarget(range);
  if (target == null) return false;
  if (dispatch) dispatch(state.tr.lift(range, target).scrollIntoView());
  return true;
};
var newlineInCode = function newlineInCode(state, dispatch) {
  var _state$selection4 = state.selection,
    $head = _state$selection4.$head,
    $anchor = _state$selection4.$anchor;
  if (!$head.parent.type.spec.code || !$head.sameParent($anchor)) return false;
  if (dispatch) dispatch(state.tr.insertText("\n").scrollIntoView());
  return true;
};
function defaultBlockAt(match) {
  for (var i = 0; i < match.edgeCount; i++) {
    var _match$edge = match.edge(i),
      type = _match$edge.type;
    if (type.isTextblock && !type.hasRequiredAttrs()) return type;
  }
  return null;
}
var exitCode = function exitCode(state, dispatch) {
  var _state$selection5 = state.selection,
    $head = _state$selection5.$head,
    $anchor = _state$selection5.$anchor;
  if (!$head.parent.type.spec.code || !$head.sameParent($anchor)) return false;
  var above = $head.node(-1),
    after = $head.indexAfter(-1),
    type = defaultBlockAt(above.contentMatchAt(after));
  if (!type || !above.canReplaceWith(after, after, type)) return false;
  if (dispatch) {
    var pos = $head.after(),
      tr = state.tr.replaceWith(pos, pos, type.createAndFill());
    tr.setSelection(prosemirrorState.Selection.near(tr.doc.resolve(pos), 1));
    dispatch(tr.scrollIntoView());
  }
  return true;
};
var createParagraphNear = function createParagraphNear(state, dispatch) {
  var sel = state.selection,
    $from = sel.$from,
    $to = sel.$to;
  if (sel instanceof prosemirrorState.AllSelection || $from.parent.inlineContent || $to.parent.inlineContent) return false;
  var type = defaultBlockAt($to.parent.contentMatchAt($to.indexAfter()));
  if (!type || !type.isTextblock) return false;
  if (dispatch) {
    var side = (!$from.parentOffset && $to.index() < $to.parent.childCount ? $from : $to).pos;
    var tr = state.tr.insert(side, type.createAndFill());
    tr.setSelection(prosemirrorState.TextSelection.create(tr.doc, side + 1));
    dispatch(tr.scrollIntoView());
  }
  return true;
};
var liftEmptyBlock = function liftEmptyBlock(state, dispatch) {
  var $cursor = state.selection.$cursor;
  if (!$cursor || $cursor.parent.content.size) return false;
  if ($cursor.depth > 1 && $cursor.after() != $cursor.end(-1)) {
    var before = $cursor.before();
    if (prosemirrorTransform.canSplit(state.doc, before)) {
      if (dispatch) dispatch(state.tr.split(before).scrollIntoView());
      return true;
    }
  }
  var range = $cursor.blockRange(),
    target = range && prosemirrorTransform.liftTarget(range);
  if (target == null) return false;
  if (dispatch) dispatch(state.tr.lift(range, target).scrollIntoView());
  return true;
};
function splitBlockAs(splitNode) {
  return function (state, dispatch) {
    var _state$selection6 = state.selection,
      $from = _state$selection6.$from,
      $to = _state$selection6.$to;
    if (state.selection instanceof prosemirrorState.NodeSelection && state.selection.node.isBlock) {
      if (!$from.parentOffset || !prosemirrorTransform.canSplit(state.doc, $from.pos)) return false;
      if (dispatch) dispatch(state.tr.split($from.pos).scrollIntoView());
      return true;
    }
    if (!$from.parent.isBlock) return false;
    if (dispatch) {
      var atEnd = $to.parentOffset == $to.parent.content.size;
      var tr = state.tr;
      if (state.selection instanceof prosemirrorState.TextSelection || state.selection instanceof prosemirrorState.AllSelection) tr.deleteSelection();
      var deflt = $from.depth == 0 ? null : defaultBlockAt($from.node(-1).contentMatchAt($from.indexAfter(-1)));
      var splitType = splitNode && splitNode($to.parent, atEnd, $from);
      var types = splitType ? [splitType] : atEnd && deflt ? [{
        type: deflt
      }] : undefined;
      var can = prosemirrorTransform.canSplit(tr.doc, tr.mapping.map($from.pos), 1, types);
      if (!types && !can && prosemirrorTransform.canSplit(tr.doc, tr.mapping.map($from.pos), 1, deflt ? [{
        type: deflt
      }] : undefined)) {
        if (deflt) types = [{
          type: deflt
        }];
        can = true;
      }
      if (can) {
        tr.split(tr.mapping.map($from.pos), 1, types);
        if (!atEnd && !$from.parentOffset && $from.parent.type != deflt) {
          var first = tr.mapping.map($from.before()),
            $first = tr.doc.resolve(first);
          if (deflt && $from.node(-1).canReplaceWith($first.index(), $first.index() + 1, deflt)) tr.setNodeMarkup(tr.mapping.map($from.before()), deflt);
        }
      }
      dispatch(tr.scrollIntoView());
    }
    return true;
  };
}
var splitBlock = splitBlockAs();
var splitBlockKeepMarks = function splitBlockKeepMarks(state, dispatch) {
  return splitBlock(state, dispatch && function (tr) {
    var marks = state.storedMarks || state.selection.$to.parentOffset && state.selection.$from.marks();
    if (marks) tr.ensureMarks(marks);
    dispatch(tr);
  });
};
var selectParentNode = function selectParentNode(state, dispatch) {
  var _state$selection7 = state.selection,
    $from = _state$selection7.$from,
    to = _state$selection7.to,
    pos;
  var same = $from.sharedDepth(to);
  if (same == 0) return false;
  pos = $from.before(same);
  if (dispatch) dispatch(state.tr.setSelection(prosemirrorState.NodeSelection.create(state.doc, pos)));
  return true;
};
var selectAll = function selectAll(state, dispatch) {
  if (dispatch) dispatch(state.tr.setSelection(new prosemirrorState.AllSelection(state.doc)));
  return true;
};
function joinMaybeClear(state, $pos, dispatch) {
  var before = $pos.nodeBefore,
    after = $pos.nodeAfter,
    index = $pos.index();
  if (!before || !after || !before.type.compatibleContent(after.type)) return false;
  if (!before.content.size && $pos.parent.canReplace(index - 1, index)) {
    if (dispatch) dispatch(state.tr["delete"]($pos.pos - before.nodeSize, $pos.pos).scrollIntoView());
    return true;
  }
  if (!$pos.parent.canReplace(index, index + 1) || !(after.isTextblock || prosemirrorTransform.canJoin(state.doc, $pos.pos))) return false;
  if (dispatch) dispatch(state.tr.clearIncompatible($pos.pos, before.type, before.contentMatchAt(before.childCount)).join($pos.pos).scrollIntoView());
  return true;
}
function deleteBarrier(state, $cut, dispatch, dir) {
  var before = $cut.nodeBefore,
    after = $cut.nodeAfter,
    conn,
    match;
  var isolated = before.type.spec.isolating || after.type.spec.isolating;
  if (!isolated && joinMaybeClear(state, $cut, dispatch)) return true;
  var canDelAfter = !isolated && $cut.parent.canReplace($cut.index(), $cut.index() + 1);
  if (canDelAfter && (conn = (match = before.contentMatchAt(before.childCount)).findWrapping(after.type)) && match.matchType(conn[0] || after.type).validEnd) {
    if (dispatch) {
      var end = $cut.pos + after.nodeSize,
        wrap = prosemirrorModel.Fragment.empty;
      for (var i = conn.length - 1; i >= 0; i--) wrap = prosemirrorModel.Fragment.from(conn[i].create(null, wrap));
      wrap = prosemirrorModel.Fragment.from(before.copy(wrap));
      var tr = state.tr.step(new prosemirrorTransform.ReplaceAroundStep($cut.pos - 1, end, $cut.pos, end, new prosemirrorModel.Slice(wrap, 1, 0), conn.length, true));
      var joinAt = end + 2 * conn.length;
      if (prosemirrorTransform.canJoin(tr.doc, joinAt)) tr.join(joinAt);
      dispatch(tr.scrollIntoView());
    }
    return true;
  }
  var selAfter = after.type.spec.isolating || dir > 0 && isolated ? null : prosemirrorState.Selection.findFrom($cut, 1);
  var range = selAfter && selAfter.$from.blockRange(selAfter.$to),
    target = range && prosemirrorTransform.liftTarget(range);
  if (target != null && target >= $cut.depth) {
    if (dispatch) dispatch(state.tr.lift(range, target).scrollIntoView());
    return true;
  }
  if (canDelAfter && textblockAt(after, "start", true) && textblockAt(before, "end")) {
    var at = before,
      _wrap = [];
    for (;;) {
      _wrap.push(at);
      if (at.isTextblock) break;
      at = at.lastChild;
    }
    var afterText = after,
      afterDepth = 1;
    for (; !afterText.isTextblock; afterText = afterText.firstChild) afterDepth++;
    if (at.canReplace(at.childCount, at.childCount, afterText.content)) {
      if (dispatch) {
        var _end = prosemirrorModel.Fragment.empty;
        for (var _i = _wrap.length - 1; _i >= 0; _i--) _end = prosemirrorModel.Fragment.from(_wrap[_i].copy(_end));
        var _tr = state.tr.step(new prosemirrorTransform.ReplaceAroundStep($cut.pos - _wrap.length, $cut.pos + after.nodeSize, $cut.pos + afterDepth, $cut.pos + after.nodeSize - afterDepth, new prosemirrorModel.Slice(_end, _wrap.length, 0), 0, true));
        dispatch(_tr.scrollIntoView());
      }
      return true;
    }
  }
  return false;
}
function selectTextblockSide(side) {
  return function (state, dispatch) {
    var sel = state.selection,
      $pos = side < 0 ? sel.$from : sel.$to;
    var depth = $pos.depth;
    while ($pos.node(depth).isInline) {
      if (!depth) return false;
      depth--;
    }
    if (!$pos.node(depth).isTextblock) return false;
    if (dispatch) dispatch(state.tr.setSelection(prosemirrorState.TextSelection.create(state.doc, side < 0 ? $pos.start(depth) : $pos.end(depth))));
    return true;
  };
}
var selectTextblockStart = selectTextblockSide(-1);
var selectTextblockEnd = selectTextblockSide(1);
function wrapIn(nodeType) {
  var attrs = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
  return function (state, dispatch) {
    var _state$selection8 = state.selection,
      $from = _state$selection8.$from,
      $to = _state$selection8.$to;
    var range = $from.blockRange($to),
      wrapping = range && prosemirrorTransform.findWrapping(range, nodeType, attrs);
    if (!wrapping) return false;
    if (dispatch) dispatch(state.tr.wrap(range, wrapping).scrollIntoView());
    return true;
  };
}
function setBlockType(nodeType) {
  var attrs = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
  return function (state, dispatch) {
    var applicable = false;
    for (var i = 0; i < state.selection.ranges.length && !applicable; i++) {
      var _state$selection$rang = state.selection.ranges[i],
        from = _state$selection$rang.$from.pos,
        to = _state$selection$rang.$to.pos;
      state.doc.nodesBetween(from, to, function (node, pos) {
        if (applicable) return false;
        if (!node.isTextblock || node.hasMarkup(nodeType, attrs)) return;
        if (node.type == nodeType) {
          applicable = true;
        } else {
          var $pos = state.doc.resolve(pos),
            index = $pos.index();
          applicable = $pos.parent.canReplaceWith(index, index + 1, nodeType);
        }
      });
    }
    if (!applicable) return false;
    if (dispatch) {
      var tr = state.tr;
      for (var _i2 = 0; _i2 < state.selection.ranges.length; _i2++) {
        var _state$selection$rang2 = state.selection.ranges[_i2],
          _from = _state$selection$rang2.$from.pos,
          _to = _state$selection$rang2.$to.pos;
        tr.setBlockType(_from, _to, nodeType, attrs);
      }
      dispatch(tr.scrollIntoView());
    }
    return true;
  };
}
function markApplies(doc, ranges, type, enterAtoms) {
  var _loop = function _loop() {
      var _ranges$i = ranges[i],
        $from = _ranges$i.$from,
        $to = _ranges$i.$to;
      var can = $from.depth == 0 ? doc.inlineContent && doc.type.allowsMarkType(type) : false;
      doc.nodesBetween($from.pos, $to.pos, function (node, pos) {
        if (can || !enterAtoms && node.isAtom && node.isInline && pos >= $from.pos && pos + node.nodeSize <= $to.pos) return false;
        can = node.inlineContent && node.type.allowsMarkType(type);
      });
      if (can) return {
        v: true
      };
    },
    _ret;
  for (var i = 0; i < ranges.length; i++) {
    _ret = _loop();
    if (_ret) return _ret.v;
  }
  return false;
}
function removeInlineAtoms(ranges) {
  var result = [];
  var _loop2 = function _loop2() {
    var _ranges$i2 = ranges[i],
      $from = _ranges$i2.$from,
      $to = _ranges$i2.$to;
    $from.doc.nodesBetween($from.pos, $to.pos, function (node, pos) {
      if (node.isAtom && node.content.size && node.isInline && pos >= $from.pos && pos + node.nodeSize <= $to.pos) {
        if (pos + 1 > $from.pos) result.push(new prosemirrorState.SelectionRange($from, $from.doc.resolve(pos + 1)));
        $from = $from.doc.resolve(pos + 1 + node.content.size);
        return false;
      }
    });
    if ($from.pos < $to.pos) result.push(new prosemirrorState.SelectionRange($from, $to));
  };
  for (var i = 0; i < ranges.length; i++) {
    _loop2();
  }
  return result;
}
function toggleMark(markType) {
  var attrs = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
  var options = arguments.length > 2 ? arguments[2] : undefined;
  var removeWhenPresent = (options && options.removeWhenPresent) !== false;
  var enterAtoms = (options && options.enterInlineAtoms) !== false;
  return function (state, dispatch) {
    var _state$selection9 = state.selection,
      empty = _state$selection9.empty,
      $cursor = _state$selection9.$cursor,
      ranges = _state$selection9.ranges;
    if (empty && !$cursor || !markApplies(state.doc, ranges, markType, enterAtoms)) return false;
    if (dispatch) {
      if ($cursor) {
        if (markType.isInSet(state.storedMarks || $cursor.marks())) dispatch(state.tr.removeStoredMark(markType));else dispatch(state.tr.addStoredMark(markType.create(attrs)));
      } else {
        var add,
          tr = state.tr;
        if (!enterAtoms) ranges = removeInlineAtoms(ranges);
        if (removeWhenPresent) {
          add = !ranges.some(function (r) {
            return state.doc.rangeHasMark(r.$from.pos, r.$to.pos, markType);
          });
        } else {
          add = !ranges.every(function (r) {
            var missing = false;
            tr.doc.nodesBetween(r.$from.pos, r.$to.pos, function (node, pos, parent) {
              if (missing) return false;
              missing = !markType.isInSet(node.marks) && !!parent && parent.type.allowsMarkType(markType) && !(node.isText && /^\s*$/.test(node.textBetween(Math.max(0, r.$from.pos - pos), Math.min(node.nodeSize, r.$to.pos - pos))));
            });
            return !missing;
          });
        }
        for (var i = 0; i < ranges.length; i++) {
          var _ranges$i3 = ranges[i],
            $from = _ranges$i3.$from,
            $to = _ranges$i3.$to;
          if (!add) {
            tr.removeMark($from.pos, $to.pos, markType);
          } else {
            var from = $from.pos,
              to = $to.pos,
              start = $from.nodeAfter,
              end = $to.nodeBefore;
            var spaceStart = start && start.isText ? /^\s*/.exec(start.text)[0].length : 0;
            var spaceEnd = end && end.isText ? /\s*$/.exec(end.text)[0].length : 0;
            if (from + spaceStart < to) {
              from += spaceStart;
              to -= spaceEnd;
            }
            tr.addMark(from, to, markType.create(attrs));
          }
        }
        dispatch(tr.scrollIntoView());
      }
    }
    return true;
  };
}
function wrapDispatchForJoin(dispatch, isJoinable) {
  return function (tr) {
    if (!tr.isGeneric) return dispatch(tr);
    var ranges = [];
    for (var i = 0; i < tr.mapping.maps.length; i++) {
      var map = tr.mapping.maps[i];
      for (var j = 0; j < ranges.length; j++) ranges[j] = map.map(ranges[j]);
      map.forEach(function (_s, _e, from, to) {
        return ranges.push(from, to);
      });
    }
    var joinable = [];
    for (var _i3 = 0; _i3 < ranges.length; _i3 += 2) {
      var from = ranges[_i3],
        to = ranges[_i3 + 1];
      var $from = tr.doc.resolve(from),
        depth = $from.sharedDepth(to),
        parent = $from.node(depth);
      for (var index = $from.indexAfter(depth), pos = $from.after(depth + 1); pos <= to; ++index) {
        var after = parent.maybeChild(index);
        if (!after) break;
        if (index && joinable.indexOf(pos) == -1) {
          var before = parent.child(index - 1);
          if (before.type == after.type && isJoinable(before, after)) joinable.push(pos);
        }
        pos += after.nodeSize;
      }
    }
    joinable.sort(function (a, b) {
      return a - b;
    });
    for (var _i4 = joinable.length - 1; _i4 >= 0; _i4--) {
      if (prosemirrorTransform.canJoin(tr.doc, joinable[_i4])) tr.join(joinable[_i4]);
    }
    dispatch(tr);
  };
}
function autoJoin(command, isJoinable) {
  var canJoin = Array.isArray(isJoinable) ? function (node) {
    return isJoinable.indexOf(node.type.name) > -1;
  } : isJoinable;
  return function (state, dispatch, view) {
    return command(state, dispatch && wrapDispatchForJoin(dispatch, canJoin), view);
  };
}
function chainCommands() {
  for (var _len = arguments.length, commands = new Array(_len), _key = 0; _key < _len; _key++) {
    commands[_key] = arguments[_key];
  }
  return function (state, dispatch, view) {
    for (var i = 0; i < commands.length; i++) if (commands[i](state, dispatch, view)) return true;
    return false;
  };
}
var backspace = chainCommands(deleteSelection, joinBackward, selectNodeBackward);
var del = chainCommands(deleteSelection, joinForward, selectNodeForward);
var pcBaseKeymap = {
  "Enter": chainCommands(newlineInCode, createParagraphNear, liftEmptyBlock, splitBlock),
  "Mod-Enter": exitCode,
  "Backspace": backspace,
  "Mod-Backspace": backspace,
  "Shift-Backspace": backspace,
  "Delete": del,
  "Mod-Delete": del,
  "Mod-a": selectAll
};
var macBaseKeymap = {
  "Ctrl-h": pcBaseKeymap["Backspace"],
  "Alt-Backspace": pcBaseKeymap["Mod-Backspace"],
  "Ctrl-d": pcBaseKeymap["Delete"],
  "Ctrl-Alt-Backspace": pcBaseKeymap["Mod-Delete"],
  "Alt-Delete": pcBaseKeymap["Mod-Delete"],
  "Alt-d": pcBaseKeymap["Mod-Delete"],
  "Ctrl-a": selectTextblockStart,
  "Ctrl-e": selectTextblockEnd
};
for (var key in pcBaseKeymap) macBaseKeymap[key] = pcBaseKeymap[key];
var mac = typeof navigator != "undefined" ? /Mac|iP(hone|[oa]d)/.test(navigator.platform) : typeof os != "undefined" && os.platform ? os.platform() == "darwin" : false;
var baseKeymap = mac ? macBaseKeymap : pcBaseKeymap;
exports.autoJoin = autoJoin;
exports.baseKeymap = baseKeymap;
exports.chainCommands = chainCommands;
exports.createParagraphNear = createParagraphNear;
exports.deleteSelection = deleteSelection;
exports.exitCode = exitCode;
exports.joinBackward = joinBackward;
exports.joinDown = joinDown;
exports.joinForward = joinForward;
exports.joinTextblockBackward = joinTextblockBackward;
exports.joinTextblockForward = joinTextblockForward;
exports.joinUp = joinUp;
exports.lift = lift;
exports.liftEmptyBlock = liftEmptyBlock;
exports.macBaseKeymap = macBaseKeymap;
exports.newlineInCode = newlineInCode;
exports.pcBaseKeymap = pcBaseKeymap;
exports.selectAll = selectAll;
exports.selectNodeBackward = selectNodeBackward;
exports.selectNodeForward = selectNodeForward;
exports.selectParentNode = selectParentNode;
exports.selectTextblockEnd = selectTextblockEnd;
exports.selectTextblockStart = selectTextblockStart;
exports.setBlockType = setBlockType;
exports.splitBlock = splitBlock;
exports.splitBlockAs = splitBlockAs;
exports.splitBlockKeepMarks = splitBlockKeepMarks;
exports.toggleMark = toggleMark;
exports.wrapIn = wrapIn;
