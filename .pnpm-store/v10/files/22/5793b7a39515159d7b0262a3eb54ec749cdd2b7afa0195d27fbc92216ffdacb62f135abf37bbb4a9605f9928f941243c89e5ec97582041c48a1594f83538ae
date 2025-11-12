/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 *
 * A lightweight readable stream implemention that handles event dispatching.
 * Objects that inherit from streams should call init in their constructors.
 */
'use strict';

var Stream = function Stream() {
  this.init = function () {
    var listeners = {};
    /**
     * Add a listener for a specified event type.
     * @param type {string} the event name
     * @param listener {function} the callback to be invoked when an event of
     * the specified type occurs
     */

    this.on = function (type, listener) {
      if (!listeners[type]) {
        listeners[type] = [];
      }

      listeners[type] = listeners[type].concat(listener);
    };
    /**
     * Remove a listener for a specified event type.
     * @param type {string} the event name
     * @param listener {function} a function previously registered for this
     * type of event through `on`
     */


    this.off = function (type, listener) {
      var index;

      if (!listeners[type]) {
        return false;
      }

      index = listeners[type].indexOf(listener);
      listeners[type] = listeners[type].slice();
      listeners[type].splice(index, 1);
      return index > -1;
    };
    /**
     * Trigger an event of the specified type on this stream. Any additional
     * arguments to this function are passed as parameters to event listeners.
     * @param type {string} the event name
     */


    this.trigger = function (type) {
      var callbacks, i, length, args;
      callbacks = listeners[type];

      if (!callbacks) {
        return;
      } // Slicing the arguments on every invocation of this method
      // can add a significant amount of overhead. Avoid the
      // intermediate object creation for the common case of a
      // single callback argument


      if (arguments.length === 2) {
        length = callbacks.length;

        for (i = 0; i < length; ++i) {
          callbacks[i].call(this, arguments[1]);
        }
      } else {
        args = [];
        i = arguments.length;

        for (i = 1; i < arguments.length; ++i) {
          args.push(arguments[i]);
        }

        length = callbacks.length;

        for (i = 0; i < length; ++i) {
          callbacks[i].apply(this, args);
        }
      }
    };
    /**
     * Destroys the stream and cleans up.
     */


    this.dispose = function () {
      listeners = {};
    };
  };
};
/**
 * Forwards all `data` events on this stream to the destination stream. The
 * destination stream should provide a method `push` to receive the data
 * events as they arrive.
 * @param destination {stream} the stream that will receive all `data` events
 * @param autoFlush {boolean} if false, we will not call `flush` on the destination
 *                            when the current stream emits a 'done' event
 * @see http://nodejs.org/api/stream.html#stream_readable_pipe_destination_options
 */


Stream.prototype.pipe = function (destination) {
  this.on('data', function (data) {
    destination.push(data);
  });
  this.on('done', function (flushSource) {
    destination.flush(flushSource);
  });
  this.on('partialdone', function (flushSource) {
    destination.partialFlush(flushSource);
  });
  this.on('endedtimeline', function (flushSource) {
    destination.endTimeline(flushSource);
  });
  this.on('reset', function (flushSource) {
    destination.reset(flushSource);
  });
  return destination;
}; // Default stream functions that are expected to be overridden to perform
// actual work. These are provided by the prototype as a sort of no-op
// implementation so that we don't have to check for their existence in the
// `pipe` function above.


Stream.prototype.push = function (data) {
  this.trigger('data', data);
};

Stream.prototype.flush = function (flushSource) {
  this.trigger('done', flushSource);
};

Stream.prototype.partialFlush = function (flushSource) {
  this.trigger('partialdone', flushSource);
};

Stream.prototype.endTimeline = function (flushSource) {
  this.trigger('endedtimeline', flushSource);
};

Stream.prototype.reset = function (flushSource) {
  this.trigger('reset', flushSource);
};

module.exports = Stream;