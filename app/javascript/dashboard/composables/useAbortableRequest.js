import { getCurrentScope, onScopeDispose, ref } from 'vue';

export const isAbortError = error =>
  error?.name === 'AbortError' ||
  error?.name === 'CanceledError' ||
  error?.code === 'ERR_CANCELED';

/**
 * Keeps only the latest request alive. Starting a new `run` (or calling
 * `abort`) cancels the previous request through its `AbortSignal`, so
 * out-of-order responses can never overwrite fresher data.
 *
 * @example
 * const { run, abort, isPending } = useAbortableRequest();
 * const results = await run(signal => api.search(query, { signal }));
 *
 * @returns {{
 *   run: (runner: (signal: AbortSignal) => Promise<any>, options?: { onAbort?: any }) => Promise<any>,
 *   abort: () => void,
 *   isPending: import('vue').Ref<boolean>,
 * }}
 * `run` resolves with the runner's value, or `options.onAbort` (default
 * `undefined`) when the request was superseded. Non-abort errors are rethrown.
 */
export function useAbortableRequest() {
  const isPending = ref(false);
  let controller = null;

  const abort = () => {
    controller?.abort();
    controller = null;
    isPending.value = false;
  };

  const run = async (runner, { onAbort } = {}) => {
    controller?.abort();
    const currentController = new AbortController();
    controller = currentController;
    isPending.value = true;

    try {
      return await runner(currentController.signal);
    } catch (error) {
      if (currentController.signal.aborted || isAbortError(error))
        return onAbort;
      throw error;
    } finally {
      // Only the latest run owns the shared state; a superseded run leaves it
      // for the run that replaced it.
      if (controller === currentController) {
        controller = null;
        isPending.value = false;
      }
    }
  };

  // Cancel any in-flight request when the owning scope is disposed.
  // Guarded so the composable can also be used outside an effect scope.
  if (getCurrentScope()) onScopeDispose(abort);

  return { run, abort, isPending };
}
