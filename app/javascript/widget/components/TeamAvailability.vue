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
  <div
    class="flex flex-col gap-3 w-full shadow outline-1 outline outline-n-container rounded-xl bg-n-background dark:bg-n-solid-2 px-5 py-4"
  >
    <AvailabilityContainer :agents="availableAgents" show-header show-avatars />

    <button
      class="inline-flex items-center gap-1 font-medium text-n-slate-12"
      :style="{ color: widgetColor }"
      @click="startConversation"
    >
      <span>
        {{
          hasConversation
            ? $t('CONTINUE_CONVERSATION')
            : $t('START_CONVERSATION')
        }}
      </span>
      <i class="i-lucide-chevron-right size-5 mt-px" />
    </button>
  </div>
</template>
