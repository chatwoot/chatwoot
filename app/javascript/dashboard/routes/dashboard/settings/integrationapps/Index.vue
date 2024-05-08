<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto">
    <div class="flex flex-col">
      <div v-if="uiFlags.isFetching" class="mx-auto my-0">
        <woot-loading-state :message="$t('INTEGRATION_APPS.FETCHING')" />
      </div>

      <div v-else class="w-full">
        <div>
          <div
            v-for="item in enabledIntegrations"
            :key="item.id"
            class="p-4 mb-4 bg-white border border-solid rounded-sm dark:bg-slate-800 border-slate-75 dark:border-slate-700/50"
          >
            <integration-item
              :integration-id="item.id"
              :integration-logo="item.logo"
              :integration-name="item.name"
              :integration-description="item.description"
              :integration-enabled="item.hooks.length"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { computed, onMounted } from 'vue';
import IntegrationItem from './IntegrationItem.vue';
const store = useStore();
const getters = useStoreGetters();

const uiFlags = getters['integrations/getUIFlags'];

const accountId = getters.getCurrentAccountId;

const integrationList = computed(() => {
  return getters['integrations/getAppIntegrations'].value;
});

const isLinearIntegrationEnabled = computed(() => {
  return getters['accounts/isFeatureEnabledonAccount'].value(
    accountId.value,
    'linear_integration'
  );
});
const enabledIntegrations = computed(() => {
  if (!isLinearIntegrationEnabled.value) {
    return integrationList.value.filter(
      integration => integration.id !== 'linear'
    );
  }
  return integrationList.value;
});

onMounted(() => {
  store.dispatch('integrations/get');
});
</script>
