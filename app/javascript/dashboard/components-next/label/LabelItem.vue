<script setup>
import Label from 'dashboard/components-next/Label/Label.vue';
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
  compact: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['remove', 'hover']);

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
  <Label :label="label" :compact="compact" @mouseenter="handleMouseEnter">
    <template #action>
      <div
        class="w-0 flex relative ltr:left-0.5 rtl:right-0.5 flex-shrink-0 overflow-hidden transition-[width] duration-300 ease-out"
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
    </template>
  </Label>
</template>
