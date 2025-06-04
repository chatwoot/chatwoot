<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';

const getters = useStoreGetters();
const accountId = getters.getCurrentAccountId;

const integrationId = 'linear';

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/linear`)
);

const openLinearAccount = () => {
  window.open(actionURL.value, '_blank');
};
</script>

<template>
  <div class="flex flex-col flex-1 p-3 m-[1px]">
    <div class="flex items-start justify-between">
      <div class="flex w-12 h-12 mb-3">
        <img
          :src="`/dashboard/images/integrations/${integrationId}.png`"
          class="block max-w-full border rounded-md shadow-sm border-n-weak dark:hidden dark:bg-n-alpha-2"
        />
        <img
          :src="`/dashboard/images/integrations/${integrationId}-dark.png`"
          class="hidden max-w-full border rounded-md shadow-sm border-n-weak dark:block dark:bg-n-alpha-2"
        />
      </div>
    </div>
    <div class="flex flex-col flex-1 m-0">
      <div class="flex items-center justify-between mb-1">
        <span class="text-sm leading-5 text-n-slate-12">{{
          $t('INTEGRATION_SETTINGS.LINEAR.CTA.TITLE')
        }}</span>
      </div>
      <p class="text-sm leading-5 text-n-slate-11">
        {{ $t('INTEGRATION_SETTINGS.LINEAR.CTA.DESCRIPTION') }}
      </p>
    </div>
    <NextButton faded slate class="mt-4" @click="openLinearAccount">
      {{ $t('INTEGRATION_SETTINGS.LINEAR.CTA.BUTTON_TEXT') }}
    </NextButton>
  </div>
</template>
