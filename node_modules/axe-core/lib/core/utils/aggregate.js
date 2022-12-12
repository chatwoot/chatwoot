/**
 * From a list of values, find the one with the greatest weight according to
 * the supplied map
 * @param  {object} params Contains 3 properties:
 * - map: a map indicating the order of values to run in
 *        example: ['small', 'medium', 'large']
 * - values: Array of values to take the highest from
 * - initial: optional starting value
 */
function aggregate(map, values, initial) {
  values = values.slice();
  if (initial) {
    values.push(initial);
  }

  var sorting = values.map(val => map.indexOf(val)).sort(); // Stupid NodeJS array.sort functor doesn't work!!

  return map[sorting.pop()];
}

export default aggregate;
