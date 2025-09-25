<script setup>
import { ref, nextTick, onMounted } from 'vue';

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
      class="w-full reset-base bg-n-alpha-3 ltr:pl-4 ltr:pr-12 rtl:pl-12 rtl:pr-4 py-3 text-sm border border-n-weak rounded-lg focus:outline-0 focus:outline-none focus:ring-2 focus:ring-n-blue-11 focus:border-n-blue-11 resize-none overflow-hidden max-h-[200px] mb-0 text-n-slate-12"
      rows="1"
      @input="handleInput"
      @keydown.enter.exact.prevent="sendMessage"
    />
    <button
      class="absolute ltr:right-1 rtl:left-1 top-1/2 -translate-y-1/2 h-9 w-10 flex items-center justify-center text-n-slate-11 hover:text-n-blue-11"
      type="submit"
    >
      <i class="i-ph-arrow-up" />
    </button>
  </form>
</template>
