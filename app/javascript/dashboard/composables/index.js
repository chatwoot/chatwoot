import { getCurrentInstance } from 'vue';
import { emitter } from 'shared/helpers/mitt';

export const useTrack = () => {
  const vm = getCurrentInstance();
  if (!vm) throw new Error('must be called in setup');

  return vm.proxy.$track;
};

export function useAlert(message, action) {
  emitter.emit('newToastMessage', message, action);
}
