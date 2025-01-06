<script setup>
import { computed, ref, onMounted, nextTick } from 'vue';
const props = defineProps({
  modelValue: {
    type: [String, Number],
    default: '',
  },
  type: {
    type: String,
    default: 'text',
  },
  customInputClass: {
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
  message: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  messageType: {
    type: String,
    default: 'info',
    validator: value => ['info', 'error', 'success'].includes(value),
  },
  min: {
    type: String,
    default: '',
  },
  autofocus: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'update:modelValue',
  'blur',
  'input',
  'focus',
  'enter',
]);

const isFocused = ref(false);
const inputRef = ref(null);

const messageClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'text-n-ruby-9 dark:text-n-ruby-9';
    case 'success':
      return 'text-green-500 dark:text-green-400';
    default:
      return 'text-n-slate-11 dark:text-n-slate-11';
  }
});

const inputBorderClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'border-n-ruby-8 dark:border-n-ruby-8 hover:border-n-ruby-9 dark:hover:border-n-ruby-9 disabled:border-n-ruby-8 dark:disabled:border-n-ruby-8';
    default:
      return 'border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand';
  }
});

const handleInput = event => {
  emit('update:modelValue', event.target.value);
  emit('input', event);
};

const handleFocus = event => {
  emit('focus', event);
  isFocused.value = true;
};

const handleBlur = event => {
  emit('blur', event);
  isFocused.value = false;
};

const handleEnter = event => {
  emit('enter', event);
};

onMounted(() => {
  if (props.autofocus) {
    nextTick(() => {
      inputRef.value?.focus();
    });
  }
});
</script>

<template>
  <div class="relative flex flex-col min-w-0 gap-1">
    <label
      v-if="label"
      :for="id"
      class="mb-0.5 text-sm font-medium text-n-slate-12"
    >
      {{ label }}
    </label>
    <!-- Added prefix slot to allow adding icons to the input -->
    <slot name="prefix" />
    <input
      :id="id"
      ref="inputRef"
      :value="modelValue"
      :class="[
        customInputClass,
        inputBorderClass,
        {
          error: messageType === 'error',
          focus: isFocused,
        },
      ]"
      :type="type"
      :placeholder="placeholder"
      :disabled="disabled"
      :min="['date', 'datetime-local', 'time'].includes(type) ? min : undefined"
      class="block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
      @input="handleInput"
      @focus="handleFocus"
      @blur="handleBlur"
      @keyup.enter="handleEnter"
    />
    <p
      v-if="message"
      class="min-w-0 mt-1 mb-0 text-xs truncate transition-all duration-500 ease-in-out"
      :class="messageClass"
    >
      {{ message }}
    </p>
  </div>
</template>
