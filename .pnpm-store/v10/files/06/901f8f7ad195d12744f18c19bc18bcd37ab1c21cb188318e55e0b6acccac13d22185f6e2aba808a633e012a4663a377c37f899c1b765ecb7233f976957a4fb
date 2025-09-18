/**
 * Creates a typing indicator utility.
 * @param onStartTyping Callback function to be called when typing starts
 * @param onStopTyping Callback function to be called when typing stops after delay
 * @param idleTime Delay for idle time in ms before considering typing stopped
 * @returns An object with start and stop methods for typing indicator
 */

type CallbackFunction = () => void;
type Timeout = ReturnType<typeof setTimeout>;

export const createTypingIndicator = (
  onStartTyping: CallbackFunction,
  onStopTyping: CallbackFunction,
  idleTime: number
) => {
  let timer: Timeout | null = null;

  const start = (): void => {
    if (!timer) {
      onStartTyping();
    }
    reset();
  };

  const stop = (): void => {
    if (timer) {
      clearTimeout(timer as Timeout);
      timer = null;
      onStopTyping();
    }
  };

  const reset = (): void => {
    if (timer) {
      clearTimeout(timer as Timeout);
    }
    timer = setTimeout(() => {
      stop();
    }, idleTime) as Timeout;
  };

  return { start, stop };
};
