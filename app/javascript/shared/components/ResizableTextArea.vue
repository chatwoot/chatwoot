<template>
  <textarea
    ref="textarea"
    :placeholder="placeholder"
    :value="value"
    @input="onInput"
    @focus="onFocus"
    @blur="onBlur"
  />
</template>

<script>
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
    onBlur() {
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
