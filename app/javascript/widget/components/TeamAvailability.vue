<script setup>
import { IFrameHelper } from 'widget/helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from '../constants/sdkEvents';
import AvailabilityContainer from 'widget/components/Availability/AvailabilityContainer.vue';
import { useMapGetter } from 'dashboard/composables/store.js';

const props = defineProps({
  availableAgents: { type: Array, default: () => [] },
  hasConversation: { type: Boolean, default: false },
});

const emit = defineEmits(['startConversation']);

const widgetColor = useMapGetter('appConfig/getWidgetColor');

const startConversation = () => {
  emit('startConversation');
  if (!props.hasConversation) {
    IFrameHelper.sendMessage({
      event: 'onEvent',
      eventIdentifier: CHATWOOT_ON_START_CONVERSATION,
      data: { hasConversation: false },
    });
  }
};
</script>

<template>
  <div class="w-full surface-card divide-y divide-n-weak dark:divide-n-strong">
    <div class="px-4 py-3">
      <AvailabilityContainer
        :agents="availableAgents"
        show-header
        show-avatars
      />
    </div>
    <button
      class="flex items-center justify-between w-full gap-2 px-4 py-3 text-base font-medium rounded-b-xl outline-none text-n-slate-12 transition-colors hover:bg-n-alpha-2 focus-visible:bg-n-alpha-2"
      @click="startConversation"
    >
      <span>
        {{
          hasConversation
            ? $t('CONTINUE_CONVERSATION')
            : $t('START_CONVERSATION')
        }}
      </span>
      <i
        class="i-lucide-arrow-right size-5 rtl:rotate-180"
        :style="{ color: widgetColor }"
        aria-hidden="true"
      />
    </button>
  </div>
</template>
