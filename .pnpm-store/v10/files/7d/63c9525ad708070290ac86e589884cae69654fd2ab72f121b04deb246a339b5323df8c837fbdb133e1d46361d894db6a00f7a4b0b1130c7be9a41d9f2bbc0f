import { markActive, hasCode } from './utils';
import { hasParentNodeOfType } from 'prosemirror-utils';
import { Selection, TextSelection, NodeSelection } from 'prosemirror-state';
import { mapSlice, canMoveDown, canMoveUp } from './utils';

export const applyMarkOnRange = (from, to, removeMark, mark, tr) => {
  // const { schema } = tr.doc.type;
  // const { code } = schema.marks;
  // if (mark.type === code) {
  // // When turning to code we need to flat some special characters
  // import { transformSmartCharsMentionsAndEmojis } from '../plugins/text-formatting/commands/transform-to-code';
  //   transformSmartCharsMentionsAndEmojis(from, to, tr);
  // }

  tr.doc.nodesBetween(tr.mapping.map(from), tr.mapping.map(to), (node, pos) => {
    if (!node.isText) {
      return true;
    }

    // This is an issue when the user selects some text.
    // We need to check if the current node position is less than the range selection from.
    // If it’s true, that means we should apply the mark using the range selection,
    // not the current node position.
    const nodeBetweenFrom = Math.max(pos, tr.mapping.map(from));
    const nodeBetweenTo = Math.min(pos + node.nodeSize, tr.mapping.map(to));

    if (removeMark) {
      tr.removeMark(nodeBetweenFrom, nodeBetweenTo, mark);
    } else {
      tr.addMark(nodeBetweenFrom, nodeBetweenTo, mark);
    }

    return true;
  });

  return tr;
};

export const moveRight = () => {
  return (state, dispatch) => {
    const { code } = state.schema.marks;
    const { empty, $cursor } = state.selection;
    if (!empty || !$cursor) {
      return false;
    }
    const { storedMarks } = state.tr;
    if (code) {
      const insideCode = markActive(state, code.create());
      const currentPosHasCode = state.doc.rangeHasMark(
        $cursor.pos,
        $cursor.pos,
        code
      );
      const nextPosHasCode = state.doc.rangeHasMark(
        $cursor.pos,
        $cursor.pos + 1,
        code
      );

      const exitingCode =
        !currentPosHasCode &&
        !nextPosHasCode &&
        (!storedMarks || !!storedMarks.length);
      const enteringCode =
        !currentPosHasCode &&
        nextPosHasCode &&
        (!storedMarks || !storedMarks.length);

      // entering code mark (from the left edge): don't move the cursor, just add the mark
      if (!insideCode && enteringCode) {
        if (dispatch) {
          dispatch(state.tr.addStoredMark(code.create()));
        }
        return true;
      }

      // exiting code mark: don't move the cursor, just remove the mark
      if (insideCode && exitingCode) {
        if (dispatch) {
          dispatch(state.tr.removeStoredMark(code));
        }
        return true;
      }
    }

    return false;
  };
};

export const moveLeft = () => {
  return (state, dispatch) => {
    const { code } = state.schema.marks;
    const { empty, $cursor } = state.selection;
    if (!empty || !$cursor) {
      return false;
    }

    const { storedMarks } = state.tr;
    if (code) {
      const insideCode = code && markActive(state, code.create());
      const currentPosHasCode = hasCode(state, $cursor.pos);
      const nextPosHasCode = hasCode(state, $cursor.pos - 1);
      const nextNextPosHasCode = hasCode(state, $cursor.pos - 2);

      const exitingCode =
        currentPosHasCode && !nextPosHasCode && Array.isArray(storedMarks);
      const atLeftEdge =
        nextPosHasCode &&
        !nextNextPosHasCode &&
        (storedMarks === null ||
          (Array.isArray(storedMarks) && !!storedMarks.length));
      const atRightEdge =
        ((exitingCode && Array.isArray(storedMarks) && !storedMarks.length) ||
          (!exitingCode && storedMarks === null)) &&
        !nextPosHasCode &&
        nextNextPosHasCode;
      const enteringCode =
        !currentPosHasCode &&
        nextPosHasCode &&
        Array.isArray(storedMarks) &&
        !storedMarks.length;

      // at the right edge: remove code mark and move the cursor to the left
      if (!insideCode && atRightEdge) {
        const tr = state.tr.setSelection(
          Selection.near(state.doc.resolve($cursor.pos - 1))
        );

        if (dispatch) {
          dispatch(tr.removeStoredMark(code));
        }
        return true;
      }

      // entering code mark (from right edge): don't move the cursor, just add the mark
      if (!insideCode && enteringCode) {
        if (dispatch) {
          dispatch(state.tr.addStoredMark(code.create()));
        }
        return true;
      }

      // at the left edge: add code mark and move the cursor to the left
      if (insideCode && atLeftEdge) {
        const tr = state.tr.setSelection(
          Selection.near(state.doc.resolve($cursor.pos - 1))
        );

        if (dispatch) {
          dispatch(tr.addStoredMark(code.create()));
        }
        return true;
      }

      // exiting code mark (or at the beginning of the line): don't move the cursor, just remove the mark
      const isFirstChild = $cursor.index($cursor.depth - 1) === 0;
      if (
        insideCode &&
        (exitingCode || (!$cursor.nodeBefore && isFirstChild))
      ) {
        if (dispatch) {
          dispatch(state.tr.removeStoredMark(code));
        }
        return true;
      }
    }

    return false;
  };
};

export const insertBlock = (state, nodeType, nodeName, start, end, attrs) => {
  // To ensure that match is done after HardBreak.
  const {
    hard_break: hardBreak,
    code_block: codeBlock,
    list_item: listItem,
  } = state.schema.nodes;
  const $pos = state.doc.resolve(start);
  if ($pos.nodeAfter.type !== hardBreak) {
    return null;
  }

  // To ensure no nesting is done. (unless we're inserting a codeBlock inside lists)
  if (
    $pos.depth > 1 &&
    !(nodeType === codeBlock && hasParentNodeOfType(listItem)(state.selection))
  ) {
    return null;
  }

  // Split at the start of autoformatting and delete formatting characters.
  let tr = state.tr.delete(start, end).split(start);
  let currentNode = tr.doc.nodeAt(start + 1);

  // If node has more content split at the end of autoformatting.
  let nodeHasMoreContent = false;
  tr.doc.nodesBetween(start, start + currentNode.nodeSize, (node, pos) => {
    if (!nodeHasMoreContent && node.type === hardBreak) {
      nodeHasMoreContent = true;
      tr = tr.split(pos + 1).delete(pos, pos + 1);
    }
  });
  if (nodeHasMoreContent) {
    currentNode = tr.doc.nodeAt(start + 1);
  }

  // Create new node and fill with content of current node.
  const { blockquote, paragraph } = state.schema.nodes;
  let content;
  let depth;
  if (nodeType === blockquote) {
    depth = 3;
    content = [paragraph.create({}, currentNode.content)];
  } else {
    depth = 2;
    content = currentNode.content;
  }
  const newNode = nodeType.create(attrs, content);

  // Add new node.
  tr = tr
    .setSelection(new NodeSelection(tr.doc.resolve(start + 1)))
    .replaceSelectionWith(newNode)
    .setSelection(new TextSelection(tr.doc.resolve(start + depth)));
  return tr;
};

export function transformToCodeBlockAction(state, attrs) {
  if (!state.selection.empty) {
    // Don't do anything, if there is something selected
    return state.tr;
  }

  const codeBlock = state.schema.nodes.code_block;
  const startOfCodeBlockText = state.selection.$from;
  const parentPos = startOfCodeBlockText.before();
  const end = startOfCodeBlockText.end();

  const codeBlockSlice = mapSlice(
    state.doc.slice(startOfCodeBlockText.pos, end),
    node => {
      if (node.type === state.schema.nodes.hard_break) {
        return state.schema.text('\n');
      }

      if (node.isText) {
        return node.mark([]);
      } else if (node.isInline) {
        return node.attrs.text ? state.schema.text(node.attrs.text) : null;
      } else {
        return node.content.childCount ? node.content : null;
      }
    }
  );

  const tr = state.tr.replaceRange(
    startOfCodeBlockText.pos,
    end,
    codeBlockSlice
  );
  // If our offset isnt at 3 (backticks) at the start of line, cater for content.
  if (startOfCodeBlockText.parentOffset >= 3) {
    return tr.split(startOfCodeBlockText.pos, undefined, [
      { type: codeBlock, attrs },
    ]);
  }
  // TODO: Check parent node for valid code block marks, ATM It's not necessary because code block doesn't have any valid mark.
  const codeBlockMarks = [];
  return tr.setNodeMarkup(parentPos, codeBlock, attrs, codeBlockMarks);
}

export function isConvertableToCodeBlock(state) {
  // Before a document is loaded, there is no selection.
  if (!state.selection) {
    return false;
  }

  const { $from } = state.selection;
  const node = $from.parent;

  if (!node.isTextblock || node.type === state.schema.nodes.code_block) {
    return false;
  }

  const parentDepth = $from.depth - 1;
  const parentNode = $from.node(parentDepth);
  const index = $from.index(parentDepth);

  return parentNode.canReplaceWith(
    index,
    index + 1,
    state.schema.nodes.code_block
  );
}

export const cleanUpAtTheStartOfDocument = (state, dispatch) => {
  const { $cursor } = state.selection;
  if (
    $cursor &&
    !$cursor.nodeBefore &&
    !$cursor.nodeAfter &&
    $cursor.pos === 1
  ) {
    const { tr, schema } = state;
    const { paragraph } = schema.nodes;
    const { parent } = $cursor;

    /**
     * Use cases:
     * 1. Change `heading` to `paragraph`
     * 2. Remove block marks
     *
     * NOTE: We already know it's an empty doc so it's safe to use 0
     */
    tr.setNodeMarkup(0, paragraph, parent.attrs, []);
    if (dispatch) {
      dispatch(tr);
    }
    return true;
  }
  return false;
};

function canCreateParagraphNear(state) {
  const {
    selection: { $from },
  } = state;
  const node = $from.node($from.depth);
  const insideCodeBlock = !!node && node.type === state.schema.nodes.code_block;
  const isNodeSelection = state.selection instanceof NodeSelection;
  return $from.depth > 1 || isNodeSelection || insideCodeBlock;
}

export const createNewParagraphBelow = (state, dispatch) => {
  const append = true;
  if (!canMoveDown(state) && canCreateParagraphNear(state)) {
    createParagraphNear(append)(state, dispatch);
    return true;
  }

  return false;
};

export const createNewParagraphAbove = (state, dispatch) => {
  const append = false;
  if (!canMoveUp(state) && canCreateParagraphNear(state)) {
    createParagraphNear(append)(state, dispatch);
    return true;
  }

  return false;
};

function topLevelNodeIsEmptyTextBlock(state) {
  const topLevelNode = state.selection.$from.node(1);
  return (
    topLevelNode.isTextblock &&
    topLevelNode.type !== state.schema.nodes.code_block &&
    topLevelNode.nodeSize === 2
  );
}

function getInsertPosFromTextBlock(state, append) {
  const { $from, $to } = state.selection;
  let pos;
  if (!append) {
    pos = $from.start(0);
  } else {
    pos = $to.end(0);
  }
  return pos;
}

function getInsertPosFromNonTextBlock(state, append) {
  const { $from, $to } = state.selection;

  let pos;
  if (!append) {
    // The start position is different with text block because it starts from 0
    pos = $from.start($from.depth);
    // The depth is different with text block because it starts from 0
    pos = $from.depth > 0 ? pos - 1 : pos;
  } else {
    pos = $to.end($to.depth);
    pos = $to.depth > 0 ? pos + 1 : pos;
  }
  return pos;
}

export function createParagraphNear(append = true) {
  return function (state, dispatch) {
    const paragraph = state.schema.nodes.paragraph;

    if (!paragraph) {
      return false;
    }

    let insertPos;

    if (state.selection instanceof TextSelection) {
      if (topLevelNodeIsEmptyTextBlock(state)) {
        return false;
      }
      insertPos = getInsertPosFromTextBlock(state, append);
    } else {
      insertPos = getInsertPosFromNonTextBlock(state, append);
    }

    const tr = state.tr.insert(insertPos, paragraph.createAndFill());
    tr.setSelection(TextSelection.create(tr.doc, insertPos + 1));

    if (dispatch) {
      dispatch(tr);
    }

    return true;
  };
}
