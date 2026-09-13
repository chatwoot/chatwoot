<script setup>
import { useI18n } from 'vue-i18n';
import { ref, watch, nextTick } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import PlaygroundRunDetails from './PlaygroundRunDetails.vue';

const props = defineProps({
  selectable: { type: Boolean, default: false },
  selectedMessageIndex: { type: Number, default: null },
  selectionLabel: { type: String, default: '' },
  messages: {
    type: Array,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});
const emit = defineEmits(['select']);

const messageContainer = ref(null);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const isUserMessage = sender => sender === 'user';

const getMessageAlignment = sender =>
  isUserMessage(sender) ? 'justify-end' : 'justify-start';

const getMessageDirection = sender =>
  isUserMessage(sender) ? 'flex-row-reverse' : 'flex-row';

const getAvatarName = sender =>
  isUserMessage(sender)
    ? t('CAPTAIN.PLAYGROUND.USER')
    : t('CAPTAIN.PLAYGROUND.ASSISTANT');

const messageStyle = message => {
  if (message.isError) {
    return 'bg-n-ruby-3 text-n-ruby-11 rounded-es-sm rounded-ee-xl rounded-t-xl';
  }

  return isUserMessage(message.sender)
    ? 'bg-n-solid-blue text-n-slate-12 rounded-ee-sm rounded-es-xl rounded-t-xl'
    : 'bg-n-solid-iris text-n-slate-12 rounded-es-sm rounded-ee-xl rounded-t-xl';
};

const scrollToBottom = async () => {
  await nextTick();
  if (messageContainer.value) {
    messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
  }
};

watch(() => props.messages.length, scrollToBottom);
</script>

<template>
  <div
    ref="messageContainer"
    class="flex-1 min-w-0 max-w-full overflow-y-auto mb-4 px-6 space-y-6"
  >
    <template v-for="(message, index) in messages" :key="index">
      <div class="flex" :class="getMessageAlignment(message.sender)">
        <div
          class="flex min-w-0 max-w-[90%] items-end gap-1.5 md:max-w-[75%]"
          :class="getMessageDirection(message.sender)"
        >
          <Avatar
            :name="getAvatarName(message.sender)"
            rounded-full
            :size="24"
            class="shrink-0"
          />
          <div
            class="min-w-0 px-4 py-3 text-sm [overflow-wrap:break-word]"
            :class="[
              messageStyle(message),
              {
                'ring-2 ring-n-brand':
                  selectable &&
                  !isUserMessage(message.sender) &&
                  selectedMessageIndex === index,
              },
            ]"
          >
            <div
              class="prose prose-bubble max-w-none overflow-x-auto [&>:last-child]:mb-0"
              v-html="formatMessage(message.content)"
            />
            <PlaygroundRunDetails
              v-if="message.runDetails && message.setupSummary"
              :run-details="message.runDetails"
              :setup-summary="message.setupSummary"
            />
            <button
              v-if="selectable && !isUserMessage(message.sender)"
              type="button"
              class="mt-3 rounded text-xs text-n-slate-11 hover:text-n-slate-12 focus-visible:ring-2 focus-visible:ring-n-brand"
              :aria-pressed="selectedMessageIndex === index"
              @click.stop="emit('select', index)"
            >
              {{ selectionLabel }}
            </button>
          </div>
        </div>
      </div>
      <slot name="message-output" :message="message" />
    </template>
    <div v-if="isLoading" class="flex justify-start">
      <div class="flex items-start gap-1.5">
        <Avatar :name="getAvatarName('assistant')" rounded-full :size="24" />
        <div
          class="max-w-sm rounded-lg p-3 text-sm bg-n-solid-iris text-n-slate-12"
        >
          <div class="flex gap-1">
            <div class="w-2 h-2 rounded-full bg-n-iris-10 animate-bounce" />
            <div
              class="w-2 h-2 rounded-full bg-n-iris-10 animate-bounce [animation-delay:0.2s]"
            />
            <div
              class="w-2 h-2 rounded-full bg-n-iris-10 animate-bounce [animation-delay:0.4s]"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
