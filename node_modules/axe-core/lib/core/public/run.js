import { getReporter } from './reporter';
import cache from '../base/cache';

function isContext(potential) {
  switch (true) {
    case typeof potential === 'string':
    case Array.isArray(potential):
    case window.Node && potential instanceof window.Node:
    case window.NodeList && potential instanceof window.NodeList:
      return true;

    case typeof potential !== 'object':
      return false;

    case potential.include !== undefined:
    case potential.exclude !== undefined:
    case typeof potential.length === 'number':
      return true;

    default:
      return false;
  }
}

var noop = function noop() {};

/**
 * Normalize the optional params of axe.run()
 * @param  {object}   context
 * @param  {object}   options
 * @param  {Function} callback
 * @return {object}            With 3 keys: context, options, callback
 */
function normalizeRunParams(context, options, callback) {
  const typeErr = new TypeError('axe.run arguments are invalid');

  // Determine the context
  if (!isContext(context)) {
    if (callback !== undefined) {
      // Either context is invalid or there are too many params
      throw typeErr;
    }
    // Set default and shift one over
    callback = options;
    options = context;
    context = document;
  }

  // Determine the options
  if (typeof options !== 'object') {
    if (callback !== undefined) {
      // Either options is invalid or there are too many params
      throw typeErr;
    }
    // Set default and shift one over
    callback = options;
    options = {};
  }

  // Set the callback or noop;
  if (typeof callback !== 'function' && callback !== undefined) {
    throw typeErr;
  }

  return {
    context: context,
    options: options,
    callback: callback || noop
  };
}

/**
 * Runs a number of rules against the provided HTML page and returns the
 * resulting issue list
 *
 * @param  {Object}   context  (optional) Defines the scope of the analysis
 * @param  {Object}   options  (optional) Set of options passed into rules or checks
 * @param  {Function} callback (optional) The callback when axe is done, given 2 params:
 *                             - Error    If any errors occured, otherwise null
 *                             - Results  The results object / array, or undefined on error
 * @return {Promise}           Resolves with the axe results. Only available when natively supported
 */
function run(context, options, callback) {
  if (!axe._audit) {
    throw new Error('No audit configured');
  }

  // if window or document are not defined and context was passed in
  // we can use it to configure them
  // NOTE: because our polyfills run first, the global window object
  // always exists but may not have things we expect
  const hasWindow = window && 'Node' in window && 'NodeList' in window;
  const hasDoc = !!document;
  if (!hasWindow || !hasDoc) {
    if (!context || !context.ownerDocument) {
      throw new Error(
        'Required "window" or "document" globals not defined and cannot be deduced from the context. ' +
          'Either set the globals before running or pass in a valid Element.'
      );
    }

    if (!hasDoc) {
      cache.set('globalDocumentSet', true);
      document = context.ownerDocument;
    }

    if (!hasWindow) {
      cache.set('globalWindowSet', true);
      window = document.defaultView;
    }
  }

  const args = normalizeRunParams(context, options, callback);
  context = args.context;
  options = args.options;
  callback = args.callback;

  // set defaults:
  options.reporter = options.reporter || axe._audit.reporter || 'v1';

  if (options.performanceTimer) {
    axe.utils.performanceTimer.start();
  }
  let p;
  let reject = noop;
  let resolve = noop;

  if (typeof Promise === 'function' && callback === noop) {
    p = new Promise((_resolve, _reject) => {
      reject = _reject;
      resolve = _resolve;
    });
  }

  if (axe._running) {
    const err =
      'Axe is already running. Use `await axe.run()` to wait ' +
      'for the previous run to finish before starting a new run.';
    callback(err);
    reject(err);
    return p;
  }

  axe._running = true;
  axe._runRules(
    context,
    options,
    (rawResults, cleanup) => {
      const respond = results => {
        axe._running = false;
        cleanup();
        try {
          callback(null, results);
        } catch (e) {
          axe.log(e);
        }
        resolve(results);
      };
      if (options.performanceTimer) {
        axe.utils.performanceTimer.end();
      }

      try {
        const reporter = getReporter(options.reporter);
        const results = reporter(rawResults, options, respond);
        if (results !== undefined) {
          respond(results);
        }
      } catch (err) {
        axe._running = false;
        cleanup();
        callback(err);
        reject(err);
      }
    },
    err => {
      axe._running = false;
      callback(err);
      reject(err);
    }
  );

  return p;
}

export default run;
