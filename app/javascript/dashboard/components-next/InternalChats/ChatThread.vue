<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  format,
  fromUnixTime,
  isSameDay,
  isYesterday,
  isToday,
} from 'date-fns';
import { messageStamp } from 'shared/helpers/timeHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';
import ChatMessageBubble from './ChatMessageBubble.vue';
import ChatComposer from './ChatComposer.vue';
import ChatEmptyState from './ChatEmptyState.vue';

const props = defineProps({
  room: { type: Object, required: true },
  messages: { type: Array, default: () => [] },
  hasMore: { type: Boolean, default: false },
  isFetchingMessages: { type: Boolean, default: false },
  isCreating: { type: Boolean, default: false },
  showBack: { type: Boolean, default: false },
  accountId: { type: [String, Number], default: 0 },
  loadOlder: { type: Function, default: null },
});

const emit = defineEmits(['send', 'back', 'draftChange', 'retryMessage']);

const GROUP_WINDOW_SECONDS = 5 * 60;

const { t } = useI18n();

const threadEl = ref(null);
const draft = ref('');
const composerRef = ref(null);
const isLoadingOlder = ref(false);
const isMembersOpen = ref(false);
const headerRef = ref(null);
const draftRestored = ref(false);
const restoredBannerTimer = ref(null);

const teamName = computed(
  () => props.room.team?.name || t('INTERNAL_CHATS.UNKNOWN_TEAM')
);

const members = computed(() => props.room.team?.members || []);
const memberCount = computed(() => members.value.length);

const dayLabel = timestamp => {
  if (!timestamp) return '';
  const date = fromUnixTime(timestamp);
  if (isToday(date)) return t('INTERNAL_CHATS.DAY.TODAY');
  if (isYesterday(date)) return t('INTERNAL_CHATS.DAY.YESTERDAY');
  return format(date, 'd MMM yyyy');
};

const shouldShowMeta = (message, index) => {
  if (index === 0) return true;
  const prev = props.messages[index - 1];
  if (!prev || prev.user_id !== message.user_id) return true;
  return message.created_at - prev.created_at > GROUP_WINDOW_SECONDS;
};

const shouldGroupWithNext = (message, index) => {
  const next = props.messages[index + 1];
  if (!next || next.user_id !== message.user_id) return false;
  return next.created_at - message.created_at <= GROUP_WINDOW_SECONDS;
};

const shouldShowDaySeparator = (message, index) => {
  if (index === 0) return true;
  const prev = props.messages[index - 1];
  if (!prev?.created_at || !message.created_at) return false;
  return !isSameDay(
    fromUnixTime(prev.created_at),
    fromUnixTime(message.created_at)
  );
};

const threadItems = computed(() =>
  props.messages.map((message, index) => ({
    message,
    showMeta: shouldShowMeta(message, index),
    groupWithNext: shouldGroupWithNext(message, index),
    dayLabel: shouldShowDaySeparator(message, index)
      ? dayLabel(message.created_at)
      : null,
  }))
);

const scrollToBottom = async () => {
  await nextTick();
  if (threadEl.value) {
    threadEl.value.scrollTop = threadEl.value.scrollHeight;
  }
};

const onScroll = async () => {
  const el = threadEl.value;
  if (
    !el ||
    isLoadingOlder.value ||
    !props.hasMore ||
    props.isFetchingMessages ||
    typeof props.loadOlder !== 'function'
  ) {
    return;
  }
  if (el.scrollTop > 40) return;

  const oldest = props.messages[0];
  if (!oldest) return;

  isLoadingOlder.value = true;
  const previousHeight = el.scrollHeight;
  try {
    await props.loadOlder(oldest.id);
    await nextTick();
    el.scrollTop = el.scrollHeight - previousHeight;
  } finally {
    isLoadingOlder.value = false;
  }
};

const onSend = () => {
  const content = draft.value.trim();
  if (!content || props.isCreating) return;
  emit('send', content);
  draft.value = '';
  emit('draftChange', { roomId: props.room.id, content: '' });
  nextTick(() => composerRef.value?.focus());
};

const onDraftInput = value => {
  emit('draftChange', { roomId: props.room.id, content: value });
};

const draftStorageKey = computed(
  () => `internal-chat:draft:${props.accountId}:${props.room.id}`
);

const loadDraft = () => {
  if (typeof window === 'undefined') return '';
  try {
    return window.localStorage.getItem(draftStorageKey.value) || '';
  } catch {
    return '';
  }
};

const restoreDraft = () => {
  const stored = loadDraft();
  if (stored && stored !== draft.value) {
    draft.value = stored;
    draftRestored.value = true;
    nextTick(() => composerRef.value?.focus());
    if (restoredBannerTimer.value) clearTimeout(restoredBannerTimer.value);
    restoredBannerTimer.value = setTimeout(() => {
      draftRestored.value = false;
    }, 3000);
  }
};

const beforeUnloadHandler = event => {
  if (draft.value.trim()) {
    event.preventDefault();
    event.returnValue = t('INTERNAL_CHATS.DRAFT_UNSAVED_WARNING');
    return event.returnValue;
  }
  return undefined;
};

watch(
  () => props.room.id,
  () => {
    draft.value = '';
    restoreDraft();
    nextTick(() => {
      scrollToBottom();
      composerRef.value?.focus();
    });
  }
);

watch(
  draft,
  value => {
    if (!props.room?.id || typeof window === 'undefined') return;
    try {
      if (value && value.trim()) {
        window.localStorage.setItem(draftStorageKey.value, value);
      } else {
        window.localStorage.removeItem(draftStorageKey.value);
      }
    } catch {
      /* noop */
    }
  },
  { flush: 'post' }
);

watch(
  () => props.messages.length,
  (next, prev) => {
    if (isLoadingOlder.value) return;
    if (next > (prev || 0)) scrollToBottom();
  }
);

const onWindowClick = event => {
  if (!isMembersOpen.value || !headerRef.value) return;
  if (!headerRef.value.contains(event.target)) isMembersOpen.value = false;
};

onMounted(() => {
  scrollToBottom();
  composerRef.value?.focus();
  if (typeof window !== 'undefined') {
    window.addEventListener('click', onWindowClick);
    window.addEventListener('beforeunload', beforeUnloadHandler);
  }
});

onUnmounted(() => {
  if (typeof window !== 'undefined') {
    window.removeEventListener('click', onWindowClick);
    window.removeEventListener('beforeunload', beforeUnloadHandler);
  }
  if (restoredBannerTimer.value) clearTimeout(restoredBannerTimer.value);
});

defineExpose({ scrollToBottom });
</script>

<template>
  <div
    class="flex h-full min-h-0 min-w-0 w-full flex-col overflow-hidden border-l border-n-weak bg-n-surface-1 transition-colors duration-150 rtl:border-l-0 rtl:border-r"
  >
    <div
      ref="headerRef"
      class="relative flex h-14 shrink-0 items-center justify-between gap-2 border-b border-n-weak px-4 xl:h-12"
    >
      <div class="flex min-w-0 flex-1 items-center">
        <Button
          v-if="showBack"
          icon="i-lucide-chevron-left"
          variant="ghost"
          color="slate"
          size="sm"
          class="shrink-0 ltr:mr-1 rtl:ml-1 md:hidden"
          :title="t('INTERNAL_CHATS.BACK')"
          :aria-label="t('INTERNAL_CHATS.BACK')"
          @click="emit('back')"
        />
        <Avatar
          :name="teamName"
          :src="room.team?.thumbnail || ''"
          :size="32"
          rounded-full
          class="shrink-0"
        />
        <div class="ml-2 min-w-0 flex-1 overflow-hidden rtl:ml-0 rtl:mr-2">
          <div class="flex min-w-0 items-center gap-2">
            <p
              class="truncate text-sm font-medium leading-tight text-n-slate-12"
            >
              {{ teamName }}
            </p>
          </div>
          <p class="truncate text-xs text-n-slate-11">
            {{ t('INTERNAL_CHATS.MEMBERS', memberCount) }}
          </p>
        </div>
      </div>

      <div class="relative flex shrink-0 items-center">
        <Button
          icon="i-lucide-users"
          variant="ghost"
          color="slate"
          size="sm"
          :title="t('INTERNAL_CHATS.MEMBERS_TOOLTIP')"
          :aria-label="t('INTERNAL_CHATS.INFO_TITLE')"
          :aria-expanded="isMembersOpen"
          @click="isMembersOpen = !isMembersOpen"
        />
        <div
          v-if="isMembersOpen"
          class="absolute right-0 top-full z-20 mt-1 max-h-80 w-72 overflow-y-auto rounded-xl border border-n-weak bg-n-surface-1 p-2 shadow-lg"
          role="dialog"
          :aria-label="t('INTERNAL_CHATS.INFO_TITLE')"
        >
          <h3
            class="px-2 py-1.5 text-xs font-semibold uppercase tracking-wide text-n-slate-11"
          >
            {{ t('INTERNAL_CHATS.INFO_TITLE') }}
          </h3>
          <ul v-if="members.length" class="flex flex-col">
            <li
              v-for="member in members"
              :key="member.id"
              class="flex items-center gap-2.5 rounded-lg px-2 py-2 hover:bg-n-alpha-1"
            >
              <Avatar
                :name="member.name"
                :src="member.thumbnail || ''"
                :size="28"
                rounded-full
                :status="member.availability_status"
                hide-offline-status
              />
              <span class="truncate text-sm text-n-slate-12">{{
                member.name
              }}</span>
            </li>
          </ul>
          <p v-else class="px-2 py-2 text-xs text-n-slate-11">
            {{ t('INTERNAL_CHATS.UNKNOWN_USER') }}
          </p>
        </div>
      </div>
    </div>

    <div
      v-if="draftRestored && draft"
      class="border-b border-n-weak bg-n-amber-3 px-3 py-1.5 text-center text-xs text-n-amber-12"
      role="status"
    >
      {{ t('INTERNAL_CHATS.DRAFT_RESTORED') }}
    </div>

    <div class="flex min-h-0 flex-1 flex-col overflow-hidden">
      <div
        ref="threadEl"
        role="log"
        aria-live="polite"
        class="min-h-0 flex-1 overflow-y-auto px-3 py-4"
        @scroll="onScroll"
      >
        <div
          v-if="isLoadingOlder || (isFetchingMessages && messages.length)"
          class="flex justify-center py-2 text-xs text-n-slate-11"
        >
          {{ t('INTERNAL_CHATS.LOADING_OLDER') }}
        </div>

        <div
          v-if="!messages.length"
          class="flex min-h-[12rem] items-center justify-center py-10"
        >
          <ChatEmptyState
            :variant="isFetchingMessages ? 'loading' : 'empty_thread'"
          />
        </div>

        <template v-for="item in threadItems" :key="item.message.id">
          <div v-if="item.dayLabel" class="my-4 flex justify-center">
            <span
              v-tooltip.top="
                messageStamp(
                  item.message.created_at,
                  t('INTERNAL_CHATS.DAY_FULL')
                )
              "
              class="inline-flex cursor-default rounded-full bg-n-alpha-1 px-2.5 py-1 text-xs text-n-slate-11"
            >
              {{ item.dayLabel }}
            </span>
          </div>
          <ChatMessageBubble
            :message="item.message"
            :show-meta="item.showMeta"
            :group-with-next="item.groupWithNext"
            @retry="emit('retryMessage', $event)"
          />
        </template>
      </div>

      <ChatComposer
        ref="composerRef"
        v-model="draft"
        :is-sending="isCreating"
        :placeholder="t('INTERNAL_CHATS.PLACEHOLDER')"
        autofocus
        @send="onSend"
        @update:model-value="onDraftInput"
      />
    </div>
  </div>
</template>
