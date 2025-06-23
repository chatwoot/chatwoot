import { getCurrentInstance } from 'vue';

export function useReplaceRoute() {
  const { proxy } = getCurrentInstance();

  async function replaceRoute(name, params = {}) {
    if (proxy.$route.name !== name) {
      return proxy.$router.replace({ name, params });
    }
    return undefined;
  }

  return { replaceRoute };
}