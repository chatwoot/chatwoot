(function (global, $) {

  /**
  * Try to catch the `do` function every `interval` delay, until it succedes
  * (does not throw an error) or a given `timout` time passed.
  * If a `then` function is passed, it is called after `do` succeded.
  * If a `catch` function is passed, it is called after each time `do` fails.
  *
  * @param  {object} opts
  * @param  {object} opts
  */
  global.tryInterval = function (opts) {
    var _opts = $.extend({}, opts);
    var totalTime = 0;

    var interval = setInterval(function () {
      var succeded = false;
      var error = null;

      totalTime += _opts.time;

      try {
        _opts.try();
        succeded = true;
      }
      catch (err) { error = err; }

      if (succeded) {
        clearInterval(interval);
        if (typeof _opts.then === 'function') _opts.then();
      }
      else if (totalTime > _opts.timeout) {
        clearInterval(interval);
        throw error;
      }
      else {
        if (typeof _opts.catch === 'function') _opts.catch(error);
      }

    }, _opts.interval);
  };

})(window, jQuery);
