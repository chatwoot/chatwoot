import { computed, ref } from 'vue';
import { useStore } from 'dashboard/composables/store';

export const useHook = (integrationObj, integrationId) => {
  const store = useStore();
  const integration = ref(null);
  if (integrationId) {
    integration.value =
      store.getters['integrations/getIntegration'](integrationId);
  } else {
    integration.value = integrationObj;
  }

  const isHookTypeInbox = computed(() => {
    return integration.value.hook_type === 'inbox';
  });

  const hasConnectedHooks = computed(() => {
    return !!integration.value.hooks.length;
  });

  return {
    isHookTypeInbox,
    hasConnectedHooks,
  };
};
