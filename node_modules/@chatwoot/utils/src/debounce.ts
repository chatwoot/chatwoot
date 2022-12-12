// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.

/**
 * @func Callback function to be called after delay
 * @delay Delay for debounce in ms
 * @immediate should execute immediately
 * @returns debounced callaback function
 */
export const debounce = (
  func: (args: any) => void,
  wait: number,
  immediate?: boolean
) => {
  let timeout: number | undefined | null;

  return function() {
    const context = null;
    const args = arguments;
    const later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args as any);
    };
    const callNow = immediate && !timeout;
    clearTimeout(timeout as number);
    timeout = window.setTimeout(later, wait);
    if (callNow) func.apply(context, args as any);
  };
};
