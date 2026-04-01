<script setup>
import { ref, watch, nextTick } from 'vue';

const props = defineProps({
  items: {
    type: Array,
    required: true,
  },
  selectedIndex: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['select']);

const toolsDropdownRef = ref(null);

const onItemClick = idx => emit('select', idx);

watch(
  () => props.selectedIndex,
  () => {
    nextTick(() => {
      const el = toolsDropdownRef.value?.querySelector(
        `#tool-item-${props.selectedIndex}`
      );
      if (el) {
        el.scrollIntoView({ block: 'nearest', behavior: 'auto' });
      }
    });
  },
  { immediate: true }
);
</script>

<template>
  <div
    ref="toolsDropdownRef"
    class="absolute z-50 flex max-h-[20rem] w-[22.5rem] flex-col gap-1 overflow-y-auto rounded-xl border border-outline-variant/10 bg-surface-container-high/95 p-2 shadow-lg backdrop-blur-md"
  >
    <div
      v-for="(tool, idx) in items"
      :id="`tool-item-${idx}`"
      :key="tool.id || idx"
      :class="{
        'bg-surface-container-highest': idx === selectedIndex,
      }"
      class="flex cursor-pointer flex-col gap-1 rounded-md px-2 py-2 hover:bg-surface-container-highest"
      @click="onItemClick(idx)"
    >
      <span class="text-sm font-medium text-on-surface">{{ tool.title }}</span>
      <span class="text-sm text-on-surface-variant">{{
        tool.description
      }}</span>
    </div>
  </div>
</template>
