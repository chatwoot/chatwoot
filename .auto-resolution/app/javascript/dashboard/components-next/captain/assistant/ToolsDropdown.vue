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
    class="w-[22.5rem] p-2 flex flex-col gap-1 z-50 absolute rounded-xl bg-n-alpha-3 shadow outline outline-1 outline-n-weak backdrop-blur-[50px] max-h-[20rem] overflow-y-auto"
  >
    <div
      v-for="(tool, idx) in items"
      :id="`tool-item-${idx}`"
      :key="tool.id || idx"
      :class="{ 'bg-n-alpha-black2': idx === selectedIndex }"
      class="flex flex-col gap-1 rounded-md py-2 px-2 cursor-pointer hover:bg-n-alpha-black2"
      @click="onItemClick(idx)"
    >
      <span class="text-n-slate-12 font-medium text-sm">{{ tool.title }}</span>
      <span class="text-n-slate-11 text-sm">{{ tool.description }}</span>
    </div>
  </div>
</template>
