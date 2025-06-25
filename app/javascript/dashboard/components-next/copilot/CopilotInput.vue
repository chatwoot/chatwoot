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
  <form
    class="border border-n-weak bg-n-alpha-3 rounded-lg h-12 flex"
    @submit.prevent="sendMessage"
  >
    <input
      v-model="message"
      type="text"
      :placeholder="$t('CAPTAIN.COPILOT.SEND_MESSAGE')"
      class="w-full reset-base bg-transparent px-4 py-3 text-n-slate-11 text-sm"
      @keyup.enter="sendMessage"
    />
    <button
      class="h-auto w-12 flex items-center justify-center text-n-slate-11"
      type="submit"
    >
      <i class="i-ph-arrow-up" />
    </button>
  </form>
</template>
