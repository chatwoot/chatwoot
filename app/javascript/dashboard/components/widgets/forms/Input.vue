<template>
  <label class="input-container">
    <span v-if="label">{{ label }}</span>
    <input
      class="bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 border-slate-200 dark:border-slate-600"
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
    <slot name="masked" />
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
  @apply mt-0.5 text-xs not-italic text-slate-600 dark:text-slate-400;
}

.message {
  margin-top: 0 !important;
}
</style>
