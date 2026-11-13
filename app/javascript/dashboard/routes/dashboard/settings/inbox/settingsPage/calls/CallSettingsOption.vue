<script setup>
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

// A checkbox, or a radio when given a value, with an optional help line under its label; `card`
// draws it as a bordered card
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
  card: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const model = defineModel({ type: [String, Boolean], default: false });
</script>

<template>
  <label
    class="flex items-start gap-3 mb-0"
    :class="{
      'px-4 py-3 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak':
        card,
      'opacity-50 cursor-not-allowed': disabled,
      'cursor-pointer': !disabled,
    }"
  >
    <input
      v-if="props.value !== null"
      v-model="model"
      type="radio"
      :name="name"
      :value="value"
      :disabled="disabled"
      class="mt-1 !mb-0 size-4 shrink-0 cursor-pointer accent-n-brand"
    />
    <Checkbox
      v-else
      v-model="model"
      :disabled="disabled"
      class="mt-0.5 shrink-0"
    />
    <span class="flex flex-col gap-0.5">
      <span class="text-body-main text-n-slate-12">{{ label }}</span>
      <span v-if="help" class="text-body-main text-n-slate-11">
        {{ help }}
      </span>
    </span>
  </label>
</template>
