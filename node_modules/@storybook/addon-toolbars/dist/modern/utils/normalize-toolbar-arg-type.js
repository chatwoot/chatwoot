const defaultItemValues = {
  type: 'item',
  value: ''
};
export const normalizeArgType = (key, argType) => Object.assign({}, argType, {
  name: argType.name || key,
  description: argType.description || key,
  toolbar: Object.assign({}, argType.toolbar, {
    items: argType.toolbar.items.map(_item => {
      const item = typeof _item === 'string' ? {
        value: _item,
        title: _item
      } : _item; // Cater for the special type "reset" which will reset value and also icon
      // of toolbar button if any icon was present on toolbar to begin with

      if (item.type === 'reset' && argType.toolbar.icon) {
        item.icon = argType.toolbar.icon;
        item.hideIcon = true;
      }

      return Object.assign({}, defaultItemValues, item);
    })
  })
});