<script setup>
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

// A checkbox, or a radio when given a value, with an optional help line under its label
const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  help: {
    type: String,
    default: '',
  },
  // Boolean first, so a bare `value` attribute reads as true
  value: {
    type: [Boolean, String],
    default: null,
  },
  name: {
    type: String,
    default: '',
  },
});

const model = defineModel({ type: [String, Boolean], default: false });
</script>

<template>
  <label class="flex items-start gap-3 mb-0 cursor-pointer">
    <input
      v-if="props.value !== null"
      v-model="model"
      type="radio"
      :name="name"
      :value="value"
      class="mt-1 !mb-0 size-4 shrink-0 cursor-pointer accent-n-brand"
    />
    <Checkbox v-else v-model="model" class="mt-0.5 shrink-0" />
    <span class="flex flex-col gap-0.5">
      <span class="text-body-main text-n-slate-12">{{ label }}</span>
      <span v-if="help" class="text-body-main text-n-slate-11">
        {{ help }}
      </span>
    </span>
  </label>
</template>
