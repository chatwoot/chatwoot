<template>
  <label class="input-container">
    <span v-if="label">{{ label }}</span>
    <input
      :value="value"
      :type="type"
      :placeholder="placeholder"
      :readonly="readonly"
      :style="styles"
      @input="onChange"
      @blur="onBlur"
    />
    <p v-if="helpText" class="help-text">{{ helpText }}</p>
    <span v-if="error" class="message">
      {{ error }}
    </span>
  </label>
</template>

<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    value: {
      type: [String, Number],
      default: '',
    },
    type: {
      type: String,
      default: 'text',
    },
    placeholder: {
      type: String,
      default: '',
    },
    helpText: {
      type: String,
      default: '',
    },
    error: {
      type: String,
      default: '',
    },
    readonly: {
      type: Boolean,
      default: false,
    },
    styles: {
      type: Object,
      default: () => {},
    },
  },
  methods: {
    onChange(e) {
      this.$emit('input', e.target.value);
    },
    onBlur(e) {
      this.$emit('blur', e.target.value);
    },
  },
};
</script>
<style scoped lang="scss">
.help-text {
  margin-top: var(--space-micro);
  font-size: var(--font-size-mini);
  color: var(--s-600);
  font-style: normal;
}
</style>
