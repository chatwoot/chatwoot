<script setup>
import { ref, nextTick, onMounted } from 'vue';

const props = defineProps({
  onSend: {
    type: Function,
    required: true,
  },
  // While Copilot works, the button stops it instead of sending. The agent can still type the next message.
  isWorking: {
    type: Boolean,
    default: false,
  },
  onStop: {
    type: Function,
    default: () => {},
  },
});
const message = defineModel({ type: String, default: '' });
const textareaRef = ref(null);
const isSending = ref(false);
const isStopping = ref(false);

const adjustHeight = () => {
  if (!textareaRef.value) return;

  // Reset height to auto to get the correct scrollHeight
  textareaRef.value.style.height = 'auto';
  // Set the height to the scrollHeight
  textareaRef.value.style.height = `${textareaRef.value.scrollHeight}px`;
};

const focus = () => textareaRef.value?.focus();

const sendMessage = async () => {
  const sentMessage = message.value;
  if (!sentMessage.trim() || isSending.value || props.isWorking) return;

  isSending.value = true;
  // A click on the send button moves focus to it, and the button stays disabled until the request ends.
  focus();
  // The box stays editable while sending, so from here on it only holds what is pasted or typed next.
  message.value = '';
  nextTick(adjustHeight);
  try {
    const isSuccess = await props.onSend(sentMessage);
    if (!isSuccess) {
      // The unsent message goes back in front of anything added while the request was in flight.
      message.value = message.value
        ? `${sentMessage}\n${message.value}`
        : sentMessage;
      nextTick(adjustHeight);
    }
  } finally {
    isSending.value = false;
  }
};

const stop = async () => {
  isStopping.value = true;
  try {
    await props.onStop();
  } finally {
    isStopping.value = false;
  }
};

defineExpose({ focus });

const handleInput = () => {
  nextTick(adjustHeight);
};

const handleEnterKey = event => {
  if (event.isComposing) return;
  event.preventDefault();
  sendMessage();
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
      class="w-full reset-base bg-n-alpha-3 ltr:pl-4 ltr:pr-12 rtl:pl-12 rtl:pr-4 py-3 text-sm border border-n-weak rounded-lg focus:outline-0 focus:outline-none focus:ring-2 focus:ring-n-blue-11 focus:border-n-blue-11 resize-none overflow-y-auto max-h-[200px] mb-0 text-n-slate-12"
      rows="1"
      @input="handleInput"
      @keydown.enter.exact="handleEnterKey"
    />
    <button
      v-if="isWorking"
      :disabled="isStopping"
      :aria-label="$t('CAPTAIN.COPILOT.STOP')"
      :title="$t('CAPTAIN.COPILOT.STOP')"
      class="absolute end-1 top-1/2 -translate-y-1/2 h-9 w-10 flex items-center justify-center text-n-slate-11 hover:text-n-blue-11 disabled:cursor-not-allowed disabled:opacity-60"
      type="button"
      @click="stop"
    >
      <i class="i-ph-stop-fill" />
    </button>
    <button
      v-else
      :disabled="isSending"
      class="absolute end-1 top-1/2 -translate-y-1/2 h-9 w-10 flex items-center justify-center text-n-slate-11 hover:text-n-blue-11 disabled:cursor-not-allowed disabled:opacity-60"
      type="submit"
    >
      <i class="i-ph-arrow-up" />
    </button>
  </form>
</template>
