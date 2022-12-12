import querySelectorAllFilter from './query-selector-all-filter';

/**
 * querySelectorAll implementation that operates on the flattened tree (supports shadow DOM)
 * @method querySelectorAll
 * @memberof axe.utils
 * @param	{NodeList} domTree flattened tree collection to search
 * @param	{String} selector String containing one or more CSS selectors separated by commas
 * @return {NodeList} Elements matched by any of the selectors
 */
export function querySelectorAll(domTree, selector) {
  return querySelectorAllFilter(domTree, selector);
}

export default querySelectorAll;
