import analyticsHelper from '.';

export default {
  // This function is called when the Vue plugin is installed
  install(Vue) {
    const helper = analyticsHelper;
    Vue.prototype.$analytics = helper;

    // Add a shorthand function for the track method on the helper module
    Vue.prototype.$track = helper.track;
  },
};
