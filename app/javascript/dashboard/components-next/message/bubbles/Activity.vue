<script setup>
import { ref, computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import BaseBubble from './Base.vue';
import PostContent from './ActivityContent/PostContent.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes, createdAt } = useMessageContext();

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, h:mm a')
);

const hasAdditionalContent = computed(() => {
  return Object.keys(contentAttributes.value).length !== 0;
});

const isPostActivityMessage = computed(() => {
  return contentAttributes.value.activityType === 'post';
});

const toggleExpand = ref(false);
</script>

<template>
  <BaseBubble
    v-tooltip.top="readableTime"
    class="!rounded-xl flex flex-col items-center min-w-0 gap-2"
    data-bubble-name="activity"
  >
    <span class="text-sm px-4 py-2">
      <span v-dompurify-html="content" :title="content" />
      <a
        class="underline text-n-blue-text ms-1"
        rel="noopener noreferrer"
        target="_blank"
        :href="contentAttributes.link"
      >
        {{ $t('MESSAGES.ACTIVITY_MESSAGE.VIEW_DETAILS') }}
      </a>
    </span>
    <div
      v-if="hasAdditionalContent"
      class="flex flex-col items-center gap-2 py-1 w-full"
    >
      <PostContent
        v-if="isPostActivityMessage"
        :content-attributes="contentAttributes"
        :toggle-expand="toggleExpand"
      />
      <button
        class="text-n-blue-text text-sm font-medium hover:underline focus:outline-none"
        @click="toggleExpand = !toggleExpand"
      >
        {{
          toggleExpand
            ? $t('MESSAGES.ACTIVITY_MESSAGE.COLLAPSE')
            : $t('MESSAGES.ACTIVITY_MESSAGE.EXPAND')
        }}
      </button>
    </div>
  </BaseBubble>
</template>
