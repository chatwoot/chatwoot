<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  label: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['remove']);

const handleRemoveLabel = () => {
  emit('remove', props.label?.id);
};
</script>

<template>
  <div
    class="flex items-center px-1 py-1 overflow-hidden transition-all duration-300 ease-out rounded-md bg-n-alpha-2 group/label h-7 w-fit"
  >
    <div
      class="w-2 h-2 m-1 rounded-sm"
      :style="{ backgroundColor: label.color }"
    />
    <span class="text-sm text-n-slate-12 ltr:mr-px rtl:ml-px">
      {{ label.title }}
    </span>
    <div
      class="w-0 flex relative ltr:left-1 rtl:right-1 flex-shrink-0 overflow-hidden group-hover/label:w-6 transition-[width] duration-300 ease-out"
    >
      <Button
        class="transition-opacity duration-200 !h-7 ltr:rounded-r-md rtl:rounded-l-md ltr:rounded-l-none rtl:rounded-r-none w-6 bg-transparent opacity-0 group-hover/label:opacity-100"
        slate
        xs
        faded
        icon="i-lucide-x"
        @click="handleRemoveLabel"
      />
    </div>
  </div>
</template>
