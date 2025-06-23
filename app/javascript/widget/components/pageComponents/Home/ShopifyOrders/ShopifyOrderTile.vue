<script setup>

// Props
const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
});

// Emits
const emit = defineEmits(['track', 'cancel', 'report-issue']);

// Methods
const handleTrack = () => {
  emit('track', props.order);
};

const handleCancel = () => {
  emit('cancel', props.order);
};

const handleReportIssue = () => {
  emit('report-issue', props.order);
};
</script>
<template>
  <div
    class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 w-full max-w-sm"
  >
    <!-- Order Header -->
    <div class="flex justify-between items-start mb-4">
      <div>
        <h2 class="text-base font-semibold text-gray-900">
          Order #{{ order.id }}
        </h2>
        <span class="text-sm text-gray-600"> Shipment </span>
      </div>
      <div class="text-right flex flex-col items-end">
        <div class="text-base font-semibold text-gray-900">
          ₹{{ order.total_price }}
        </div>
        <span
          class="px-2 py-1 rounded text-xs font-medium bg-gray-100 text-gray-700 uppercase"
        >
          {{ order.fulfillment_status }}
        </span>
      </div>
    </div>

    <!-- Action Buttons - Stacked for narrow width -->
    <div class="grid grid-cols-3 gap-2 mb-2">
      <button
        @click="handleTrack"
        class="bg-white hover:bg-gray-50 text-gray-700 font-medium py-2.5 px-2 rounded-lg text-sm transition-all duration-200 border border-gray-200 shadow-md hover:shadow-lg"
      >
        Track
      </button>
      <button
        @click="handleCancel"
        class="bg-white hover:bg-gray-50 text-gray-700 font-medium py-2.5 px-2 rounded-lg text-sm transition-all duration-200 border border-gray-200 shadow-md hover:shadow-lg"
      >
        Cancel
      </button>
      <button
        @click="handleReportIssue"
        class="bg-white hover:bg-gray-50 text-gray-700 font-medium py-2.5 px-2 rounded-lg text-sm transition-all duration-200 border border-gray-200 shadow-md hover:shadow-lg"
      >
        Report
      </button>
    </div>

    <!-- Order Items -->
    <div class="border-t pt-2">
      <div
        v-for="item in order.line_items"
        :key="item.id"
        class="flex items-center gap-3 p-2 border border-gray-200 rounded"
      >
        <!-- Product Image Placeholder -->

        <div
          class="w-12 h-12 bg-gray-100 rounded flex items-center justify-center flex-shrink-0"
        >
          <svg
            class="w-6 h-6 text-gray-400"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fill-rule="evenodd"
              d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z"
              clip-rule="evenodd"
            />
          </svg>
        </div>

        <!-- Product Details -->
        <div class="flex-1 min-w-0">
          <h3 class="font-medium text-gray-900 text-sm truncate">
            {{ item.name }}
          </h3>
          <div class="flex items-center gap-2 text-sm text-gray-600">
            <span>₹{{ item.price }}</span>
            <span>x{{ item.quantity }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
