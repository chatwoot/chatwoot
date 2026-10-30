/**
 * Retry an async call a few times with exponential backoff.
 *
 * Added because syncLatestMessages, the widget's only route for recovering
 * messages missed while disconnected, discarded its errors outright. It runs
 * immediately after a reconnect, which is exactly when a transient failure is
 * most likely, so one unlucky fetch left the chat permanently stale while still
 * reporting healthy.
 *
 * Deliberately small: no jitter, no circuit breaker, no per-status handling.
 * Those matter for a server calling a server thousands of times a second. This
 * is one browser recovering one conversation.
 */
export const retryWithBackoff = async (
  fn,
  {
    attempts = 3,
    baseDelay = 500,
    sleep = ms =>
      new Promise(resolve => {
        setTimeout(resolve, ms);
      }),
  } = {}
) => {
  let lastError;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      // eslint-disable-next-line no-await-in-loop
      return await fn();
    } catch (error) {
      lastError = error;
      // Do not sleep after the final attempt; the caller is about to be told.
      if (attempt < attempts - 1) {
        // eslint-disable-next-line no-await-in-loop
        await sleep(baseDelay * 2 ** attempt);
      }
    }
  }
  throw lastError;
};

export default retryWithBackoff;
