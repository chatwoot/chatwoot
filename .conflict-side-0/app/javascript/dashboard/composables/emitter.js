import { emitter } from 'shared/helpers/mitt';
import { onMounted, onBeforeUnmount } from 'vue';

// this will automatically add event listeners to the emitter
// and remove them when the component is destroyed
const useEmitter = (eventName, callback) => {
  const cleanup = () => {
    emitter.off(eventName, callback);
  };

  onMounted(() => {
    emitter.on(eventName, callback);
  });

  onBeforeUnmount(cleanup);

  return cleanup;
};

export { useEmitter };
