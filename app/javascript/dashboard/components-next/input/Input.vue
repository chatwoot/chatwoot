<script setup>
import { computed, ref, onMounted, nextTick, getCurrentInstance } from 'vue';
const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  type: { type: String, default: 'text' },
  customInputClass: { type: [String, Object, Array], default: '' },
  placeholder: { type: String, default: '' },
  label: { type: String, default: '' },
  id: { type: String, default: '' },
  size: {
    type: String,
    default: 'md',
    validator: value => ['sm', 'md'].includes(value),
  },
  message: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  messageType: {
    type: String,
    default: 'info',
    validator: value => ['info', 'error', 'success'].includes(value),
  },
  min: { type: String, default: '' },
  max: { type: String, default: '' },
  autofocus: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:modelValue',
  'blur',
  'input',
  'focus',
  'enter',
]);

// Generate a unique ID per component instance when `id` prop is not provided.
const { uid } = getCurrentInstance();
const uniqueId = computed(() => props.id || `input-${uid}`);

const isFocused = ref(false);
const inputRef = ref(null);

const messageClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'text-s-error dark:text-s-error';
    case 'success':
      return 'text-s-success dark:text-s-success';
    default:
      return 'text-s-muted dark:text-s-muted';
  }
});

const inputOutlineClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'outline-s-error dark:outline-s-error hover:outline-s-error dark:hover:outline-s-error disabled:outline-s-error dark:disabled:outline-s-error';
    default:
      return 'outline-s-border dark:outline-s-border hover:outline-s-border dark:hover:outline-s-border disabled:outline-s-border dark:disabled:outline-s-border focus:outline-s-brand dark:focus:outline-s-brand';
  }
});

const handleInput = event => {
  let value = event.target.value;
  // Convert to number if type is number and value is not empty
  if (props.type === 'number' && value !== '') {
    value = Number(value);
  }
  emit('update:modelValue', value);
  emit('input', event);
};

const handleFocus = event => {
  emit('focus', event);
  isFocused.value = true;
};

const sizeClass = computed(() => {
  switch (props.size) {
    case 'sm':
      return 'h-8 !px-3 !py-2';
    case 'md':
      return 'h-10 !px-3 !py-2.5';
    default:
      return 'h-10 !px-3 !py-2.5';
  }
});

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
      :for="uniqueId"
      class="mb-0.5 text-heading-3 text-s-primary"
    >
      {{ label }}
    </label>
    <!-- Added prefix slot to allow adding icons to the input -->
    <slot name="prefix" />
    <input
      :id="uniqueId"
      v-bind="$attrs"
      ref="inputRef"
      :value="modelValue"
      :class="[
        customInputClass,
        inputOutlineClass,
        sizeClass,
        {
          error: messageType === 'error',
          focus: isFocused,
        },
      ]"
      :type="type"
      :placeholder="placeholder"
      :disabled="disabled"
      :min="['date', 'datetime-local', 'time'].includes(type) ? min : undefined"
      :max="
        ['date', 'datetime-local', 'time', 'number'].includes(type)
          ? max
          : undefined
      "
      class="block w-full reset-base text-sm !mb-0 outline outline-1 border-none border-0 outline-offset-[-1px] rounded-lg bg-s-primary/15 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-s-muted dark:placeholder:text-s-muted disabled:cursor-not-allowed disabled:opacity-50 text-s-primary transition-all duration-500 ease-in-out [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
      @input="handleInput"
      @focus="handleFocus"
      @blur="handleBlur"
      @keyup.enter="handleEnter"
    />
    <p
      v-if="message"
      class="min-w-0 mt-1 mb-0 text-label-small truncate transition-all duration-500 ease-in-out"
      :class="messageClass"
    >
      {{ message }}
    </p>
  </div>
</template>
