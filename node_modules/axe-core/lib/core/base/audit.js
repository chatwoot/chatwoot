import Rule from './rule';
import Check from './check';
import standards from '../../standards';
import RuleResult from './rule-result';
import {
  clone,
  queue,
  preload,
  findBy,
  ruleShouldRun,
  performanceTimer
} from '../utils';
import doT from '@deque/dot';
import log from '../log';
import constants from '../constants';

const dotRegex = /\{\{.+?\}\}/g;

function getDefaultOrigin() {
  // @see https://html.spec.whatwg.org/multipage/webappapis.html#dom-origin-dev
  // window.origin does not exist in ie11
  if (window.origin) {
    return window.origin;
  }
  // window.location does not exist in node when we run the build
  if (window.location && window.location.origin) {
    return window.location.origin;
  }
}

/*eslint no-unused-vars: 0*/
function getDefaultConfiguration(audit) {
  var config;
  if (audit) {
    config = clone(audit);
    // Commons are configured into axe like everything else,
    // however because things go funky if we have multiple commons objects
    // we're not using the copy of that.
    config.commons = audit.commons;
  } else {
    config = {};
  }

  config.reporter = config.reporter || null;
  config.noHtml = config.noHtml || false;

  if (!config.allowedOrigins) {
    const defaultOrigin = getDefaultOrigin();
    config.allowedOrigins = defaultOrigin ? [defaultOrigin] : [];
  }

  config.rules = config.rules || [];
  config.checks = config.checks || [];
  config.data = { checks: {}, rules: {}, ...config.data };
  return config;
}

function unpackToObject(collection, audit, method) {
  var i, l;
  for (i = 0, l = collection.length; i < l; i++) {
    audit[method](collection[i]);
  }
}

/**
 * Merge two check locales (a, b), favoring `b`.
 *
 * Both locale `a` and the returned shape resemble:
 *
 *    {
 *      impact: string,
 *      messages: {
 *        pass: string | function,
 *        fail: string | function,
 *        incomplete: string | {
 *          [key: string]: string | function
 *        }
 *      }
 *    }
 *
 * Locale `b` follows the `axe.CheckLocale` shape and resembles:
 *
 *    {
 *      pass: string,
 *      fail: string,
 *      incomplete: string | { [key: string]: string }
 *    }
 */

const mergeCheckLocale = (a, b) => {
  let { pass, fail } = b;
  // If the message(s) are Strings, they have not yet been run
  // thru doT (which will return a Function).
  if (typeof pass === 'string' && dotRegex.test(pass)) {
    pass = doT.compile(pass);
  }
  if (typeof fail === 'string' && dotRegex.test(fail)) {
    fail = doT.compile(fail);
  }
  return {
    ...a,
    messages: {
      pass: pass || a.messages.pass,
      fail: fail || a.messages.fail,
      incomplete:
        typeof a.messages.incomplete === 'object'
          ? // TODO: for compleness-sake, we should be running
            // incomplete messages thru doT as well. This was
            // out-of-scope for runtime localization, but should
            // eventually be addressed.
            { ...a.messages.incomplete, ...b.incomplete }
          : b.incomplete
    }
  };
};

/**
 * Merge two rule locales (a, b), favoring `b`.
 */

const mergeRuleLocale = (a, b) => {
  let { help, description } = b;
  // If the message(s) are Strings, they have not yet been run
  // thru doT (which will return a Function).
  if (typeof help === 'string' && dotRegex.test(help)) {
    help = doT.compile(help);
  }
  if (typeof description === 'string' && dotRegex.test(description)) {
    description = doT.compile(description);
  }
  return {
    ...a,
    help: help || a.help,
    description: description || a.description
  };
};

/**
 * Merge two failure messages (a, b), favoring `b`.
 */

const mergeFailureMessage = (a, b) => {
  let { failureMessage } = b;
  // If the message(s) are Strings, they have not yet been run
  // thru doT (which will return a Function).
  if (typeof failureMessage === 'string' && dotRegex.test(failureMessage)) {
    failureMessage = doT.compile(failureMessage);
  }
  return {
    ...a,
    failureMessage: failureMessage || a.failureMessage
  };
};

/**
 * Merge two incomplete fallback messages (a, b), favoring `b`.
 */

const mergeFallbackMessage = (a, b) => {
  if (typeof b === 'string' && dotRegex.test(b)) {
    b = doT.compile(b);
  }
  return b || a;
};

/**
 * Constructor which holds configured rules and information about the document under test
 */
class Audit {
  constructor(audit) {
    // defaults
    this.lang = 'en';
    this.defaultConfig = audit;
    this.standards = standards;
    this._init();
    // A copy of the "default" locale. This will be set if the user
    // provides a new locale to `axe.configure()` and used to undo
    // changes in `axe.reset()`.
    this._defaultLocale = null;
  }
  /**
   * Build and set the previous locale. Will noop if a previous
   * locale was already set, as we want the ability to "reset"
   * to the default ("first") configuration.
   */
  _setDefaultLocale() {
    if (this._defaultLocale) {
      return;
    }
    const locale = {
      checks: {},
      rules: {},
      failureSummaries: {},
      incompleteFallbackMessage: '',
      lang: this.lang
    };
    // XXX: unable to use `for-of` here, as doing so would
    // require us to polyfill `Symbol`.
    const checkIDs = Object.keys(this.data.checks);
    for (let i = 0; i < checkIDs.length; i++) {
      const id = checkIDs[i];
      const check = this.data.checks[id];
      const { pass, fail, incomplete } = check.messages;
      locale.checks[id] = {
        pass,
        fail,
        incomplete
      };
    }
    const ruleIDs = Object.keys(this.data.rules);
    for (let i = 0; i < ruleIDs.length; i++) {
      const id = ruleIDs[i];
      const rule = this.data.rules[id];
      const { description, help } = rule;
      locale.rules[id] = { description, help };
    }
    const failureSummaries = Object.keys(this.data.failureSummaries);
    for (let i = 0; i < failureSummaries.length; i++) {
      const type = failureSummaries[i];
      const failureSummary = this.data.failureSummaries[type];
      const { failureMessage } = failureSummary;
      locale.failureSummaries[type] = { failureMessage };
    }
    locale.incompleteFallbackMessage = this.data.incompleteFallbackMessage;
    this._defaultLocale = locale;
  }
  /**
   * Reset the locale to the "default".
   */
  _resetLocale() {
    // If the default locale has not already been set, we can exit early.
    const defaultLocale = this._defaultLocale;
    if (!defaultLocale) {
      return;
    }
    // Apply the default locale
    this.applyLocale(defaultLocale);
  }
  /**
   * Apply locale for the given `checks`.
   */
  _applyCheckLocale(checks) {
    const keys = Object.keys(checks);
    for (let i = 0; i < keys.length; i++) {
      const id = keys[i];
      if (!this.data.checks[id]) {
        throw new Error(`Locale provided for unknown check: "${id}"`);
      }
      this.data.checks[id] = mergeCheckLocale(this.data.checks[id], checks[id]);
    }
  }
  /**
   * Apply locale for the given `rules`.
   */
  _applyRuleLocale(rules) {
    const keys = Object.keys(rules);
    for (let i = 0; i < keys.length; i++) {
      const id = keys[i];
      if (!this.data.rules[id]) {
        throw new Error(`Locale provided for unknown rule: "${id}"`);
      }
      this.data.rules[id] = mergeRuleLocale(this.data.rules[id], rules[id]);
    }
  }
  /**
   * Apply locale for the given failureMessage
   */
  _applyFailureSummaries(messages) {
    const keys = Object.keys(messages);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (!this.data.failureSummaries[key]) {
        throw new Error(`Locale provided for unknown failureMessage: "${key}"`);
      }
      this.data.failureSummaries[key] = mergeFailureMessage(
        this.data.failureSummaries[key],
        messages[key]
      );
    }
  }
  /**
   * Apply the given `locale`.
   *
   * @param {axe.Locale}
   */
  applyLocale(locale) {
    this._setDefaultLocale();
    if (locale.checks) {
      this._applyCheckLocale(locale.checks);
    }
    if (locale.rules) {
      this._applyRuleLocale(locale.rules);
    }
    if (locale.failureSummaries) {
      this._applyFailureSummaries(locale.failureSummaries, 'failureSummaries');
    }
    if (locale.incompleteFallbackMessage) {
      this.data.incompleteFallbackMessage = mergeFallbackMessage(
        this.data.incompleteFallbackMessage,
        locale.incompleteFallbackMessage
      );
    }
    if (locale.lang) {
      this.lang = locale.lang;
    }
  }
  /**
   * Set the normalized allowed origins.
   *
   * @param {String[]}
   */
  setAllowedOrigins(allowedOrigins) {
    const defaultOrigin = getDefaultOrigin();

    this.allowedOrigins = [];
    for (const origin of allowedOrigins) {
      if (origin === constants.allOrigins) {
        // No other origins needed. Set '*' and exit
        this.allowedOrigins = ['*'];
        return;
      } else if (origin !== constants.sameOrigin) {
        this.allowedOrigins.push(origin);
      } else if (defaultOrigin) {
        // sameOrigin, only if the default is known
        this.allowedOrigins.push(defaultOrigin);
      }
    }
  }
  /**
   * Initializes the rules and checks
   */
  _init() {
    var audit = getDefaultConfiguration(this.defaultConfig);
    this.lang = audit.lang || 'en';
    this.reporter = audit.reporter;
    this.commands = {};
    this.rules = [];
    this.checks = {};
    this.brand = 'axe';
    this.application = 'axeAPI';
    this.tagExclude = ['experimental'];
    this.noHtml = audit.noHtml;
    this.allowedOrigins = audit.allowedOrigins;
    unpackToObject(audit.rules, this, 'addRule');
    unpackToObject(audit.checks, this, 'addCheck');
    this.data = {};
    this.data.checks = (audit.data && audit.data.checks) || {};
    this.data.rules = (audit.data && audit.data.rules) || {};
    this.data.failureSummaries =
      (audit.data && audit.data.failureSummaries) || {};
    this.data.incompleteFallbackMessage =
      (audit.data && audit.data.incompleteFallbackMessage) || '';
    this._constructHelpUrls(); // create default helpUrls
  }
  /**
   * Adds a new command to the audit
   */
  registerCommand(command) {
    this.commands[command.id] = command.callback;
  }
  /**
   * Adds a new rule to the Audit.  If a rule with specified ID already exists, it will be overridden
   * @param {Object} spec Rule specification object
   */
  addRule(spec) {
    if (spec.metadata) {
      this.data.rules[spec.id] = spec.metadata;
    }
    const rule = this.getRule(spec.id);
    if (rule) {
      rule.configure(spec);
    } else {
      this.rules.push(new Rule(spec, this));
    }
  }
  /**
   * Adds a new check to the Audit.  If a Check with specified ID already exists, it will be
   * reconfigured
   *
   * @param {Object} spec Check specification object
   */
  addCheck(spec) {
    /*eslint no-eval: 0 */

    const metadata = spec.metadata;
    if (typeof metadata === 'object') {
      this.data.checks[spec.id] = metadata;
      // Transform messages into functions:
      if (typeof metadata.messages === 'object') {
        Object.keys(metadata.messages)
          .filter(
            prop =>
              metadata.messages.hasOwnProperty(prop) &&
              typeof metadata.messages[prop] === 'string'
          )
          .forEach(prop => {
            if (metadata.messages[prop].indexOf('function') === 0) {
              metadata.messages[prop] = new Function(
                'return ' + metadata.messages[prop] + ';'
              )();
            }
          });
      }
    }
    if (this.checks[spec.id]) {
      this.checks[spec.id].configure(spec);
    } else {
      this.checks[spec.id] = new Check(spec);
    }
  }
  /**
   * Runs the Audit; which in turn should call `run` on each rule.
   * @async
   * @param  {Context}   context The scope definition/context for analysis (include/exclude)
   * @param  {Object}    options Options object to pass into rules and/or disable rules or checks
   * @param  {Function} fn       Callback function to fire when audit is complete
   */
  run(context, options, resolve, reject) {
    this.normalizeOptions(options);

    // TODO: es-modules_selectCache
    axe._selectCache = [];
    // get a list of rules to run NOW vs. LATER (later are preload assets dependent rules)
    const allRulesToRun = getRulesToRun(this.rules, context, options);
    const runNowRules = allRulesToRun.now;
    const runLaterRules = allRulesToRun.later;
    // init a NOW queue for rules to run immediately
    const nowRulesQueue = queue();
    // construct can run NOW rules into NOW queue
    runNowRules.forEach(rule => {
      nowRulesQueue.defer(getDefferedRule(rule, context, options));
    });
    // init a PRELOADER queue to start preloading assets
    const preloaderQueue = queue();
    // defer preload if preload dependent rules exist
    if (runLaterRules.length) {
      preloaderQueue.defer(resolve => {
        // handle both success and fail of preload
        // and resolve, to allow to run all checks
        preload(options)
          .then(assets => resolve(assets))
          .catch(err => {
            /**
             * Note:
             * we do not reject, to allow other (non-preload) rules to `run`
             * -> instead we resolve as `undefined`
             */
            console.warn(`Couldn't load preload assets: `, err);
            resolve(undefined);
          });
      });
    }
    // defer now and preload queue to run immediately
    const queueForNowRulesAndPreloader = queue();
    queueForNowRulesAndPreloader.defer(nowRulesQueue);
    queueForNowRulesAndPreloader.defer(preloaderQueue);
    // invoke the now queue
    queueForNowRulesAndPreloader
      .then(nowRulesAndPreloaderResults => {
        // interpolate results into separate variables
        const assetsFromQueue = nowRulesAndPreloaderResults.pop();
        if (assetsFromQueue && assetsFromQueue.length) {
          // result is a queue (again), hence the index resolution
          // assets is either an object of key value pairs of asset type and values
          // eg: cssom: [stylesheets]
          // or undefined if preload failed
          const assets = assetsFromQueue[0];
          // extend context with preloaded assets
          if (assets) {
            context = {
              ...context,
              ...assets
            };
          }
        }
        // the reminder of the results are RuleResults
        const nowRulesResults = nowRulesAndPreloaderResults[0];
        // if there are no rules to run LATER - resolve with rule results
        if (!runLaterRules.length) {
          // remove the cache
          axe._selectCache = undefined;
          // resolve
          resolve(nowRulesResults.filter(result => !!result));
          return;
        }
        // init a LATER queue for rules that are dependant on preloaded assets
        const laterRulesQueue = queue();
        runLaterRules.forEach(rule => {
          const deferredRule = getDefferedRule(rule, context, options);
          laterRulesQueue.defer(deferredRule);
        });
        // invoke the later queue
        laterRulesQueue
          .then(laterRuleResults => {
            // remove the cache
            axe._selectCache = undefined;
            // resolve
            resolve(
              nowRulesResults
                .concat(laterRuleResults)
                .filter(result => !!result)
            );
          })
          .catch(reject);
      })
      .catch(reject);
  }
  /**
   * Runs Rule `after` post processing functions
   * @param  {Array} results  Array of RuleResults to postprocess
   * @param  {Mixed} options  Options object to pass into rules and/or disable rules or checks
   */
  after(results, options) {
    var rules = this.rules;
    return results.map(ruleResult => {
      var rule = findBy(rules, 'id', ruleResult.id);
      if (!rule) {
        // If you see this, you're probably running the Mocha tests with the axe extension installed
        throw new Error(
          'Result for unknown rule. You may be running mismatch axe-core versions'
        );
      }
      return rule.after(ruleResult, options);
    });
  }
  /**
   * Get the rule with a given ID
   * @param  {string}
   * @return {Rule}
   */
  getRule(ruleId) {
    return this.rules.find(rule => rule.id === ruleId);
  }
  /**
   * Ensure all rules that are expected to run exist
   * @throws {Error} If any tag or rule specified in options is unknown
   * @param  {Object} options  Options object
   * @return {Object}          Validated options object
   */
  normalizeOptions(options) {
    var audit = this;
    const tags = [];
    const ruleIds = [];
    audit.rules.forEach(rule => {
      ruleIds.push(rule.id);
      rule.tags.forEach(tag => {
        if (!tags.includes(tag)) {
          tags.push(tag);
        }
      });
    });
    // Validate runOnly
    if (typeof options.runOnly === 'object') {
      if (Array.isArray(options.runOnly)) {
        const hasTag = options.runOnly.find(value => tags.includes(value));
        const hasRule = options.runOnly.find(value => ruleIds.includes(value));
        if (hasTag && hasRule) {
          throw new Error('runOnly cannot be both rules and tags');
        }
        if (hasRule) {
          options.runOnly = {
            type: 'rule',
            values: options.runOnly
          };
        } else {
          options.runOnly = {
            type: 'tag',
            values: options.runOnly
          };
        }
      }
      const only = options.runOnly;
      if (only.value && !only.values) {
        only.values = only.value;
        delete only.value;
      }
      if (!Array.isArray(only.values) || only.values.length === 0) {
        throw new Error('runOnly.values must be a non-empty array');
      }
      // Check if every value in options.runOnly is a known rule ID
      if (['rule', 'rules'].includes(only.type)) {
        only.type = 'rule';
        only.values.forEach(ruleId => {
          if (!ruleIds.includes(ruleId)) {
            throw new Error('unknown rule `' + ruleId + '` in options.runOnly');
          }
        });
        // Validate 'tags' (e.g. anything not 'rule')
      } else if (['tag', 'tags', undefined].includes(only.type)) {
        only.type = 'tag';
        const unmatchedTags = only.values.filter(tag => !tags.includes(tag));
        if (unmatchedTags.length !== 0) {
          log('Could not find tags `' + unmatchedTags.join('`, `') + '`');
        }
      } else {
        throw new Error(`Unknown runOnly type '${only.type}'`);
      }
    }
    if (typeof options.rules === 'object') {
      Object.keys(options.rules).forEach(ruleId => {
        if (!ruleIds.includes(ruleId)) {
          throw new Error('unknown rule `' + ruleId + '` in options.rules');
        }
      });
    }
    return options;
  }
  /*
   * Updates the default options and then applies them
   * @param  {Mixed} options  Options object
   */
  setBranding(branding) {
    const previous = {
      brand: this.brand,
      application: this.application
    };
    if (
      branding &&
      branding.hasOwnProperty('brand') &&
      branding.brand &&
      typeof branding.brand === 'string'
    ) {
      this.brand = branding.brand;
    }
    if (
      branding &&
      branding.hasOwnProperty('application') &&
      branding.application &&
      typeof branding.application === 'string'
    ) {
      this.application = branding.application;
    }
    this._constructHelpUrls(previous);
  }
  _constructHelpUrls(previous = null) {
    // TODO: es-modules-version
    var version = (axe.version.match(/^[1-9][0-9]*\.[0-9]+/) || ['x.y'])[0];
    this.rules.forEach(rule => {
      if (!this.data.rules[rule.id]) {
        this.data.rules[rule.id] = {};
      }
      const metaData = this.data.rules[rule.id];
      if (
        typeof metaData.helpUrl !== 'string' ||
        (previous &&
          metaData.helpUrl === getHelpUrl(previous, rule.id, version))
      ) {
        metaData.helpUrl = getHelpUrl(this, rule.id, version);
      }
    });
  }
  /**
   * Reset the default rules, checks and meta data
   */
  resetRulesAndChecks() {
    this._init();
    this._resetLocale();
  }
}

/**
 * Splits a given array of rules to two, with rules that can be run immediately and one's that are dependent on preloadedAssets
 * @method getRulesToRun
 * @param {Array<Object>} rules complete list of rules
 * @param {Object} context
 * @param {Object} options
 * @return {Object} out, an object containing two arrays, one being list of rules to run now and list of rules to run later
 * @private
 */
function getRulesToRun(rules, context, options) {
  // entry object for reduce function below
  const base = {
    now: [],
    later: []
  };

  // iterate through rules and separate out rules that need to be run now vs later
  const splitRules = rules.reduce((out, rule) => {
    // ensure rule can run
    if (!ruleShouldRun(rule, context, options)) {
      return out;
    }

    // does rule require preload assets - push to later array
    if (rule.preload) {
      out.later.push(rule);
      return out;
    }

    // default to now array
    out.now.push(rule);

    // return
    return out;
  }, base);

  // return
  return splitRules;
}

/**
 * Convenience method, that consturcts a rule `run` function that can be deferred
 * @param {Object} rule rule to be deferred
 * @param {Object} context context object essential to be passed into rule `run`
 * @param {Object} options normalised options to be passed into rule `run`
 * @param {Object} assets (optional) preloaded assets to be passed into rule and checks (if the rule is preload dependent)
 * @return {Function} a deferrable function for rule
 */
function getDefferedRule(rule, context, options) {
  // init performance timer of requested via options
  if (options.performanceTimer) {
    performanceTimer.mark('mark_rule_start_' + rule.id);
  }

  return (resolve, reject) => {
    // invoke `rule.run`
    rule.run(
      context,
      options,
      // resolve callback for rule `run`
      ruleResult => {
        // resolve
        resolve(ruleResult);
      },
      // reject callback for rule `run`
      err => {
        // if debug - construct error details
        if (!options.debug) {
          const errResult = Object.assign(new RuleResult(rule), {
            result: constants.CANTTELL,
            description: 'An error occured while running this rule',
            message: err.message,
            stack: err.stack,
            error: err,
            // Add a serialized reference to the node the rule failed on for easier debugging.
            // See https://github.com/dequelabs/axe-core/issues/1317.
            errorNode: err.errorNode
          });
          // resolve
          resolve(errResult);
        } else {
          // reject
          reject(err);
        }
      }
    );
  };
}

/**
 * For all the rules, create the helpUrl and add it to the data for that rule
 */
function getHelpUrl({ brand, application, lang }, ruleId, version) {
  return (
    constants.helpUrlBase +
    brand +
    '/' +
    (version || axe.version.substring(0, axe.version.lastIndexOf('.'))) +
    '/' +
    ruleId +
    '?application=' +
    encodeURIComponent(application) +
    (lang && lang !== 'en' ? '&lang=' + encodeURIComponent(lang) : '')
  );
}

export default Audit;
