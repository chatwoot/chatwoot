import log from '../log';

function noop() {}
function funcGuard(f) {
  if (typeof f !== 'function') {
    throw new TypeError('Queue methods require functions as arguments');
  }
}

/**
 * Create an asynchronous "queue", list of functions to be invoked in parallel, but not necessarily returned in order
 * @return {Queue} The newly generated "queue"
 */
function queue() {
  var tasks = [];
  var started = 0;
  var remaining = 0; // number of tasks not yet finished
  var completeQueue = noop;
  var complete = false;
  var err;

  // By default, wait until the next tick,
  // if no catch was set, throw to console.
  var defaultFail = e => {
    err = e;
    setTimeout(() => {
      if (err !== undefined && err !== null) {
        log('Uncaught error (of queue)', err);
      }
    }, 1);
  };
  var failed = defaultFail;

  function createResolve(i) {
    return r => {
      tasks[i] = r;
      remaining -= 1;
      if (!remaining && completeQueue !== noop) {
        complete = true;
        completeQueue(tasks);
      }
    };
  }

  function abort(msg) {
    // reset tasks
    completeQueue = noop;

    // notify catch
    failed(msg);
    // return unfinished work
    return tasks;
  }

  function pop() {
    var length = tasks.length;
    for (; started < length; started++) {
      var task = tasks[started];

      try {
        task.call(null, createResolve(started), abort);
      } catch (e) {
        abort(e);
      }
    }
  }

  var q = {
    /**
     * Defer a function that may or may not run asynchronously.
     *
     * First parameter should be the function to execute with subsequent
     * parameters being passed as arguments to that function
     */
    defer(fn) {
      if (typeof fn === 'object' && fn.then && fn.catch) {
        var defer = fn;
        fn = (resolve, reject) => {
          defer.then(resolve).catch(reject);
        };
      }
      funcGuard(fn);
      if (err !== undefined) {
        return;
      } else if (complete) {
        throw new Error('Queue already completed');
      }

      tasks.push(fn);
      ++remaining;
      pop();
      return q;
    },

    /**
     * The callback to execute once all "deferred" functions have completed.  Will only be invoked once.
     * @param  {Function} f The callback, receives an array of the return/callbacked
     * values of each of the "deferred" functions
     */
    then(fn) {
      funcGuard(fn);
      if (completeQueue !== noop) {
        throw new Error('queue `then` already set');
      }
      if (!err) {
        completeQueue = fn;
        if (!remaining) {
          complete = true;
          completeQueue(tasks);
        }
      }
      return q;
    },

    catch: function(fn) {
      funcGuard(fn);
      if (failed !== defaultFail) {
        throw new Error('queue `catch` already set');
      }
      if (!err) {
        failed = fn;
      } else {
        fn(err);
        err = null;
      }
      return q;
    },
    /**
     * Abort the "queue" and prevent `then` function from firing
     * @param  {Function} fn The callback to execute; receives an array of the results which have completed
     */
    abort: abort
  };
  return q;
}

export default queue;
