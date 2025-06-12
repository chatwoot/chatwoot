<script setup>
import { ref, onMounted, nextTick } from 'vue';

const props = defineProps({
  type: {
    type: String,
    default: 'text',
  },
  customInputClass: {
    type: [String, Object, Array],
    default: '',
  },
  customLabelClass: {
    type: [String, Object, Array],
    default: '',
  },
  placeholder: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
  id: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  focusOnMount: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['enterPress', 'input', 'blur', 'focus']);

const modelValue = defineModel({
  type: [String, Number],
  default: '',
});

const inlineInputRef = ref(null);

const onEnterPress = () => {
  emit('enterPress');
};

const handleInput = event => {
  emit('input', event.target.value);
  modelValue.value = event.target.value;
};

const handleBlur = event => {
  emit('blur', event.target.value);
};

const handleFocus = event => {
  emit('focus', event.target.value);
};

onMounted(() => {
  nextTick(() => {
    if (props.focusOnMount) {
      inlineInputRef.value?.focus();
    }
  });
});

defineExpose({
  focus: () => inlineInputRef.value?.focus(),
});
</script>

<template>
  <div
    class="relative flex items-center justify-between w-full gap-3 whitespace-nowrap"
  >
    <label
      v-if="label"
      :for="id"
      :class="customLabelClass"
      class="mb-0.5 text-sm font-medium text-n-slate-12"
    >
      {{ label }}
    </label>
    <!-- Added prefix slot to allow adding custom labels to the input -->
    <slot name="prefix" />
    <input
      :id="id"
      ref="inlineInputRef"
      v-model="modelValue"
      :type="type"
      :placeholder="placeholder"
      :disabled="disabled"
      :class="customInputClass"
      class="flex w-full reset-base text-sm h-6 !mb-0 border-0 rounded-none outline-none outline-0 bg-transparent dark:bg-transparent placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 dark:text-n-slate-12 transition-all duration-500 ease-in-out"
      @input="handleInput"
      @focus="handleFocus"
      @blur="handleBlur"
      @keydown.enter.prevent="onEnterPress"
    />
  </div>
</template>
