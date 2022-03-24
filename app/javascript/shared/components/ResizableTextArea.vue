<template>
  <textarea
    ref="textarea"
    :class="inputColor"
    :placeholder="placeholder"
    :value="value"
    @input="onInput"
    @focus="onFocus"
    @keyup="onKeyup"
    @blur="onBlur"
  />
</template>

<script>
const TYPING_INDICATOR_IDLE_TIME = 4000;
import darkModeMixin from 'widget/mixins/darkModeMixin.js';
export default {
  mixins: [darkModeMixin],
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
  },
  data() {
    return {
      idleTimer: null,
    };
  },
  computed: {
    inputColor() {
      return `${this.$dm('bg-white', 'dark:bg-slate-600')}
        ${this.$dm('text-black-900', 'dark:text-slate-50')}`;
    },
  },
  watch: {
    value() {
      this.resizeTextarea();
    },
  },
  methods: {
    resizeTextarea() {
      if (!this.value) {
        this.$el.style.height = `${this.minHeight}rem`;
      } else {
        this.$el.style.height = `${this.$el.scrollHeight}px`;
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
      this.$refs.textarea.focus();
    },
  },
};
</script>
