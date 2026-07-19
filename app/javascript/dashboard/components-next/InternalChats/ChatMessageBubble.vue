<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { messageBubbleStamp } from 'shared/helpers/timeHelper';
import Avatar from 'next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  message: { type: Object, required: true },
  showMeta: { type: Boolean, default: true },
  groupWithNext: { type: Boolean, default: false },
});

const emit = defineEmits(['retry']);

const { t } = useI18n();
const currentUserId = useMapGetter('getCurrentUserID');

const isMine = computed(() => props.message.user_id === currentUserId.value);
const isPending = computed(() => Boolean(props.message.pending));
const isFailed = computed(() => Boolean(props.message.error));
const showAvatar = computed(() => props.showMeta && !props.groupWithNext);

const displayName = computed(
  () =>
    props.message.user?.available_name ||
    props.message.user?.name ||
    t('INTERNAL_CHATS.UNKNOWN_USER')
);

const avatarSrc = computed(
  () => props.message.user?.thumbnail || props.message.user?.avatar_url || ''
);

const avatarStatus = computed(
  () => props.message.user?.availability_status || null
);

const stamp = computed(() =>
  props.message.created_at ? messageBubbleStamp(props.message.created_at) : ''
);

const bubbleToneClass = computed(() => {
  if (isFailed.value) return 'bg-n-ruby-4 text-n-ruby-12';
  if (isMine.value) return 'bg-n-solid-blue text-n-slate-12';
  return 'bg-n-slate-4 text-n-slate-12';
});

const bubbleShapeClass = computed(() => {
  if (isMine.value) {
    return props.groupWithNext
      ? 'rounded-xl ltr:rounded-br-md rtl:rounded-bl-md'
      : 'rounded-xl ltr:rounded-br-sm rtl:rounded-bl-sm';
  }
  return props.groupWithNext
    ? 'rounded-xl ltr:rounded-bl-md rtl:rounded-br-md'
    : 'rounded-xl ltr:rounded-bl-sm rtl:rounded-br-sm';
});

const rowGapClass = computed(() => (props.groupWithNext ? 'mb-0.5' : 'mb-3'));

const onRetry = () => emit('retry', props.message);
</script>

<template>
  <div
    class="flex w-full"
    :class="[rowGapClass, isMine ? 'justify-end' : 'justify-start']"
    data-clarity-mask="True"
  >
    <div
      class="flex max-w-lg gap-2"
      :class="isMine ? 'flex-row-reverse' : 'flex-row'"
    >
      <div class="flex w-6 shrink-0 items-end justify-center pb-0.5">
        <Avatar
          v-if="showAvatar"
          v-tooltip="displayName"
          :name="displayName"
          :src="avatarSrc"
          :size="24"
          rounded-full
          :status="avatarStatus"
          hide-offline-status
        />
      </div>

      <div
        class="flex min-w-0 flex-col"
        :class="isMine ? 'items-end' : 'items-start'"
      >
        <p
          v-if="!isMine && showMeta"
          class="mb-1 truncate text-xs font-medium text-n-slate-11"
        >
          {{ displayName }}
        </p>

        <div
          class="min-w-0 px-3.5 py-2.5 text-sm"
          :class="[bubbleToneClass, bubbleShapeClass]"
        >
          <p class="whitespace-pre-wrap break-words leading-snug">
            {{ message.content }}
          </p>
        </div>

        <div
          v-if="showAvatar || isFailed || isPending"
          class="mt-1 flex items-center gap-1.5 text-xs text-n-slate-10"
          :class="isMine ? 'flex-row-reverse' : 'flex-row'"
        >
          <span v-if="isPending" class="flex items-center gap-1">
            <span class="i-lucide-loader-circle size-3 animate-spin" />
            {{ t('INTERNAL_CHATS.MESSAGE_PENDING') }}
          </span>
          <span
            v-else-if="isFailed"
            class="flex items-center gap-1 text-n-ruby-11"
          >
            <span class="i-lucide-alert-circle size-3" />
            {{ t('INTERNAL_CHATS.MESSAGE_FAILED') }}
          </span>
          <span v-else-if="stamp">{{ stamp }}</span>
          <Button
            v-if="isFailed"
            icon="i-lucide-rotate-ccw"
            color="ruby"
            variant="ghost"
            size="xs"
            :label="t('INTERNAL_CHATS.RETRY')"
            @click="onRetry"
          />
        </div>
      </div>
    </div>
  </div>
</template>
