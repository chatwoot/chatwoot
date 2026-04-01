<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useBranding } from 'shared/composables/useBranding';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/${props.id}`)
);
</script>

<template>
  <div
    class="flex flex-col rounded-xl border border-outline-variant/15 bg-surface-container-lowest/80 p-5 shadow-sm transition-shadow hover:shadow-md"
  >
    <div class="flex items-start justify-between gap-3">
      <div class="flex h-12 w-12 shrink-0">
        <img
          :src="`/dashboard/images/integrations/${id}.png`"
          class="max-w-full rounded-lg border border-outline-variant/15 bg-surface-container-lowest shadow-sm block dark:hidden"
        />
        <img
          :src="`/dashboard/images/integrations/${id}-dark.png`"
          class="max-w-full rounded-lg border border-outline-variant/15 bg-surface-container-lowest shadow-sm hidden dark:block"
        />
      </div>
      <span
        v-tooltip="integrationStatus"
        class="inline-flex size-8 shrink-0 items-center justify-center rounded-full"
        :class="
          enabled
            ? 'bg-secondary/15 text-secondary'
            : 'bg-on-surface-variant/10 text-on-surface-variant'
        "
      >
        <Icon
          :icon="enabled ? 'i-lucide-check' : 'i-lucide-minus'"
          class="size-4"
        />
      </span>
    </div>
    <div class="mt-4 flex min-h-0 flex-1 flex-col gap-2">
      <div class="flex items-start justify-between gap-2">
        <h3 class="mb-0 text-base font-semibold leading-snug text-on-surface">
          {{ name }}
        </h3>
        <router-link :to="actionURL" class="shrink-0">
          <Button :label="$t('INTEGRATION_APPS.CONFIGURE')" link teal />
        </router-link>
      </div>
      <p class="mb-0 text-sm leading-relaxed text-on-surface-variant">
        {{ replaceInstallationName(description) }}
      </p>
    </div>
  </div>
</template>
