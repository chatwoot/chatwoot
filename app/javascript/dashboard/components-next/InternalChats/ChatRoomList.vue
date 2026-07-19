<script setup>
import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import ChatRoomItem from './ChatRoomItem.vue';
import ChatRoomSkeleton from './ChatRoomSkeleton.vue';

const props = defineProps({
  rooms: { type: Array, default: () => [] },
  selectedId: { type: Number, default: 0 },
  isFetching: { type: Boolean, default: false },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const listRef = ref(null);
const roomCount = computed(() => props.rooms.length);

const onItemSelect = id => emit('select', id);

const focusRoomAt = index => {
  const el = listRef.value?.querySelectorAll('[role="option"]')?.[index];
  if (el) el.focus();
};

const onListKeydown = event => {
  const items = props.rooms;
  if (!items.length) return;
  const currentIndex = items.findIndex(r => r.id === props.selectedId);

  if (event.key === 'ArrowDown') {
    event.preventDefault();
    const next = Math.min(currentIndex + 1, items.length - 1);
    const id = items[next < 0 ? 0 : next].id;
    if (id !== props.selectedId) emit('select', id);
    nextTick(() => focusRoomAt(next < 0 ? 0 : next));
  } else if (event.key === 'ArrowUp') {
    event.preventDefault();
    const prev = Math.max(currentIndex - 1, 0);
    const id = items[prev].id;
    if (id !== props.selectedId) emit('select', id);
    nextTick(() => focusRoomAt(prev));
  } else if (event.key === 'Home') {
    event.preventDefault();
    emit('select', items[0].id);
    nextTick(() => focusRoomAt(0));
  } else if (event.key === 'End') {
    event.preventDefault();
    const last = items.length - 1;
    emit('select', items[last].id);
    nextTick(() => focusRoomAt(last));
  }
};
</script>

<template>
  <aside
    class="conversations-list-wrap relative flex h-full min-h-0 w-full shrink-0 flex-col border-r border-n-weak bg-n-surface-1 md:w-[340px] 2xl:w-[412px]"
  >
    <div
      class="flex h-[3.25rem] shrink-0 items-center justify-between gap-2 border-b border-n-weak px-4"
    >
      <div class="flex min-w-0 items-center gap-2">
        <h1 class="truncate text-base font-medium text-n-slate-12">
          {{ t('INTERNAL_CHATS.TITLE') }}
        </h1>
        <span
          v-if="roomCount > 0 && !isFetching"
          class="shrink-0 rounded-md bg-n-slate-3 px-2 py-0.5 text-xxs text-n-slate-12"
        >
          {{ roomCount }}
        </span>
      </div>
    </div>

    <ul
      v-if="isFetching"
      class="min-h-0 flex-1 overflow-y-auto"
      role="status"
      :aria-label="t('INTERNAL_CHATS.LOADING')"
    >
      <li v-for="i in 5" :key="i">
        <ChatRoomSkeleton />
      </li>
    </ul>

    <p
      v-else-if="!rooms.length"
      class="flex flex-1 items-center justify-center p-4 text-center text-sm text-n-slate-11"
      role="status"
    >
      {{ t('INTERNAL_CHATS.EMPTY_ROOMS') }}
    </p>

    <ul
      v-else
      ref="listRef"
      role="listbox"
      :aria-label="t('INTERNAL_CHATS.TITLE')"
      tabindex="0"
      class="conversations-list min-h-0 flex-1 overflow-y-auto focus:outline-none"
      @keydown="onListKeydown"
    >
      <li v-for="room in rooms" :key="room.id">
        <ChatRoomItem
          :room="room"
          :is-active="room.id === selectedId"
          @select="onItemSelect"
        />
      </li>
    </ul>
  </aside>
</template>
