/**
 * How to add an item.
 * @param {string} item
 */
export function sentence (item) {
  if (typeof item === 'string') {
    return item[0].toUpperCase() + item.substr(1)
  }
  return item
}
