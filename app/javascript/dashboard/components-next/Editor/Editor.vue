<script setup>
import { computed, ref, watch, useSlots } from 'vue';

import WootEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

const props = defineProps({
  modelValue: { type: String, default: '' },
  editorKey: { type: String, default: '' },
  label: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  focusOnMount: { type: Boolean, default: false },
  maxLength: { type: Number, default: 200 },
  showCharacterCount: { type: Boolean, default: true },
  disabled: { type: Boolean, default: false },
  message: { type: String, default: '' },
  messageType: {
    type: String,
    default: 'info',
    validator: value => ['info', 'error', 'success'].includes(value),
  },
  enableVariables: { type: Boolean, default: false },
  enableCannedResponses: { type: Boolean, default: true },
  enableCaptainTools: { type: Boolean, default: false },
  signature: { type: String, default: '' },
  allowSignature: { type: Boolean, default: false },
  sendWithSignature: { type: Boolean, default: false },
  channelType: { type: String, default: '' },
  medium: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue']);

const slots = useSlots();

const isFocused = ref(false);

const characterCount = computed(() => props.modelValue.length);

const messageClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'text-n-ruby-9 dark:text-n-ruby-9';
    case 'success':
      return 'text-n-teal-10 dark:text-n-teal-10';
    default:
      return 'text-n-slate-11 dark:text-n-slate-11';
  }
});

const handleInput = value => {
  if (!props.disabled) {
    emit('update:modelValue', value);
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

watch(
  () => props.modelValue,
  newValue => {
    if (props.maxLength && props.showCharacterCount && !slots.actions) {
      if (characterCount.value >= props.maxLength) {
        emit('update:modelValue', newValue.slice(0, props.maxLength));
      }
    }
  }
);
</script>

<template>
  <div class="flex flex-col min-w-0 gap-1">
    <label v-if="label" class="mb-0.5 text-sm font-medium text-on-surface">
      {{ label }}
    </label>
    <div
      class="editor-wrapper flex w-full flex-col gap-2 rounded-lg border border-solid bg-surface-container-lowest px-3 py-3 transition-all duration-200 ease-in-out"
      :class="[
        {
          'cursor-not-allowed opacity-50 pointer-events-none border-outline-variant/20':
            disabled,
          'border-secondary ring-1 ring-secondary ring-offset-0': isFocused,
          'border-outline-variant/30 hover:border-outline-variant/50':
            !isFocused && messageType !== 'error',
          'border-error hover:border-error':
            messageType === 'error' && !isFocused,
        },
      ]"
    >
      <WootEditor
        :editor-id="editorKey"
        :model-value="modelValue"
        :placeholder="placeholder"
        :focus-on-mount="focusOnMount"
        :disabled="disabled"
        :enable-variables="enableVariables"
        :enable-canned-responses="enableCannedResponses"
        :enable-captain-tools="enableCaptainTools"
        :signature="signature"
        :allow-signature="allowSignature"
        :send-with-signature="sendWithSignature"
        :channel-type="channelType"
        :medium="medium"
        @input="handleInput"
        @focus="handleFocus"
        @blur="handleBlur"
      />
      <div
        v-if="showCharacterCount || slots.actions"
        class="flex items-center justify-end h-4 ltr:right-3 rtl:left-3"
      >
        <span
          v-if="showCharacterCount && !slots.actions"
          class="text-xs tabular-nums text-on-surface-variant"
        >
          {{ characterCount }} / {{ maxLength }}
        </span>
        <slot v-else name="actions" />
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
      .ProseMirror.ProseMirror-woot-style {
        p {
          @apply first:mt-0 !important;
        }

        .empty-node {
          @apply m-0 !important;

          &::before {
            @apply text-n-slate-11 dark:text-n-slate-11;
          }
        }
      }

      .ProseMirror-menubar {
        width: fit-content !important;
        position: relative !important;
        top: unset !important;
        @apply ltr:left-[-0.188rem] rtl:right-[-0.188rem] !important;
      }
    }
  }
}
</style>
