/**
 * Creates a debounced version of a function that delays invoking the provided function
 * until after a specified wait time has elapsed since the last time it was invoked.
 *
 * @param {Function} func - The function to debounce. Will receive any arguments passed to the debounced function.
 * @param {number} wait - The number of milliseconds to delay execution after the last call.
 * @param {boolean} [immediate] - If true, the function will execute immediately on the first call,
 *                               then start the debounce behavior for subsequent calls.
 * @param {number} [maxWait] - The maximum time the function can be delayed before it's forcibly executed.
 *                            If specified, the function will be called after this many milliseconds
 *                            have passed since its last execution, regardless of the debounce wait time.
 *
 * @returns {Function} A debounced version of the original function that has the following behavior:
 *   - Delays execution until `wait` milliseconds have passed since the last call
 *   - If `immediate` is true, executes on the leading edge of the first call
 *   - If `maxWait` is provided, ensures the function is called at least once every `maxWait` milliseconds
 *   - Preserves the `this` context and arguments of the most recent call
 *   - Cancels pending executions when called again within the wait period
 *
 * @example
 * // Basic debounce
 * const debouncedSearch = debounce(searchAPI, 300);
 *
 * // With immediate execution
 * const debouncedSave = debounce(saveData, 1000, true);
 *
 * // With maximum wait time
 * const debouncedUpdate = debounce(updateUI, 200, false, 1000);
 */
export const debounce = (
  func: (...args: any[]) => void,
  wait: number,
  immediate?: boolean,
  maxWait?: number
) => {
  let timeout: ReturnType<typeof setTimeout> | null = null;
  let lastInvokeTime = 0;

  return function(this: any, ...args: any[]) {
    const time = Date.now();
    const isFirstCall = lastInvokeTime === 0;

    // Check if this is the first call and immediate execution is requested
    if (isFirstCall && immediate) {
      lastInvokeTime = time;
      func.apply(this, args);
      return;
    }

    // Clear any existing timeout
    if (timeout !== null) {
      clearTimeout(timeout);
      timeout = null;
    }

    // Calculate if maxWait threshold has been reached
    const timeSinceLastInvoke = time - lastInvokeTime;
    const shouldInvokeNow =
      maxWait !== undefined && timeSinceLastInvoke >= maxWait;

    if (shouldInvokeNow) {
      lastInvokeTime = time;
      func.apply(this, args);
      return;
    }

    // Set a new timeout
    timeout = setTimeout(() => {
      lastInvokeTime = Date.now();
      timeout = null;
      func.apply(this, args);
    }, wait);
  };
};
