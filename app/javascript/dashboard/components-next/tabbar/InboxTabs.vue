<script setup>
import { computed } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  activeTab: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['change']);

const activeIndex = computed(() =>
  props.items.findIndex(item => item.key === props.activeTab)
);

const selectIndex = index => {
  const item = props.items[index];
  if (!item || item.key === props.activeTab) return;
  emit('change', item.key);
};

const keyboardEvents = {
  'Alt+KeyN': {
    action: () => {
      if (!props.items.length) return;
      const nextIndex =
        activeIndex.value < 0
          ? 0
          : (activeIndex.value + 1) % props.items.length;
      selectIndex(nextIndex);
    },
  },
};

useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div
    role="tablist"
    class="flex items-end gap-5 px-4 border-b border-[#DCE3EE] dark:border-[#1B2640]"
  >
    <button
      v-for="(item, index) in items"
      :key="item.key"
      type="button"
      role="tab"
      :aria-selected="item.key === activeTab"
      class="relative inline-flex items-center gap-2 h-11 text-sm font-medium border-0 bg-transparent cursor-pointer transition-colors duration-200"
      :class="
        item.key === activeTab
          ? 'text-[#1F63D6] dark:text-[#86B6FF]'
          : 'text-[#5B6880] dark:text-[#8493AC] hover:text-[#101828] dark:hover:text-[#E8EEF8]'
      "
      @click="selectIndex(index)"
    >
      <span>{{ item.name }}</span>
      <span
        v-if="item.count"
        class="min-w-5 h-5 px-1.5 inline-flex items-center justify-center rounded-full text-xs font-semibold"
        :class="
          item.key === activeTab
            ? 'bg-[#1F63D6] text-white dark:bg-[#2A72E8]'
            : 'bg-[#EEF2F8] text-[#3B475C] dark:bg-[#192135] dark:text-[#B5C1D6]'
        "
      >
        {{ item.count }}
      </span>
      <span
        class="absolute inset-x-0 -bottom-px h-0.5 rounded-full transition-opacity duration-200"
        :class="
          item.key === activeTab
            ? 'bg-[#1F63D6] dark:bg-[#2A72E8] opacity-100'
            : 'opacity-0'
        "
      />
    </button>
  </div>
</template>
