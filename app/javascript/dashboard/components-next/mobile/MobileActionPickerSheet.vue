<script setup>
import { computed, ref, watch } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import MobileBottomSheet from './MobileBottomSheet.vue';
import { vHapticTap } from './hapticTap';

const props = defineProps({
  open: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
  selectedKey: {
    type: [String, Number, null],
    default: null,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  emptyText: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close', 'select']);

const query = ref('');

watch(
  () => props.open,
  isOpen => {
    if (isOpen) query.value = '';
  }
);

const filteredItems = computed(() => {
  const normalizedQuery = query.value.trim().toLowerCase();
  if (!normalizedQuery) return props.items;

  return props.items.filter(item => {
    const haystack = [item.label, item.description]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();
    return haystack.includes(normalizedQuery);
  });
});

const isSelected = item => item.key === props.selectedKey;
</script>

<template>
  <MobileBottomSheet v-if="open" :title="title" @close="emit('close')">
    <div class="space-y-3">
      <input
        v-if="searchPlaceholder"
        v-model="query"
        type="text"
        class="w-full rounded-xl border border-n-weak bg-n-surface-2 px-4 py-3 text-sm text-n-slate-12 outline-none placeholder:text-n-slate-9"
        :placeholder="searchPlaceholder"
      />

      <div
        v-if="!filteredItems.length"
        class="rounded-2xl border border-dashed border-n-weak px-4 py-8 text-center text-sm text-n-slate-10"
      >
        {{ emptyText }}
      </div>

      <div
        v-else
        class="overflow-hidden rounded-[1.25rem] border border-n-weak bg-white dark:bg-n-background shadow-sm"
      >
        <button
          v-for="item in filteredItems"
          :key="item.key"
          v-haptic-tap
          class="flex w-full items-center gap-3 px-4 py-3 text-left transition-colors active:bg-n-alpha-2"
          :class="{ 'border-t border-n-weak': item !== filteredItems[0] }"
          @click="emit('select', item)"
        >
          <Avatar
            v-if="item.avatar || item.name"
            :src="item.avatar"
            :name="item.name || item.label"
            :size="36"
            class="shrink-0"
          />
          <span
            v-else-if="item.icon"
            class="flex size-9 shrink-0 items-center justify-center rounded-full bg-n-surface-2 text-n-slate-11"
          >
            <span class="size-4" :class="item.icon" />
          </span>
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm font-medium text-n-slate-12">
              {{ item.label }}
            </p>
            <p v-if="item.description" class="truncate text-xs text-n-slate-10">
              {{ item.description }}
            </p>
          </div>
          <span
            v-if="isSelected(item)"
            class="flex size-6 items-center justify-center rounded-full bg-n-brand text-white"
          >
            <span class="i-lucide-check size-4" />
          </span>
          <span v-else class="i-lucide-chevron-right size-4 text-n-slate-9" />
        </button>
      </div>
    </div>
  </MobileBottomSheet>
</template>
