<script>
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
export default {
  props: {
    integrationId: {
      type: String,
      required: true,
    },
  },
  emits: ['add', 'delete'],
  setup(props) {
    const { integration, hasConnectedHooks } = useIntegrationHook(
      props.integrationId
    );
    return { integration, hasConnectedHooks };
  },
};
</script>

<template>
  <div
    class="outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow flex-shrink flex-grow overflow-auto p-4"
  >
    <div class="flex">
      <div class="flex h-16 w-16 items-center justify-center">
        <img
          :src="`/dashboard/images/integrations/${integrationId}.png`"
          class="max-w-full rounded-md border border-n-weak shadow-sm block dark:hidden bg-n-alpha-3 dark:bg-n-alpha-2"
        />
        <img
          :src="`/dashboard/images/integrations/${integrationId}-dark.png`"
          class="max-w-full rounded-md border border-n-weak shadow-sm hidden dark:block bg-n-alpha-3 dark:bg-n-alpha-2"
        />
      </div>
      <div class="flex flex-col justify-center m-0 mx-4 flex-1">
        <h3 class="mb-1 text-xl font-medium text-n-slate-12">
          {{ integration.name }}
        </h3>
        <p class="text-n-slate-11 text-sm leading-6">
          {{ integration.description }}
        </p>
      </div>
      <div class="flex justify-center items-center mb-0 w-[15%]">
        <div v-if="hasConnectedHooks">
          <div @click="$emit('delete', integration.hooks[0])">
            <woot-button class="nice alert">
              {{ $t('INTEGRATION_APPS.DISCONNECT.BUTTON_TEXT') }}
            </woot-button>
          </div>
        </div>
        <div v-else>
          <woot-button class="button nice" @click="$emit('add')">
            {{ $t('INTEGRATION_APPS.CONNECT.BUTTON_TEXT') }}
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>
