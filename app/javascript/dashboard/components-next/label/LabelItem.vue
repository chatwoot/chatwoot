<script setup>
import { computed } from 'vue';
import { tintStylesFromHex } from 'dashboard/helper/colorHelper';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  label: {
    type: Object,
    default: null,
  },
  isHovered: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['remove', 'hover']);

const tintStyles = computed(() => {
  const styles = tintStylesFromHex(props.label?.color);
  return Object.keys(styles).length ? styles : null;
});

const handleRemoveLabel = () => {
  emit('remove', props.label);
};

const handleMouseEnter = () => {
  // Notify parent component when this label is hovered
  // Added this to show the remove button with transition when hovering over the label
  // This will solve the flickering issue when hovering over the last label item
  emit('hover', props.label?.id);
};
</script>

<template>
  <div
    class="flex items-center px-1.5 py-1 overflow-hidden transition-all duration-300 ease-out rounded-md border h-7"
    :class="{ 'bg-n-alpha-2 border-transparent': !tintStyles }"
    :style="tintStyles || undefined"
    @mouseenter="handleMouseEnter"
  >
    <span
      class="text-sm ltr:mr-px rtl:ml-px"
      :class="{ 'text-n-slate-12': !tintStyles }"
    >
      {{ label.title }}
    </span>
    <div
      class="w-0 flex relative ltr:left-1 rtl:right-1 flex-shrink-0 overflow-hidden transition-[width] duration-300 ease-out"
      :class="{ 'w-6': isHovered }"
    >
      <Button
        class="transition-opacity duration-200 !h-7 ltr:rounded-r-md rtl:rounded-l-md ltr:rounded-l-none rtl:rounded-r-none w-6 bg-transparent"
        :class="{ 'opacity-0': !isHovered, 'opacity-100': isHovered }"
        type="button"
        slate
        xs
        faded
        icon="i-lucide-x"
        @click="handleRemoveLabel"
      />
    </div>
  </div>
</template>
