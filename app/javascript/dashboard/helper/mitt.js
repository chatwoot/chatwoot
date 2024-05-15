import mitt from 'mitt';

const emitter = mitt();

const bus = {
  $on: emitter.on,
  $off: emitter.off,
  $emit: emitter.emit,
};

export default bus;
