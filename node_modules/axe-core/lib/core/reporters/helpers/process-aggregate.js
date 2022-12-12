import constants from '../../constants';

function normalizeRelatedNodes(node, options) {
  ['any', 'all', 'none'].forEach(type => {
    if (!Array.isArray(node[type])) {
      return;
    }
    node[type]
      .filter(checkRes => Array.isArray(checkRes.relatedNodes))
      .forEach(checkRes => {
        checkRes.relatedNodes = checkRes.relatedNodes.map(relatedNode => {
          var res = {
            html: relatedNode.source
          };
          if (options.elementRef && !relatedNode.fromFrame) {
            res.element = relatedNode.element;
          }
          if (options.selectors !== false || relatedNode.fromFrame) {
            res.target = relatedNode.selector;
          }
          if (options.ancestry) {
            res.ancestry = relatedNode.ancestry;
          }
          if (options.xpath) {
            res.xpath = relatedNode.xpath;
          }
          return res;
        });
      });
  });
}

var resultKeys = constants.resultGroups;

/**
 * Configures the processing of axe results.
 *
 * @typedef ProcessOptions
 * @property {Array} resultsTypes limit the types of results to process ('passes', 'violations', etc.)
 * @property {Boolean} elementRef display node's element references
 * @property {Boolean} selectors display node's selectors
 * @property {Boolean} xpath display node's xpaths
 */

/**
 * Aggregate and process the axe results,
 * adding desired data to nodes and relatedNodes in each rule result.
 *
 * Prepares result data for reporters.
 *
 * @method processAggregate
 * @memberof helpers
 * @param	{Array} results
 * @param	{ProcessOptions} options
 * @return {Object}
 *
 */
function processAggregate(results, options) {
  var resultObject = axe.utils.aggregateResult(results);

  resultKeys.forEach(key => {
    if (options.resultTypes && !options.resultTypes.includes(key)) {
      // If the user asks us to, truncate certain finding types to maximum one finding
      (resultObject[key] || []).forEach(ruleResult => {
        if (Array.isArray(ruleResult.nodes) && ruleResult.nodes.length > 0) {
          ruleResult.nodes = [ruleResult.nodes[0]];
        }
      });
    }
    resultObject[key] = (resultObject[key] || []).map(ruleResult => {
      ruleResult = Object.assign({}, ruleResult);

      if (Array.isArray(ruleResult.nodes) && ruleResult.nodes.length > 0) {
        ruleResult.nodes = ruleResult.nodes.map(subResult => {
          if (typeof subResult.node === 'object') {
            subResult.html = subResult.node.source;
            if (options.elementRef && !subResult.node.fromFrame) {
              subResult.element = subResult.node.element;
            }
            if (options.selectors !== false || subResult.node.fromFrame) {
              subResult.target = subResult.node.selector;
            }
            if (options.ancestry) {
              subResult.ancestry = subResult.node.ancestry;
            }
            if (options.xpath) {
              subResult.xpath = subResult.node.xpath;
            }
          }
          delete subResult.result;
          delete subResult.node;

          normalizeRelatedNodes(subResult, options);

          return subResult;
        });
      }

      resultKeys.forEach(key => delete ruleResult[key]);
      delete ruleResult.pageLevel;
      delete ruleResult.result;

      return ruleResult;
    });
  });

  return resultObject;
}

export default processAggregate;
