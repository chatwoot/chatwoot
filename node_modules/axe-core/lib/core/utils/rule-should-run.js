/**
 * Check if a rule matches the value of runOnly type=tag
 * @private
 * @param  {object} rule
 * @param  {object}	runOnly Value of runOnly with type=tags
 * @return {bool}
 */
function matchTags(rule, runOnly) {
  var include, exclude, matching;
  var defaultExclude =
    // TODO: es-modules_audit
    axe._audit && axe._audit.tagExclude ? axe._audit.tagExclude : [];

  // normalize include/exclude
  if (runOnly.hasOwnProperty('include') || runOnly.hasOwnProperty('exclude')) {
    // Wrap include and exclude if it's not already an array
    include = runOnly.include || [];
    include = Array.isArray(include) ? include : [include];

    exclude = runOnly.exclude || [];
    exclude = Array.isArray(exclude) ? exclude : [exclude];
    // add defaults, unless mentioned in include
    exclude = exclude.concat(
      defaultExclude.filter(tag => {
        return include.indexOf(tag) === -1;
      })
    );

    // Otherwise, only use the include value, ignore exclude
  } else {
    include = Array.isArray(runOnly) ? runOnly : [runOnly];
    // exclude the defaults not included
    exclude = defaultExclude.filter(tag => {
      return include.indexOf(tag) === -1;
    });
  }

  matching = include.some(tag => {
    return rule.tags.indexOf(tag) !== -1;
  });
  if (matching || (include.length === 0 && rule.enabled !== false)) {
    return exclude.every(tag => {
      return rule.tags.indexOf(tag) === -1;
    });
  } else {
    return false;
  }
}

/**
 * Determines whether a rule should run
 * @param  {Rule}    rule     The rule to test
 * @param  {Context} context  The context of the Audit
 * @param  {Object}  options  Options object
 * @return {Boolean}
 */
function ruleShouldRun(rule, context, options) {
  var runOnly = options.runOnly || {};
  var ruleOptions = (options.rules || {})[rule.id];

  // Never run page level rules if the context is not on the page
  if (rule.pageLevel && !context.page) {
    return false;

    // First, runOnly type rule overrides anything else
  } else if (runOnly.type === 'rule') {
    return runOnly.values.indexOf(rule.id) !== -1;

    // Second, if options.rules[rule].enabled is set, it overrides all
  } else if (ruleOptions && typeof ruleOptions.enabled === 'boolean') {
    return ruleOptions.enabled;

    // Third, if tags are set, look at those
  } else if (runOnly.type === 'tag' && runOnly.values) {
    return matchTags(rule, runOnly.values);

    // If nothing is set, only check for default excludes
  } else {
    return matchTags(rule, []);
  }
}

export default ruleShouldRun;
