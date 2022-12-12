/**
 * Searches and returns rules that contain a tag in the list of tags.
 * @param  {Array}   tags  Optional array of tags
 * @return {Array}  Array of rules
 */
function getRules(tags) {
  tags = tags || [];
  var matchingRules = !tags.length
    ? axe._audit.rules
    : axe._audit.rules.filter(item => {
        return !!tags.filter(tag => {
          return item.tags.indexOf(tag) !== -1;
        }).length;
      });

  var ruleData = axe._audit.data.rules || {};
  return matchingRules.map(matchingRule => {
    var rd = ruleData[matchingRule.id] || {};
    return {
      ruleId: matchingRule.id,
      description: rd.description,
      help: rd.help,
      helpUrl: rd.helpUrl,
      tags: matchingRule.tags
    };
  });
}

export default getRules;
