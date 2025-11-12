import {
  moveRight,
  moveLeft,
  cleanUpAtTheStartOfDocument,
  createNewParagraphBelow,
  createNewParagraphAbove,
} from './commands';
import {
  enterKeyOnListCommand,
  indentList,
  outdentList,
  splitListItem,
} from './rules/lists';

import {
  chainCommands,
  toggleMark,
  exitCode,
  joinUp,
  joinDown,
  selectParentNode,
  baseKeymap,
  deleteSelection,
  joinBackward,
  selectNodeBackward,
  newlineInCode,
  createParagraphNear,
  liftEmptyBlock,
  splitBlock,
} from 'prosemirror-commands';

import { undo, redo } from 'prosemirror-history';
import { undoInputRule } from 'prosemirror-inputrules';
import { keymap } from 'prosemirror-keymap';

const mac =
  typeof navigator !== 'undefined' ? /Mac/.test(navigator.platform) : false;

export function baseKeyMaps(schema) {
  let keys = baseKeymap;
  function bind(key, cmd) {
    keys[key] = cmd;
  }

  bind('Mod-z', chainCommands(undoInputRule, undo));
  bind('Shift-Mod-z', redo);
  const backspaceComands = chainCommands(
    undoInputRule,
    cleanUpAtTheStartOfDocument,
    deleteSelection,
    joinBackward,
    selectNodeBackward
  );
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
        dispatch(
          state.tr
            .insertText(` `)
            .replaceSelectionWith(br.create())
            .scrollIntoView()
        );
        return true;
      });
    bind('Mod-Enter', cmd);
    bind('Shift-Enter', cmd);
    if (mac) bind('Ctrl-Enter', cmd);
  }
  const modEnter = mac ? 'Mod-Enter' : 'Ctrl-Enter';

  const enterCommands = [
    newlineInCode,
    createParagraphNear,
    liftEmptyBlock,
    splitBlock,
  ];

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
