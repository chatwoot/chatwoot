import { values } from './object';

export const range = (start, end) => {
  const result = [];

  for (let i = start; i < end; i++) {
    result.push(i);
  }

  return result;
};

export const flatten = lists => lists.reduce((x, y) => x.concat(y), []);

export const from = list => {
  if (!list.length) {
    return [];
  }

  const result = [];

  for (let i = 0; i < list.length; i++) {
    result.push(list[i]);
  }

  return result;
};

export const findIndexes = (l, key) => l.reduce((a, e, i) => {
  if (e[key]) {
    a.push(i);
  }

  return a;
}, []);

/**
 * Returns the first index that satisfies the matching function, or -1 if not found.
 *
 * Only necessary because of IE11 support.
 *
 * @param {Array} list - the list to search through
 * @param {Function} matchingFunction - the matching function
 *
 * @return {number} the matching index or -1 if not found
 */
export const findIndex = (list, matchingFunction) => {
  for (let i = 0; i < list.length; i++) {
    if (matchingFunction(list[i])) {
      return i;
    }
  }

  return -1;
};

/**
 * Returns whether the list contains the search element.
 *
 * Only necessary because of IE11 support.
 *
 * @param {Array} list - the list to search through
 * @param {*} searchElement - the element to look for
 *
 * @return {boolean} whether the list includes the search element or not
 */
export const includes = (list, searchElement) => {
  return list.some((element) => element === searchElement);
};

/**
 * Returns a union of the included lists provided each element can be identified by a key.
 *
 * @param {Array} list - list of lists to get the union of
 * @param {Function} keyFunction - the function to use as a key for each element
 *
 * @return {Array} the union of the arrays
 */
export const union = (lists, keyFunction) => {
  return values(lists.reduce((acc, list) => {
    list.forEach((el) => {
      acc[keyFunction(el)] = el;
    });

    return acc;
  }, {}));
};
