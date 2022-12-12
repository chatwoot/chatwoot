import constants from '../constants';

function copyToGroup(resultObject, subResult, group) {
  var resultCopy = Object.assign({}, subResult);
  resultCopy.nodes = (resultCopy[group] || []).concat();
  constants.resultGroups.forEach(group => {
    delete resultCopy[group];
  });
  resultObject[group].push(resultCopy);
}

/**
 * Calculates the result of a Rule based on its types and the result of its child Checks
 * @param  {RuleResult} ruleResult The RuleResult to calculate the result of
 */
function aggregateResult(results) {
  const resultObject = {};

  // Create an array for each type
  constants.resultGroups.forEach(groupName => (resultObject[groupName] = []));

  // Fill the array with nodes
  results.forEach(subResult => {
    if (subResult.error) {
      copyToGroup(resultObject, subResult, constants.CANTTELL_GROUP);
    } else if (subResult.result === constants.NA) {
      copyToGroup(resultObject, subResult, constants.NA_GROUP);
    } else {
      constants.resultGroups.forEach(group => {
        if (Array.isArray(subResult[group]) && subResult[group].length > 0) {
          copyToGroup(resultObject, subResult, group);
        }
      });
    }
  });
  return resultObject;
}

export default aggregateResult;
