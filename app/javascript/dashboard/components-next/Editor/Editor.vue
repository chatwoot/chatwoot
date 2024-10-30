<script setup>
import { computed, ref, watch } from 'vue';

import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: '',
  },
  focusOnMount: {
    type: Boolean,
    default: false,
  },
  maxLength: {
    type: Number,
    default: 200,
  },
  showCharacterCount: {
    type: Boolean,
    default: true,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  message: {
    type: String,
    default: '',
  },
  messageType: {
    type: String,
    default: 'info',
    validator: value => ['info', 'error', 'success'].includes(value),
  },
});

const emit = defineEmits(['update:modelValue']);

const isFocused = ref(false);

const characterCount = computed(() => props.modelValue.length);

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

const handleInput = value => {
  emit('update:modelValue', value);
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

watch(
  () => props.modelValue,
  newValue => {
    if (props.maxLength && props.showCharacterCount) {
      if (characterCount.value >= props.maxLength) {
        emit('update:modelValue', newValue.slice(0, props.maxLength));
      }
    }
  }
);
</script>

<template>
  <div class="flex flex-col min-w-0 gap-1">
    <label v-if="label" class="mb-0.5 text-sm font-medium text-n-slate-12">
      {{ label }}
    </label>
    <div
      class="w-full transition-all duration-500 ease-in-out border rounded-lg editor-wrapper bg-n-alpha-black2"
      :class="[
        {
          'cursor-not-allowed opacity-50 pointer-events-none !bg-n-alpha-black2 disabled:border-n-weak dark:disabled:border-n-weak':
            disabled,
          'border-n-brand dark:border-n-brand': isFocused,
          'hover:border-n-slate-6 dark:hover:border-n-slate-6 border-n-weak dark:border-n-weak':
            !isFocused && messageType !== 'error',
          'border-n-ruby-8 dark:border-n-ruby-8 hover:border-n-ruby-9 dark:hover:border-n-ruby-9':
            messageType === 'error' && !isFocused,
        },
      ]"
    >
      <WootMessageEditor
        :model-value="modelValue"
        :placeholder="placeholder"
        :focus-on-mount="focusOnMount"
        :disabled="disabled"
        @input="handleInput"
        @focus="handleFocus"
        @blur="handleBlur"
      />
      <div
        v-if="showCharacterCount"
        class="flex items-center justify-end h-4 px-3 mt-1 mb-3 bottom-3 ltr:right-3 rtl:left-3"
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

<style lang="scss" scoped>
.editor-wrapper {
  ::v-deep {
    .ProseMirror-menubar-wrapper {
      .ProseMirror-menubar {
        @apply bg-transparent dark:bg-transparent w-fit left-4  !important;

        .ProseMirror-icon {
          @apply p-1 w-3 h-3 text-n-slate-12 dark:text-n-slate-12 !important;
        }
      }
      .ProseMirror.ProseMirror-woot-style {
        @apply px-3 !important;

        .empty-node::before {
          @apply text-n-slate-11 dark:text-n-slate-11 !important;
        }
      }
    }
  }
}
</style>
