<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from './FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import { CONTENT_TYPES, MESSAGE_TYPES } from '../../constants';
import { useMessageContext } from '../../provider.js';
import { onMounted } from 'vue';
import { useStore } from 'vuex';

const store = useStore();

const { content, contentType, attachments, contentAttributes, messageType } =
  useMessageContext();

const isTemplate = computed(() => {
  return messageType.value === MESSAGE_TYPES.TEMPLATE;
});

const isEmpty = computed(() => {
  return !content.value && !attachments.value?.length;
});
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="text">
    <div class="gap-3 flex flex-col">
      <span v-if="isEmpty" class="text-n-slate-11">
        {{ $t('CONVERSATION.NO_CONTENT') }}
      </span>
      <FormattedContent v-if="content" :content="content" />
      <AttachmentChips :attachments="attachments" class="gap-2" />

      <div
        v-if="
          contentType == 'calling_event' &&
          activeCall?.room_id != contentAttributes.callRoom
        "
        class="px-2 py-1 rounded-lg bg-n-alpha-3"
      >
        {{
          !contentAttributes.callStatus
            ? 'Missed'
            : contentAttributes.callStatus[0].toUpperCase() +
              contentAttributes.callStatus.slice(1)
        }}
      </div>

      <template v-if="isTemplate">
        <div
          v-if="contentAttributes.submittedEmail"
          class="px-2 py-1 rounded-lg bg-n-alpha-3"
        >
          {{ contentAttributes.submittedEmail }}
        </div>
      </template>
    </div>
  </BaseBubble>
</template>

<style>
p:last-child {
  margin-bottom: 0;
}
</style>
