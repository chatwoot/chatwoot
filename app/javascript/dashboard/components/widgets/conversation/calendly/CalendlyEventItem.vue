<script setup>
import { computed } from 'vue';
import { format } from 'date-fns';

const props = defineProps({
  event: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['cancel']);

const eventName = computed(() => props.event.name || 'Meeting');

const formattedTime = computed(() => {
  if (!props.event.start_time) return '';
  return format(new Date(props.event.start_time), 'MMM d, yyyy h:mm a');
});

const statusClass = computed(() => {
  if (props.event.status === 'canceled') {
    return 'bg-n-ruby-5 text-n-ruby-12';
  }
  return 'bg-n-teal-5 text-n-teal-12';
});

const statusLabel = computed(() => {
  return props.event.status === 'canceled' ? 'Canceled' : 'Active';
});

const eventUuid = computed(() => {
  const uri = props.event.uri || '';
  return uri.split('/').pop();
});
</script>

<template>
  <div
    class="py-3 border-b border-n-weak last:border-b-0 flex flex-col gap-1.5"
  >
    <div class="flex justify-between items-center">
      <span class="font-medium text-n-slate-12 truncate">
        {{ eventName }}
      </span>
      <span
        :class="statusClass"
        class="text-xs px-2 py-1 rounded capitalize truncate"
      >
        {{ statusLabel }}
      </span>
    </div>
    <div class="text-sm text-n-slate-11">
      {{ formattedTime }}
    </div>
    <div v-if="event.status === 'active'" class="flex mt-1">
      <button
        class="text-xs text-n-ruby-11 hover:text-n-ruby-12 cursor-pointer"
        @click="emit('cancel', eventUuid)"
      >
        {{ $t('CONVERSATION_SIDEBAR.CALENDLY.CANCEL_EVENT') }}
      </button>
    </div>
  </div>
</template>
