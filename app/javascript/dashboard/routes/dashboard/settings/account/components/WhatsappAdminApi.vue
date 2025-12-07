<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WhatsappAdminApi from 'dashboard/api/whatsappAdminApi';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const baseUrl = ref('');
const apiToken = ref('');
const portRangeStart = ref(3001);
const portRangeEnd = ref(3100);
const isTesting = ref(false);
const isSaving = ref(false);
const connectionStatus = ref('unknown'); // unknown, connected, failed, not_configured
const availablePorts = ref(0);

const connectionStatusClass = computed(() => {
  switch (connectionStatus.value) {
    case 'connected':
      return 'text-green-700 bg-green-100 dark:text-green-400 dark:bg-green-900/20';
    case 'failed':
      return 'text-red-700 bg-red-100 dark:text-red-400 dark:bg-red-900/20';
    case 'not_configured':
      return 'text-gray-700 bg-gray-100 dark:text-gray-400 dark:bg-gray-900/20';
    default:
      return 'text-gray-700 bg-gray-100 dark:text-gray-400 dark:bg-gray-900/20';
  }
});

const connectionStatusText = computed(() => {
  switch (connectionStatus.value) {
    case 'connected':
      return t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.STATUS.CONNECTED');
    case 'failed':
      return t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.STATUS.FAILED');
    case 'not_configured':
      return t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.STATUS.NOT_CONFIGURED');
    default:
      return t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.STATUS.UNKNOWN');
  }
});

const testConnection = async () => {
  isTesting.value = true;
  try {
    const response = await WhatsappAdminApi.checkAdminApiStatus();
    if (response.data.healthy) {
      connectionStatus.value = 'connected';
      availablePorts.value = response.data.available_ports || 0;
    } else if (response.data.configured) {
      connectionStatus.value = 'failed';
    } else {
      connectionStatus.value = 'not_configured';
    }
  } catch (error) {
    connectionStatus.value = 'failed';
  } finally {
    isTesting.value = false;
  }
};

// Watch for account changes to load existing settings
watch(
  currentAccount,
  account => {
    if (account) {
      baseUrl.value = account.whatsapp_admin_api_base_url || '';
      apiToken.value = account.whatsapp_admin_api_token || '';
      portRangeStart.value = account.whatsapp_admin_port_range_start || 3001;
      portRangeEnd.value = account.whatsapp_admin_port_range_end || 3100;

      if (baseUrl.value && apiToken.value) {
        testConnection();
      }
    }
  },
  { immediate: true }
);

const saveSettings = async () => {
  isSaving.value = true;
  try {
    await updateAccount({
      whatsapp_admin_api_base_url: baseUrl.value,
      whatsapp_admin_api_token: apiToken.value,
      whatsapp_admin_port_range_start: parseInt(portRangeStart.value, 10),
      whatsapp_admin_port_range_end: parseInt(portRangeEnd.value, 10),
    });
    useAlert(t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.SAVE_SUCCESS'));
    await testConnection();
  } catch (error) {
    useAlert(
      error.message || t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.SAVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.TITLE')"
    :description="t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.DESCRIPTION')"
    with-border
  >
    <div class="grid gap-5">
      <div
        v-if="connectionStatus !== 'unknown'"
        class="flex items-center justify-between p-3 rounded-lg border border-n-weak"
      >
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.CONNECTION_STATUS') }}
        </span>
        <span
          class="px-2 py-1 text-xs font-medium rounded-full"
          :class="connectionStatusClass"
        >
          {{ connectionStatusText }}
        </span>
      </div>

      <form class="grid gap-4" @submit.prevent="saveSettings">
        <WithLabel
          :label="t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.BASE_URL.LABEL')"
        >
          <NextInput
            v-model="baseUrl"
            type="url"
            class="w-full"
            :placeholder="
              t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.BASE_URL.PLACEHOLDER')
            "
          />
        </WithLabel>

        <WithLabel
          :label="t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.TOKEN.LABEL')"
        >
          <NextInput
            v-model="apiToken"
            type="password"
            class="w-full"
            :placeholder="
              t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.TOKEN.PLACEHOLDER')
            "
          />
        </WithLabel>

        <div class="grid grid-cols-2 gap-4">
          <WithLabel
            :label="
              t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.PORT_RANGE.START_LABEL')
            "
          >
            <NextInput
              v-model.number="portRangeStart"
              type="number"
              min="1024"
              max="65535"
              class="w-full"
            />
          </WithLabel>

          <WithLabel
            :label="
              t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.PORT_RANGE.END_LABEL')
            "
          >
            <NextInput
              v-model.number="portRangeEnd"
              type="number"
              min="1024"
              max="65535"
              class="w-full"
            />
          </WithLabel>
        </div>

        <div
          v-if="connectionStatus === 'connected'"
          class="text-sm text-n-slate-11"
        >
          {{
            t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.AVAILABLE_PORTS', {
              count: availablePorts,
            })
          }}
        </div>

        <div class="flex gap-2">
          <NextButton
            type="button"
            variant="outline"
            :is-loading="isTesting"
            @click="testConnection"
          >
            {{ t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.TEST_CONNECTION') }}
          </NextButton>

          <NextButton blue type="submit" :is-loading="isSaving">
            {{ t('GENERAL_SETTINGS.WHATSAPP_ADMIN_API.SAVE') }}
          </NextButton>
        </div>
      </form>
    </div>
  </SectionLayout>
</template>
