import processMessage from './process-message';
import clone from './clone';
import findBy from './find-by';
import extendMetaData from './extend-meta-data';
import incompleteFallbackMessage from '../reporters/helpers/incomplete-fallback-msg';

/**
 * Construct incomplete message from check.data
 * @param  {Object} checkData Check result with reason specified
 * @param  {Object} messages Source data object with message options
 * @return  {String}
 * @private
 */
function getIncompleteReason(checkData, messages) {
  function getDefaultMsg(messages) {
    if (messages.incomplete && messages.incomplete.default) {
      // fall back to the default message if no reason specified
      return messages.incomplete.default;
    } else {
      return incompleteFallbackMessage();
    }
  }
  if (checkData && checkData.missingData) {
    try {
      var msg = messages.incomplete[checkData.missingData[0].reason];
      if (!msg) {
        throw new Error();
      }
      return msg;
    } catch (e) {
      if (typeof checkData.missingData === 'string') {
        // return a string with the appropriate reason
        return messages.incomplete[checkData.missingData];
      } else {
        return getDefaultMsg(messages);
      }
    }
  } else if (checkData && checkData.messageKey) {
    return messages.incomplete[checkData.messageKey];
  } else {
    return getDefaultMsg(messages);
  }
}

/**
 * Extend checksData with the correct result message
 * @param  {Object} checksData The check result data
 * @param  {Boolean} shouldBeTrue Result of pass/fail check run
 * @return {Function}
 * @private
 */
function extender(checksData, shouldBeTrue) {
  return check => {
    var sourceData = checksData[check.id] || {};
    var messages = sourceData.messages || {};
    var data = Object.assign({}, sourceData);
    delete data.messages;
    if (check.result === undefined) {
      // handle old doT template
      if (
        typeof messages.incomplete === 'object' &&
        !Array.isArray(check.data)
      ) {
        data.message = getIncompleteReason(check.data, messages);
      }

      // fallback to new process message style
      if (!data.message) {
        data.message = messages.incomplete;
      }
    } else {
      data.message =
        check.result === shouldBeTrue ? messages.pass : messages.fail;
    }

    // don't process doT template functions
    if (typeof data.message !== 'function') {
      data.message = processMessage(data.message, check.data);
    }

    extendMetaData(check, data);
  };
}

/**
 * Publish metadata from axe._audit.data
 * @param  {RuleResult} result Result to publish to
 * @private
 */
function publishMetaData(ruleResult) {
  // TODO: es-modules_audit
  var checksData = axe._audit.data.checks || {};
  var rulesData = axe._audit.data.rules || {};
  var rule = findBy(axe._audit.rules, 'id', ruleResult.id) || {};

  ruleResult.tags = clone(rule.tags || []);

  var shouldBeTrue = extender(checksData, true);
  var shouldBeFalse = extender(checksData, false);
  ruleResult.nodes.forEach(detail => {
    detail.any.forEach(shouldBeTrue);
    detail.all.forEach(shouldBeTrue);
    detail.none.forEach(shouldBeFalse);
  });
  extendMetaData(ruleResult, clone(rulesData[ruleResult.id] || {}));
}

export default publishMetaData;
