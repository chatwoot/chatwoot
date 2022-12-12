const rawReporter = (results, options, callback) => {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  // Guard against tests which don't pass an array as the first param here.
  if (!results || !Array.isArray(results)) {
    return callback(results);
  }

  const transformedResults = results.map(result => {
    const transformedResult = { ...result };
    const types = ['passes', 'violations', 'incomplete', 'inapplicable'];
    for (const type of types) {
      // Some tests don't include all of the types, so we have to guard against that here.
      // TODO: ensure tests always use "proper" results to avoid having these hacks in production code paths.
      if (transformedResult[type] && Array.isArray(transformedResult[type])) {
        transformedResult[type] = transformedResult[type].map(typeResult => ({
          ...typeResult,
          node: typeResult.node.toJSON()
        }));
      }
    }

    return transformedResult;
  });

  callback(transformedResults);
};

export default rawReporter;
