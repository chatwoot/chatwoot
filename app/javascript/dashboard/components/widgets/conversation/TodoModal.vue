<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import Modal from 'dashboard/components/Modal.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  currentChat: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['cancel']);

const store = useStore();

const isOpen = ref(props.show);

// Watch for prop changes
watch(
  () => props.show,
  newVal => {
    isOpen.value = newVal;
  }
);

// Get current account ID from store
const accountId = computed(() => {
  const accountIdFromRoute = store.getters.getCurrentAccountId;
  return accountIdFromRoute;
});

// Get contact info from current chat
const contactName = computed(() => {
  return props.currentChat?.meta?.sender?.name || 'Unknown';
});

// Build iframe URL with query parameters
const iframeUrl = computed(() => {
  // Get URL from environment variable or use default
  // TODO: Replace with actual deployed URL
  const baseUrl =
    window.chatwootConfig?.todoAppUrl ||
    process.env.VUE_APP_TODO_URL ||
    'https://todolist-test.swgaming.dev/';
  const params = new URLSearchParams({
    accountId: accountId.value,
    chatId: props.currentChat?.id || '',
    contactName: contactName.value,
    embedded: 'true',
  });
  return `${baseUrl}?${params.toString()}`;
});

const closeModal = () => {
  isOpen.value = false;
  emit('cancel');
};
</script>

<template>
  <Modal v-model:show="isOpen" :on-close="closeModal" @close="closeModal">
    <div class="flex flex-col">
      <!-- Header -->
      <div class="p-4 border-b border-n-slate-5">
        <h1 class="text-n-slate-12 text-lg font-semibold">
          {{ $t('TODO.CREATE_TASK') }}
        </h1>
      </div>

      <!-- Body -->
      <div class="flex flex-col gap-4 p-4">
        <p class="text-n-slate-11">
          {{ $t('TODO.CREATE_TASK_FROM_CHAT') }}
          <strong>{{ contactName }}</strong>
        </p>

        <div class="iframe-container">
          <iframe
            :src="iframeUrl"
            class="todo-iframe"
            :title="$t('TODO.TITLE')"
            allow="clipboard-write"
          />
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end gap-2 p-4 border-t border-n-slate-5">
        <button class="button button--light" @click="closeModal">
          {{ $t('TODO.CLOSE') }}
        </button>
      </div>
    </div>
  </Modal>
</template>

<style scoped>
.iframe-container {
  width: 100%;
  height: 500px;
  border: 1px solid rgb(229, 231, 235);
  border-radius: 8px;
  overflow: hidden;
}

.todo-iframe {
  width: 100%;
  height: 100%;
  background: #ffffff;
  border: none;
}
</style>
