import { undo, redo, history } from 'prosemirror-history';
import { Plugin, TextSelection, Selection, NodeSelection } from 'prosemirror-state';
export { EditorState, Selection } from 'prosemirror-state';
import { dropCursor } from 'prosemirror-dropcursor';
import { gapCursor } from 'prosemirror-gapcursor';
import { MenuItem, menuBar } from 'prosemirror-menu';
import { DecorationSet, Decoration } from 'prosemirror-view';
export { EditorView } from 'prosemirror-view';
import { InputRule, inputRules, wrappingInputRule, textblockTypeInputRule, undoInputRule } from 'prosemirror-inputrules';
import { Slice, Fragment, Schema } from 'prosemirror-model';
import { hasParentNodeOfType, safeInsert } from 'prosemirror-utils';
import * as baseListCommand from 'prosemirror-schema-list';
import { wrapInList, orderedList, bulletList, listItem } from 'prosemirror-schema-list';
import LinkifyIt from 'linkify-it';
import { chainCommands, deleteSelection, joinBackward, selectNodeBackward, toggleMark, exitCode, baseKeymap, joinUp, joinDown, selectParentNode, newlineInCode, createParagraphNear as createParagraphNear$1, liftEmptyBlock, splitBlock, setBlockType } from 'prosemirror-commands';
import { keymap } from 'prosemirror-keymap';
import MarkdownIt from 'markdown-it';
import { MarkdownParser, MarkdownSerializer, schema } from 'prosemirror-markdown';
import MarkdownItSup from 'markdown-it-sup';

var Placeholder = (placeholderText = '') => {
  return new Plugin({
    props: {
      decorations: state => {
        const decorations = [];
        const decorate = (node, pos) => {
          if (state.doc.content.size === 2) {
            decorations.push(Decoration.node(pos, pos + node.nodeSize, {
              class: 'empty-node',
              'data-placeholder': placeholderText
            }));
          }
        };
        state.doc.descendants(decorate);
        return DecorationSet.create(state.doc, decorations);
      }
    }
  });
};

/**
 * Determine if a mark (with specific attribute values) exists anywhere in the selection.
 */
const markActive = (state, mark) => {
  const {
    from,
    to,
    empty
  } = state.selection;
  // When the selection is empty, only the active marks apply.
  if (empty) {
    return !!mark.isInSet(state.tr.storedMarks || state.selection.$from.marks());
  }
  // For a non-collapsed selection, the marks on the nodes matter.
  let found = false;
  state.doc.nodesBetween(from, to, node => {
    found = found || mark.isInSet(node.marks);
  });
  return found;
};
const hasCode = (state, pos) => {
  const {
    code
  } = state.schema.marks;
  const node = pos >= 0 && state.doc.nodeAt(pos);
  if (node) {
    return !!node.marks.filter(mark => mark.type === code).length;
  }
  return false;
};
const hasUnsupportedMarkForBlockInputRule = (state, start, end) => {
  const {
    doc,
    schema: {
      marks
    }
  } = state;
  let unsupportedMarksPresent = false;
  const isUnsupportedMark = node => node.type === marks.code || node.type === marks.link;
  doc.nodesBetween(start, end, node => {
    unsupportedMarksPresent = unsupportedMarksPresent || node.marks.filter(isUnsupportedMark).length > 0;
  });
  return unsupportedMarksPresent;
};
const hasUnsupportedMarkForInputRule = (state, start, end) => {
  const {
    doc,
    schema: {
      marks
    }
  } = state;
  let unsupportedMarksPresent = false;
  const isCodemark = mark => mark.type === marks.code;
  doc.nodesBetween(start, end, node => {
    unsupportedMarksPresent = unsupportedMarksPresent || node.marks.filter(isCodemark).length > 0;
  });
  return unsupportedMarksPresent;
};
function defaultInputRuleHandler(inputRule, isBlockNodeRule = false) {
  const originalHandler = inputRule.handler;
  inputRule.handler = (state, match, start, end) => {
    // Skip any input rule inside code
    // https://product-fabric.atlassian.net/wiki/spaces/E/pages/37945345/Editor+content+feature+rules#Editorcontent/featurerules-Rawtextblocks
    const unsupportedMarks = isBlockNodeRule ? hasUnsupportedMarkForBlockInputRule(state, start, end) : hasUnsupportedMarkForInputRule(state, start, end);
    if (state.selection.$from.parent.type.spec.code || unsupportedMarks) {
      return;
    }
    return originalHandler(state, match, start, end);
  };
  return inputRule;
}
const createInputRule$1 = (match, handler, isBlockNodeRule = false) => defaultInputRuleHandler(new InputRule(match, handler), isBlockNodeRule);

// ProseMirror uses the Unicode Character 'OBJECT REPLACEMENT CHARACTER' (U+FFFC) as text representation for
// leaf nodes, i.e. nodes that don't have any content or text property (e.g. hardBreak, emoji, mention, rule)
// It was introduced because of https://github.com/ProseMirror/prosemirror/issues/262
// This can be used in an input rule regex to be able to include or exclude such nodes.
const leafNodeReplacementCharacter = '\ufffc';

/**
 * Returns false if node contains only empty inline nodes and hardBreaks.
 */
function hasVisibleContent(node) {
  const isInlineNodeHasVisibleContent = inlineNode => {
    return inlineNode.isText ? !!inlineNode.textContent.trim() : inlineNode.type.name !== 'hardBreak';
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
function isEmptyParagraph(node) {
  return !node || node.type.name === 'paragraph' && !node.textContent && !node.childCount;
}

/**
 * Checks if a node has any content. Ignores node that only contain empty block nodes.
 */
function isNodeEmpty(node) {
  if (node && node.textContent) {
    return false;
  }
  if (!node || !node.childCount || node.childCount === 1 && isEmptyParagraph(node.firstChild)) {
    return true;
  }
  const block = [];
  const nonBlock = [];
  node.forEach(child => {
    child.isInline ? nonBlock.push(child) : block.push(child);
  });
  return !nonBlock.length && !block.filter(childNode => !!childNode.childCount && !(childNode.childCount === 1 && isEmptyParagraph(childNode.firstChild)) || childNode.isAtom).length;
}
const compose = (...functions) => args => functions.reduceRight((arg, fn) => fn(arg), args);

/**
 * A helper to get the underlying array of a fragment.
 */
function getFragmentBackingArray(fragment) {
  return fragment.content;
}
function mapFragment(content, callback, parent) {
  const children = [];
  for (let i = 0, size = content.childCount; i < size; i++) {
    const node = content.child(i);
    const transformed = node.isLeaf ? callback(node, parent, i) : callback(node.copy(mapFragment(node.content, callback, node)), parent, i);
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
function mapSlice(slice, callback) {
  const fragment = mapFragment(slice.content, callback);
  return new Slice(fragment, slice.openStart, slice.openEnd);
}
function atTheEndOfDoc(state) {
  const {
    selection,
    doc
  } = state;
  return doc.nodeSize - selection.$to.pos - 2 === selection.$to.depth;
}
function canMoveDown(state) {
  const {
    selection
  } = state;
  if (selection instanceof TextSelection) {
    if (!selection.empty) {
      return true;
    }
  }
  return !atTheEndOfDoc(state);
}
function atTheBeginningOfDoc(state) {
  const {
    selection
  } = state;
  return selection.$from.pos === selection.$from.depth;
}
function canMoveUp(state) {
  const {
    selection
  } = state;
  if (selection instanceof TextSelection) {
    if (!selection.empty) {
      return true;
    }
  }
  return !atTheBeginningOfDoc(state);
}

const maxIndentation = 3;
function createInputRule(regexp, nodeType) {
  return wrappingInputRule(regexp, nodeType, {}, (_, node) => node.type === nodeType);
}
const insertList = (state, listType, listTypeName, start, end) => {
  // To ensure that match is done after HardBreak.
  const {
    hardBreak
  } = state.schema.nodes;
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
  const {
    list_item
  } = state.schema.nodes;
  const position = tr.doc.resolve(start + 2);
  let range = position.blockRange(position);
  tr = tr.wrap(range, [{
    type: listType
  }, {
    type: list_item
  }]);
  return tr;
};

/**
 * Create input rules for bullet list node
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getBulletListInputRules(schema) {
  const asteriskRule = createInputRule(/^\s*([\*\-]) $/, schema.nodes['bullet_list']);
  const leafNodeAsteriskRule = createInputRule$1(new RegExp(`${leafNodeReplacementCharacter}\\s*([\\*\\-]) $`), (state, _match, start, end) => {
    return insertList(state, schema.nodes['bullet_list'], 'bullet', start, end);
  }, true);
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
  const numberOneRule = createInputRule(/^(1)[\.\)] $/, schema.nodes['ordered_list']);
  const leafNodeNumberOneRule = createInputRule$1(new RegExp(`${leafNodeReplacementCharacter}(1)[\\.\\)] $`), (state, _match, start, end) => {
    return insertList(state, schema.nodes['ordered_list'], 'numbered', start, end);
  }, true);
  return [numberOneRule, leafNodeNumberOneRule];
}
function listInputRules(schema) {
  const rules = [];
  if (schema.nodes['bullet_list']) {
    rules.push(...getBulletListInputRules(schema));
  }
  if (schema.nodes['ordered_list']) {
    rules.push(...getOrderedListInputRules(schema));
  }
  if (rules.length !== 0) {
    return inputRules({
      rules
    });
  }
  return;
}
const isInsideListItem = state => {
  const {
    $from
  } = state.selection;
  const {
    list_item,
    paragraph
  } = state.schema.nodes;
  return hasParentNodeOfType(list_item)(state.selection) && $from.parent.type === paragraph;
};

// Returns the number of nested lists that are ancestors of the given selection
const numberNestedLists = (resolvedPos, nodes) => {
  const {
    bullet_list,
    ordered_list
  } = nodes;
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
    return (state, dispatch) => command(state, tr => {
      const $start = state.doc.resolve(range.start);
      const $end = state.doc.resolve(range.end);
      const $join = tr.doc.resolve(tr.mapping.map(range.end - 1));
      if ($join.nodeBefore && $join.nodeAfter && $join.nodeBefore.type === $join.nodeAfter.type) {
        if ($end.nodeAfter && $end.nodeAfter.type === listItem && $end.parent.type === $start.parent.type) {
          tr.join($join.pos);
        }
      }
      if (dispatch) {
        dispatch(tr.scrollIntoView());
      }
    });
  };
}
function outdentList() {
  return function (state, dispatch) {
    const {
      list_item
    } = state.schema.nodes;
    const {
      $from,
      $to
    } = state.selection;
    if (isInsideListItem(state)) {
      let range = $from.blockRange($to, node => node.childCount > 0 && node.firstChild.type === list_item);
      if (!range) {
        return false;
      }
      return compose(mergeLists(list_item, range),
      // 2. Check if I need to merge nearest list
      baseListCommand.liftListItem // 1. First lift list item
      )(list_item)(state, dispatch);
    }
    return false;
  };
}
function splitListItem(itemType) {
  return function (state, dispatch) {
    const ref = state.selection;
    const $from = ref.$from;
    const $to = ref.$to;
    const node = ref.node;
    if (node && node.isBlock || $from.depth < 2 || !$from.sameParent($to)) {
      return false;
    }
    const grandParent = $from.node(-1);
    if (grandParent.type !== itemType) {
      return false;
    }
    if (grandParent.content.content.length <= 1 && $from.parent.content.size === 0 && !(grandParent.content.size === 0)) {
      // In an empty block. If this is a nested list, the wrapping
      // list item should be split. Otherwise, bail out and let next
      // command handle lifting.
      if ($from.depth === 2 || $from.node(-3).type !== itemType || $from.index(-2) !== $from.node(-2).childCount - 1) {
        return false;
      }
      if (dispatch) {
        let wrap = Fragment.empty;
        const keepItem = $from.index(-1) > 0;
        // Build a fragment containing empty versions of the structure
        // from the outer list item to the parent node of the cursor
        for (let d = $from.depth - (keepItem ? 1 : 2); d >= $from.depth - 3; d--) {
          wrap = Fragment.from($from.node(d).copy(wrap));
        }
        // Add a second list item with an empty default start node
        wrap = wrap.append(Fragment.from(itemType.createAndFill()));
        const tr$1 = state.tr.replace($from.before(keepItem ? undefined : -1), $from.after(-3), new Slice(wrap, keepItem ? 3 : 2, 2));
        tr$1.setSelection(state.selection.constructor.near(tr$1.doc.resolve($from.pos + (keepItem ? 3 : 2))));
        dispatch(tr$1.scrollIntoView());
      }
      return true;
    }
    const nextType = $to.pos === $from.end() ? grandParent.contentMatchAt(0).defaultType : undefined;
    const tr = state.tr.delete($from.pos, $to.pos);
    const types = nextType && [undefined, {
      type: nextType
    }];
    if (dispatch) {
      dispatch(tr.split($from.pos, 2, types).scrollIntoView());
    }
    return true;
  };
}
const enterKeyOnListCommand = (state, dispatch) => {
  const {
    selection
  } = state;
  if (selection.empty) {
    const {
      $from
    } = selection;
    const {
      list_item
    } = state.schema.nodes;
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
    currentIndentationLevel = numberNestedLists(resolvedPos, state.schema.nodes);
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
function indentList() {
  return function (state, dispatch) {
    const {
      list_item
    } = state.schema.nodes;
    if (isInsideListItem(state)) {
      // Record initial list indentation
      const initialIndentationLevel = numberNestedLists(state.selection.$from, state.schema.nodes);
      if (canSink(initialIndentationLevel, state)) {
        baseListCommand.sinkListItem(list_item)(state, dispatch);
      }
      return true;
    }
    return false;
  };
}

// This is a copy of the linkify-it regex, passing `undefined` for the schema
// will use the default regex.
const linkify = new LinkifyIt(undefined, {
  fuzzyLink: false
});
linkify.add('sourcetree:', 'http:');
const tlds = 'app|biz|com|edu|gov|net|org|pro|web|xxx|aero|asia|coop|info|museum|name|shop|рф'.split('|');
const tlds2Char = 'a[cdefgilmnoqrtuwxz]|b[abdefghijmnorstvwyz]|c[acdfghiklmnoruvwxyz]|d[ejkmoz]|e[cegrstu]|f[ijkmor]|g[abdefghilmnpqrstuwy]|h[kmnrtu]|i[delmnoqrst]|j[emop]|k[eghimnprwyz]|l[abcikrstuvy]|m[acdeghklmnopqrtuvwxyz]|n[acefgilopruz]|om|p[aefghkmnrtw]|qa|r[eosuw]|s[abcdegijklmnrtuvxyz]|t[cdfghjklmnortvwz]|u[agksyz]|v[aceginu]|w[fs]|y[et]|z[amw]';
tlds.push(tlds2Char);
linkify.tlds(tlds, false);
function createLinkInputRule(regexp) {
  // Plain typed text (eg, typing 'www.google.com') should convert to a hyperlink
  return createInputRule$1(regexp, (state, match, start, end) => {
    const {
      schema
    } = state;
    if (state.doc.rangeHasMark(start, end, schema.marks.link)) {
      return null;
    }
    const [link] = match;
    const url = normalizeUrl(link.url);
    const markType = schema.mark('link', {
      href: url
    });
    return state.tr.addMark(start - (link.input.length - link.lastIndex), end - (link.input.length - link.lastIndex), markType).insertText(' ');
  });
}
class LinkMatcher {
  exec(str) {
    if (str.endsWith(' ')) {
      const chunks = str.slice(0, str.length - 1).split(' ');
      const lastChunk = chunks[chunks.length - 1];
      const links = linkify.match(lastChunk);
      if (links && links.length > 0) {
        const lastLink = links[links.length - 1];
        lastLink.input = lastChunk;
        lastLink.length = lastLink.lastIndex - lastLink.index + 1;
        return [lastLink];
      }
    }
    return null;
  }
}
const whitelistedURLPatterns = [/^https?:\/\//im, /^ftps?:\/\//im, /^\//im, /^mailto:/im, /^skype:/im, /^callto:/im, /^facetime:/im, /^git:/im, /^irc6?:/im, /^news:/im, /^nntp:/im, /^feed:/im, /^cvs:/im, /^svn:/im, /^mvn:/im, /^ssh:/im, /^scp:\/\//im, /^sftp:\/\//im, /^itms:/im, /^notes:/im, /^hipchat:\/\//im, /^sourcetree:/im, /^urn:/im, /^tel:/im, /^xmpp:/im, /^telnet:/im, /^vnc:/im, /^rdp:/im, /^whatsapp:/im, /^slack:/im, /^sips?:/im, /^magnet:/im];
const isSafeUrl = url => {
  return whitelistedURLPatterns.some(p => p.test(url.trim()) === true);
};
function getLinkMatch(str) {
  const match = str && linkify.match(str);
  return match && match[0];
}

/**
 * Adds protocol to url if needed.
 */
function normalizeUrl(url) {
  if (!url) {
    return '';
  }
  if (isSafeUrl(url)) {
    return url;
  }
  const match = getLinkMatch(url);
  return match && match.url || '';
}
function linksInputRules(schema) {
  if (!schema.marks.link) {
    return;
  }
  const urlWithASpaceRule = createLinkInputRule(new LinkMatcher());

  // [something](link) should convert to a hyperlink
  const markdownLinkRule = createInputRule$1(/(^|[^!])\[(.*?)\]\((\S+)\)$/, (state, match, start, end) => {
    const {
      schema
    } = state;
    const [, prefix, linkText, linkUrl] = match;
    const url = normalizeUrl(linkUrl);
    const markType = schema.mark('link', {
      href: url
    });
    return state.tr.replaceWith(start + prefix.length, end, schema.text(linkText, [markType]));
  });
  return inputRules({
    rules: [urlWithASpaceRule, markdownLinkRule]
  });
}

const applyMarkOnRange = (from, to, removeMark, mark, tr) => {
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
const moveRight = () => {
  return (state, dispatch) => {
    const {
      code
    } = state.schema.marks;
    const {
      empty,
      $cursor
    } = state.selection;
    if (!empty || !$cursor) {
      return false;
    }
    const {
      storedMarks
    } = state.tr;
    if (code) {
      const insideCode = markActive(state, code.create());
      const currentPosHasCode = state.doc.rangeHasMark($cursor.pos, $cursor.pos, code);
      const nextPosHasCode = state.doc.rangeHasMark($cursor.pos, $cursor.pos + 1, code);
      const exitingCode = !currentPosHasCode && !nextPosHasCode && (!storedMarks || !!storedMarks.length);
      const enteringCode = !currentPosHasCode && nextPosHasCode && (!storedMarks || !storedMarks.length);

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
const moveLeft = () => {
  return (state, dispatch) => {
    const {
      code
    } = state.schema.marks;
    const {
      empty,
      $cursor
    } = state.selection;
    if (!empty || !$cursor) {
      return false;
    }
    const {
      storedMarks
    } = state.tr;
    if (code) {
      const insideCode = code && markActive(state, code.create());
      const currentPosHasCode = hasCode(state, $cursor.pos);
      const nextPosHasCode = hasCode(state, $cursor.pos - 1);
      const nextNextPosHasCode = hasCode(state, $cursor.pos - 2);
      const exitingCode = currentPosHasCode && !nextPosHasCode && Array.isArray(storedMarks);
      const atLeftEdge = nextPosHasCode && !nextNextPosHasCode && (storedMarks === null || Array.isArray(storedMarks) && !!storedMarks.length);
      const atRightEdge = (exitingCode && Array.isArray(storedMarks) && !storedMarks.length || !exitingCode && storedMarks === null) && !nextPosHasCode && nextNextPosHasCode;
      const enteringCode = !currentPosHasCode && nextPosHasCode && Array.isArray(storedMarks) && !storedMarks.length;

      // at the right edge: remove code mark and move the cursor to the left
      if (!insideCode && atRightEdge) {
        const tr = state.tr.setSelection(Selection.near(state.doc.resolve($cursor.pos - 1)));
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
        const tr = state.tr.setSelection(Selection.near(state.doc.resolve($cursor.pos - 1)));
        if (dispatch) {
          dispatch(tr.addStoredMark(code.create()));
        }
        return true;
      }

      // exiting code mark (or at the beginning of the line): don't move the cursor, just remove the mark
      const isFirstChild = $cursor.index($cursor.depth - 1) === 0;
      if (insideCode && (exitingCode || !$cursor.nodeBefore && isFirstChild)) {
        if (dispatch) {
          dispatch(state.tr.removeStoredMark(code));
        }
        return true;
      }
    }
    return false;
  };
};
const insertBlock = (state, nodeType, nodeName, start, end, attrs) => {
  // To ensure that match is done after HardBreak.
  const {
    hard_break: hardBreak,
    code_block: codeBlock,
    list_item: listItem
  } = state.schema.nodes;
  const $pos = state.doc.resolve(start);
  if ($pos.nodeAfter.type !== hardBreak) {
    return null;
  }

  // To ensure no nesting is done. (unless we're inserting a codeBlock inside lists)
  if ($pos.depth > 1 && !(nodeType === codeBlock && hasParentNodeOfType(listItem)(state.selection))) {
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
  const {
    blockquote,
    paragraph
  } = state.schema.nodes;
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
  tr = tr.setSelection(new NodeSelection(tr.doc.resolve(start + 1))).replaceSelectionWith(newNode).setSelection(new TextSelection(tr.doc.resolve(start + depth)));
  return tr;
};
function transformToCodeBlockAction(state, attrs) {
  if (!state.selection.empty) {
    // Don't do anything, if there is something selected
    return state.tr;
  }
  const codeBlock = state.schema.nodes.code_block;
  const startOfCodeBlockText = state.selection.$from;
  const parentPos = startOfCodeBlockText.before();
  const end = startOfCodeBlockText.end();
  const codeBlockSlice = mapSlice(state.doc.slice(startOfCodeBlockText.pos, end), node => {
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
  });
  const tr = state.tr.replaceRange(startOfCodeBlockText.pos, end, codeBlockSlice);
  // If our offset isnt at 3 (backticks) at the start of line, cater for content.
  if (startOfCodeBlockText.parentOffset >= 3) {
    return tr.split(startOfCodeBlockText.pos, undefined, [{
      type: codeBlock,
      attrs
    }]);
  }
  // TODO: Check parent node for valid code block marks, ATM It's not necessary because code block doesn't have any valid mark.
  const codeBlockMarks = [];
  return tr.setNodeMarkup(parentPos, codeBlock, attrs, codeBlockMarks);
}
function isConvertableToCodeBlock(state) {
  // Before a document is loaded, there is no selection.
  if (!state.selection) {
    return false;
  }
  const {
    $from
  } = state.selection;
  const node = $from.parent;
  if (!node.isTextblock || node.type === state.schema.nodes.code_block) {
    return false;
  }
  const parentDepth = $from.depth - 1;
  const parentNode = $from.node(parentDepth);
  const index = $from.index(parentDepth);
  return parentNode.canReplaceWith(index, index + 1, state.schema.nodes.code_block);
}
const cleanUpAtTheStartOfDocument = (state, dispatch) => {
  const {
    $cursor
  } = state.selection;
  if ($cursor && !$cursor.nodeBefore && !$cursor.nodeAfter && $cursor.pos === 1) {
    const {
      tr,
      schema
    } = state;
    const {
      paragraph
    } = schema.nodes;
    const {
      parent
    } = $cursor;

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
    selection: {
      $from
    }
  } = state;
  const node = $from.node($from.depth);
  const insideCodeBlock = !!node && node.type === state.schema.nodes.code_block;
  const isNodeSelection = state.selection instanceof NodeSelection;
  return $from.depth > 1 || isNodeSelection || insideCodeBlock;
}
const createNewParagraphBelow = (state, dispatch) => {
  const append = true;
  if (!canMoveDown(state) && canCreateParagraphNear(state)) {
    createParagraphNear(append)(state, dispatch);
    return true;
  }
  return false;
};
const createNewParagraphAbove = (state, dispatch) => {
  const append = false;
  if (!canMoveUp(state) && canCreateParagraphNear(state)) {
    createParagraphNear(append)(state, dispatch);
    return true;
  }
  return false;
};
function topLevelNodeIsEmptyTextBlock(state) {
  const topLevelNode = state.selection.$from.node(1);
  return topLevelNode.isTextblock && topLevelNode.type !== state.schema.nodes.code_block && topLevelNode.nodeSize === 2;
}
function getInsertPosFromTextBlock(state, append) {
  const {
    $from,
    $to
  } = state.selection;
  let pos;
  if (!append) {
    pos = $from.start(0);
  } else {
    pos = $to.end(0);
  }
  return pos;
}
function getInsertPosFromNonTextBlock(state, append) {
  const {
    $from,
    $to
  } = state.selection;
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
function createParagraphNear(append = true) {
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

const MAX_HEADING_LEVEL = 6;
function getHeadingLevel(match) {
  return {
    level: match[1].length
  };
}
function headingRule(nodeType, maxLevel) {
  return textblockTypeInputRule(new RegExp('^(#{1,' + maxLevel + '})\\s$'), nodeType, getHeadingLevel);
}
function blockQuoteRule(nodeType) {
  return wrappingInputRule(/^\s*>\s$/, nodeType);
}

/**
 * Get heading rules
 *
 * @param {Schema} schema
 * @returns {}
 */
function getHeadingRules(schema) {
  // '# ' for h1, '## ' for h2 and etc
  const hashRule = defaultInputRuleHandler(headingRule(schema.nodes.heading, MAX_HEADING_LEVEL), true);
  const leftNodeReplacementHashRule = createInputRule$1(new RegExp(`${leafNodeReplacementCharacter}(#{1,6})\\s$`), (state, match, start, end) => {
    const level = match[1].length;
    return insertBlock(state, schema.nodes.heading, `heading${level}`, start, end, {
      level
    });
  }, true);
  return [hashRule, leftNodeReplacementHashRule];
}

/**
 * Get all block quote input rules
 *
 * @param {Schema} schema
 * @returns {}
 */
function getBlockQuoteRules(schema) {
  // '> ' for blockquote
  const greatherThanRule = defaultInputRuleHandler(blockQuoteRule(schema.nodes.blockquote), true);
  const leftNodeReplacementGreatherRule = createInputRule$1(new RegExp(`${leafNodeReplacementCharacter}\\s*>\\s$`), (state, _match, start, end) => {
    return insertBlock(state, schema.nodes.blockquote, 'blockquote', start, end);
  }, true);
  return [greatherThanRule, leftNodeReplacementGreatherRule];
}

/**
 * Get all code block input rules
 *
 * @param {Schema} schema
 * @returns {}
 */
function getCodeBlockRules(schema) {
  const threeTildeRule = createInputRule$1(/((^`{3,})|(\s`{3,}))(\S*)$/, (state, match, start, end) => {
    const attributes = {};
    if (match[4]) {
      attributes.language = match[4];
    }
    const newStart = match[0][0] === ' ' ? start + 1 : start;
    if (isConvertableToCodeBlock(state)) {
      const tr = transformToCodeBlockAction(state, attributes)
      // remove markdown decorator ```
      .delete(newStart, end).scrollIntoView();
      return tr;
    }
    let {
      tr
    } = state;
    tr = tr.delete(newStart, end);
    const codeBlock = state.schema.nodes.code_block.createChecked();
    return safeInsert(codeBlock)(tr);
  }, true);
  const leftNodeReplacementThreeTildeRule = createInputRule$1(new RegExp(`((${leafNodeReplacementCharacter}\`{3,})|(\\s\`{3,}))(\\S*)$`), (state, match, start, end) => {
    const attributes = {};
    if (match[4]) {
      attributes.language = match[4];
    }
    let tr = insertBlock(state, schema.nodes.code_block, 'codeblock', start, end, attributes);
    return tr;
  }, true);
  return [threeTildeRule, leftNodeReplacementThreeTildeRule];
}
function blocksInputRule(schema) {
  const rules = [];
  if (schema.nodes.heading) {
    rules.push(...getHeadingRules(schema));
  }
  if (schema.nodes.blockquote) {
    rules.push(...getBlockQuoteRules(schema));
  }
  if (schema.nodes.code_block) {
    rules.push(...getCodeBlockRules(schema));
  }
  if (rules.length !== 0) {
    return inputRules({
      rules
    });
  }
  return;
}

function createHorizontalRuleInputRule(type) {
  return createInputRule$1(/^(?:---|___|\*\*\*)\s$/,
  // Ensures rule is triggered with space after "---", "___", or "***"
  (state, match, start, end) => {
    if (!match[0]) {
      return null; // If no match found, return null
    }

    // Deletes the matched sequence including the space
    let tr = state.tr.delete(start, end);
    const hrPos = start; // Position where the horizontal rule should be inserted

    // Insert the horizontal rule at the position
    tr = safeInsert(type.create(), hrPos)(tr);

    // Insert a paragraph node after the horizontal rule
    tr = safeInsert(state.schema.nodes.paragraph.create(), tr.mapping.map(hrPos + 1))(tr);
    return tr;
  });
}
function hrInputRules(schema) {
  if (!schema.nodes.horizontal_rule) {
    // Ensures that horizontal_rule is part of the schema
    return inputRules({
      rules: []
    });
  }
  const hrRule = createHorizontalRuleInputRule(schema.nodes.horizontal_rule);
  return inputRules({
    rules: [hrRule]
  });
}

const mac = typeof navigator !== 'undefined' ? /Mac/.test(navigator.platform) : false;
function baseKeyMaps(schema) {
  let keys = baseKeymap;
  function bind(key, cmd) {
    keys[key] = cmd;
  }
  bind('Mod-z', chainCommands(undoInputRule, undo));
  bind('Shift-Mod-z', redo);
  const backspaceComands = chainCommands(undoInputRule, cleanUpAtTheStartOfDocument, deleteSelection, joinBackward, selectNodeBackward);
  bind('Backspace', backspaceComands);
  bind('Mod-Backspace', backspaceComands);
  if (!mac) bind('Mod-y', redo);
  bind('Alt-ArrowUp', joinUp);
  bind('Alt-ArrowDown', joinDown);
  bind('Escape', selectParentNode);
  bind('ArrowLeft', moveLeft());
  bind('ArrowRight', moveRight());
  bind('ArrowDown', createNewParagraphBelow);
  bind('ArrowUp', createNewParagraphAbove);
  if (schema.marks.strong) {
    bind('Mod-b', toggleMark(schema.marks.strong));
    bind('Mod-B', toggleMark(schema.marks.strong));
  }
  if (schema.marks.em) {
    bind('Mod-i', toggleMark(schema.marks.em));
    bind('Mod-I', toggleMark(schema.marks.em));
  }
  if (schema.marks.superscript) {
    bind('Shift-Mod-.', toggleMark(schema.marks.superscript));
  }
  if (schema.nodes.hard_break) {
    let br = schema.nodes.hard_break,
      cmd = chainCommands(exitCode, (state, dispatch) => {
        dispatch(state.tr.insertText(` `).replaceSelectionWith(br.create()).scrollIntoView());
        return true;
      });
    bind('Mod-Enter', cmd);
    bind('Shift-Enter', cmd);
    if (mac) bind('Ctrl-Enter', cmd);
  }
  const modEnter = mac ? 'Mod-Enter' : 'Ctrl-Enter';
  const enterCommands = [newlineInCode, createParagraphNear$1, liftEmptyBlock, splitBlock];
  if (schema.nodes.list_item) {
    enterCommands.unshift(enterKeyOnListCommand);

    // TODO: Remove hacky fix
    // This needs to done only when the editor sends messages on Enter.
    // Currently Mod+enter command is never reached as it is overridden at the editor
    //  side with Cmd+Enter for sending messages.
    // Fix this by using a different keymap or overriding existing keymap on condition.

    enterCommands.unshift(splitListItem(schema.nodes.list_item));
    bind('Tab', indentList());
    bind('Shift-Tab', outdentList());
  }
  bind('Enter', chainCommands.apply(null, enterCommands));
  bind(modEnter, chainCommands.apply(null, enterCommands));
  return keymap(keys);
}

const validCombos = {
  '**': ['_', '~~', '^'],
  '*': ['__', '~~', '^'],
  '^': ['*', '_'],
  __: ['*', '~~', '^'],
  _: ['**', '~~', '^'],
  '~~': ['__', '_', '**', '*', '^']
};
const validRegex = (char, str) => {
  for (let i = 0; i < validCombos[char].length; i++) {
    const ch = validCombos[char][i];
    if (ch === str) {
      return true;
    }
    const matchLength = str.length - ch.length;
    if (str.substr(matchLength, str.length) === ch) {
      return validRegex(ch, str.substr(0, matchLength));
    }
  }
  return false;
};
function addMark(markType, schema, charSize, char) {
  return (state, match, start, end) => {
    const [, prefix, textWithCombo] = match;
    const to = end;
    // in case of *string* pattern it matches the text from beginning of the paragraph,
    // because we want ** to work for strong text
    // that's why "start" argument is wrong and we need to calculate it ourselves
    const from = textWithCombo ? start + prefix.length : start;
    const nodeBefore = state.doc.resolve(start + prefix.length).nodeBefore;
    if (prefix && prefix.length > 0 && !validRegex(char, prefix) && !(nodeBefore && nodeBefore.type === state.schema.nodes.hard_break)) {
      return null;
    }
    // fixes the following case: my `*name` is *
    // expected result: should ignore special characters inside "code"
    if (state.schema.marks.code && state.schema.marks.code.isInSet(state.doc.resolve(from + 1).marks())) {
      return null;
    }

    // Prevent autoformatting across hardbreaks
    let containsHardBreak;
    state.doc.nodesBetween(from, to, node => {
      if (node.type === schema.nodes.hard_break) {
        containsHardBreak = true;
        return false;
      }
      return !containsHardBreak;
    });
    if (containsHardBreak) {
      return null;
    }

    // fixes autoformatting in heading nodes: # Heading *bold*
    // expected result: should not autoformat *bold*; <h1>Heading *bold*</h1>
    if (state.doc.resolve(from).sameParent(state.doc.resolve(to))) {
      if (!state.doc.resolve(from).parent.type.allowsMarkType(markType)) {
        return null;
      }
    }

    // apply mark to the range (from, to)
    let tr = state.tr.addMark(from, to, markType.create());
    if (charSize > 1) {
      // delete special characters after the text
      // Prosemirror removes the last symbol by itself, so we need to remove "charSize - 1" symbols
      tr = tr.delete(to - (charSize - 1), to);
    }
    return tr
    // delete special characters before the text
    .delete(from, from + charSize).removeStoredMark(markType);
  };
}
function addCodeMark(markType, specialChar) {
  return (state, match, start, end) => {
    if (match[1] && match[1].length > 0) {
      const allowedPrefixConditions = [prefix => {
        return prefix === '(';
      }, prefix => {
        const nodeBefore = state.doc.resolve(start + prefix.length).nodeBefore;
        return nodeBefore && nodeBefore.type === state.schema.nodes.hard_break || false;
      }];
      if (allowedPrefixConditions.every(condition => !condition(match[1]))) {
        return null;
      }
    }
    // fixes autoformatting in heading nodes: # Heading `bold`
    // expected result: should not autoformat *bold*; <h1>Heading `bold`</h1>
    if (state.doc.resolve(start).sameParent(state.doc.resolve(end))) {
      if (!state.doc.resolve(start).parent.type.allowsMarkType(markType)) {
        return null;
      }
    }
    let tr = state.tr;
    // checks if a selection exists and needs to be removed
    if (state.selection.from !== state.selection.to) {
      tr.delete(state.selection.from, state.selection.to);
      end -= state.selection.to - state.selection.from;
    }
    const regexStart = end - match[2].length + 1;
    const codeMark = state.schema.marks.code.create();
    return applyMarkOnRange(regexStart, end, false, codeMark, tr).setStoredMarks([codeMark]).delete(regexStart, regexStart + specialChar.length).removeStoredMark(markType);
  };
}
const strongRegex1 = /(\S*)(\_\_([^\_\s](\_(?!\_)|[^\_])*[^\_\s]|[^\_\s])\_\_)$/;
const strongRegex2 = /(\S*)(\*\*([^\*\s](\*(?!\*)|[^\*])*[^\*\s]|[^\*\s])\*\*)$/;
const italicRegex1 = /(\S*[^\s\_]*)(\_([^\s\_][^\_]*[^\s\_]|[^\s\_])\_)$/;
const italicRegex2 = /(\S*[^\s\*]*)(\*([^\s\*][^\*]*[^\s\*]|[^\s\*])\*)$/;
const strikeRegex = /(\S*)(\~\~([^\s\~](\~(?!\~)|[^\~])*[^\s\~]|[^\s\~])\~\~)$/;
const codeRegex = /(\S*)(`[^\s][^`]*`)$/;
const supertextRegex = /(\S*[^\s^]*)(\^([^\s^][^^]*[^\s^]|[^\s^])\^)$/;

/**
 * Create input rules for strong mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getStrongInputRules(schema) {
  // **string** or __strong__ should bold the text

  const markLength = 2;
  const doubleUnderscoreRule = createInputRule$1(strongRegex1, addMark(schema.marks.strong, schema, markLength, '__'));
  const doubleAsterixRule = createInputRule$1(strongRegex2, addMark(schema.marks.strong, schema, markLength, '**'));
  return [doubleUnderscoreRule, doubleAsterixRule];
}

/**
 * Create input rules for em mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getItalicInputRules(schema) {
  // *string* or _string_ should italic the text
  const markLength = 1;
  const underscoreRule = createInputRule$1(italicRegex1, addMark(schema.marks.em, schema, markLength, '_'));
  const asterixRule = createInputRule$1(italicRegex2, addMark(schema.marks.em, schema, markLength, '*'));
  return [underscoreRule, asterixRule];
}

/**
 * Create input rules for strike mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getStrikeInputRules(schema) {
  const markLength = 2;
  const doubleTildeRule = createInputRule$1(strikeRegex, addMark(schema.marks.strike, schema, markLength, '~~'));
  return [doubleTildeRule];
}
function getSuperscriptInputRules(schema) {
  const markLength = 1;
  // const doubleTildeRule = addMark(schema.marks.superscript);
  const doubleTildeRule = createInputRule$1(supertextRegex, addMark(schema.marks.superscript, schema, markLength, '^'));
  return [doubleTildeRule];
}

/**
 * Create input rules for code mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getCodeInputRules(schema) {
  const backTickRule = createInputRule$1(codeRegex, addCodeMark(schema.marks.code, '`'));
  return [backTickRule];
}
function textFormattingInputRules(schema) {
  const rules = [];
  if (schema.marks.strong) {
    rules.push(...getStrongInputRules(schema));
  }
  if (schema.marks.em) {
    rules.push(...getItalicInputRules(schema));
  }
  if (schema.marks.superscript) {
    rules.push(...getSuperscriptInputRules(schema));
  }
  if (schema.marks.strike) {
    rules.push(...getStrikeInputRules(schema));
  }
  if (schema.marks.code) {
    rules.push(...getCodeInputRules(schema));
  }
  if (rules.length !== 0) {
    return inputRules({
      rules
    });
  }
  return;
}

/* eslint-disable no-plusplus */
const prefix = 'ProseMirror-prompt';
function reportInvalid(dom, message) {
  // FIXME this is awful and needs a lot more work
  let parent = dom.parentNode;
  let msg = parent.appendChild(document.createElement('div'));
  msg.style.left = dom.offsetLeft + dom.offsetWidth + 2 + 'px';
  msg.style.top = dom.offsetTop - 5 + 'px';
  msg.className = 'ProseMirror-invalid';
  msg.textContent = message;
  setTimeout(() => parent.removeChild(msg), 1500);
}
function getValues(fields, domFields) {
  let result = Object.keys(fields).filter((name, index) => {
    let field = fields[name];
    let dom = domFields[index];
    let value = field.read(dom);
    let bad = field.validate(value);
    if (bad) reportInvalid(dom, bad);
    return !bad;
  }).reduce((acc, name, index) => {
    let field = fields[name];
    let dom = domFields[index];
    let value = field.read(dom);
    acc[name] = field.clean(value);
    return acc;
  }, {});
  return result;
}
function openPrompt(options) {
  let wrapper = document.body.appendChild(document.createElement('div'));
  wrapper.className = prefix;
  const close = () => {
    // eslint-disable-next-line no-use-before-define
    window.removeEventListener('mousedown', mouseOutside);
    if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
  };
  let mouseOutside = e => {
    if (!wrapper.contains(e.target)) close();
  };
  setTimeout(() => window.addEventListener('mousedown', mouseOutside), 50);
  let domFields = [];
  Object.values(options.fields).map(field => domFields.push(field.render()));
  let submitButton = document.createElement('button');
  submitButton.type = 'submit';
  submitButton.className = 'button tiny button--save-link ' + prefix + '-submit';
  submitButton.textContent = 'Create Link';
  let cancelButton = document.createElement('button');
  cancelButton.type = 'button';
  cancelButton.className = 'button tiny hollow secondary' + prefix + '-cancel';
  cancelButton.textContent = 'Cancel';
  cancelButton.addEventListener('click', close);
  let form = wrapper.appendChild(document.createElement('form'));
  if (options.title) {
    const titleDom = document.createElement('h5');
    titleDom.className = 'sub-block-title';
    form.appendChild(titleDom).textContent = options.title;
  }
  domFields.forEach(field => {
    form.appendChild(document.createElement('div')).appendChild(field);
  });
  let buttons = form.appendChild(document.createElement('div'));
  buttons.className = prefix + '-buttons';
  buttons.appendChild(submitButton);
  buttons.appendChild(document.createTextNode(' '));
  buttons.appendChild(cancelButton);
  let box = wrapper.getBoundingClientRect();
  wrapper.style.top = (window.innerHeight - box.height) / 2 + 'px';
  wrapper.style.left = (window.innerWidth - box.width) / 2 + 'px';
  let submit = () => {
    let params = getValues(options.fields, domFields);
    if (params) {
      close();
      options.callback(params);
    }
  };
  form.addEventListener('submit', e => {
    e.preventDefault();
    submit();
  });
  form.addEventListener('keydown', e => {
    if (e.key === 'Esc') {
      e.preventDefault();
      close();
    } else if (e.key === 'Enter' && !(e.ctrlKey || e.metaKey || e.shiftKey)) {
      e.preventDefault();
      submit();
    } else if (e.key === 'Tab') {
      window.setTimeout(() => {
        if (!wrapper.contains(document.activeElement)) close();
      }, 500);
    }
  });
  let input = form.elements[0];
  if (input) input.focus();
}

/* eslint-disable class-methods-use-this */
// ::- The type of field that `FieldPrompt` expects to be passed to it.
class Field {
  // :: (Object)
  // Create a field with the given options. Options support by all
  // field types are:
  //
  // **`value`**`: ?any`
  //   : The starting value for the field.
  //
  // **`label`**`: string`
  //   : The label for the field.
  //
  // **`required`**`: ?bool`
  //   : Whether the field is required.
  //
  // **`validate`**`: ?(any) → ?string`
  //   : A function to validate the given value. Should return an
  //     error message if it is not valid.
  constructor(options) {
    this.options = options;
  }

  // render:: (state: EditorState, props: Object) → dom.Node
  // Render the field to the DOM. Should be implemented by all subclasses.

  // :: (dom.Node) → any
  // Read the field's value from its DOM node.
  read(dom) {
    return dom.value;
  }

  // :: (any) → ?string
  // A field-type-specific validation function.
  validateType() {}
  validate(value) {
    if (!value && this.options.required) return 'Required field';
    return this.validateType(value) || this.options.validate && this.options.validate(value);
  }
  clean(value) {
    return this.options.clean ? this.options.clean(value) : value;
  }
}

// ::- A field class for single-line text fields.
class TextField extends Field {
  render() {
    let input = document.createElement('input');
    input.type = 'text';
    input.placeholder = this.options.label;
    input.className = this.options.class;
    input.value = this.options.value || '';
    input.autocomplete = 'off';
    return input;
  }
}

const cmdItem = (cmd, options) => {
  const passedOptions = {
    label: options.title,
    run: cmd
  };
  Object.keys(options).reduce((acc, optionKey) => {
    acc[optionKey] = options[optionKey];
    return acc;
  }, passedOptions);
  if ((!options.enable || options.enable === true) && !options.select) {
    passedOptions[options.enable ? 'enable' : 'select'] = state => cmd(state);
  }
  return new MenuItem(passedOptions);
};
const markItem = (markType, options) => {
  const passedOptions = {
    active(state) {
      return markActive(state, markType);
    },
    enable: true
  };
  Object.keys(options).reduce((acc, optionKey) => {
    acc[optionKey] = options[optionKey];
    return acc;
  }, passedOptions);
  return cmdItem(toggleMark(markType), passedOptions);
};
const blockTypeIsActive = (state, type, attrs) => {
  const {
    $from
  } = state.selection;
  let wrapperDepth;
  let currentDepth = $from.depth;
  while (currentDepth > 0) {
    const currentNodeAtDepth = $from.node(currentDepth);
    ({
      ...attrs
    });
    if (currentNodeAtDepth.attrs.level) {
      currentNodeAtDepth.attrs.level;
    }
    const isType = type.name === currentNodeAtDepth.type.name;
    const hasAttrs = Object.keys(attrs).reduce((prev, curr) => {
      if (attrs[curr] !== currentNodeAtDepth.attrs[curr]) {
        return false;
      }
      return prev;
    }, true);
    if (isType && hasAttrs) {
      wrapperDepth = currentDepth;
    }
    currentDepth -= 1;
  }
  return wrapperDepth;
};
const toggleBlockType = (type, attrs) => (state, dispatch) => {
  const isActive = blockTypeIsActive(state, type, attrs);
  const newNodeType = isActive ? state.schema.nodes.paragraph : type;
  const setBlockFunction = setBlockType(newNodeType, attrs);
  return setBlockFunction(state, dispatch);
};

const BaseIcon = {
  width: 24,
  height: 24,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 2,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
  path: ''
};
const icons = {
  strong: {
    ...BaseIcon,
    path: 'M6.935 4.44A1.5 1.5 0 0 1 7.996 4h4.383C15.017 4 17 6.182 17 8.625a4.63 4.63 0 0 1-.865 2.682c1.077.827 1.866 2.12 1.866 3.813C18 18.232 15.3 20 13.12 20H8a1.5 1.5 0 0 1-1.5-1.5l-.004-13c0-.397.158-.779.44-1.06ZM9.5 10.25h2.88c.903 0 1.62-.76 1.62-1.625S13.281 7 12.38 7H9.498l.002 3.25Zm0 3V17h3.62c.874 0 1.88-.754 1.88-1.88 0-1.13-.974-1.87-1.88-1.87H9.5Z'
  },
  em: {
    ...BaseIcon,
    path: 'M9.75 4h8.504a.75.75 0 0 1 .102 1.493l-.102.006h-3.197L10.037 18.5h4.213a.75.75 0 0 1 .742.648l.007.102a.75.75 0 0 1-.648.743L14.25 20h-9.5a.747.747 0 0 1-.746-.75c0-.38.28-.694.645-.743l.101-.007h3.685l.021-.065L13.45 5.499h-3.7a.75.75 0 0 1-.742-.648L9 4.75a.75.75 0 0 1 .648-.743L9.751 4h8.503-8.503Z'
  },
  superScript: {
    ...BaseIcon,
    path: `M18.736 3.5c-.543 0-.986.495-.986 1.023a.75.75 0 0 1-1.5 0C16.25 3.278 17.258 2 18.736 2c.855 0 1.684.4 2.15 1.117.49.751.5 1.724-.057 2.672-.285.484-.673.847-1.045 1.141-.187.148-.379.284-.557.41l-.078.056a17.45 17.45 0 0 0-.432.311c-.356.268-.619.511-.78.793h2.514a.75.75 0 0 1 0 1.5H17a.75.75 0 0 1-.75-.75c0-1.396.821-2.182 1.565-2.741.157-.119.32-.234.472-.341l.074-.052c.177-.126.34-.243.493-.363.306-.242.532-.47.682-.724.31-.53.229-.886.093-1.094-.158-.244-.486-.435-.893-.435Z
      M15.26 4.71c.06.562.385 1.043.847 1.318L10.987 12l5.583 6.512a.75.75 0 1 1-1.14.976L10 13.152l-5.43 6.336a.75.75 0 0 1-1.14-.976L9.013 12 3.431 5.488a.75.75 0 1 1 1.139-.976L10 10.848l5.26-6.137Z`
  },
  code: {
    ...BaseIcon,
    path: 'm8.066 18.943 6.5-14.5a.75.75 0 0 1 1.404.518l-.036.096-6.5 14.5a.75.75 0 0 1-1.404-.518l.036-.096 6.5-14.5-6.5 14.5ZM2.22 11.47l4.25-4.25a.75.75 0 0 1 1.133.976l-.073.085L3.81 12l3.72 3.719a.75.75 0 0 1-.976 1.133l-.084-.073-4.25-4.25a.75.75 0 0 1-.073-.976l.073-.084 4.25-4.25-4.25 4.25Zm14.25-4.25a.75.75 0 0 1 .976-.073l.084.073 4.25 4.25a.75.75 0 0 1 .073.976l-.073.085-4.25 4.25a.75.75 0 0 1-1.133-.977l.073-.084L20.19 12l-3.72-3.72a.75.75 0 0 1 0-1.06Z'
  },
  link: {
    ...BaseIcon,
    path: 'M9.25 7a.75.75 0 0 1 .11 1.492l-.11.008H7a3.5 3.5 0 0 0-.206 6.994L7 15.5h2.25a.75.75 0 0 1 .11 1.492L9.25 17H7a5 5 0 0 1-.25-9.994L7 7h2.25ZM17 7a5 5 0 0 1 .25 9.994L17 17h-2.25a.75.75 0 0 1-.11-1.492l.11-.008H17a3.5 3.5 0 0 0 .206-6.994L17 8.5h-2.25a.75.75 0 0 1-.11-1.492L14.75 7H17ZM7 11.25h10a.75.75 0 0 1 .102 1.493L17 12.75H7a.75.75 0 0 1-.102-1.493L7 11.25h10H7Z'
  },
  undo: {
    ...BaseIcon,
    path: 'M4.75 2a.75.75 0 0 1 .743.648l.007.102v5.69l4.574-4.56a6.41 6.41 0 0 1 8.879-.179l.186.18a6.41 6.41 0 0 1 0 9.063l-8.846 8.84a.75.75 0 0 1-1.06-1.062l8.845-8.838a4.91 4.91 0 0 0-6.766-7.112l-.178.17L6.562 9.5h5.688a.75.75 0 0 1 .743.648l.007.102a.75.75 0 0 1-.648.743L12.25 11h-7.5a.75.75 0 0 1-.743-.648L4 10.25v-7.5A.75.75 0 0 1 4.75 2Z'
  },
  redo: {
    ...BaseIcon,
    path: 'M19.25 2a.75.75 0 0 0-.743.648l-.007.102v5.69l-4.574-4.56a6.41 6.41 0 0 0-8.878-.179l-.186.18a6.41 6.41 0 0 0 0 9.063l8.845 8.84a.75.75 0 0 0 1.06-1.062l-8.845-8.838a4.91 4.91 0 0 1 6.766-7.112l.178.17L17.438 9.5H11.75a.75.75 0 0 0-.743.648L11 10.25c0 .38.282.694.648.743l.102.007h7.5a.75.75 0 0 0 .743-.648L20 10.25v-7.5a.75.75 0 0 0-.75-.75Z'
  },
  bulletList: {
    ...BaseIcon,
    path: 'M3.25 17.5a1.25 1.25 0 1 1 0 2.5 1.25 1.25 0 0 1 0-2.5Zm3.5.5h14.5a.75.75 0 0 1 .102 1.494l-.102.006H6.75a.75.75 0 0 1-.102-1.493L6.75 18h14.5-14.5Zm-3.5-7a1.25 1.25 0 1 1 0 2.5 1.25 1.25 0 0 1 0-2.5Zm3.5.5h14.5a.75.75 0 0 1 .102 1.494L21.25 13H6.75a.75.75 0 0 1-.102-1.493l.102-.007h14.5-14.5Zm-3.5-7A1.25 1.25 0 1 1 3.25 7a1.25 1.25 0 0 1 0-2.499Zm3.5.5h14.5a.75.75 0 0 1 .102 1.494l-.102.006H6.75a.75.75 0 0 1-.102-1.493L6.75 5h14.5-14.5Z'
  },
  orderedList: {
    ...BaseIcon,
    path: 'M6 2.75a.75.75 0 0 0-1.434-.307l-.002.003a1.45 1.45 0 0 1-.067.132 4.126 4.126 0 0 1-.238.384c-.217.313-.524.663-.906.902a.75.75 0 1 0 .794 1.272c.125-.078.243-.161.353-.248V7.25a.75.75 0 0 0 1.5 0v-4.5ZM20.5 18.75a.75.75 0 0 0-.75-.75h-9a.75.75 0 0 0 0 1.5h9a.75.75 0 0 0 .75-.75ZM20.5 12.244a.75.75 0 0 0-.75-.75h-9a.75.75 0 1 0 0 1.5h9a.75.75 0 0 0 .75-.75ZM20.5 5.75a.75.75 0 0 0-.75-.75h-9a.75.75 0 0 0 0 1.5h9a.75.75 0 0 0 .75-.75ZM5.15 10.52c-.3-.053-.676.066-.87.26a.75.75 0 1 1-1.06-1.06c.556-.556 1.43-.812 2.192-.677.397.07.805.254 1.115.605.316.358.473.825.473 1.352 0 .62-.271 1.08-.606 1.42-.278.283-.63.511-.906.689l-.08.051a5.88 5.88 0 0 0-.481.34H6.25a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1-.75-.75c0-1.314.984-1.953 1.575-2.337l.06-.04c.318-.205.533-.345.69-.504.134-.136.175-.238.175-.369 0-.223-.061-.318-.098-.36a.42.42 0 0 0-.251-.12ZM2.97 21.28s.093.084.004.005l.006.005.013.013a1.426 1.426 0 0 0 .15.125c.095.07.227.158.397.243.341.17.83.329 1.46.329.64 0 1.196-.181 1.601-.54.408-.36.61-.857.595-1.359A1.775 1.775 0 0 0 6.77 19c.259-.305.412-.685.426-1.101a1.73 1.73 0 0 0-.595-1.36C6.196 16.181 5.64 16 5 16c-.63 0-1.119.158-1.46.33a2.592 2.592 0 0 0-.51.334 1.426 1.426 0 0 0-.037.033l-.013.013-.006.005-.002.003H2.97l-.001.002a.75.75 0 0 0 1.048 1.072 1.1 1.1 0 0 1 .192-.121c.159-.08.42-.171.79-.171.36 0 .536.1.608.164.07.061.09.127.088.187a.325.325 0 0 1-.123.23c-.089.077-.263.169-.573.169a.75.75 0 0 0 0 1.5c.31 0 .484.092.573.168.091.08.121.166.123.231a.232.232 0 0 1-.088.187c-.072.064-.247.164-.608.164a1.75 1.75 0 0 1-.79-.17 1.1 1.1 0 0 1-.192-.122.75.75 0 0 0-1.048 1.072Zm.002-4.563-.001.002c.007-.006.2-.168 0-.002Z'
  },
  h1: {
    ...BaseIcon,
    path: 'M19.59 5.081a.746.746 0 0 0-.809.084.751.751 0 0 0-.249.367c-.69 2.051-2.057 3.409-3.168 4.075a.75.75 0 0 0 .772 1.286c.774-.464 1.623-1.18 2.364-2.146v9.503a.75.75 0 0 0 1.5 0V5.772a.75.75 0 0 0-.41-.69ZM3.5 5.75a.75.75 0 0 0-1.5 0v12.5a.75.75 0 0 0 1.5 0V12.5H10v5.75a.75.75 0 0 0 1.5 0V5.75a.75.75 0 0 0-1.5 0V11H3.5V5.75Z'
  },
  h2: {
    ...BaseIcon,
    path: 'M4.5 5.75a.75.75 0 0 0-1.5 0v12.5a.75.75 0 0 0 1.5 0V12.5H11v5.75a.75.75 0 0 0 1.5 0V5.75a.75.75 0 0 0-1.5 0V11H4.5V5.75Zm10.921 2.085c.23-.46.913-1.335 2.58-1.335.842 0 1.459.26 1.86.639.397.376.64.921.64 1.611 0 1.963-1.3 3.068-2.958 4.343l-.212.163C15.825 14.409 14 15.806 14 18.25a.75.75 0 0 0 .75.75h6.5a.75.75 0 0 0 0-1.5h-5.66c.315-1.252 1.427-2.11 2.866-3.218C20.05 13.057 22 11.537 22 8.75c0-1.06-.383-2.015-1.11-2.702C20.166 5.364 19.158 5 18 5c-2.333 0-3.484 1.291-3.92 2.165a.75.75 0 0 0 1.341.67Z'
  },
  h3: {
    ...BaseIcon,
    path: 'M3.5 5.75a.75.75 0 0 0-1.5 0v12.5a.75.75 0 0 0 1.5 0V12.5H10v5.75a.75.75 0 0 0 1.5 0V5.75a.75.75 0 0 0-1.5 0V11H3.5V5.75Zm11.92 2.085c.23-.46.914-1.335 2.58-1.335.843 0 1.46.26 1.86.639.398.376.64.921.64 1.611 0 .606-.161 1.026-.384 1.332-.228.314-.555.554-.953.735-.816.37-1.802.433-2.383.433a.75.75 0 0 0 0 1.5c.581 0 1.567.063 2.383.433.398.18.725.42.953.735.223.306.384.726.384 1.332 0 1.086-.914 2.25-2.5 2.25-1.727 0-2.348-.76-2.553-1.276a.75.75 0 1 0-1.394.552C14.508 17.926 15.727 19 18 19c2.414 0 4-1.836 4-3.75 0-.894-.245-1.63-.67-2.214A3.679 3.679 0 0 0 20.144 12a3.679 3.679 0 0 0 1.186-1.036c.425-.584.67-1.32.67-2.214 0-1.06-.383-2.015-1.11-2.702C20.165 5.364 19.157 5 18 5c-2.334 0-3.484 1.291-3.92 2.165a.75.75 0 1 0 1.34.67Z'
  },
  image: {
    ...BaseIcon,
    path: 'M18.75 4A3.25 3.25 0 0 1 22 7.25v11.5A3.25 3.25 0 0 1 18.75 22H7.25A3.25 3.25 0 0 1 4 18.75v-6.248c.474.198.977.34 1.5.422v5.826c0 .208.036.408.103.594l5.823-5.701a2.25 2.25 0 0 1 3.02-.116l.128.116l5.822 5.702c.067-.186.104-.386.104-.595V7.25a1.75 1.75 0 0 0-1.75-1.75h-5.826a6.457 6.457 0 0 0-.422-1.5h6.248Zm-6.191 10.644l-.084.07l-5.807 5.687c.182.064.378.099.582.099h11.5c.203 0 .399-.035.58-.099l-5.805-5.686a.75.75 0 0 0-.966-.071ZM16.252 7.5a2.252 2.252 0 1 1 0 4.504a2.252 2.252 0 0 1 0-4.504ZM6.5 1a5.5 5.5 0 1 1 0 11a5.5 5.5 0 0 1 0-11Zm9.752 8a.752.752 0 1 0 0 1.504a.752.752 0 0 0 0-1.504ZM6.5 3l-.09.007a.5.5 0 0 0-.402.402L6 3.5V6H3.498l-.09.008a.5.5 0 0 0-.402.402l-.008.09l.008.09a.5.5 0 0 0 .402.402l.09.008H6v2.503l.008.09a.5.5 0 0 0 .402.402l.09.009l.09-.009a.5.5 0 0 0 .402-.402L7 9.503V7h2.505l.09-.008a.5.5 0 0 0 .402-.402l.008-.09l-.008-.09a.5.5 0 0 0-.403-.402L9.504 6H7V3.5l-.008-.09a.5.5 0 0 0-.402-.403L6.5 3Z'
  }
};

const wrapListItem = (nodeType, options) => cmdItem(wrapInList(nodeType, options.attrs), options);
const imageUploadItem = (nodeType, onImageUpload) => new MenuItem({
  title: "Upload image",
  icon: icons.image,
  enable() {
    return true;
  },
  run() {
    onImageUpload();
    return true;
  }
});
const headerItem = (nodeType, options) => {
  const {
    level = 1
  } = options;
  return new MenuItem({
    title: `Heading ${level}`,
    icon: options.icon,
    active(state) {
      return blockTypeIsActive(state, nodeType, {
        level
      });
    },
    enable() {
      return true;
    },
    run(state, dispatch, view) {
      if (blockTypeIsActive(state, nodeType, {
        level
      })) {
        toggleBlockType(nodeType, {
          level
        })(state, dispatch);
        return true;
      }
      toggleBlockType(nodeType, {
        level
      })(view.state, view.dispatch);
      view.focus();
      return false;
    }
  });
};
const linkItem = markType => new MenuItem({
  title: "Add or remove link",
  icon: icons.link,
  active(state) {
    return markActive(state, markType);
  },
  enable(state) {
    return !state.selection.empty;
  },
  run(state, dispatch, view) {
    if (markActive(state, markType)) {
      toggleMark(markType)(state, dispatch);
      return true;
    }
    openPrompt({
      title: "Create a link",
      fields: {
        href: new TextField({
          label: "https://example.com",
          class: "small",
          required: true
        })
      },
      callback(attrs) {
        toggleMark(markType, attrs)(view.state, view.dispatch);
        view.focus();
      }
    });
    return false;
  }
});
const buildMenuOptions = (schema, {
  enabledMenuOptions = ["strong", "em", "code", "link", "undo", "redo", "bulletList", "orderedList"],
  onImageUpload = () => {}
}) => {
  const availableMenuOptions = {
    strong: markItem(schema.marks.strong, {
      title: "Toggle strong style",
      icon: icons.strong
    }),
    em: markItem(schema.marks.em, {
      title: "Toggle emphasis",
      icon: icons.em
    }),
    code: markItem(schema.marks.code, {
      title: "Toggle code font",
      icon: icons.code
    }),
    link: linkItem(schema.marks.link),
    bulletList: wrapListItem(schema.nodes.bullet_list, {
      title: "Wrap in bullet list",
      icon: icons.bulletList
    }),
    orderedList: wrapListItem(schema.nodes.ordered_list, {
      title: "Wrap in ordered list",
      icon: icons.orderedList
    }),
    undo: new MenuItem({
      title: "Undo last change",
      run: undo,
      enable: state => undo(state),
      icon: icons.undo
    }),
    redo: new MenuItem({
      title: "Redo last undone change",
      run: redo,
      enable: state => redo(state),
      icon: icons.redo
    }),
    h1: headerItem(schema.nodes.heading, {
      level: 1,
      title: "Toggle code font",
      icon: icons.h1
    }),
    h2: headerItem(schema.nodes.heading, {
      level: 2,
      title: "Toggle code font",
      icon: icons.h2
    }),
    h3: headerItem(schema.nodes.heading, {
      level: 3,
      title: "Toggle code font",
      icon: icons.h3
    }),
    imageUpload: imageUploadItem(schema.nodes.image, onImageUpload)
  };
  return [enabledMenuOptions.filter(menuOptionKey => !!availableMenuOptions[menuOptionKey]).map(menuOptionKey => availableMenuOptions[menuOptionKey])];
};

function filterMdToPmSchemaMapping(schema, map) {
  return Object.keys(map).reduce((newMap, key) => {
    const value = map[key];
    const block = value.block || value.node;
    const mark = value.mark;
    if (block && schema.nodes[block] || mark && schema.marks[mark]) {
      newMap[key] = value;
    }
    return newMap;
  }, {});
}
const baseSchemaToMdMapping = {
  nodes: {
    blockquote: 'blockquote',
    paragraph: 'paragraph',
    code_block: ['code', 'fence'],
    list_item: 'list'
  },
  marks: {
    em: 'emphasis',
    superscript: 'sup',
    strong: 'text',
    link: ['link', 'autolink', 'reference', 'linkify'],
    strike: 'strikethrough',
    code: 'backticks'
  }
};
const baseNodesMdToPmMapping = {
  blockquote: {
    block: 'blockquote'
  },
  paragraph: {
    block: 'paragraph'
  },
  softbreak: {
    node: 'hard_break'
  },
  hardbreak: {
    node: 'hard_break'
  },
  code_block: {
    block: 'code_block'
  },
  fence: {
    block: 'code_block',
    // we trim any whitespaces around language definition
    attrs: tok => ({
      language: tok.info && tok.info.trim() || null
    })
  },
  list_item: {
    block: 'list_item'
  },
  bullet_list: {
    block: 'bullet_list'
  },
  ordered_list: {
    block: 'ordered_list',
    attrs: tok => ({
      order: +tok.attrGet('order') || 1
    })
  },
  image: {
    node: 'image',
    getAttrs: tok => {
      const src = tok.attrGet('src');
      const heightMatch = src.match(/cw_image_height=(\d+)px/);
      return {
        src,
        title: tok.attrGet('title') || null,
        alt: tok.children[0] && tok.children[0].content || null,
        height: heightMatch ? `${heightMatch[1]}px` : null
      };
    }
  }
};
const baseMarksMdToPmMapping = {
  em: {
    mark: 'em'
  },
  sup: {
    mark: 'superscript'
  },
  strong: {
    mark: 'strong'
  },
  link: {
    mark: 'link',
    attrs: tok => ({
      href: tok.attrGet('href'),
      title: tok.attrGet('title') || null
    })
  },
  code_inline: {
    mark: 'code'
  },
  s: {
    mark: 'strike'
  }
};

const messageSchemaToMdMapping = {
  nodes: {
    ...baseSchemaToMdMapping.nodes
  },
  marks: {
    ...baseSchemaToMdMapping.marks
  }
};
const messageMdToPmMapping = {
  ...baseNodesMdToPmMapping,
  ...baseMarksMdToPmMapping,
  mention: {
    node: 'mention',
    getAttrs: ({
      mention
    }) => {
      console.log('mention', mention);
      const {
        userId,
        userFullName
      } = mention;
      return {
        userId,
        userFullName
      };
    }
  },
  tools: {
    node: 'tools',
    getAttrs: ({
      tools
    }) => {
      const {
        id,
        name
      } = tools;
      return {
        id,
        name
      };
    }
  }
};
const md$1 = MarkdownIt('commonmark', {
  html: false,
  linkify: false
});
md$1.enable([
// Process html entity - &#123;, &#xAF;, &quot;, ...
'entity',
// Process escaped chars and hardbreaks
'escape']);
md$1.disable(['table', 'hr', 'heading', 'lheading'], true);
class MessageMarkdownTransformer {
  constructor(schema, tokenizer = md$1) {
    // Enable markdown plugins based on schema
    ['nodes', 'marks'].forEach(key => {
      for (const idx in messageSchemaToMdMapping[key]) {
        if (schema[key][idx]) {
          tokenizer.enable(messageSchemaToMdMapping[key][idx]);
        }
      }
    });
    this.markdownParser = new MarkdownParser(schema, tokenizer, filterMdToPmSchemaMapping(schema, messageMdToPmMapping));
  }
  encode(_node) {
    throw new Error('This is not implemented yet');
  }
  parse(content) {
    return this.markdownParser.parse(content);
  }
}

const articleSchemaToMdMapping = {
  nodes: {
    ...baseSchemaToMdMapping.nodes,
    rule: 'hr',
    heading: ['heading'],
    image: 'image'
  },
  marks: {
    ...baseSchemaToMdMapping.marks
  }
};
const articleMdToPmMapping = {
  ...baseNodesMdToPmMapping,
  ...baseMarksMdToPmMapping,
  hr: {
    node: 'horizontal_rule'
  },
  heading: {
    block: 'heading',
    attrs: tok => ({
      level: +tok.tag.slice(1)
    })
  },
  mention: {
    node: 'mention',
    getAttrs: ({
      mention
    }) => {
      const {
        userId,
        userFullName
      } = mention;
      return {
        userId,
        userFullName
      };
    }
  }
};
const md = MarkdownIt('commonmark', {
  html: false,
  linkify: true,
  breaks: true
}).use(MarkdownItSup);
md.enable([
// Process html entity - &#123;, &#xAF;, &quot;, ...
'entity',
// Process escaped chars and hardbreaks
'escape', 'hr']);
class ArticleMarkdownTransformer {
  constructor(schema, tokenizer = md) {
    // Enable markdown plugins based on schema
    ['nodes', 'marks'].forEach(key => {
      for (const idx in articleSchemaToMdMapping[key]) {
        if (schema[key][idx]) {
          tokenizer.enable(articleSchemaToMdMapping[key][idx]);
        }
      }
    });
    this.markdownParser = new MarkdownParser(schema, tokenizer, filterMdToPmSchemaMapping(schema, articleMdToPmMapping));
  }
  encode(_node) {
    throw new Error('This is not implemented yet');
  }
  parse(content) {
    return this.markdownParser.parse(content);
  }
}

const mention = (state, node) => {
  const uri = state.esc(`mention://user/${node.attrs.userId}/${encodeURIComponent(node.attrs.userFullName)}`);
  const escapedDisplayName = state.esc('@' + (node.attrs.userFullName || ''));
  state.write(`[${escapedDisplayName}](${uri})`);
};
const tools = (state, node) => {
  const uri = state.esc(`tool://${node.attrs.id}`);
  const escapedDisplayName = state.esc(`@${node.attrs.name}`);
  state.write(`[${escapedDisplayName}](${uri})`);
};
const blockquote = (state, node) => {
  state.wrapBlock('> ', null, node, () => state.renderContent(node));
};
const code_block = (state, node) => {
  state.write('```' + (node.attrs.params || '') + '\n');
  state.text(node.textContent, false);
  state.ensureNewLine();
  state.write('```');
  state.closeBlock(node);
};
const heading = (state, node) => {
  state.write(state.repeat('#', node.attrs.level) + ' ');
  state.renderInline(node);
  state.closeBlock(node);
};
const horizontal_rule = (state, node) => {
  state.write(node.attrs.markup || '---');
  state.closeBlock(node);
};
const bullet_list = (state, node) => {
  state.renderList(node, '  ', () => (node.attrs.bullet || '*') + ' ');
};
const ordered_list = (state, node) => {
  let start = node.attrs.order || 1;
  let maxW = String(start + node.childCount - 1).length;
  let space = state.repeat(' ', maxW + 2);
  state.renderList(node, space, i => {
    let nStr = String(start + i);
    return state.repeat(' ', maxW - nStr.length) + nStr + '. ';
  });
};
const list_item = (state, node) => {
  state.renderContent(node);
};
const paragraph = (state, node) => {
  state.renderInline(node);
  state.closeBlock(node);
};
const image = (state, node) => {
  let src = state.esc(node.attrs.src);
  if (node.attrs.height) {
    const param = `cw_image_height=${node.attrs.height}`;
    if (src.includes('?')) {
      src = src.includes('cw_image_height=') ? src.replace(/cw_image_height=[^&]+/, param) : `${src}&${param}`;
    } else {
      src += `?${param}`;
    }
  }
  state.write('![' + state.esc(node.attrs.alt || '') + '](' + src + (node.attrs.title ? ' ' + state.quote(node.attrs.title) : '') + ')');
};
const hard_break = (state, node, parent, index) => {
  for (let i = index + 1; i < parent.childCount; i++) if (parent.child(i).type !== node.type) {
    state.write('  \n');
    return;
  }
};
const text = (state, node) => {
  state.text(node.text, false);
};
const em = {
  open: '*',
  close: '*',
  mixable: true,
  expelEnclosingWhitespace: true
};
const superscript = {
  open: '^',
  close: '^',
  mixable: false,
  escape: false,
  expelEnclosingWhitespace: false
};
const strike = {
  open: '~~',
  close: '~~',
  mixable: true,
  expelEnclosingWhitespace: true
};
const strong = {
  open: '**',
  close: '**',
  mixable: true,
  expelEnclosingWhitespace: true
};
const link = {
  open(_state, mark, parent, index) {
    return isPlainURL(mark, parent, index, 1) ? '<' : '[';
  },
  close(state, mark, parent, index) {
    return isPlainURL(mark, parent, index, -1) ? '>' : '](' + state.esc(mark.attrs.href) + (mark.attrs.title ? ' ' + state.quote(mark.attrs.title) : '') + ')';
  },
  escape: false
};
const code = {
  open(_state, _mark, parent, index) {
    return backticksFor(parent.child(index), -1);
  },
  close(_state, _mark, parent, index) {
    return backticksFor(parent.child(index - 1), 1);
  },
  escape: false
};
function backticksFor(node, side) {
  let ticks = /`+/g,
    m,
    len = 0;
  if (node.isText) while (m = ticks.exec(node.text)) len = Math.max(len, m[0].length);
  let result = len > 0 && side > 0 ? ' `' : '`';
  for (let i = 0; i < len; i++) result += '`';
  if (len > 0 && side < 0) result += ' ';
  return result;
}
function isPlainURL(link, parent, index, side) {
  if (link.attrs.title || !/^\w+:/.test(link.attrs.href)) return false;
  let content = parent.child(index + (side < 0 ? -1 : 0));
  if (!content.isText || content.text != link.attrs.href || content.marks[content.marks.length - 1] != link) return false;
  if (index == (side < 0 ? 1 : parent.childCount - 1)) return true;
  let next = parent.child(index + (side < 0 ? -2 : 1));
  return !link.isInSet(next.marks);
}

const ArticleMarkdownSerializer = new MarkdownSerializer({
  blockquote,
  code_block,
  heading,
  horizontal_rule,
  bullet_list,
  ordered_list,
  list_item,
  paragraph,
  image,
  hard_break,
  text
}, {
  em,
  superscript,
  strike,
  strong,
  link,
  code
});

const MessageMarkdownSerializer = new MarkdownSerializer({
  mention,
  blockquote,
  code_block,
  bullet_list,
  ordered_list,
  list_item,
  paragraph,
  image,
  hard_break,
  text,
  tools
}, {
  em,
  strike,
  strong,
  link,
  code
});

const fullSchema = new Schema({
  nodes: {
    doc: schema.spec.nodes.get('doc'),
    paragraph: schema.spec.nodes.get('paragraph'),
    blockquote: schema.spec.nodes.get('blockquote'),
    horizontal_rule: schema.spec.nodes.get('horizontal_rule'),
    heading: schema.spec.nodes.get('heading'),
    code_block: schema.spec.nodes.get('code_block'),
    text: schema.spec.nodes.get('text'),
    image: schema.spec.nodes.get('image'),
    hard_break: schema.spec.nodes.get('hard_break'),
    ordered_list: Object.assign(orderedList, {
      content: 'list_item+',
      group: 'block'
    }),
    bullet_list: Object.assign(bulletList, {
      content: 'list_item+',
      group: 'block'
    }),
    list_item: Object.assign(listItem, {
      content: 'paragraph block*'
    })
  },
  marks: {
    link: schema.spec.marks.get('link'),
    em: schema.spec.marks.get('em'),
    superscript: {
      parseDOM: [{
        tag: 'sup'
      }],
      toDOM() {
        return ['sup'];
      }
    },
    strong: schema.spec.marks.get('strong'),
    code: schema.spec.marks.get('code'),
    strike: {
      parseDOM: [{
        tag: 's'
      }, {
        tag: 'del'
      }, {
        tag: 'strike'
      }, {
        style: 'text-decoration',
        getAttrs: value => value === 'line-through'
      }],
      toDOM: () => ['s', 0]
    }
  }
});

const messageSchema = new Schema({
  nodes: {
    doc: schema.spec.nodes.get('doc'),
    paragraph: schema.spec.nodes.get('paragraph'),
    blockquote: schema.spec.nodes.get('blockquote'),
    code_block: schema.spec.nodes.get('code_block'),
    text: schema.spec.nodes.get('text'),
    hard_break: schema.spec.nodes.get('hard_break'),
    image: {
      ...schema.spec.nodes.get('image'),
      attrs: {
        ...schema.spec.nodes.get('image').attrs,
        height: {
          default: null
        }
      },
      parseDOM: [{
        tag: 'img[src]',
        getAttrs: dom => ({
          src: dom.getAttribute('src'),
          title: dom.getAttribute('title'),
          alt: dom.getAttribute('alt'),
          height: parseInt(dom.style.height)
        })
      }],
      toDOM: node => {
        const attrs = {
          src: node.attrs.src,
          alt: node.attrs.alt,
          height: node.attrs.height
        };
        if (node.attrs.height) {
          attrs.style = `height: ${node.attrs.height}`;
        }
        return ["img", attrs];
      }
    },
    ordered_list: Object.assign(orderedList, {
      content: 'list_item+',
      group: 'block'
    }),
    bullet_list: Object.assign(bulletList, {
      content: 'list_item+',
      group: 'block'
    }),
    list_item: Object.assign(listItem, {
      content: 'paragraph block*'
    }),
    mention: {
      attrs: {
        userFullName: {
          default: ''
        },
        userId: {
          default: ''
        }
      },
      group: 'inline',
      inline: true,
      selectable: true,
      draggable: true,
      atom: true,
      toDOM: node => ['span', {
        class: 'prosemirror-mention-node',
        'mention-user-id': node.attrs.userId,
        'mention-user-full-name': node.attrs.userFullName
      }, `@${node.attrs.userFullName}`],
      parseDOM: [{
        tag: 'span[mention-user-id][mention-user-full-name]',
        getAttrs: dom => {
          const userId = dom.getAttribute('mention-user-id');
          const userFullName = dom.getAttribute('mention-user-full-name');
          return {
            userId,
            userFullName
          };
        }
      }]
    },
    tools: {
      attrs: {
        id: {
          default: ''
        },
        name: {
          default: ''
        }
      },
      group: 'inline',
      inline: true,
      selectable: true,
      draggable: true,
      atom: true,
      toDOM: node => ['span', {
        class: 'prosemirror-tools-node',
        'tool-id': node.attrs.id,
        'tool-name': node.attrs.name
      }, `@${node.attrs.name}`],
      parseDOM: [{
        tag: 'span[tool-id][tool-name]',
        getAttrs: dom => {
          const id = dom.getAttribute('tool-id');
          const name = dom.getAttribute('tool-name');
          return {
            id,
            name
          };
        }
      }]
    }
  },
  marks: {
    link: schema.spec.marks.get('link'),
    em: schema.spec.marks.get('em'),
    strong: schema.spec.marks.get('strong'),
    code: schema.spec.marks.get('code'),
    strike: {
      parseDOM: [{
        tag: 's'
      }, {
        tag: 'del'
      }, {
        tag: 'strike'
      }, {
        style: 'text-decoration',
        getAttrs: value => value === 'line-through'
      }],
      toDOM: () => ['s', 0]
    }
  }
});

const buildEditor = ({
  schema,
  placeholder,
  methods: {
    onImageUpload
  } = {},
  plugins = [],
  enabledMenuOptions
}) => [...(plugins || []), history(), baseKeyMaps(schema), blocksInputRule(schema), textFormattingInputRules(schema), linksInputRules(schema), hrInputRules(schema), listInputRules(schema), dropCursor(), gapCursor(), Placeholder(placeholder), menuBar({
  floating: true,
  content: buildMenuOptions(schema, {
    enabledMenuOptions,
    onImageUpload
  })
}), new Plugin({
  props: {
    attributes: {
      class: "ProseMirror-woot-style"
    }
  }
})];

export { ArticleMarkdownSerializer, ArticleMarkdownTransformer, MessageMarkdownSerializer, MessageMarkdownTransformer, buildEditor, fullSchema, messageSchema };
//# sourceMappingURL=index.es.js.map
