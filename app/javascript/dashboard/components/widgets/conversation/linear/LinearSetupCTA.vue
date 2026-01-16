<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { usePolicy } from 'dashboard/composables/usePolicy';

const { isAdmin } = useAdmin();
const { checkPermissions } = usePolicy();
const getters = useStoreGetters();
const accountId = getters.getCurrentAccountId;

const integrationId = 'linear';

// CommMate: Allow integration setup if admin or has settings_integrations_manage permission
const canManageIntegrations = computed(
  () => isAdmin.value || checkPermissions(['settings_integrations_manage'])
);

const actionURL = computed(() =>
  frontendURL(
    `accounts/${accountId.value}/settings/integrations/${integrationId}`
  )
);

const openLinearAccount = () => {
  window.open(actionURL.value, '_blank');
};
</script>

<template>
  <div class="flex flex-col p-3">
    <div class="w-12 h-12 mb-3">
      <img
        :src="`/dashboard/images/integrations/${integrationId}.png`"
        class="object-contain w-full h-full border rounded-md shadow-sm border-n-weak dark:hidden dark:bg-n-alpha-2"
      />
      <img
        :src="`/dashboard/images/integrations/${integrationId}-dark.png`"
        class="hidden object-contain w-full h-full border rounded-md shadow-sm border-n-weak dark:block"
      />
    </div>

    <div class="flex-1 mb-4">
      <h3 class="mb-1.5 text-sm font-medium text-n-slate-12">
        {{ $t('INTEGRATION_SETTINGS.LINEAR.CTA.TITLE') }}
      </h3>
      <p v-if="canManageIntegrations" class="text-sm text-n-slate-11">
        {{ $t('INTEGRATION_SETTINGS.LINEAR.CTA.DESCRIPTION') }}
      </p>
      <p v-else class="text-sm text-n-slate-11">
        {{ $t('INTEGRATION_SETTINGS.LINEAR.CTA.AGENT_DESCRIPTION') }}
      </p>
    </div>

    <NextButton
      v-if="canManageIntegrations"
      faded
      slate
      @click="openLinearAccount"
    >
      {{ $t('INTEGRATION_SETTINGS.LINEAR.CTA.BUTTON_TEXT') }}
    </NextButton>
  </div>
</template>
