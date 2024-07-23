<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { computed, onMounted } from 'vue';
import IntegrationItem from './IntegrationItem.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const store = useStore();
const getters = useStoreGetters();

const uiFlags = getters['integrations/getUIFlags'];

const integrationList = computed(() => {
  const appIntegrations = getters['integrations/getAppIntegrations'].value;
  return appIntegrations.sort((i1, i2) => {
    if (i1.enabled === i2.enabled) {
      return 0;
    }

    return i1.enabled ? -1 : 1;
  });
});

onMounted(() => {
  store.dispatch('integrations/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('INTEGRATION_APPS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.HEADER')"
        :description="$t('INTEGRATION_SETTINGS.DESCRIPTION')"
        :link-text="$t('SLA.LEARN_MORE')"
        href="/"
        icon-name="flash-on"
      />
    </template>
    <template #body>
      <div class="flex-grow flex-shrink overflow-auto font-inter">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <integration-item
            v-for="item in integrationList"
            :id="item.id"
            :key="item.id"
            :logo="item.logo"
            :name="item.name"
            :description="item.description"
            :enabled="item.enabled"
          />
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
