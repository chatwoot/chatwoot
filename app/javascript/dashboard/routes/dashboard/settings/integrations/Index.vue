<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { computed, onMounted } from 'vue';
import { useBranding } from 'shared/composables/useBranding';
import IntegrationItem from './IntegrationItem.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';

const store = useStore();
const getters = useStoreGetters();
const { replaceInstallationName } = useBranding();

const uiFlags = getters['integrations/getUIFlags'];
const accountId = getters.getCurrentAccountId;

const integrationList = computed(
  () => getters['integrations/getAppIntegrations'].value
);

const whatsappSettingsURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/whatsapp`)
);

onMounted(() => {
  store.dispatch('integrations/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('INTEGRATION_SETTINGS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.HEADER')"
        :description="
          replaceInstallationName($t('INTEGRATION_SETTINGS.DESCRIPTION'))
        "
        :link-text="$t('INTEGRATION_SETTINGS.LEARN_MORE')"
        feature-name="integrations"
      />
    </template>
    <template #body>
      <div class="flex-grow flex-shrink overflow-auto">
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          <!-- WhatsApp Business Settings Card -->
          <div
            class="flex flex-col flex-1 p-6 m-[1px] outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
          >
            <div class="flex items-start justify-between">
              <div
                class="flex h-12 w-12 mb-4 items-center justify-center rounded-md border border-n-weak shadow-sm bg-n-alpha-3 dark:bg-n-alpha-2"
              >
                <i class="i-lucide-message-circle text-3xl text-green-600" />
              </div>
            </div>
            <div class="flex flex-col m-0 flex-1">
              <div
                class="font-medium mb-2 text-n-slate-12 flex justify-between items-center"
              >
                <span class="text-base font-semibold">{{
                  $t('INTEGRATION_SETTINGS.WHATSAPP.TITLE')
                }}</span>
                <router-link :to="whatsappSettingsURL">
                  <Button :label="$t('INTEGRATION_APPS.CONFIGURE')" link />
                </router-link>
              </div>
              <p class="text-n-slate-11">
                {{ $t('INTEGRATION_SETTINGS.WHATSAPP.DESCRIPTION') }}
              </p>
            </div>
          </div>

          <IntegrationItem
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
