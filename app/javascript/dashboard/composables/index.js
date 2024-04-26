import { getCurrentInstance } from 'vue';
export const useTrack = (eventName, payload) => {
  const vm = getCurrentInstance();
  if (!vm) throw new Error('must be called in setup');
  return vm.proxy.$track(eventName, payload);
};

export function useAlert(message, action) {
  bus.$emit('newToastMessage', message, action);
}
