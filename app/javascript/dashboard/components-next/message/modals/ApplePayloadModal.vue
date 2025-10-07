<script setup>
import { computed } from 'vue';
import Modal from 'dashboard/components/Modal.vue';

const props = defineProps({
  payload: { type: Object, default: null },
  status: { type: String, default: 'sent' },
  contentAttributes: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['close']);

const show = defineModel('show', { type: Boolean, default: false });

const isFailed = computed(() => props.status === 'failed');

const errorMessage = computed(() => {
  return (
    props.contentAttributes?.externalError ||
    props.contentAttributes?.external_error
  );
});

const debugInfo = computed(() => {
  const info = {
    status: props.status,
    timestamp: new Date().toISOString(),
  };

  if (errorMessage.value) {
    info.error = errorMessage.value;
  }

  return info;
});

const formattedPayload = computed(() => {
  if (!props.payload) {
    return 'No payload data available';
  }

  try {
    return JSON.stringify(props.payload, null, 2);
  } catch (e) {
    return 'Error formatting payload';
  }
});

const formattedDebugInfo = computed(() => {
  try {
    return JSON.stringify(debugInfo.value, null, 2);
  } catch (e) {
    return 'Error formatting debug info';
  }
});

const copyToClipboard = async () => {
  try {
    const fullData = {
      payload: props.payload,
      debug: debugInfo.value,
    };
    await navigator.clipboard.writeText(JSON.stringify(fullData, null, 2));
    window.bus.$emit('newToastMessage', 'Payload copied to clipboard');
  } catch (err) {
    window.bus.$emit('newToastMessage', 'Failed to copy payload');
  }
};

const closeModal = () => {
  emit('close');
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable @intlify/vue-i18n/no-raw-text -->
<template>
  <Modal
    v-model:show="show"
    :on-close="closeModal"
    :show-close-button="false"
    size="large"
  >
    <div class="flex flex-col h-full max-h-[80vh]">
      <div
        class="flex items-start justify-between p-4 border-b border-n-weak gap-4"
      >
        <div class="flex-1 min-w-0">
          <h3 class="text-base font-semibold text-n-slate-12 mb-1">
            Apple Messages Payload
          </h3>
          <p class="text-xs text-n-slate-11">
            JSON payload sent to mspgw.apple.com
          </p>
        </div>
        <div class="flex items-center gap-2 flex-shrink-0">
          <button
            class="px-3 py-1.5 text-xs font-medium text-n-slate-12 bg-n-alpha-2 hover:bg-n-alpha-3 rounded-md transition-colors flex items-center gap-1.5"
            @click="copyToClipboard"
          >
            <fluent-icon icon="copy" size="14" />
            Copy
          </button>
          <button
            class="p-1.5 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-md transition-colors"
            @click="closeModal"
          >
            <fluent-icon icon="dismiss" size="18" />
          </button>
        </div>
      </div>

      <div class="flex-1 overflow-auto p-4 bg-n-slate-1">
        <!-- Error Alert for Failed Messages -->
        <div
          v-if="isFailed"
          class="mb-4 p-3 bg-n-ruby-2 border border-n-ruby-6 rounded-md"
        >
          <div class="flex items-start gap-2">
            <fluent-icon
              icon="error-circle"
              size="16"
              class="text-n-ruby-11 mt-0.5 flex-shrink-0"
            />
            <div class="flex-1 min-w-0">
              <div class="text-sm font-semibold text-n-ruby-12 mb-1">
                Message Failed to Send
              </div>
              <div
                v-if="errorMessage"
                class="text-xs text-n-ruby-11 font-mono break-all"
              >
                {{ errorMessage }}
              </div>
            </div>
          </div>
        </div>

        <!-- Debug Information -->
        <div class="mb-4">
          <div class="flex items-center gap-2 mb-2">
            <fluent-icon icon="info" size="14" class="text-n-slate-11" />
            <h4 class="text-xs font-semibold text-n-slate-12">
              Debug Information
            </h4>
          </div>
          <pre
            class="p-3 bg-n-slate-2 rounded-md text-xs font-mono text-n-slate-12 overflow-x-auto border border-n-weak"
          >
            {{ formattedDebugInfo }}
          </pre>
        </div>

        <!-- Payload -->
        <div>
          <div class="flex items-center gap-2 mb-2">
            <fluent-icon icon="code" size="14" class="text-n-slate-11" />
            <h4 class="text-xs font-semibold text-n-slate-12">
              Request Payload
            </h4>
          </div>
          <pre
            class="p-4 bg-n-slate-2 rounded-md text-xs font-mono text-n-slate-12 overflow-x-auto border border-n-weak leading-relaxed"
          >
            {{ formattedPayload }}
          </pre>
        </div>
      </div>
    </div>
  </Modal>
</template>
