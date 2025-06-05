<script setup>
import { ref, computed, onMounted } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';

import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';

const store = useStore();

const integrationLoaded = ref(false);

const integration = useFunctionGetter('integrations/getIntegration', 'linear');

const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return integration.value.action;
});

const initializeLinearIntegration = async () => {
  await store.dispatch('integrations/get', 'linear');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeLinearIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto">
    <div class="flex flex-col">
      <div class="flex flex-col">
        <div>
          <div
            v-if="integrationLoaded && !uiFlags.isCreatingLinear"
            class="p-4 mb-4 bg-white border border-solid rounded-sm dark:bg-slate-800 border-slate-75 dark:border-slate-700/50"
          >
            <Integration
              :integration-id="integration.id"
              :integration-logo="integration.logo"
              :integration-name="integration.name"
              :integration-description="integration.description"
              :integration-enabled="integration.enabled"
              :integration-action="integrationAction"
              :delete-confirmation-text="{
                title: $t('INTEGRATION_SETTINGS.LINEAR.DELETE.TITLE'),
                message: $t('INTEGRATION_SETTINGS.LINEAR.DELETE.MESSAGE'),
              }"
            />
          </div>
          <div v-else class="flex items-center justify-center flex-1">
            <Spinner size="" color-scheme="primary" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
