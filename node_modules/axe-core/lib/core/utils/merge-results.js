import DqElement from './dq-element';
import getAllChecks from './get-all-checks';
import nodeSorter from './node-sorter';
import findBy from './find-by';

/**
 * Adds the owning frame's CSS selector onto each instance of DqElement
 * @private
 * @param	{Array} resultSet `nodes` array on a `RuleResult`
 * @param	{HTMLElement} frameElement	The frame element
 * @param	{String} frameSelector		 Unique CSS selector for the frame
 */
function pushFrame(resultSet, dqFrame, options) {
  resultSet.forEach(res => {
    res.node = DqElement.fromFrame(res.node, options, dqFrame);
    const checks = getAllChecks(res);

    checks.forEach(check => {
      check.relatedNodes = check.relatedNodes.map(node =>
        DqElement.fromFrame(node, options, dqFrame)
      );
    });
  });
}

/**
 * Adds `to` to `from` and then re-sorts by DOM order
 * @private
 * @param	{Array} target	`nodes` array on a `RuleResult`
 * @param	{Array} to	 `nodes` array on a `RuleResult`
 * @return {Array}			The merged and sorted result
 */
function spliceNodes(target, to) {
  const firstFromFrame = to[0].node;

  for (let i = 0; i < target.length; i++) {
    const node = target[i].node;
    const sorterResult = nodeSorter(
      { actualNode: node.element },
      { actualNode: firstFromFrame.element }
    );

    if (
      sorterResult > 0 ||
      (sorterResult === 0 &&
        firstFromFrame.selector.length < node.selector.length)
    ) {
      target.splice.apply(target, [i, 0].concat(to));
      return;
    }
  }

  target.push.apply(target, to);
}

function normalizeResult(result) {
  if (!result || !result.results) {
    return null;
  }

  if (!Array.isArray(result.results)) {
    return [result.results];
  }

  if (!result.results.length) {
    return null;
  }

  return result.results;
}

/**
 * Merges one or more RuleResults (possibly from different frames) into one RuleResult
 * @private
 * @param	{Array} frameResults	Array of objects including the RuleResults as `results` and frame as `frame`
 * @return {Array}							The merged RuleResults; should only have one result per rule
 */
function mergeResults(frameResults, options) {
  const mergedResult = [];
  frameResults.forEach(frameResult => {
    const results = normalizeResult(frameResult);
    if (!results || !results.length) {
      return;
    }

    let dqFrame;
    if (frameResult.frameElement) {
      const spec = { selector: [frameResult.frame] };
      dqFrame = new DqElement(frameResult.frameElement, options, spec);
    }

    results.forEach(ruleResult => {
      if (ruleResult.nodes && dqFrame) {
        pushFrame(ruleResult.nodes, dqFrame, options);
      }

      var res = findBy(mergedResult, 'id', ruleResult.id);
      if (!res) {
        mergedResult.push(ruleResult);
      } else {
        if (ruleResult.nodes.length) {
          spliceNodes(res.nodes, ruleResult.nodes);
        }
      }
    });
  });

  // Only sort results if we have the ability to run
  // document position (such as serial node context) and if
  // we have more than 1 result
  if (frameResults.length > 1 && window && window.Node) {
    mergedResult.forEach(result => {
      if (result.nodes) {
        result.nodes.sort((a, b) => {
          const aNode = a.node.element;
          const bNode = b.node.element;

          // only sort if the nodes are from different frames
          if (aNode !== bNode && (a.node._fromFrame || b.node._fromFrame)) {
            return nodeSorter(aNode, bNode);
          }

          return 0;
        });
      }
    });
  }

  return mergedResult;
}

export default mergeResults;
