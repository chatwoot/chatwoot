/* eslint-disable no-cond-assign */
/* eslint-disable no-plusplus */
import { undoItem, redoItem, icons, MenuItem } from 'prosemirror-menu';
import { toggleMark } from 'prosemirror-commands';
import { wrapInList } from 'prosemirror-schema-list';
import { openPrompt } from './prompt';
import { TextField } from './TextField';

// Helpers to create specific types of items

function cmdItem(cmd, options) {
  let passedOptions = {
    label: options.title,
    run: cmd,
  };
  Object.keys(options).reduce((acc, optionKey) => {
    acc[optionKey] = options[optionKey];
    return acc;
  }, passedOptions);
  if ((!options.enable || options.enable === true) && !options.select)
    passedOptions[options.enable ? 'enable' : 'select'] = state => cmd(state);

  return new MenuItem(passedOptions);
}

function markActive(state, type) {
  let { from, $from, to, empty } = state.selection;
  if (empty) return type.isInSet(state.storedMarks || $from.marks());
  return state.doc.rangeHasMark(from, to, type);
}

function markItem(markType, options) {
  let passedOptions = {
    active(state) {
      return markActive(state, markType);
    },
    enable: true,
  };
  Object.keys(options).reduce((acc, optionKey) => {
    acc[optionKey] = options[optionKey];
    return acc;
  }, passedOptions);
  return cmdItem(toggleMark(markType), passedOptions);
}

function linkItem(markType) {
  return new MenuItem({
    title: 'Add or remove link',
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
        title: 'Create a link',
        fields: {
          href: new TextField({
            label: 'https://example.com',
            class: 'small',
            required: true,
          }),
        },
        callback(attrs) {
          toggleMark(markType, attrs)(view.state, view.dispatch);
          view.focus();
        },
      });
      return false;
    },
  });
}

function wrapListItem(nodeType, options) {
  return cmdItem(wrapInList(nodeType, options.attrs), options);
}

export function buildMenuItems(schema) {
  let r = {};
  let type;
  if ((type = schema.marks.strong))
    r.toggleStrong = markItem(type, {
      title: 'Toggle strong style',
      icon: icons.strong,
    });
  if ((type = schema.marks.em))
    r.toggleEm = markItem(type, { title: 'Toggle emphasis', icon: icons.em });
  if ((type = schema.marks.code))
    r.toggleCode = markItem(type, {
      title: 'Toggle code font',
      icon: icons.code,
    });
  if ((type = schema.marks.link)) r.toggleLink = linkItem(type);

  if ((type = schema.nodes.bullet_list))
    r.wrapBulletList = wrapListItem(type, {
      title: 'Wrap in bullet list',
      icon: icons.bulletList,
    });
  if ((type = schema.nodes.ordered_list))
    r.wrapOrderedList = wrapListItem(type, {
      title: 'Wrap in ordered list',
      icon: icons.orderedList,
    });

  let cut = arr => arr.filter(x => x);

  r.inlineMenu = [
    cut([r.toggleStrong, r.toggleEm, r.toggleCode, r.toggleLink]),
  ];
  r.blockMenu = [cut([r.wrapBulletList, r.wrapOrderedList])];
  r.fullMenu = r.inlineMenu.concat([[undoItem, redoItem]], r.blockMenu);

  return r;
}
