import { inputRules, wrappingInputRule } from 'prosemirror-inputrules';
import { Fragment, Slice } from 'prosemirror-model';

import {
  createInputRule as defaultCreateInputRule,
  leafNodeReplacementCharacter,
  hasVisibleContent,
  isNodeEmpty,
  compose,
} from '../utils';

import { hasParentNodeOfType } from 'prosemirror-utils';

import * as baseListCommand from 'prosemirror-schema-list';

const maxIndentation = 3;

function createInputRule(regexp, nodeType) {
  return wrappingInputRule(
    regexp,
    nodeType,
    {},
    (_, node) => node.type === nodeType
  );
}

export const insertList = (state, listType, listTypeName, start, end) => {
  // To ensure that match is done after HardBreak.
  const { hardBreak } = state.schema.nodes;
  if (state.doc.resolve(start).nodeAfter.type !== hardBreak) {
    return null;
  }

  // To ensure no nesting is done.
  if (state.doc.resolve(start).depth > 1) {
    return null;
  }

  // Split at the start of autoformatting and delete formatting characters.
  let tr = state.tr.delete(start, end).split(start);

  // If node has more content split at the end of autoformatting.
  let currentNode = tr.doc.nodeAt(start + 1);
  tr.doc.nodesBetween(start, start + currentNode.nodeSize, (node, pos) => {
    if (node.type === hardBreak) {
      tr = tr.split(pos + 1).delete(pos, pos + 1);
    }
  });

  // Wrap content in list node
  const { list_item } = state.schema.nodes;
  const position = tr.doc.resolve(start + 2);
  let range = position.blockRange(position);
  tr = tr.wrap(range, [{ type: listType }, { type: list_item }]);
  return tr;
};

/**
 * Create input rules for bullet list node
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getBulletListInputRules(schema) {
  const asteriskRule = createInputRule(
    /^\s*([\*\-]) $/,
    schema.nodes['bullet_list']
  );

  const leafNodeAsteriskRule = defaultCreateInputRule(
    new RegExp(`${leafNodeReplacementCharacter}\\s*([\\*\\-]) $`),
    (state, _match, start, end) => {
      return insertList(
        state,
        schema.nodes['bullet_list'],
        'bullet',
        start,
        end
      );
    },
    true
  );

  return [asteriskRule, leafNodeAsteriskRule];
}

/**
 * Create input rules for strong mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getOrderedListInputRules(schema) {
  // NOTE: There is a built in input rule for ordered lists in ProseMirror. However, that
  // input rule will allow for a list to start at any given number, which isn't allowed in
  // markdown (where a ordered list will always start on 1). This is a slightly modified
  // version of that input rule.
  const numberOneRule = createInputRule(
    /^(1)[\.\)] $/,
    schema.nodes['ordered_list']
  );

  const leafNodeNumberOneRule = defaultCreateInputRule(
    new RegExp(`${leafNodeReplacementCharacter}(1)[\\.\\)] $`),
    (state, _match, start, end) => {
      return insertList(
        state,
        schema.nodes['ordered_list'],
        'numbered',
        start,
        end
      );
    },
    true
  );

  return [numberOneRule, leafNodeNumberOneRule];
}

export function listInputRules(schema) {
  const rules = [];
  if (schema.nodes['bullet_list']) {
    rules.push(...getBulletListInputRules(schema));
  }

  if (schema.nodes['ordered_list']) {
    rules.push(...getOrderedListInputRules(schema));
  }

  if (rules.length !== 0) {
    return inputRules({ rules });
  }

  return;
}

const isInsideListItem = state => {
  const { $from } = state.selection;
  const { list_item, paragraph } = state.schema.nodes;

  return (
    hasParentNodeOfType(list_item)(state.selection) &&
    $from.parent.type === paragraph
  );
};

// Returns the number of nested lists that are ancestors of the given selection
export const numberNestedLists = (resolvedPos, nodes) => {
  const { bullet_list, ordered_list } = nodes;
  let count = 0;
  for (let i = resolvedPos.depth - 1; i > 0; i--) {
    const node = resolvedPos.node(i);
    if (node.type === bullet_list || node.type === ordered_list) {
      count += 1;
    }
  }
  return count;
};

/**
 * Merge closest bullet list blocks into one
 *
 * @param {NodeType} listItem
 * @param {NodeRange} range
 * @returns
 */
function mergeLists(listItem, range) {
  return command => {
    return (state, dispatch) =>
      command(state, tr => {
        const $start = state.doc.resolve(range.start);
        const $end = state.doc.resolve(range.end);
        const $join = tr.doc.resolve(tr.mapping.map(range.end - 1));

        if (
          $join.nodeBefore &&
          $join.nodeAfter &&
          $join.nodeBefore.type === $join.nodeAfter.type
        ) {
          if (
            $end.nodeAfter &&
            $end.nodeAfter.type === listItem &&
            $end.parent.type === $start.parent.type
          ) {
            tr.join($join.pos);
          }
        }

        if (dispatch) {
          dispatch(tr.scrollIntoView());
        }
      });
  };
}

export function outdentList() {
  return function (state, dispatch) {
    const { list_item } = state.schema.nodes;
    const { $from, $to } = state.selection;
    if (isInsideListItem(state)) {
      let range = $from.blockRange(
        $to,
        node => node.childCount > 0 && node.firstChild.type === list_item
      );

      if (!range) {
        return false;
      }
      return compose(
        mergeLists(list_item, range), // 2. Check if I need to merge nearest list
        baseListCommand.liftListItem // 1. First lift list item
      )(list_item)(state, dispatch);
    }

    return false;
  };
}

export function splitListItem(itemType) {
  return function (state, dispatch) {
    const ref = state.selection;
    const $from = ref.$from;
    const $to = ref.$to;
    const node = ref.node;
    if ((node && node.isBlock) || $from.depth < 2 || !$from.sameParent($to)) {
      return false;
    }
    const grandParent = $from.node(-1);
    if (grandParent.type !== itemType) {
      return false;
    }
    if (
      grandParent.content.content.length <= 1 &&
      $from.parent.content.size === 0 &&
      !(grandParent.content.size === 0)
    ) {
      // In an empty block. If this is a nested list, the wrapping
      // list item should be split. Otherwise, bail out and let next
      // command handle lifting.
      if (
        $from.depth === 2 ||
        $from.node(-3).type !== itemType ||
        $from.index(-2) !== $from.node(-2).childCount - 1
      ) {
        return false;
      }
      if (dispatch) {
        let wrap = Fragment.empty;
        const keepItem = $from.index(-1) > 0;
        // Build a fragment containing empty versions of the structure
        // from the outer list item to the parent node of the cursor
        for (
          let d = $from.depth - (keepItem ? 1 : 2);
          d >= $from.depth - 3;
          d--
        ) {
          wrap = Fragment.from($from.node(d).copy(wrap));
        }
        // Add a second list item with an empty default start node
        wrap = wrap.append(Fragment.from(itemType.createAndFill()));
        const tr$1 = state.tr.replace(
          $from.before(keepItem ? undefined : -1),
          $from.after(-3),
          new Slice(wrap, keepItem ? 3 : 2, 2)
        );
        tr$1.setSelection(
          state.selection.constructor.near(
            tr$1.doc.resolve($from.pos + (keepItem ? 3 : 2))
          )
        );
        dispatch(tr$1.scrollIntoView());
      }
      return true;
    }
    const nextType =
      $to.pos === $from.end()
        ? grandParent.contentMatchAt(0).defaultType
        : undefined;
    const tr = state.tr.delete($from.pos, $to.pos);
    const types = nextType && [undefined, { type: nextType }];

    if (dispatch) {
      dispatch(tr.split($from.pos, 2, types).scrollIntoView());
    }
    return true;
  };
}

export const enterKeyOnListCommand = (state, dispatch) => {
  const { selection } = state;
  if (selection.empty) {
    const { $from } = selection;
    const { list_item } = state.schema.nodes;
    const node = $from.node($from.depth);
    const wrapper = $from.node($from.depth - 1);

    if (wrapper && wrapper.type === list_item) {
      /** Check if the wrapper has any visible content */
      const wrapperHasContent = hasVisibleContent(wrapper);
      if (isNodeEmpty(node) && !wrapperHasContent) {
        return outdentList()(state, dispatch);
      } else {
        return splitListItem(list_item)(state, dispatch);
      }
    }
  }
  return false;
};

/**
 * Check if we can sink the list.
 *
 * @param {number} initialIndentationLevel
 * @param {EditorState} state
 * @returns {boolean} - true if we can sink the list
 *                    - false if we reach the max indentation level
 */
function canSink(initialIndentationLevel, state) {
  /*
  - Keep going forward in document until indentation of the node is < than the initial
  - If indentation is EVER > max indentation, return true and don't sink the list
  */
  let currentIndentationLevel;
  let currentPos = state.tr.selection.$to.pos;
  do {
    const resolvedPos = state.doc.resolve(currentPos);
    currentIndentationLevel = numberNestedLists(
      resolvedPos,
      state.schema.nodes
    );
    if (currentIndentationLevel > maxIndentation) {
      // Cancel sink list.
      // If current indentation less than the initial, it won't be
      // larger than the max, and the loop will terminate at end of this iteration
      return false;
    }
    currentPos++;
  } while (currentIndentationLevel >= initialIndentationLevel);

  return true;
}

export function indentList() {
  return function (state, dispatch) {
    const { list_item } = state.schema.nodes;
    if (isInsideListItem(state)) {
      // Record initial list indentation
      const initialIndentationLevel = numberNestedLists(
        state.selection.$from,
        state.schema.nodes
      );
      if (canSink(initialIndentationLevel, state)) {
        baseListCommand.sinkListItem(list_item)(state, dispatch);
      }
      return true;
    }
    return false;
  };
}
