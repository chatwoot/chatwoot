export const getSelectedItem = ({
  currentValue,
  items
}) => {
  const selectedItem = currentValue != null && items.find(item => item.value === currentValue);
  return selectedItem;
};
export const getSelectedIcon = ({
  currentValue,
  items
}) => {
  const selectedItem = getSelectedItem({
    currentValue,
    items
  });
  return selectedItem === null || selectedItem === void 0 ? void 0 : selectedItem.icon;
};
export const getSelectedTitle = ({
  currentValue,
  items
}) => {
  const selectedItem = getSelectedItem({
    currentValue,
    items
  });
  return selectedItem === null || selectedItem === void 0 ? void 0 : selectedItem.title;
};