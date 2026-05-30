<script setup>
import { computed, ref, watch } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import MobileBottomSheet from './MobileBottomSheet.vue';

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
  selectedKeys: {
    type: Array,
    default: () => [],
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  emptyText: {
    type: String,
    default: '',
  },
  applyLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close', 'apply']);

const query = ref('');
const localSelectedKeys = ref([]);

watch(
  () => props.open,
  isOpen => {
    if (isOpen) {
      query.value = '';
      localSelectedKeys.value = [...props.selectedKeys];
    }
  }
);

watch(
  () => props.selectedKeys,
  nextValue => {
    if (props.open) localSelectedKeys.value = [...nextValue];
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

const toggleItem = key => {
  if (localSelectedKeys.value.includes(key)) {
    localSelectedKeys.value = localSelectedKeys.value.filter(
      item => item !== key
    );
    return;
  }

  localSelectedKeys.value = [...localSelectedKeys.value, key];
};
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
          class="flex w-full items-center gap-3 px-4 py-3 text-left transition-colors active:bg-n-alpha-2"
          :class="{ 'border-t border-n-weak': item !== filteredItems[0] }"
          @click="toggleItem(item.key)"
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
            class="flex size-6 items-center justify-center rounded-full border"
            :class="
              localSelectedKeys.includes(item.key)
                ? 'border-n-brand bg-n-brand text-white'
                : 'border-n-weak text-transparent'
            "
          >
            <span class="i-lucide-check size-4" />
          </span>
        </button>
      </div>

      <Button
        :label="applyLabel"
        class="w-full"
        @click="emit('apply', localSelectedKeys)"
      />
    </div>
  </MobileBottomSheet>
</template>
