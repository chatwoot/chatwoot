import { debounce } from '../TimeHelpers';
// Tell Jest to mock all timeout functions
jest.useFakeTimers('modern');

describe('debounce', () => {
  let func;
  let debouncedFunc;

  beforeEach(() => {
    func = jest.fn();
    debouncedFunc = debounce(func, 1000);
  });

  test('execute just once with immediate false', () => {
    // eslint-disable-next-line no-plusplus
    for (let i = 0; i < 100; i++) {
      debouncedFunc();
    }

    // Fast-forward time
    jest.runAllTimers();

    expect(func).toBeCalledTimes(1);
  });

  test('execute just once with immediate true', () => {
    // eslint-disable-next-line no-plusplus
    for (let i = 0; i < 100; i++) {
      debouncedFunc();
    }

    // Fast-forward time
    jest.runAllTimers();

    expect(func).toBeCalledTimes(1);
  });
});
