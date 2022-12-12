const joinStr = ' > ';

/**
 * Flatten an ancestry path of an iframe result into a string.
 */
function getFramePath(ancestry, nodePath) {
  // remove the last path so we're only left with iframe paths
  ancestry = ancestry.slice(0, ancestry.length - 1);

  if (nodePath) {
    ancestry = ancestry.concat(nodePath);
  }

  return ancestry.join(joinStr);
}

function headingOrderAfter(results) {
  if (results.length < 2) {
    return results;
  }

  /**
   * In order to correctly return heading order results (even for
   * headings that may be out of the current context) we need to
   * construct an in-order list of all headings on the page,
   * including headings from iframes.
   *
   * To do this we will find all nested headingOrders (i.e. those
   * from iframes) and then determine where those results fit into
   * the top-level heading order. once we've put all the heading
   * orders into their proper place, we can then determine which
   * headings are not in the correct order.
   **/

  // start by replacing all array ancestry paths with a flat string
  // path
  const pageResult = results.find(result => !result.node._fromFrame);
  let headingOrder = pageResult.data.headingOrder.map(heading => {
    return {
      ...heading,
      ancestry: getFramePath(pageResult.node.ancestry, heading.ancestry)
    };
  });

  // find all nested headindOrders
  const nestedResults = results.filter(result => {
    return result.data && result.data.headingOrder && result.node._fromFrame;
  });

  // update the path of nodes to include the iframe path
  nestedResults.forEach(result => {
    result.data.headingOrder = result.data.headingOrder.map(heading => {
      return {
        ...heading,
        ancestry: getFramePath(result.node.ancestry, heading.ancestry)
      };
    });
  });

  /**
   * Determine where the iframe results fit into the top-level
   * heading order
   */
  function getFrameIndex(result) {
    const path = getFramePath(result.node.ancestry);
    const heading = headingOrder.find(heading => {
      return heading.ancestry === path;
    });
    return headingOrder.indexOf(heading);
  }

  /**
   * Replace an iframe placeholder with its results
   */
  function replaceFrameWithResults(index, result) {
    headingOrder.splice(index, 1, ...result.data.headingOrder);
  }

  // replace each iframe in the top-level heading order with its
  // results.
  // since nested iframe results can appear before their parent
  // iframe, we will just loop over the nested results and
  // piece-meal replace each iframe in the top-level heading order
  // with their results until we no longer have results to replace
  let replaced = false;
  while (nestedResults.length) {
    for (let i = 0; i < nestedResults.length; ) {
      const nestedResult = nestedResults[i];
      const index = getFrameIndex(nestedResult);

      if (index !== -1) {
        replaceFrameWithResults(index, nestedResult);
        replaced = true;

        // remove the nested result from the list
        nestedResults.splice(i, 1);
      } else {
        i++;
      }
    }

    // something went wrong if we can't replace an iframe in
    // the top-level results
    if (!replaced) {
      throw new Error('Unable to find parent iframe of heading-order results');
    }
  }

  // replace the ancestry path with information about the result
  results.forEach(result => {
    const path = result.node.ancestry.join(joinStr);
    const heading = headingOrder.find(heading => {
      return heading.ancestry === path;
    });
    const index = headingOrder.indexOf(heading);
    headingOrder.splice(index, 1, {
      level: headingOrder[index].level,
      result
    });
  });

  // remove any iframes that aren't in context (level == -1)
  headingOrder = headingOrder.filter(heading => heading.level > 0);

  // now make sure all headings are in the correct order
  for (let i = 1; i < results.length; i++) {
    const result = results[i];
    const heading = headingOrder.find(heading => {
      return heading.result === result;
    });
    const index = headingOrder.indexOf(heading);
    const currLevel = headingOrder[index].level;
    const prevLevel = headingOrder[index - 1].level;
    if (currLevel - prevLevel > 1) {
      result.result = false;
    }
  }

  return results;
}

export default headingOrderAfter;
