import Context from '../base/context';
import teardown from './teardown';
import {
  getSelectorData,
  queue,
  performanceTimer,
  collectResultsFromFrames,
  mergeResults,
  publishMetaData,
  finalizeRuleResult
} from '../utils';
import log from '../log';

/**
 * Starts analysis on the current document and its subframes
 * @private
 * @param  {Object}   context  The `Context` specification object @see Context
 * @param  {Array}    options  Optional RuleOptions
 * @param  {Function} resolve  Called when done running rules, receives ([results : Object], teardown : Function)
 * @param  {Function} reject   Called when execution failed, receives (err : Error)
 */
function runRules(context, options, resolve, reject) {
  try {
    context = new Context(context);
    axe._tree = context.flatTree;
    axe._selectorData = getSelectorData(context.flatTree);
  } catch (e) {
    teardown();
    return reject(e);
  }

  var q = queue();
  var audit = axe._audit;

  if (options.performanceTimer) {
    performanceTimer.auditStart();
  }

  if (context.frames.length && options.iframes !== false) {
    q.defer((res, rej) => {
      collectResultsFromFrames(context, options, 'rules', null, res, rej);
    });
  }
  q.defer((res, rej) => {
    audit.run(context, options, res, rej);
  });
  q.then(data => {
    try {
      if (options.performanceTimer) {
        performanceTimer.auditEnd();
      }

      // Add wrapper object so that we may use the same "merge" function for results from inside and outside frames
      var results = mergeResults(
        data.map(results => {
          return { results };
        })
      );

      // after should only run once, so ensure we are in the top level window
      if (context.initiator) {
        results = audit.after(results, options);

        results.forEach(publishMetaData);
        results = results.map(finalizeRuleResult);
      }
      try {
        resolve(results, teardown);
      } catch (e) {
        teardown();
        log(e);
      }
    } catch (e) {
      teardown();
      reject(e);
    }
  }).catch(e => {
    teardown();
    reject(e);
  });
}

export default runRules;
