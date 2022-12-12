import "core-js/modules/es.promise.js";
import { printDuration } from './print-duration';
export var useProgressReporting = async function (router, startTime, options) {
  var _options$cache;

  var value = 0;
  var totalModules;

  var reportProgress = function () {};

  router.get('/progress', function (request, response) {
    var closed = false;

    var close = function () {
      closed = true;
      response.end();
    };

    response.on('close', close);
    if (closed || response.writableEnded) return;
    response.setHeader('Cache-Control', 'no-cache');
    response.setHeader('Content-Type', 'text/event-stream');
    response.setHeader('Connection', 'keep-alive');
    response.flushHeaders();

    reportProgress = function (progress) {
      if (closed || response.writableEnded) return;
      response.write(`data: ${JSON.stringify(progress)}\n\n`);
      response.flush();
      if (progress.value === 1) close();
    };
  });

  var handler = function (newValue, message, arg3) {
    value = Math.max(newValue, value); // never go backwards

    var progress = {
      value: value,
      message: message.charAt(0).toUpperCase() + message.slice(1)
    };

    if (message === 'building') {
      // arg3 undefined in webpack5
      var counts = arg3 && arg3.match(/(\d+)\/(\d+)/) || [];
      var complete = parseInt(counts[1], 10);
      var total = parseInt(counts[2], 10);

      if (!Number.isNaN(complete) && !Number.isNaN(total)) {
        progress.modules = {
          complete: complete,
          total: total
        };
        totalModules = total;
      }
    }

    if (value === 1) {
      if (options.cache) {
        options.cache.set('modulesCount', totalModules);
      }

      if (!progress.message) {
        progress.message = `Completed in ${printDuration(startTime)}.`;
      }
    }

    reportProgress(progress);
  };

  var modulesCount = (await ((_options$cache = options.cache) === null || _options$cache === void 0 ? void 0 : _options$cache.get('modulesCount').catch(function () {}))) || 1000;
  return {
    handler: handler,
    modulesCount: modulesCount
  };
};