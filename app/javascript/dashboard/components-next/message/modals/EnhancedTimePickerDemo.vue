<script setup>
import { ref } from 'vue';
import EnhancedTimePickerModal from './EnhancedTimePickerModal.vue';

const showModal = ref(false);
const timePickerResult = ref(null);

const businessHours = {
  monday: { start: '09:00', end: '17:00', enabled: true },
  tuesday: { start: '09:00', end: '17:00', enabled: true },
  wednesday: { start: '09:00', end: '17:00', enabled: true },
  thursday: { start: '09:00', end: '17:00', enabled: true },
  friday: { start: '09:00', end: '17:00', enabled: true },
  saturday: { start: '10:00', end: '16:00', enabled: false },
  sunday: { start: '10:00', end: '16:00', enabled: false },
};

const existingBookings = [
  {
    startTime: '2025-09-18T14:00:00Z',
    endTime: '2025-09-18T15:00:00Z',
  },
  {
    startTime: '2025-09-19T10:00:00Z',
    endTime: '2025-09-19T11:30:00Z',
  },
];

const handleSave = data => {
  timePickerResult.value = data;
  console.log('Enhanced Time Picker Data:', data);
};

const handlePreview = data => {
  console.log('Preview Data:', data);
};
</script>

<template>
  <div class="p-6 max-w-4xl mx-auto">
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-n-slate-12 dark:text-n-slate-1 mb-2">
        Enhanced Time Picker Demo
      </h1>
      <p class="text-n-slate-11 dark:text-n-slate-3">
        Demonstration of the comprehensive time picker modal component for Apple
        Messages for Business
      </p>
    </div>

    <!-- Demo Controls -->
    <div
      class="bg-white dark:bg-n-slate-1 rounded-lg border border-n-weak dark:border-n-slate-6 p-6 mb-6"
    >
      <h2
        class="text-lg font-semibold text-n-slate-12 dark:text-n-slate-1 mb-4"
      >
        Demo Controls
      </h2>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div class="space-y-2">
          <h3 class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11">
            Features
          </h3>
          <ul class="text-sm text-n-slate-11 dark:text-n-slate-10 space-y-1">
            <li>✅ Predefined time intervals (15, 30, 60, 120 minutes)</li>
            <li>✅ Custom time range selection</li>
            <li>✅ Business hours constraints</li>
            <li>✅ Availability-based slot filtering</li>
            <li>✅ Timezone-aware scheduling</li>
            <li>✅ Dynamic slot generation</li>
            <li>✅ Visual availability indicators</li>
            <li>✅ Keyboard navigation support</li>
            <li>✅ Screen reader accessibility</li>
            <li>✅ Smooth animations</li>
          </ul>
        </div>

        <div class="space-y-2">
          <h3 class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11">
            Configuration
          </h3>
          <ul class="text-sm text-n-slate-11 dark:text-n-slate-10 space-y-1">
            <li><strong>Business Hours:</strong> Mon-Fri 9AM-5PM</li>
            <li><strong>Service Duration:</strong> 60 minutes</li>
            <li>
              <strong>Timezone:</strong>
              {{ Intl.DateTimeFormat().resolvedOptions().timeZone }}
            </li>
            <li>
              <strong>Existing Bookings:</strong>
              {{ existingBookings.length }} conflicts
            </li>
          </ul>
        </div>
      </div>

      <button
        class="px-6 py-3 bg-n-blue-9 dark:bg-n-blue-10 text-white dark:text-n-slate-12 rounded-lg hover:bg-n-blue-10 dark:hover:bg-n-blue-11 transition-colors font-medium"
        @click="showModal = true"
      >
        Open Enhanced Time Picker
      </button>
    </div>

    <!-- Result Display -->
    <div
      v-if="timePickerResult"
      class="bg-n-green-1 dark:bg-n-green-2 border border-n-green-6 dark:border-n-green-7 rounded-lg p-6"
    >
      <h2
        class="text-lg font-semibold text-n-green-11 dark:text-n-green-10 mb-4"
      >
        Generated Time Picker Data
      </h2>

      <div
        class="bg-white dark:bg-n-alpha-2 rounded-lg p-4 border border-n-green-6 dark:border-n-green-7"
      >
        <pre
          class="text-sm text-n-slate-12 dark:text-n-slate-11 overflow-x-auto"
          >{{ JSON.stringify(timePickerResult, null, 2) }}</pre>
      </div>

      <div class="mt-4 text-sm text-n-green-10 dark:text-n-green-9">
        This data structure is compatible with Apple Messages for Business time
        picker format and can be sent directly to the Apple Messages gateway.
      </div>
    </div>

    <!-- Enhanced Time Picker Modal -->
    <EnhancedTimePickerModal
      :show="showModal"
      :business-hours="businessHours"
      :timezone="Intl.DateTimeFormat().resolvedOptions().timeZone"
      :existing-bookings="existingBookings"
      :service-duration="60"
      @close="showModal = false"
      @save="handleSave"
      @preview="handlePreview"
    />
  </div>
</template>

<style scoped>
pre {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
}
</style>
