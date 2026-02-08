<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useInstallationName } from 'shared/mixins/globalConfigMixin';

import Button from 'dashboard/components-next/button/Button.vue';

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
  props.enabled ? 'bg-n-teal-9' : 'bg-n-slate-8'
);

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/${props.id}`)
);
</script>

<template>
  <div
    class="flex flex-col flex-1 p-6 m-[1px] outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
  >
    <div class="flex items-start justify-between">
      <div class="flex h-12 w-12 mb-4">
        <img
          :src="`/dashboard/images/integrations/${id}.png`"
          class="max-w-full rounded-md border border-n-weak shadow-sm block dark:hidden bg-n-alpha-3 dark:bg-n-alpha-2"
        />
        <img
          :src="`/dashboard/images/integrations/${id}-dark.png`"
          class="max-w-full rounded-md border border-n-weak shadow-sm hidden dark:block bg-n-alpha-3 dark:bg-n-alpha-2"
        />
      </div>
      <span
        v-tooltip="integrationStatus"
        class="text-white p-0.5 rounded-full w-5 h-5 flex items-center justify-center"
        :class="integrationStatusColor"
      >
        <i class="i-ph-check-bold text-sm" />
      </span>
    </div>
    <div class="flex flex-col m-0 flex-1">
      <div
        class="font-medium mb-2 text-n-slate-12 flex justify-between items-center"
      >
        <span class="text-base font-semibold">{{ name }}</span>
        <router-link :to="actionURL">
          <Button :label="$t('INTEGRATION_APPS.CONFIGURE')" link />
        </router-link>
      </div>
      <p class="text-n-slate-11">
        {{ useInstallationName(description, globalConfig.installationName) }}
      </p>
    </div>
  </div>
</template>
