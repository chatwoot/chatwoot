<script setup>
import { computed, ref, onMounted, nextTick, watch } from 'vue';
import {
  appendSignature,
  removeSignature,
  extractTextFromMarkdown,
} from 'dashboard/helper/editorHelper';

const props = defineProps({
  modelValue: { type: String, default: '' },
  label: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  maxLength: { type: Number, default: 200 },
  id: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  customTextAreaClass: { type: String, default: '' },
  customTextAreaWrapperClass: { type: String, default: '' },
  showCharacterCount: { type: Boolean, default: false },
  autoHeight: { type: Boolean, default: false },
  resize: { type: Boolean, default: false },
  minHeight: { type: String, default: '4rem' },
  maxHeight: { type: String, default: '12rem' },
  autofocus: { type: Boolean, default: false },
  message: { type: String, default: '' },
  messageType: {
    type: String,
    default: 'info',
    validator: value => ['info', 'error', 'success'].includes(value),
  },
  signature: { type: String, default: '' },
  sendWithSignature: { type: Boolean, default: false }, // add this as a prop, so that we won't have to add useUISettings
  allowSignature: { type: Boolean, default: false }, // allowSignature is a kill switch, ensuring no signature methods are triggered except when this flag is true
});

const emit = defineEmits(['update:modelValue']);

const textareaRef = ref(null);
const isFocused = ref(false);

const characterCount = computed(() => props.modelValue.length);
const cleanedSignature = computed(() =>
  extractTextFromMarkdown(props.signature)
);

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

// TODO - use "field-sizing: content" and "height: auto" in future for auto height, when available.
const adjustHeight = () => {
  if (!props.autoHeight || !textareaRef.value) return;

  // Reset height to auto to get the correct scrollHeight
  textareaRef.value.style.height = 'auto';
  // Set the height to the scrollHeight
  textareaRef.value.style.height = `${textareaRef.value.scrollHeight}px`;
};

const setCursor = () => {
  if (!textareaRef.value) return;

  const bodyWithoutSignature = removeSignature(
    props.modelValue,
    cleanedSignature.value
  );
  const bodyEndsAt = bodyWithoutSignature.trimEnd().length;

  textareaRef.value.focus();
  textareaRef.value.setSelectionRange(bodyEndsAt, bodyEndsAt);
};

const toggleSignatureInEditor = signatureEnabled => {
  if (!props.allowSignature) return;
  const valueWithSignature = signatureEnabled
    ? appendSignature(props.modelValue, cleanedSignature.value)
    : removeSignature(props.modelValue, cleanedSignature.value);
  emit('update:modelValue', valueWithSignature);

  nextTick(() => {
    adjustHeight();
    setCursor();
  });
};

const handleInput = event => {
  emit('update:modelValue', event.target.value);
  if (props.autoHeight) {
    nextTick(adjustHeight);
  }
};

const handleFocus = () => {
  if (!props.disabled) {
    isFocused.value = true;
  }
};

const handleBlur = () => {
  if (!props.disabled) {
    isFocused.value = false;
  }
};

// Watch for changes in modelValue to adjust height
watch(
  () => props.modelValue,
  () => {
    if (props.autoHeight) {
      nextTick(adjustHeight);
    }
  }
);

watch(
  () => props.sendWithSignature,
  newValue => {
    if (props.allowSignature) toggleSignatureInEditor(newValue);
  }
);

onMounted(() => {
  if (props.autoHeight) {
    nextTick(adjustHeight);
  }

  if (props.autofocus) {
    textareaRef.value?.focus();
  }
});
</script>

<template>
  <div class="relative flex flex-col gap-1">
    <label
      v-if="label"
      :for="id"
      class="mb-0.5 text-sm font-medium text-n-slate-12"
    >
      {{ label }}
    </label>
    <div
      class="flex flex-col gap-2 px-3 pt-3 pb-3 transition-all duration-500 ease-in-out border rounded-lg bg-n-alpha-black2"
      :class="[
        customTextAreaWrapperClass,
        {
          'cursor-not-allowed opacity-50 !bg-n-alpha-black2 disabled:border-n-weak dark:disabled:border-n-weak':
            disabled,
          'border-n-brand dark:border-n-brand': isFocused,
          'hover:border-n-slate-6 dark:hover:border-n-slate-6 border-n-weak dark:border-n-weak':
            !isFocused && messageType !== 'error',
          'border-n-ruby-8 dark:border-n-ruby-8 hover:border-n-ruby-9 dark:hover:border-n-ruby-9':
            messageType === 'error' && !isFocused,
        },
      ]"
    >
      <slot /><!-- Slot for adding popover -->
      <textarea
        :id="id"
        ref="textareaRef"
        :value="modelValue"
        :placeholder="placeholder"
        :maxlength="showCharacterCount ? maxLength : undefined"
        :class="[
          customTextAreaClass,
          {
            'resize-none': !resize,
          },
        ]"
        :style="{
          minHeight: autoHeight ? minHeight : undefined,
          maxHeight: autoHeight ? maxHeight : undefined,
        }"
        :disabled="disabled"
        rows="1"
        class="flex w-full reset-base text-sm p-0 !rounded-none !bg-transparent dark:!bg-transparent !border-0 !outline-0 !mb-0 placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 text-n-slate-12 dark:text-n-slate-12 disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-slate-25 dark:disabled:bg-slate-900"
        @input="handleInput"
        @focus="handleFocus"
        @blur="handleBlur"
      />
      <div
        v-if="showCharacterCount"
        class="flex items-center justify-end h-4 mt-1 bottom-3 ltr:right-3 rtl:left-3"
      >
        <span class="text-xs tabular-nums text-n-slate-10">
          {{ characterCount }} / {{ maxLength }}
        </span>
      </div>
    </div>
    <p
      v-if="message"
      class="min-w-0 mt-1 mb-0 text-xs truncate transition-all duration-500 ease-in-out"
      :class="messageClass"
    >
      {{ message }}
    </p>
  </div>
</template>
