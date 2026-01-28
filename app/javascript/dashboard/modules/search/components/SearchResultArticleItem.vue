<script setup>
import { computed } from 'vue';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { ARTICLE_STATUSES } from 'dashboard/helper/portalHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import MessageFormatter from 'shared/helpers/MessageFormatter';

const props = defineProps({
  id: { type: [String, Number], default: 0 },
  title: { type: String, default: '' },
  description: { type: String, default: '' },
  category: { type: String, default: '' },
  locale: { type: String, default: '' },
  content: { type: String, default: '' },
  portalSlug: { type: String, required: true },
  accountId: { type: [String, Number], default: 0 },
  status: { type: String, default: '' },
  updatedAt: { type: Number, default: 0 },
});

const MAX_LENGTH = 300;

const navigateTo = computed(() => {
  return frontendURL(
    `accounts/${props.accountId}/portals/${props.portalSlug}/${props.locale}/articles/edit/${props.id}`
  );
});

const updatedAtTime = computed(() => {
  if (!props.updatedAt) return '';
  return dynamicTime(props.updatedAt);
});

const truncatedContent = computed(() => {
  if (!props.content) return props.description || '';

  // Use MessageFormatter to properly convert markdown to plain text
  const formatter = new MessageFormatter(props.content);
  const plainText = formatter.plainText.trim();

  return plainText.length > MAX_LENGTH
    ? `${plainText.substring(0, MAX_LENGTH)}...`
    : plainText;
});

const statusTextColor = computed(() => {
  switch (props.status) {
    case ARTICLE_STATUSES.ARCHIVED:
      return 'text-n-slate-12';
    case ARTICLE_STATUSES.DRAFT:
      return 'text-n-amber-11';
    default:
      return 'text-n-teal-11';
  }
});
</script>

<template>
  <router-link :to="navigateTo">
    <CardLayout
      layout="col"
      class="[&>div]:justify-start [&>div]:gap-2 [&>div]:px-4 [&>div]:pt-4 [&>div]:pb-5 [&>div]:items-start hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
    >
      <div class="min-w-0 flex-1 flex flex-col items-start gap-2 w-full">
        <div class="flex items-center min-w-0 justify-between gap-2 w-full">
          <div class="flex items-center gap-2">
            <h5
              class="text-sm font-medium leading-4 truncate min-w-0 text-n-slate-12"
            >
              {{ title }}
            </h5>
            <div v-if="category" class="w-px h-4 bg-n-strong mx-2" />
            <span
              v-if="category"
              class="text-xs inline-flex items-center font-medium rounded-md whitespace-nowrap capitalize bg-n-alpha-2 px-1.5 h-6 text-n-slate-12"
            >
              {{ category }}
            </span>
            <span
              v-if="status"
              class="text-xs inline-flex items-center font-medium rounded-md whitespace-nowrap capitalize bg-n-alpha-2 px-2 h-6"
              :class="statusTextColor"
            >
              {{ status }}
            </span>
          </div>
          <span
            v-if="updatedAtTime"
            class="text-sm font-normal min-w-0 truncate text-n-slate-11"
          >
            {{ updatedAtTime }}
          </span>
        </div>
        <p
          v-if="truncatedContent"
          class="text-sm leading-6 text-n-slate-11 line-clamp-2"
        >
          {{ truncatedContent }}
        </p>
      </div>
    </CardLayout>
  </router-link>
</template>
