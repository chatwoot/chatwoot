/**
 * Takes a performance entry type and a callback function, and creates a
 * `PerformanceObserver` instance that will observe the specified entry type
 * with buffering enabled and call the callback _for each entry_.
 *
 * This function also feature-detects entry support and wraps the logic in a
 * try/catch to avoid errors in unsupporting browsers.
 */
const observe = (
  type,
  callback,
  opts,
) => {
  try {
    if (PerformanceObserver.supportedEntryTypes.includes(type)) {
      const po = new PerformanceObserver(list => {
        // Delay by a microtask to workaround a bug in Safari where the
        // callback is invoked immediately, rather than in a separate task.
        // See: https://github.com/GoogleChrome/web-vitals/issues/277
        // eslint-disable-next-line @typescript-eslint/no-floating-promises
        Promise.resolve().then(() => {
          callback(list.getEntries() );
        });
      });
      po.observe(
        Object.assign(
          {
            type,
            buffered: true,
          },
          opts || {},
        ) ,
      );
      return po;
    }
  } catch (e) {
    // Do nothing.
  }
  return;
};

export { observe };
//# sourceMappingURL=observe.js.map
