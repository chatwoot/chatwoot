<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useInstallationName } from 'shared/mixins/globalConfigMixin';

const props = defineProps({
  id: {
    type: [String, Number],
    required: true,
  },
  name: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  enabled: {
    type: Boolean,
    default: false,
  },
});

const getters = useStoreGetters();
const accountId = getters.getCurrentAccountId;
const globalConfig = getters['globalConfig/get'];

const { t } = useI18n();

const integrationStatus = computed(() =>
  props.enabled
    ? t('INTEGRATION_APPS.STATUS.ENABLED')
    : t('INTEGRATION_APPS.STATUS.DISABLED')
);

const integrationStatusColor = computed(() =>
  props.enabled ? 'bg-green-500' : 'bg-slate-200'
);

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/${props.id}`)
);
</script>

<template>
  <div
    class="flex flex-col flex-1 p-6 bg-white border border-solid rounded-md dark:bg-slate-800 border-slate-50 dark:border-slate-700/50"
  >
    <div class="flex items-start justify-between">
      <div class="flex h-12 w-12 mb-4">
        <img
          :src="`/dashboard/images/integrations/${id}.png`"
          class="max-w-full rounded-md border border-slate-50 dark:border-slate-700/50 shadow-sm block dark:hidden bg-white dark:bg-slate-900"
        />
        <img
          :src="`/dashboard/images/integrations/${id}-dark.png`"
          class="max-w-full rounded-md border border-slate-50 dark:border-slate-700/50 shadow-sm hidden dark:block bg-white dark:bg-slate-900"
        />
      </div>
      <fluent-icon
        v-tooltip="integrationStatus"
        size="20"
        class="text-white p-0.5 rounded-full"
        :class="integrationStatusColor"
        icon="checkmark"
      />
    </div>
    <div class="flex flex-col m-0 flex-1">
      <div
        class="font-medium mb-2 text-slate-800 dark:text-slate-100 flex justify-between items-center"
      >
        <span class="text-base font-semibold">{{ name }}</span>
        <router-link :to="actionURL">
          <woot-button class="clear link">
            {{ $t('INTEGRATION_APPS.CONFIGURE') }}
          </woot-button>
        </router-link>
      </div>
      <p class="text-slate-700 dark:text-slate-200">
        {{ useInstallationName(description, globalConfig.installationName) }}
      </p>
    </div>
  </div>
</template>
