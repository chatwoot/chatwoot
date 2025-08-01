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

const toolStatus = computed(() =>
  props.enabled
    ? t('CAPTAIN.TOOLS.STATUS.ENABLED')
    : t('CAPTAIN.TOOLS.STATUS.DISABLED')
);

const toolStatusColor = computed(() =>
  props.enabled ? 'bg-n-teal-9' : 'bg-n-slate-8'
);

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/captain/tools/${props.id}`)
);
</script>

<template>
  <div
    class="flex flex-col flex-1 p-6 m-[1px] outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow relative"
  >
    <div class="flex items-start justify-between">
      <span
        v-tooltip="toolStatus"
        class="text-white p-0.5 rounded-full w-5 h-5 flex items-center justify-center absolute top-6 right-6"
        :class="toolStatusColor"
      >
        <i class="i-ph-check-bold text-sm" />
      </span>
    </div>
    <div class="flex flex-col m-0 flex-1">
      <div
        class="font-medium mb-2 text-n-slate-12 flex justify-between items-center"
      >
        <span class="text-base font-semibold">{{ name }}</span>
      </div>
      <p class="text-n-slate-11">
        {{ useInstallationName(description, globalConfig.installationName) }}
      </p>
    </div>
  </div>
</template>
