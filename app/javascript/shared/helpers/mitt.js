import mitt from 'mitt';
const emitter = mitt();

const EmitterPlugin = {
  install(Vue) {
    Vue.prototype.$emitter = emitter;
  },
};

export { emitter, EmitterPlugin };
