<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';

const { contentAttributes } = useMessageContext();

const event = computed(() => contentAttributes.value?.event || {});
const timeslots = computed(() => contentAttributes.value?.timeslots || []);
const timezoneOffset = computed(
  () => contentAttributes.value?.timezone_offset || 0
);

const formatDateTime = dateTimeString => {
  const date = new Date(dateTimeString);
  return {
    date: date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    }),
    time: date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    }),
  };
};

const formatDuration = minutes => {
  if (minutes < 60) {
    return `${minutes}m`;
  }
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  return remainingMinutes > 0 ? `${hours}h ${remainingMinutes}m` : `${hours}h`;
};

const handleTimeSlotClick = slot => {
  // In a real implementation, this would send the selection back to the server
  console.log('Time slot selected:', slot);
};
</script>

<template>
  <BaseBubble>
    <div class="apple-time-picker max-w-sm">
      <!-- Event Header -->
      <div class="mb-4 p-3 bg-n-alpha-2 rounded-lg">
        <h3 class="text-sm font-medium text-n-slate-12 mb-1">
          {{ event.title || 'Schedule Time' }}
        </h3>
        <p v-if="event.description" class="text-xs text-n-slate-11">
          {{ event.description }}
        </p>
      </div>

      <!-- Time Slots -->
      <div class="space-y-2">
        <button
          v-for="slot in timeslots"
          :key="slot.identifier"
          class="w-full flex items-center justify-between p-3 bg-n-alpha-1 hover:bg-n-alpha-2 rounded-lg transition-colors text-left border border-n-weak hover:border-n-strong"
          @click="handleTimeSlotClick(slot)"
        >
          <div class="flex-1">
            <div class="flex items-center space-x-3">
              <!-- Date -->
              <div class="text-center">
                <div class="text-xs text-n-slate-11 uppercase tracking-wide">
                  {{ formatDateTime(slot.startTime).date }}
                </div>
              </div>

              <!-- Time -->
              <div>
                <div class="text-sm font-medium text-n-slate-12">
                  {{ formatDateTime(slot.startTime).time }}
                </div>
                <div v-if="slot.duration" class="text-xs text-n-slate-11">
                  {{ formatDuration(slot.duration) }}
                </div>
              </div>
            </div>
          </div>

          <!-- Availability Indicator -->
          <div class="flex-shrink-0 ml-3">
            <div class="w-3 h-3 bg-n-solid-green rounded-full" />
          </div>
        </button>
      </div>

      <!-- Empty State -->
      <div v-if="timeslots.length === 0" class="text-center py-6">
        <div class="text-n-slate-11 text-sm">No available time slots</div>
      </div>

      <!-- Footer Note -->
      <div
        class="mt-4 text-xs text-n-slate-11 text-center bg-n-alpha-1 rounded p-2"
      >
        Select a time slot to schedule
      </div>
    </div>
  </BaseBubble>
</template>

<style scoped>
.apple-time-picker {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

button:active {
  transform: scale(0.98);
}
</style>
