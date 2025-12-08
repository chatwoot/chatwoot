<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { computed, onMounted, ref } from 'vue';
import { useBranding } from 'shared/composables/useBranding';
import { useI18n } from 'vue-i18n';
import whatsappSettingsAPI from 'dashboard/api/whatsappSettings';
import payzahSettingsAPI from 'dashboard/api/payzahSettings';
import tapSettingsAPI from 'dashboard/api/tapSettings';
import payzahLogo from 'assets/images/payzah-logo.webp';
import IntegrationItem from './IntegrationItem.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';

const store = useStore();
const getters = useStoreGetters();
const { replaceInstallationName } = useBranding();
const { t } = useI18n();

const uiFlags = getters['integrations/getUIFlags'];
const accountId = getters.getCurrentAccountId;
const whatsappConfigured = ref(false);
const payzahConfigured = ref(false);
const tapConfigured = ref(false);

const integrationList = computed(
  () => getters['integrations/getAppIntegrations'].value
);

const whatsappSettingsURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/whatsapp`)
);

const whatsappStatus = computed(() =>
  whatsappConfigured.value
    ? t('INTEGRATION_APPS.STATUS.ENABLED')
    : t('INTEGRATION_APPS.STATUS.DISABLED')
);

const whatsappStatusColor = computed(() =>
  whatsappConfigured.value ? 'bg-n-teal-9' : 'bg-n-slate-8'
);

const payzahSettingsURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/payzah`)
);

const payzahStatus = computed(() =>
  payzahConfigured.value
    ? t('INTEGRATION_APPS.STATUS.ENABLED')
    : t('INTEGRATION_APPS.STATUS.DISABLED')
);

const payzahStatusColor = computed(() =>
  payzahConfigured.value ? 'bg-n-teal-9' : 'bg-n-slate-8'
);

const tapSettingsURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/tap`)
);

const tapStatus = computed(() =>
  tapConfigured.value
    ? t('INTEGRATION_APPS.STATUS.ENABLED')
    : t('INTEGRATION_APPS.STATUS.DISABLED')
);

const tapStatusColor = computed(() =>
  tapConfigured.value ? 'bg-n-teal-9' : 'bg-n-slate-8'
);

const loadWhatsappSettings = async () => {
  try {
    const response = await whatsappSettingsAPI.get();
    whatsappConfigured.value = !!response.data?.app_id;
  } catch (error) {
    whatsappConfigured.value = false;
  }
};

const loadPayzahSettings = async () => {
  try {
    const response = await payzahSettingsAPI.get();
    payzahConfigured.value = !!response.data?.enabled;
  } catch (error) {
    payzahConfigured.value = false;
  }
};

const loadTapSettings = async () => {
  try {
    const response = await tapSettingsAPI.get();
    tapConfigured.value = !!response.data?.enabled;
  } catch (error) {
    tapConfigured.value = false;
  }
};

onMounted(() => {
  store.dispatch('integrations/get');
  loadWhatsappSettings();
  loadPayzahSettings();
  loadTapSettings();
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
              <span
                v-tooltip="whatsappStatus"
                class="text-white p-0.5 rounded-full w-5 h-5 flex items-center justify-center"
                :class="whatsappStatusColor"
              >
                <i class="i-ph-check-bold text-sm" />
              </span>
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

          <!-- Payzah Payment Gateway Settings Card -->
          <div
            class="flex flex-col flex-1 p-6 m-[1px] outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
          >
            <div class="flex items-start justify-between">
              <div
                class="flex h-12 w-12 mb-4 items-center justify-center rounded-md border border-n-weak shadow-sm bg-n-alpha-3 dark:bg-n-alpha-2"
              >
                <img
                  :src="payzahLogo"
                  alt="Payzah"
                  class="h-10 w-10 object-contain"
                />
              </div>
              <span
                v-tooltip="payzahStatus"
                class="text-white p-0.5 rounded-full w-5 h-5 flex items-center justify-center"
                :class="payzahStatusColor"
              >
                <i class="i-ph-check-bold text-sm" />
              </span>
            </div>
            <div class="flex flex-col m-0 flex-1">
              <div
                class="font-medium mb-2 text-n-slate-12 flex justify-between items-center"
              >
                <span class="text-base font-semibold">
                  {{ $t('INTEGRATION_SETTINGS.PAYZAH.TITLE') }}
                </span>
                <router-link :to="payzahSettingsURL">
                  <Button :label="$t('INTEGRATION_APPS.CONFIGURE')" link />
                </router-link>
              </div>
              <p class="text-n-slate-11">
                {{ $t('INTEGRATION_SETTINGS.PAYZAH.DESCRIPTION') }}
              </p>
            </div>
          </div>

          <!-- Tap Payment Gateway Settings Card -->
          <div
            class="flex flex-col flex-1 p-6 m-[1px] outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
          >
            <div class="flex items-start justify-between">
              <div
                class="flex h-12 w-12 mb-4 items-center justify-center rounded-md border border-n-weak shadow-sm bg-n-alpha-3 dark:bg-n-alpha-2"
              >
                <i class="i-lucide-credit-card text-3xl text-blue-600" />
              </div>
              <span
                v-tooltip="tapStatus"
                class="text-white p-0.5 rounded-full w-5 h-5 flex items-center justify-center"
                :class="tapStatusColor"
              >
                <i class="i-ph-check-bold text-sm" />
              </span>
            </div>
            <div class="flex flex-col m-0 flex-1">
              <div
                class="font-medium mb-2 text-n-slate-12 flex justify-between items-center"
              >
                <span class="text-base font-semibold">
                  {{ $t('INTEGRATION_SETTINGS.TAP.TITLE') }}
                </span>
                <router-link :to="tapSettingsURL">
                  <Button :label="$t('INTEGRATION_APPS.CONFIGURE')" link />
                </router-link>
              </div>
              <p class="text-n-slate-11">
                {{ $t('INTEGRATION_SETTINGS.TAP.DESCRIPTION') }}
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
