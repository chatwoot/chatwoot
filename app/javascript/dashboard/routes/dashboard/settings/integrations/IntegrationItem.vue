<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'dashboard/composables/useI18n';
import { frontendURL } from 'dashboard/helper/URLHelper';
import WootLabel from 'dashboard/components/ui/Label.vue';
import { useInstallationName } from 'shared/mixins/globalConfigMixin';

const props = defineProps({
  id: {
    type: [String, Number],
    required: true,
  },
  logo: {
    type: String,
    default: '',
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

const labelText = computed(() =>
  props.enabled
    ? t('INTEGRATION_APPS.STATUS.ENABLED')
    : t('INTEGRATION_APPS.STATUS.DISABLED')
);

const labelColor = computed(() => (props.enabled ? 'success' : 'secondary'));

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
          class="max-w-full rounded-md border border-slate-50 dark:border-slate-700/50 shadow-sm block dark:hidden"
        />
        <img
          :src="`/dashboard/images/integrations/${id}-dark.png`"
          class="max-w-full rounded-md border border-slate-50 dark:border-slate-700/50 shadow-sm hidden dark:block"
        />
      </div>
      <router-link :to="actionURL">
        <woot-button icon="settings" class="clear link">
          {{ $t('INTEGRATION_APPS.CONFIGURE') }}
        </woot-button>
      </router-link>
    </div>
    <div class="flex flex-col m-0 flex-1">
      <div
        class="text-xl font-medium mb-2 text-slate-800 dark:text-slate-100 flex justify-between items-center"
      >
        <span>{{ name }}</span>
        <woot-label
          :title="labelText"
          :color-scheme="labelColor"
          class="text-xs rounded-sm !mb-0"
        />
      </div>
      <p class="text-slate-700 dark:text-slate-200">
        {{ useInstallationName(description, globalConfig.installationName) }}
      </p>
    </div>
  </div>
</template>
