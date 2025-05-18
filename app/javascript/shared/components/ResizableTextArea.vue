<script>
import {
  appendSignature,
  removeSignature,
  extractTextFromMarkdown,
} from 'dashboard/helper/editorHelper';
import { createTypingIndicator } from '@chatwoot/utils';

const TYPING_INDICATOR_IDLE_TIME = 4000;
export default {
  props: {
    placeholder: {
      type: String,
      default: '',
    },
    modelValue: {
      type: String,
      default: '',
    },
    minHeight: {
      type: Number,
      default: 2,
    },
    signature: {
      type: String,
      default: '',
    },
    rows: {
      type: Number,
      default: 2,
    },
    // add this as a prop, so that we won't have to add useUISettings
    sendWithSignature: {
      type: Boolean,
      default: false,
    },
    // allowSignature is a kill switch, ensuring no signature methods are triggered except when this flag is true
    allowSignature: {
      type: Boolean,
      default: false,
    },
  },
  emits: [
    'typingOn',
    'typingOff',
    'update:modelValue',
    'input',
    'blur',
    'focus',
  ],
  data() {
    return {
      typingIndicator: createTypingIndicator(
        () => {
          this.$emit('typingOn');
        },
        () => {
          this.$emit('typingOff');
        },
        TYPING_INDICATOR_IDLE_TIME
      ),
    };
  },
  computed: {
    cleanedSignature() {
      // clean the signature, this will ensure that we don't have
      // any markdown formatted text in the signature
      return extractTextFromMarkdown(this.signature);
    },
  },
  watch: {
    value() {
      this.resizeTextarea();
      // 🚨 watch triggers every time the value is changed, we cannot set this to focus then
      // when this runs, it sets the cursor to the end of the body, ignoring the signature
      // Suppose if someone manually set the cursor to the middle of the body
      // and starts typing, the cursor will be set to the end of the body
      // A surprise cursor jump? Definitely not user-friendly.
      if (document.activeElement !== this.$refs.textarea) {
        this.$nextTick(() => {
          this.setCursor();
        });
      }
    },
    sendWithSignature(newValue) {
      if (this.allowSignature) {
        this.toggleSignatureInEditor(newValue);
      }
    },
  },
  mounted() {
    this.$nextTick(() => {
      if (this.modelValue) {
        this.resizeTextarea();
        this.setCursor();
      } else {
        this.focus();
      }
    });
  },
  methods: {
    resizeTextarea() {
      this.$el.style.height = 'auto';
      if (!this.modelValue) {
        this.$el.style.height = `${this.minHeight}rem`;
      } else {
        this.$el.style.height = `${this.$el.scrollHeight}px`;
      }
    },
    // The toggleSignatureInEditor gets the new value from the
    // watcher, this means that if the value is true, the signature
    // is supposed to be added, else we remove it.
    toggleSignatureInEditor(signatureEnabled) {
      const valueWithSignature = signatureEnabled
        ? appendSignature(this.modelValue, this.cleanedSignature)
        : removeSignature(this.modelValue, this.cleanedSignature);

      this.$emit('update:modelValue', valueWithSignature);
      this.$emit('input', valueWithSignature);

      this.$nextTick(() => {
        this.resizeTextarea();
        this.setCursor();
      });
    },
    setCursor() {
      const bodyWithoutSignature = removeSignature(
        this.modelValue,
        this.cleanedSignature
      );

      // only trim at end, so if there are spaces at the start, those are not removed
      const bodyEndsAt = bodyWithoutSignature.trimEnd().length;
      const textarea = this.$refs.textarea;

      if (textarea) {
        textarea.focus();
        textarea.setSelectionRange(bodyEndsAt, bodyEndsAt);
      }
    },
    onInput(event) {
      this.$emit('update:modelValue', event.target.value);
      this.$emit('input', event.target.value);
      this.resizeTextarea();
    },
    onKeyup() {
      if (this.modelValue.length) {
        this.typingIndicator.start();
      } else {
        this.typingIndicator.stop();
      }
    },
    onBlur() {
      this.typingIndicator.stop();
      this.$emit('blur');
    },
    onFocus() {
      this.$emit('focus');
    },
    focus() {
      if (this.$refs.textarea) this.$refs.textarea.focus();
    },
  },
};
</script>

<template>
  <textarea
    ref="textarea"
    :placeholder="placeholder"
    :rows="rows"
    :value="modelValue"
    @input="onInput"
    @focus="onFocus"
    @keyup="onKeyup"
    @blur="onBlur"
  />
</template>
