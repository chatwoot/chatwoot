import { computed, unref } from 'vue';
import { getCurrentInstance } from 'vue';

export const useStore = () => {
  const vm = getCurrentInstance();
  if (!vm) throw new Error('must be called in setup');
  return vm.proxy.$store;
};

export const useStoreGetters = () => {
  const store = useStore();
  return Object.fromEntries(
    Object.keys(store.getters).map(getter => [
      getter,
      computed(() => store.getters[getter]),
    ])
  );
};

export const useMapGetter = key => {
  const store = useStore();
  return computed(() => store.getters[key]);
};

export const useFunctionGetter = (key, ...args) => {
  const store = useStore();
  return computed(() => {
    const unrefedArgs = args.map(arg => unref(arg));
    return store.getters[key](...unrefedArgs);
  });
};
