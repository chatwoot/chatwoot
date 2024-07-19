import Vue from 'vue';
import plugin from '../plugin';
import analyticsHelper from '../index';

vi.spyOn(analyticsHelper, 'init');
vi.spyOn(analyticsHelper, 'track');

describe('Vue Analytics Plugin', () => {
  beforeEach(() => {
    Vue.use(plugin);
  });

  it('should call the init method on analyticsHelper once during plugin installation', () => {
    expect(analyticsHelper.init).toHaveBeenCalledTimes(1);
  });

  it('should add the analyticsHelper to the Vue prototype as $analytics', () => {
    expect(Vue.prototype.$analytics).toBe(analyticsHelper);
  });

  it('should add a track method to the Vue prototype as $track', () => {
    expect(typeof Vue.prototype.$track).toBe('function');
    Vue.prototype.$track('eventName');
    expect(analyticsHelper.track)
      .toHaveBeenCalledTimes(1)
      .toHaveBeenCalledWith('eventName');
  });

  it('should call the track method on analyticsHelper with the correct event name when $track is called', () => {
    const eventName = 'testEvent';
    Vue.prototype.$track(eventName);
    expect(analyticsHelper.track)
      .toHaveBeenCalledTimes(1)
      .toHaveBeenCalledWith(eventName);
  });
});
