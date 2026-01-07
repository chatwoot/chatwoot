<script setup>
import { computed } from 'vue';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  isPdfDocument,
  formatDocumentLink,
} from 'shared/helpers/documentHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    default: '',
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
  externalLink: {
    type: String,
    required: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['action']);

const createdAt = computed(() => dynamicTime(props.createdAt));

const displayLink = computed(() => formatDocumentLink(props.externalLink));
const linkIcon = computed(() =>
  isPdfDocument(props.externalLink) ? 'i-lucide-file-text' : 'i-lucide-link'
);

const handleAction = (action, value) => {
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout class="[&>div]:px-5 [&>div]:gap-2">
    <div class="flex gap-1 justify-between w-full">
      <span class="text-heading-3 text-n-slate-12 line-clamp-1">
        {{ name }}
      </span>
      <div class="flex gap-2 items-center">
        <Button
          icon="i-woot-menu-list"
          slate
          sm
          ghost
          @click="handleAction('viewRelatedQuestions', 'viewRelatedQuestions')"
        />
        <div class="w-px h-3 bg-n-weak rounded-lg" />
        <Policy :permissions="['administrator']">
          <Button
            icon="i-woot-bin"
            slate
            sm
            ghost
            @click="handleAction('delete', 'delete')"
          />
        </Policy>
      </div>
    </div>
    <div class="flex gap-4 justify-between items-center w-full">
      <span
        class="flex gap-1 items-center text-sm truncate shrink-0 text-n-slate-11"
      >
        <Icon icon="i-woot-captain" />
        {{ assistant?.name || '' }}
      </span>
      <span
        class="flex flex-1 gap-1 justify-start items-center text-sm truncate text-n-slate-11"
      >
        <Icon :icon="linkIcon" class="shrink-0" />
        <span class="truncate text-body-main">{{ displayLink }}</span>
      </span>
      <div class="text-label-small shrink-0 text-n-slate-11 line-clamp-1">
        {{ createdAt }}
      </div>
    </div>
  </CardLayout>
</template>
