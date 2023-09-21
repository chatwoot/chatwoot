import analyticsHelper from '.';

export default {
  // This function is called when the Vue plugin is installed
  install(Vue) {
    analyticsHelper.init();
    Vue.prototype.$analytics = analyticsHelper;
    // Add a shorthand function for the track method on the helper module
    Vue.prototype.$track = analyticsHelper.track.bind(analyticsHelper);
  },
};
