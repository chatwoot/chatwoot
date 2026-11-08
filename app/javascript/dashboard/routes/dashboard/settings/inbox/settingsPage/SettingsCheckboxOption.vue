<script setup>
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

// A one-line checkbox setting; the editor slot opens under it while checked
defineProps({
  header: {
    type: String,
    required: true,
  },
});

const modelValue = defineModel({ type: Boolean, default: false });
</script>

<template>
  <div class="flex flex-col gap-3">
    <label
      class="flex items-center gap-3 mb-0 cursor-pointer text-body-main text-n-slate-12"
    >
      <Checkbox v-model="modelValue" />
      {{ header }}
    </label>
    <div v-if="$slots.editor" class="ps-7">
      <slot name="editor" />
    </div>
  </div>
</template>
