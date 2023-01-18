import Vue from 'vue';
import plugin from '../plugin';
import analyticsHelper from '../index';

describe('Vue Analytics Plugin', () => {
  beforeEach(() => {
    jest.spyOn(analyticsHelper, 'init');
    jest.spyOn(analyticsHelper, 'track');
    Vue.use(plugin);
  });

  afterEach(() => {
    jest.resetModules();
    jest.clearAllMocks();
  });

  it('should call the init method on the analyticsHelper', () => {
    expect(analyticsHelper.init).toHaveBeenCalled();
  });

  it('should add the analyticsHelper to the Vue prototype', () => {
    expect(Vue.prototype.$analytics).toBe(analyticsHelper);
  });

  it('should add the track method to the Vue prototype', () => {
    expect(typeof Vue.prototype.$track).toBe('function');
    Vue.prototype.$track('eventName');
    expect(analyticsHelper.track).toHaveBeenCalledWith('eventName');
  });

  it('should call the track method on the analyticsHelper when $track is called', () => {
    Vue.prototype.$track('eventName');
    expect(analyticsHelper.track).toHaveBeenCalledWith('eventName');
  });
});
