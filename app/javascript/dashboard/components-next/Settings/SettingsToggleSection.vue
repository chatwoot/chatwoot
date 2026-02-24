<script setup>
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

defineProps({
  header: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  compact: {
    type: Boolean,
    default: false,
  },
});

const modelValue = defineModel({ type: Boolean, default: false });
</script>

<template>
  <div
    class="flex flex-col items-start outline outline-1 -outline-offset-1 outline-n-weak rounded-xl [interpolate-size:allow-keywords]"
  >
    <div class="flex flex-col gap-1 items-start w-full px-4 py-3">
      <div class="flex items-center gap-3 w-full justify-between">
        <span class="text-heading-3 text-n-slate-12">
          {{ header }}
        </span>
        <ToggleSwitch v-model="modelValue" />
      </div>
      <span v-if="description" class="text-body-main text-n-slate-11">
        {{ description }}
      </span>
    </div>
    <div
      v-if="$slots.editor"
      class="w-full border-t border-n-weak"
      :class="{ 'p-0': compact, 'px-4 pb-4 pt-2': !compact }"
    >
      <slot name="editor" />
    </div>
  </div>
</template>
