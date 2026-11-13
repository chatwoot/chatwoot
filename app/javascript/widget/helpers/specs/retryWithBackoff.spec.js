import { retryWithBackoff } from '../retryWithBackoff';

const noSleep = () => Promise.resolve();

describe('retryWithBackoff', () => {
  it('returns the value without retrying when the call succeeds', async () => {
    const fn = vi.fn().mockResolvedValue('ok');
    await expect(retryWithBackoff(fn, { sleep: noSleep })).resolves.toBe('ok');
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it('retries and succeeds on a later attempt', async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce(new Error('blip'))
      .mockResolvedValue('ok');
    await expect(retryWithBackoff(fn, { sleep: noSleep })).resolves.toBe('ok');
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it('rethrows the last error once every attempt fails', async () => {
    const fn = vi.fn().mockRejectedValue(new Error('down'));
    await expect(retryWithBackoff(fn, { sleep: noSleep })).rejects.toThrow(
      'down'
    );
    expect(fn).toHaveBeenCalledTimes(3);
  });

  it('must not swallow the failure by resolving undefined', async () => {
    const fn = vi.fn().mockRejectedValue(new Error('down'));
    let threw = false;
    try {
      await retryWithBackoff(fn, { sleep: noSleep });
    } catch (e) {
      threw = true;
    }
    expect(threw).toBe(true);
  });

  it('backs off exponentially and does not sleep after the final attempt', async () => {
    const delays = [];
    const fn = vi.fn().mockRejectedValue(new Error('down'));
    await expect(
      retryWithBackoff(fn, {
        attempts: 3,
        baseDelay: 100,
        sleep: ms => {
          delays.push(ms);
          return Promise.resolve();
        },
      })
    ).rejects.toThrow('down');
    expect(delays).toEqual([100, 200]);
  });

  it('honours a custom attempt count', async () => {
    const fn = vi.fn().mockRejectedValue(new Error('down'));
    await expect(
      retryWithBackoff(fn, { attempts: 5, sleep: noSleep })
    ).rejects.toThrow('down');
    expect(fn).toHaveBeenCalledTimes(5);
  });
});
