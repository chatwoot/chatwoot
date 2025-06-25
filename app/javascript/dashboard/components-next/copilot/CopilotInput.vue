<script setup>
import { ref } from 'vue';

const emit = defineEmits(['send']);
const message = ref('');

const sendMessage = () => {
  if (message.value.trim()) {
    emit('send', message.value);
    message.value = '';
  }
};
</script>

<template>
  <form class="relative" @submit.prevent="sendMessage">
    <input
      v-model="message"
      type="text"
      :placeholder="$t('CAPTAIN.COPILOT.SEND_MESSAGE')"
      class="w-full reset-base bg-n-alpha-3 ltr:pl-4 ltr:pr-12 rtl:pl-12 rtl:pr-4 py-3 text-n-slate-11 text-sm border border-n-weak rounded-lg focus:outline-none focus:ring-1 focus:ring-n-blue-11 focus:border-n-blue-11"
      @keyup.enter="sendMessage"
    />
    <button
      class="absolute ltr:right-1 rtl:left-1 top-1/2 -translate-y-1/2 h-9 w-10 flex items-center justify-center text-n-slate-11 hover:text-n-blue-11"
      type="submit"
    >
      <i class="i-ph-arrow-up" />
    </button>
  </form>
</template>
