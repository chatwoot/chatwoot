import { MenuItem } from 'prosemirror-menu';
import { toggleMark, setBlockType } from 'prosemirror-commands';
import { markActive } from '../utils';

export const cmdItem = (cmd, options) => {
  const passedOptions = {
    label: options.title,
    run: cmd,
  };
  Object.keys(options).reduce((acc, optionKey) => {
    acc[optionKey] = options[optionKey];
    return acc;
  }, passedOptions);
  if ((!options.enable || options.enable === true) && !options.select) {
    passedOptions[options.enable ? 'enable' : 'select'] = (state) => cmd(state);
  }

  return new MenuItem(passedOptions);
};

export const markItem = (markType, options) => {
  const passedOptions = {
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
};

export const blockTypeIsActive = (state, type, attrs) => {
  const { $from } = state.selection;

  let wrapperDepth;
  let currentDepth = $from.depth;
  while (currentDepth > 0) {
    const currentNodeAtDepth = $from.node(currentDepth);

    const comparisonAttrs = {
      ...attrs,
    };
    if (currentNodeAtDepth.attrs.level) {
      comparisonAttrs.level = currentNodeAtDepth.attrs.level;
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

export const toggleBlockType = (type, attrs) => (state, dispatch) => {
  const isActive = blockTypeIsActive(state, type, attrs);
  const newNodeType = isActive ? state.schema.nodes.paragraph : type;
  const setBlockFunction = setBlockType(newNodeType, attrs);
  return setBlockFunction(state, dispatch);
};
