<script setup>
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import { useBranding } from 'shared/composables/useBranding';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  integrationId: {
    type: String,
    required: true,
  },
});

defineEmits(['add', 'delete']);

const { integration, hasConnectedHooks } = useIntegrationHook(
  props.integrationId
);

const { replaceInstallationName } = useBranding();
</script>

<template>
  <div
    class="flex w-full flex-col gap-6 rounded-2xl border border-outline-variant/10 bg-surface-container-low p-6 shadow-xl lg:flex-row lg:items-center lg:justify-between"
  >
    <div
      class="flex min-w-0 flex-1 flex-col items-start gap-4 sm:flex-row sm:items-center sm:gap-6"
    >
      <div class="flex h-16 w-16 shrink-0 items-center justify-center">
        <img
          :src="`/dashboard/images/integrations/${integrationId}.png`"
          class="block max-w-full rounded-lg border border-outline-variant/15 bg-surface-container-lowest shadow-sm dark:hidden"
        />
        <img
          :src="`/dashboard/images/integrations/${integrationId}-dark.png`"
          class="hidden max-w-full rounded-lg border border-outline-variant/15 bg-surface-container-lowest shadow-sm dark:block"
        />
      </div>
      <div class="min-w-0 flex-1">
        <h3 class="mb-1 text-xl font-bold tracking-tight text-on-surface">
          {{ integration.name }}
        </h3>
        <p class="mb-0 text-sm leading-relaxed text-on-surface-variant">
          {{ replaceInstallationName(integration.description) }}
        </p>
      </div>
    </div>
    <div
      class="flex w-full shrink-0 justify-stretch sm:justify-end lg:w-auto lg:justify-center"
    >
      <NextButton
        v-if="hasConnectedHooks && integration.hooks?.[0]"
        ruby
        faded
        lg
        class="w-full font-semibold sm:w-auto"
        :label="$t('INTEGRATION_APPS.DISCONNECT.BUTTON_TEXT')"
        @click="$emit('delete', integration.hooks[0])"
      />
      <NextButton
        v-else
        teal
        faded
        lg
        class="w-full font-semibold sm:w-auto"
        :label="$t('INTEGRATION_APPS.CONNECT.BUTTON_TEXT')"
        @click="$emit('add')"
      />
    </div>
  </div>
</template>
