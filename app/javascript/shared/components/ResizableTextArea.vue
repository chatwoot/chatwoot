<template>
  <textarea
    ref="textarea"
    :style="{ height: textareaHeight }"
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
const PIXELS_PER_REM = 16;
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
    // allowSignature is a kill switch, ensuring no signature methods are triggered except when this flag is true
    allowSignature: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      idleTimer: null,
      textareaHeight: `${this.minHeight * PIXELS_PER_REM}px`,
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
      if (this.value) {
        this.resizeTextarea();
        this.setCursor();
      } else {
        this.focus();
      }
    });
  },
  methods: {
    resizeTextarea() {
      const textarea = this.$refs.textarea;
      if (!textarea || !this.value) return;
      // Reset the height to the minimum first to allow shrinking
      const minHeightPx = this.minHeight * PIXELS_PER_REM;
      this.textareaHeight = `${minHeightPx}px`;

      this.$nextTick(() => {
        const newHeight = Math.max(textarea.scrollHeight, minHeightPx);
        this.textareaHeight = `${newHeight}px`; // Update the height
      });
    },
    // The toggleSignatureInEditor gets the new value from the
    // watcher, this means that if the value is true, the signature
    // is supposed to be added, else we remove it.
    toggleSignatureInEditor(signatureEnabled) {
      const valueWithSignature = signatureEnabled
        ? appendSignature(this.value, this.cleanedSignature)
        : removeSignature(this.value, this.cleanedSignature);

      this.$emit('input', valueWithSignature);

      this.$nextTick(() => {
        this.resizeTextarea();
        this.setCursor();
      });
    },
    setCursor() {
      const bodyWithoutSignature = removeSignature(
        this.value,
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
      if (this.$refs.textarea) this.$refs.textarea.focus();
    },
  },
};
</script>
