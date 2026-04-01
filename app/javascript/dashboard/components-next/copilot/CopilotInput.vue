<script setup>
import { ref, nextTick, onMounted } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['send']);
const message = ref('');
const textareaRef = ref(null);

const adjustHeight = () => {
  if (!textareaRef.value) return;

  // Reset height to auto to get the correct scrollHeight
  textareaRef.value.style.height = 'auto';
  // Set the height to the scrollHeight
  textareaRef.value.style.height = `${textareaRef.value.scrollHeight}px`;
};

const sendMessage = () => {
  if (message.value.trim()) {
    emit('send', message.value);
    message.value = '';
    // Reset textarea height after sending
    nextTick(() => {
      adjustHeight();
    });
  }
};

const handleInput = () => {
  nextTick(adjustHeight);
};

onMounted(() => {
  nextTick(adjustHeight);
});
</script>

<template>
  <form class="relative" @submit.prevent="sendMessage">
    <textarea
      ref="textareaRef"
      v-model="message"
      :placeholder="$t('CAPTAIN.COPILOT.SEND_MESSAGE')"
      class="reset-base mb-0 max-h-[200px] w-full resize-none overflow-hidden rounded-lg border border-solid border-outline-variant/30 bg-surface-container-lowest py-3 text-sm text-on-surface placeholder:text-on-primary-container/70 focus:border-secondary focus:outline-none focus:ring-1 focus:ring-secondary focus:ring-offset-0 ltr:pl-4 ltr:pr-12 rtl:pl-12 rtl:pr-4"
      rows="1"
      @input="handleInput"
      @keydown.enter.exact.prevent="sendMessage"
    />
    <button
      class="absolute top-1/2 flex h-9 w-10 -translate-y-1/2 items-center justify-center rounded-lg text-on-surface-variant transition-colors hover:bg-surface-container-high hover:text-secondary ltr:right-1 rtl:left-1"
      type="submit"
    >
      <Icon icon="i-lucide-arrow-up" class="size-5" />
    </button>
  </form>
</template>
