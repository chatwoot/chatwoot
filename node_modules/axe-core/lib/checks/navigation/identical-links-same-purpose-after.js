/**
 * Check if two given objects are the same (Note: this fn is not extensive in terms of depth equality)
 * @param {Object} a object a, to compare
 * @param {*} b object b, to compare
 * @returns {Boolean}
 */
function isIdenticalObject(a, b) {
  if (!a || !b) {
    return false;
  }

  const aProps = Object.getOwnPropertyNames(a);
  const bProps = Object.getOwnPropertyNames(b);

  if (aProps.length !== bProps.length) {
    return false;
  }

  const result = aProps.every(propName => {
    const aValue = a[propName];
    const bValue = b[propName];

    if (typeof aValue !== typeof bValue) {
      return false;
    }

    if (typeof aValue === `object` || typeof bValue === `object`) {
      return isIdenticalObject(aValue, bValue);
    }

    return aValue === bValue;
  });

  return result;
}

function identicalLinksSamePurposeAfter(results) {
  /**
   * Skip, as no results to curate
   */
  if (results.length < 2) {
    return results;
  }

  /**
   * Filter results for which `result` is undefined & thus `data`, `relatedNodes` are undefined
   */
  const incompleteResults = results.filter(
    ({ result }) => result !== undefined
  );

  /**
   * for each result
   * - get other results with matching accessible name
   * - check if same purpose is served
   * - if not change `result` to `undefined`
   * - construct a list of unique results with relatedNodes to return
   */
  const uniqueResults = [];
  const nameMap = {};

  for (let index = 0; index < incompleteResults.length; index++) {
    const currentResult = incompleteResults[index];

    const { name, urlProps } = currentResult.data;
    /**
     * This is to avoid duplications in the `nodeMap`
     */
    if (nameMap[name]) {
      continue;
    }

    const sameNameResults = incompleteResults.filter(
      ({ data }, resultNum) => data.name === name && resultNum !== index
    );
    const isSameUrl = sameNameResults.every(({ data }) =>
      isIdenticalObject(data.urlProps, urlProps)
    );

    /**
     * when identical nodes exists but do not resolve to same url, flag result as `incomplete`
     */
    if (sameNameResults.length && !isSameUrl) {
      currentResult.result = undefined;
    }

    /**
     *  -> deduplicate results (for both `pass` or `incomplete`) and add `relatedNodes` if any
     */
    currentResult.relatedNodes = [];
    currentResult.relatedNodes.push(
      ...sameNameResults.map(node => node.relatedNodes[0])
    );

    /**
     * Update `nodeMap` with `sameNameResults`
     */
    nameMap[name] = sameNameResults;

    uniqueResults.push(currentResult);
  }

  return uniqueResults;
}

export default identicalLinksSamePurposeAfter;
