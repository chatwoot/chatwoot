const disallowedCycleableItemTypes = ['reset'];
export const createCycleValueArray = items => {
  // Do not allow items in the cycle arrays that are conditional in placement
  const valueArray = items.filter(item => !disallowedCycleableItemTypes.includes(item.type)).map(item => item.value);
  return valueArray;
};