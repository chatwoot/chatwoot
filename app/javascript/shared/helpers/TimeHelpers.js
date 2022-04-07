// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.

export const debounce = (func, delay, immediate) => {
  let timerId;
  return (...args) => {
    const boundFunc = func.bind(this, ...args);
    clearTimeout(timerId);
    if (immediate && !timerId) {
      boundFunc();
    }
    const calleeFunc = immediate
      ? () => {
          timerId = null;
        }
      : boundFunc;
    timerId = setTimeout(calleeFunc, delay);
  };
};
