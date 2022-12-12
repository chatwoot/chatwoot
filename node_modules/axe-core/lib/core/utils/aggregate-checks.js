import constants from '../constants';
import aggregate from './aggregate';

const { CANTTELL_PRIO, FAIL_PRIO } = constants;
const checkMap = [];
checkMap[constants.PASS_PRIO] = true;
checkMap[constants.CANTTELL_PRIO] = null;
checkMap[constants.FAIL_PRIO] = false;

/**
 * Map over the any / all / none properties
 */
const checkTypes = ['any', 'all', 'none'];
function anyAllNone(obj, functor) {
  return checkTypes.reduce((out, type) => {
    out[type] = (obj[type] || []).map(val => functor(val, type));
    return out;
  }, {});
}

function aggregateChecks(nodeResOriginal) {
  // Create a copy
  const nodeResult = Object.assign({}, nodeResOriginal);

  // map each result value to a priority
  anyAllNone(nodeResult, (check, type) => {
    const i =
      typeof check.result === 'undefined' ? -1 : checkMap.indexOf(check.result);
    // default to cantTell
    check.priority = i !== -1 ? i : constants.CANTTELL_PRIO;

    if (type === 'none') {
      // For none, swap pass and fail outcomes.
      // none-type checks should pass when result is false rather than true.
      if (check.priority === constants.PASS_PRIO) {
        check.priority = constants.FAIL_PRIO;
      } else if (check.priority === constants.FAIL_PRIO) {
        check.priority = constants.PASS_PRIO;
      }
    }
  });

  // Find the result with the highest priority
  const priorities = {
    all: nodeResult.all.reduce((a, b) => Math.max(a, b.priority), 0),
    none: nodeResult.none.reduce((a, b) => Math.max(a, b.priority), 0),
    // get the lowest passing of 'any' defaulting
    // to 0 by wrapping around 4 to 0 (inapplicable)
    any: nodeResult.any.reduce((a, b) => Math.min(a, b.priority), 4) % 4
  };

  nodeResult.priority = Math.max(
    priorities.all,
    priorities.none,
    priorities.any
  );

  // Of each type, filter out all results not matching the final priority
  const impacts = [];
  checkTypes.forEach(type => {
    nodeResult[type] = nodeResult[type].filter(check => {
      return (
        check.priority === nodeResult.priority &&
        check.priority === priorities[type]
      );
    });
    nodeResult[type].forEach(check => impacts.push(check.impact));
  });

  // for failed nodes, define the impact
  if ([CANTTELL_PRIO, FAIL_PRIO].includes(nodeResult.priority)) {
    nodeResult.impact = aggregate(constants.impact, impacts);
  } else {
    nodeResult.impact = null;
  }

  // Delete the old result and priority properties
  anyAllNone(nodeResult, c => {
    delete c.result;
    delete c.priority;
  });

  // Convert the index to a result string value
  nodeResult.result = constants.results[nodeResult.priority];
  delete nodeResult.priority;

  return nodeResult;
}

export default aggregateChecks;
