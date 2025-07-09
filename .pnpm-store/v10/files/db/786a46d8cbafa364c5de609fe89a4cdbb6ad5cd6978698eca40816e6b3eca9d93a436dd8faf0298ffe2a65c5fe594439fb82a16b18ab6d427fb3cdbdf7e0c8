import { InputRule } from 'prosemirror-inputrules';
import { Fragment, Slice } from 'prosemirror-model';
import { TextSelection } from 'prosemirror-state';

/**
 * Determine if a mark (with specific attribute values) exists anywhere in the selection.
 */
export const markActive = (state, mark) => {
  const { from, to, empty } = state.selection;
  // When the selection is empty, only the active marks apply.
  if (empty) {
    return !!mark.isInSet(
      state.tr.storedMarks || state.selection.$from.marks()
    );
  }
  // For a non-collapsed selection, the marks on the nodes matter.
  let found = false;
  state.doc.nodesBetween(from, to, node => {
    found = found || mark.isInSet(node.marks);
  });
  return found;
};

export const hasCode = (state, pos) => {
  const { code } = state.schema.marks;
  const node = pos >= 0 && state.doc.nodeAt(pos);
  if (node) {
    return !!node.marks.filter(mark => mark.type === code).length;
  }

  return false;
};

const hasUnsupportedMarkForBlockInputRule = (state, start, end) => {
  const {
    doc,
    schema: { marks },
  } = state;
  let unsupportedMarksPresent = false;
  const isUnsupportedMark = node =>
    node.type === marks.code || node.type === marks.link;
  doc.nodesBetween(start, end, node => {
    unsupportedMarksPresent =
      unsupportedMarksPresent ||
      node.marks.filter(isUnsupportedMark).length > 0;
  });
  return unsupportedMarksPresent;
};

const hasUnsupportedMarkForInputRule = (state, start, end) => {
  const {
    doc,
    schema: { marks },
  } = state;
  let unsupportedMarksPresent = false;
  const isCodemark = mark => mark.type === marks.code;
  doc.nodesBetween(start, end, node => {
    unsupportedMarksPresent =
      unsupportedMarksPresent || node.marks.filter(isCodemark).length > 0;
  });
  return unsupportedMarksPresent;
};

export function defaultInputRuleHandler(inputRule, isBlockNodeRule = false) {
  const originalHandler = inputRule.handler;
  inputRule.handler = (state, match, start, end) => {
    // Skip any input rule inside code
    // https://product-fabric.atlassian.net/wiki/spaces/E/pages/37945345/Editor+content+feature+rules#Editorcontent/featurerules-Rawtextblocks
    const unsupportedMarks = isBlockNodeRule
      ? hasUnsupportedMarkForBlockInputRule(state, start, end)
      : hasUnsupportedMarkForInputRule(state, start, end);
    if (state.selection.$from.parent.type.spec.code || unsupportedMarks) {
      return;
    }
    return originalHandler(state, match, start, end);
  };
  return inputRule;
}

export const createInputRule = (match, handler, isBlockNodeRule = false) =>
  defaultInputRuleHandler(new InputRule(match, handler), isBlockNodeRule);

// ProseMirror uses the Unicode Character 'OBJECT REPLACEMENT CHARACTER' (U+FFFC) as text representation for
// leaf nodes, i.e. nodes that don't have any content or text property (e.g. hardBreak, emoji, mention, rule)
// It was introduced because of https://github.com/ProseMirror/prosemirror/issues/262
// This can be used in an input rule regex to be able to include or exclude such nodes.
export const leafNodeReplacementCharacter = '\ufffc';

/**
 * Returns false if node contains only empty inline nodes and hardBreaks.
 */
export function hasVisibleContent(node) {
  const isInlineNodeHasVisibleContent = inlineNode => {
    return inlineNode.isText
      ? !!inlineNode.textContent.trim()
      : inlineNode.type.name !== 'hardBreak';
  };

  if (node.isInline) {
    return isInlineNodeHasVisibleContent(node);
  } else if (node.isBlock && (node.isLeaf || node.isAtom)) {
    return true;
  } else if (!node.childCount) {
    return false;
  }

  for (let index = 0; index < node.childCount; index++) {
    const child = node.child(index);

    if (hasVisibleContent(child)) {
      return true;
    }
  }

  return false;
}

/**
 * Checks if node is an empty paragraph.
 */
export function isEmptyParagraph(node) {
  return (
    !node ||
    (node.type.name === 'paragraph' && !node.textContent && !node.childCount)
  );
}

/**
 * Checks if a node has any content. Ignores node that only contain empty block nodes.
 */
export function isNodeEmpty(node) {
  if (node && node.textContent) {
    return false;
  }

  if (
    !node ||
    !node.childCount ||
    (node.childCount === 1 && isEmptyParagraph(node.firstChild))
  ) {
    return true;
  }

  const block = [];
  const nonBlock = [];

  node.forEach(child => {
    child.isInline ? nonBlock.push(child) : block.push(child);
  });

  return (
    !nonBlock.length &&
    !block.filter(
      childNode =>
        (!!childNode.childCount &&
          !(
            childNode.childCount === 1 && isEmptyParagraph(childNode.firstChild)
          )) ||
        childNode.isAtom
    ).length
  );
}

export const compose =
  (...functions) =>
  args =>
    functions.reduceRight((arg, fn) => fn(arg), args);

/**
 * A helper to get the underlying array of a fragment.
 */
export function getFragmentBackingArray(fragment) {
  return fragment.content;
}

export function mapFragment(content, callback, parent) {
  const children = [];
  for (let i = 0, size = content.childCount; i < size; i++) {
    const node = content.child(i);
    const transformed = node.isLeaf
      ? callback(node, parent, i)
      : callback(
          node.copy(mapFragment(node.content, callback, node)),
          parent,
          i
        );
    if (transformed) {
      if (transformed) {
        children.push(...getFragmentBackingArray(transformed));
      } else if (Array.isArray(transformed)) {
        children.push(...transformed);
      } else {
        children.push(transformed);
      }
    }
  }
  return Fragment.fromArray(children);
}

export function mapSlice(slice, callback) {
  const fragment = mapFragment(slice.content, callback);
  return new Slice(fragment, slice.openStart, slice.openEnd);
}

export function atTheEndOfDoc(state) {
  const { selection, doc } = state;
  return doc.nodeSize - selection.$to.pos - 2 === selection.$to.depth;
}

export function canMoveDown(state) {
  const { selection } = state;

  if (selection instanceof TextSelection) {
    if (!selection.empty) {
      return true;
    }
  }

  return !atTheEndOfDoc(state);
}

export function atTheBeginningOfDoc(state) {
  const { selection } = state;
  return selection.$from.pos === selection.$from.depth;
}

export function canMoveUp(state) {
  const { selection } = state;

  if (selection instanceof TextSelection) {
    if (!selection.empty) {
      return true;
    }
  }

  return !atTheBeginningOfDoc(state);
}
