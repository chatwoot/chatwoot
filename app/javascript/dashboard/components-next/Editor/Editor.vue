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

const emit = defineEmits(['update:modelValue', 'executeCopilotAction']);

const slots = useSlots();

const isFocused = ref(false);

const characterCount = computed(() => props.modelValue.length);

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
    <label v-if="label" class="mb-0.5 text-sm font-medium text-s-primary">
      {{ label }}
    </label>
    <div
      class="flex flex-col w-full gap-2 px-3 py-3 transition-all duration-500 ease-in-out border rounded-lg editor-wrapper bg-s-primary/15"
      :class="[
        {
          'cursor-not-allowed opacity-50 pointer-events-none !bg-s-primary/15 disabled:border-s-border dark:disabled:border-s-border':
            disabled,
          'border-s-brand dark:border-s-brand': isFocused,
          'hover:border-s-border dark:hover:border-s-border border-s-border dark:border-s-border':
            !isFocused && messageType !== 'error',
          'border-s-error dark:border-s-error hover:border-s-error dark:hover:border-s-error':
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
        @execute-copilot-action="
          (...args) => emit('executeCopilotAction', ...args)
        "
      />
      <div
        v-if="showCharacterCount || slots.actions"
        class="flex items-center justify-end h-4 ltr:right-3 rtl:left-3"
      >
        <span
          v-if="showCharacterCount && !slots.actions"
          class="text-xs tabular-nums text-s-muted"
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
            @apply text-s-muted dark:text-s-muted;
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
