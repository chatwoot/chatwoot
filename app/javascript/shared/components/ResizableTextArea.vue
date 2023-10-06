<template>
  <div ref="textareaGrower" class="wrap grid max-h-32">
    <textarea
      ref="textarea"
      class="overflow-x-hidden overflow-y-auto max-h-[inherit] w-full border-0 focus:border-0 active:outline-0 focus-within:outline-0 resize-none m-0 p-0"
      :style="{
        minHeight: editorHeight,
      }"
      :placeholder="placeholder"
      :value="value"
      rows="1"
      @input="onInput"
      @focus="onFocus"
      @keyup="onKeyup"
      @blur="onBlur"
    />
  </div>
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
    // allowSignature is a kill switch, ensuring no signature methods are triggered except when this flag is true
    allowSignature: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      idleTimer: null,
      editorHeight: `${this.minHeight}rem`,
    };
  },
  computed: {
    cleanedSignature() {
      // clean the signature, this will ensure that we don't have
      // any markdown formatted text in the signature
      return extractTextFromMarkdown(this.signature);
    },
    textAreaHeight() {
      return this.editorHeight;
    },
  },
  watch: {
    value(value, oldValue) {
      if (value !== oldValue) {
        this.$nextTick(() => {
          this.resizeTextarea();
        });
      }
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
        this.setCursor();
      } else {
        this.focus();
      }
    });
  },
  methods: {
    resizeTextarea() {
      this.$refs.textareaGrower.dataset.replicatedValue = this.value;
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
<style scoped>
.wrap::after {
  /* Note the weird space! Needed to preventy jumpy behavior */
  content: attr(data-replicated-value) ' ';

  /* This is how textarea text behaves */
  white-space: pre-wrap;

  /* Hidden from view, clicks, and screen readers */
  visibility: hidden;
}

.wrap > textarea,
.wrap::after {
  /* Identical styling required!! */
  font: inherit;

  /* Place on top of each other */
  grid-area: 1 / 1 / 2 / 2;
}
</style>
