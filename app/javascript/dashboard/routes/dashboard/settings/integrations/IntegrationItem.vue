<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useBranding } from 'shared/composables/useBranding';

import Button from 'dashboard/components-next/button/Button.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import googleCalendarLogo from 'dashboard/assets/images/integrations/google-calendar.svg';

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

const { t } = useI18n();
const { replaceInstallationName } = useBranding();

const integrationStatus = computed(() =>
  props.enabled
    ? t('INTEGRATION_APPS.STATUS.ENABLED')
    : t('INTEGRATION_APPS.STATUS.DISABLED')
);

const integrationStatusColor = computed(() =>
  props.enabled ? 'teal' : 'slate'
);

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/${props.id}`)
);

const logoSrc = computed(() => {
  if (props.id === 'calendars') {
    return googleCalendarLogo;
  }
  return `/dashboard/images/integrations/${props.id}.png`;
});

const logoSrcDark = computed(() => {
  if (props.id === 'calendars') {
    return googleCalendarLogo;
  }
  return `/dashboard/images/integrations/${props.id}-dark.png`;
});
</script>

<template>
  <div
    class="flex flex-col flex-1 p-4 m-px outline outline-n-container outline-1 bg-n-card rounded-xl"
  >
    <div class="flex items-start justify-between">
      <div class="flex h-12 w-12 mb-2">
        <img
          :src="logoSrc"
          class="max-w-full rounded-md border border-n-weak shadow-sm block dark:hidden bg-n-alpha-3 dark:bg-n-alpha-2"
        />
        <img
          :src="logoSrcDark"
          class="max-w-full rounded-md border border-n-weak shadow-sm hidden dark:block bg-n-alpha-3 dark:bg-n-alpha-2"
        />
      </div>
      <Label
        :label="integrationStatus"
        :color="integrationStatusColor"
        compact
      />
    </div>
    <div class="flex flex-col m-0 flex-1">
      <div
        class="font-medium mb-2 text-n-slate-12 flex justify-between items-center"
      >
        <span class="text-heading-3 text-n-slate-12">{{ name }}</span>
        <router-link :to="actionURL">
          <Button
            :label="$t('INTEGRATION_APPS.CONFIGURE')"
            icon="i-woot-settings"
            link
            xs
          />
        </router-link>
      </div>
      <p class="text-n-slate-11 text-body-main">
        {{ replaceInstallationName(description) }}
      </p>
    </div>
  </div>
</template>
