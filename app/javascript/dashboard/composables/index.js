import { getCurrentInstance } from 'vue';
import { emitter } from 'shared/helpers/mitt';

export const useTrack = () => {
  const vm = getCurrentInstance();
  if (!vm) throw new Error('must be called in setup');

  return vm.proxy.$track;
};

export const useAlert = (message, action = null) => {
  emitter.emit('newToastMessage', { message, action });
};
