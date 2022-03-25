import { debounce } from '../TimeHelpers';
// Tell Jest to mock all timeout functions
jest.useFakeTimers('modern');

describe('debounce', () => {
  test('execute just once with immediate false', () => {
    let func = jest.fn();
    let debouncedFunc = debounce(func, 1000);

    for (let i = 0; i < 100; i += 1) {
      debouncedFunc();
    }

    // Fast-forward time
    jest.runAllTimers();

    expect(func).toBeCalledTimes(1);
  });

  test('execute just once with immediate true', () => {
    let func = jest.fn();
    let debouncedFunc = debounce(func, 1000, true);

    for (let i = 0; i < 100; i += 1) {
      debouncedFunc();
    }

    jest.runAllTimers();

    expect(func).toBeCalledTimes(1);
  });
});
