<script setup>
import { computed } from 'vue';
import { frontendURL } from 'dashboard/helper/URLHelper.js';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { useInbox } from 'dashboard/composables/useInbox';
import { ATTACHMENT_TYPES } from 'dashboard/components-next/message/constants.js';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import FileChip from 'next/message/chips/File.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import TranscribedText from './TranscribedText.vue';

const props = defineProps({
  id: {
    type: Number,
    default: 0,
  },
  inboxId: {
    type: Number,
    default: 0,
  },
  isPrivate: {
    type: Boolean,
    default: false,
  },
  accountId: {
    type: [String, Number],
    default: '',
  },
  createdAt: {
    type: [String, Date, Number],
    default: '',
  },
  messageId: {
    type: Number,
    default: 0,
  },
  attachments: {
    type: Array,
    default: () => [],
  },
});

const { inbox } = useInbox(props.inboxId);

const navigateTo = computed(() => {
  const params = {};
  if (props.messageId) {
    params.messageId = props.messageId;
  }
  return frontendURL(
    `accounts/${props.accountId}/conversations/${props.id}`,
    params
  );
});

const createdAtTime = computed(() => {
  if (!props.createdAt) return '';
  return dynamicTime(props.createdAt);
});

const inboxName = computed(() => inbox.value?.name);

const inboxIcon = computed(() => {
  if (!inbox.value) return null;
  const { channelType, medium } = inbox.value;
  return getInboxIconByType(channelType, medium);
});

const fileAttachments = computed(() => {
  return props.attachments.filter(
    attachment => attachment.fileType !== ATTACHMENT_TYPES.AUDIO
  );
});

const audioAttachments = computed(() => {
  return props.attachments.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.AUDIO
  );
});
</script>

<template>
  <router-link :to="navigateTo">
    <CardLayout
      layout="col"
      class="[&>div]:justify-start [&>div]:gap-2 [&>div]:px-4 [&>div]:py-3 [&>div]:items-start hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
    >
      <div
        class="flex items-center min-w-0 justify-between gap-2 w-full h-7 mb-1"
      >
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-1.5 flex-shrink-0">
            <Icon
              icon="i-lucide-hash"
              class="flex-shrink-0 text-n-slate-11 size-4"
            />
            <span class="text-n-slate-12 text-sm leading-4">
              {{ id }}
            </span>
          </div>
          <div v-if="inboxName" class="w-px h-3 bg-n-strong" />
          <div v-if="inboxName" class="flex items-center gap-1.5 flex-shrink-0">
            <div
              v-if="inboxIcon"
              class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-alpha-2 size-4"
            >
              <Icon
                :icon="inboxIcon"
                class="flex-shrink-0 text-n-slate-11 size-2.5"
              />
            </div>
            <span class="text-sm leading-4 text-n-slate-12">
              {{ inboxName }}
            </span>
          </div>
          <div v-if="isPrivate" class="w-px h-3 bg-n-strong" />
          <div
            v-if="isPrivate"
            class="flex items-center text-n-amber-11 gap-1.5 flex-shrink-0"
          >
            <Icon icon="i-lucide-lock-keyhole" class="flex-shrink-0 size-3.5" />
            <span class="text-sm leading-4">
              {{ $t('SEARCH.PRIVATE') }}
            </span>
          </div>
        </div>
        <span
          v-if="createdAtTime"
          class="text-sm font-normal min-w-0 truncate text-n-slate-11"
        >
          {{ createdAtTime }}
        </span>
      </div>
      <slot />
      <div v-if="audioAttachments.length" class="mt-1.5 space-y-4 w-full">
        <div
          v-for="attachment in audioAttachments"
          :key="attachment.id"
          class="w-full"
        >
          <AudioChip
            class="bg-n-alpha-2 dark:bg-n-alpha-2 text-n-slate-12"
            :attachment="attachment"
            :show-transcribed-text="false"
            @click.prevent
          />
          <div v-if="attachment.transcribedText" class="pt-2">
            <TranscribedText :text="attachment.transcribedText" />
          </div>
        </div>
      </div>
      <div
        v-if="fileAttachments.length"
        class="flex gap-2 flex-wrap items-center mt-1.5"
      >
        <FileChip
          v-for="attachment in fileAttachments"
          :key="attachment.id"
          :attachment="attachment"
          class="!h-8"
          @click.stop
        />
      </div>
    </CardLayout>
  </router-link>
</template>
