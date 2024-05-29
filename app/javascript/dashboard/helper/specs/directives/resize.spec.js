import resize from '../../directives/resize';

class ResizeObserverMock {
  // eslint-disable-next-line class-methods-use-this
  observe() {}

  // eslint-disable-next-line class-methods-use-this
  unobserve() {}

  // eslint-disable-next-line class-methods-use-this
  disconnect() {}
}

describe('resize directive', () => {
  let el;
  let binding;
  let observer;

  beforeEach(() => {
    el = document.createElement('div');
    binding = {
      value: jest.fn(),
    };
    observer = {
      observe: jest.fn(),
      unobserve: jest.fn(),
      disconnect: jest.fn(),
    };
    window.ResizeObserver = ResizeObserverMock;
    jest.spyOn(window, 'ResizeObserver').mockImplementation(() => observer);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should create ResizeObserver on bind', () => {
    resize.bind(el, binding);

    expect(ResizeObserver).toHaveBeenCalled();
    expect(observer.observe).toHaveBeenCalledWith(el);
  });

  it('should call callback on observer callback', () => {
    el = document.createElement('div');
    binding = {
      value: jest.fn(),
    };

    resize.bind(el, binding);

    const entries = [{ contentRect: { width: 100, height: 100 } }];
    const callback = binding.value;
    callback(entries[0]);

    expect(binding.value).toHaveBeenCalledWith(entries[0]);
  });

  it('should destroy and recreate observer on update', () => {
    resize.bind(el, binding);

    resize.update(el, { ...binding, oldValue: 'old' });

    expect(observer.unobserve).toHaveBeenCalledWith(el);
    expect(observer.disconnect).toHaveBeenCalled();
    expect(ResizeObserver).toHaveBeenCalledTimes(2);
    expect(observer.observe).toHaveBeenCalledTimes(2);
  });

  it('should destroy observer on unbind', () => {
    resize.bind(el, binding);

    resize.unbind(el);

    expect(observer.unobserve).toHaveBeenCalledWith(el);
    expect(observer.disconnect).toHaveBeenCalled();
  });
});
