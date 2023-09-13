<template>
  <textarea
    ref="textarea"
    :placeholder="placeholder"
    :value="value"
    @input="onInput"
    @focus="onFocus"
    @keyup="onKeyup"
    @blur="onBlur"
  />
</template>

<script>
import {
  appendSignature,
  removeSignature,
  extractTextFromMarkdown,
} from 'dashboard/helper/editorHelper';

const TYPING_INDICATOR_IDLE_TIME = 4000;
export default {
  props: {
    placeholder: {
      type: String,
      default: '',
    },
    value: {
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
    // add this as a prop, so that we won't have to include uiSettingsMixin
    sendWithSignature: {
      type: Boolean,
      default: false,
    },
    allowSignature: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      idleTimer: null,
    };
  },
  watch: {
    value() {
      this.resizeTextarea();
    },
    sendWithSignature(newValue) {
      if (this.allowSignature) {
        this.toggleSignatureInEditor(newValue);
      }
    },
  },
  mounted() {
    this.$nextTick(() => {
      if (this.value) {
        this.resizeTextarea();
      }
    });
  },
  methods: {
    resizeTextarea() {
      if (!this.value) {
        this.$el.style.height = `${this.minHeight}rem`;
      } else {
        this.$el.style.height = `${this.$el.scrollHeight}px`;
      }
    },
    toggleSignatureInEditor(signatureEnabled) {
      // The toggleSignatureInEditor gets the new value from the
      // watcher, this means that if the value is true, the signature
      // is supposed to be added, else we remove it.

      const cleanedSignature = extractTextFromMarkdown(this.signature);

      if (signatureEnabled) {
        this.value = appendSignature(this.value, cleanedSignature);
      } else {
        this.value = removeSignature(this.value, cleanedSignature);
      }

      this.$emit('input', this.value);

      this.$nextTick(() => {
        this.resizeTextarea();
      });
    },
    onInput(event) {
      this.$emit('input', event.target.value);
      this.resizeTextarea();
    },
    resetTyping() {
      this.$emit('typing-off');
      this.idleTimer = null;
    },
    turnOffIdleTimer() {
      if (this.idleTimer) {
        clearTimeout(this.idleTimer);
      }
    },
    onKeyup() {
      if (!this.idleTimer) {
        this.$emit('typing-on');
      }
      this.turnOffIdleTimer();
      this.idleTimer = setTimeout(
        () => this.resetTyping(),
        TYPING_INDICATOR_IDLE_TIME
      );
    },
    onBlur() {
      this.turnOffIdleTimer();
      this.resetTyping();
      this.$emit('blur');
    },
    onFocus() {
      this.$emit('focus');
    },
    focus() {
      this.$refs.textarea.focus();
    },
  },
};
</script>
