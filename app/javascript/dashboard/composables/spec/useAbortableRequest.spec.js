import { effectScope } from 'vue';
import { useAbortableRequest } from '../useAbortableRequest';

// Resolves when the request "completes", rejects like axios does when the
// signal is aborted mid-flight.
const abortableRunner =
  (value, { fail = false } = {}) =>
  signal =>
    new Promise((resolve, reject) => {
      signal.addEventListener('abort', () => {
        const error = new Error('canceled');
        error.name = 'CanceledError';
        reject(error);
      });
      // Defer so a follow-up `run`/`abort` can supersede this one first.
      Promise.resolve().then(() => {
        if (signal.aborted) return;
        if (fail) {
          reject(new Error('boom'));
          return;
        }
        resolve(value);
      });
    });

describe('useAbortableRequest', () => {
  it('passes a fresh signal to the runner and returns its result', async () => {
    const { run } = useAbortableRequest();
    let received = null;

    const result = await run(signal => {
      received = signal;
      return Promise.resolve('ok');
    });

    expect(received).toBeInstanceOf(AbortSignal);
    expect(received.aborted).toBe(false);
    expect(result).toBe('ok');
  });

  it('toggles isPending around the request', async () => {
    const { run, isPending } = useAbortableRequest();
    expect(isPending.value).toBe(false);

    const pending = run(() => Promise.resolve('done'));
    expect(isPending.value).toBe(true);

    await pending;
    expect(isPending.value).toBe(false);
  });

  it('aborts the previous request when a new one starts', async () => {
    const { run } = useAbortableRequest();

    const first = run(abortableRunner('first'));
    const second = run(abortableRunner('second'));

    await expect(first).resolves.toBeUndefined();
    await expect(second).resolves.toBe('second');
  });

  it('returns the onAbort value when a request is superseded', async () => {
    const { run } = useAbortableRequest();

    const first = run(abortableRunner('first'), { onAbort: null });
    const second = run(abortableRunner('second'));

    await expect(first).resolves.toBeNull();
    await expect(second).resolves.toBe('second');
  });

  it('abort cancels the in-flight request and clears isPending', async () => {
    const { run, abort, isPending } = useAbortableRequest();

    const pending = run(abortableRunner('value'));
    expect(isPending.value).toBe(true);

    abort();

    await expect(pending).resolves.toBeUndefined();
    expect(isPending.value).toBe(false);
  });

  it('rethrows non-abort errors and clears isPending', async () => {
    const { run, isPending } = useAbortableRequest();

    await expect(run(abortableRunner(null, { fail: true }))).rejects.toThrow(
      'boom'
    );
    expect(isPending.value).toBe(false);
  });

  it('aborts the in-flight request when its scope is disposed', async () => {
    const scope = effectScope();
    let request;
    scope.run(() => {
      request = useAbortableRequest();
    });

    const pending = request.run(abortableRunner('value'));
    expect(request.isPending.value).toBe(true);

    scope.stop();

    await expect(pending).resolves.toBeUndefined();
    expect(request.isPending.value).toBe(false);
  });

  it('keeps separate controllers per instance', async () => {
    const a = useAbortableRequest();
    const b = useAbortableRequest();

    const first = a.run(abortableRunner('a'));
    // Starting b's request must not abort a's.
    const second = b.run(abortableRunner('b'));

    await expect(first).resolves.toBe('a');
    await expect(second).resolves.toBe('b');
  });
});
