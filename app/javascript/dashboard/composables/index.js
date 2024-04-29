import { getCurrentInstance } from 'vue';

export const useTrack = () => {
  const vm = getCurrentInstance();
  if (!vm) throw new Error('must be called in setup');

  return vm.proxy.$track;
};

export function useAlert(message, action) {
  bus.$emit('newToastMessage', message, action);
}
