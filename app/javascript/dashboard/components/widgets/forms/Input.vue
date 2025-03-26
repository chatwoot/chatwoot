<script>
/**
 * @deprecated This component is deprecated and will be removed in the next major version.
 * Please use v3/components/Form/Input.vue instead
 */
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    modelValue: {
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
  emits: ['update:modelValue', 'input', 'blur'],
  mounted() {
    if (import.meta.env.DEV) {
      // eslint-disable-next-line no-console
      console.warn(
        '[DEPRECATED] <WootInput> has be deprecated and will be removed soon. Please use v3/components/Form/Input.vue instead'
      );
    }
  },
  methods: {
    onChange(e) {
      this.$emit('input', e.target.value);
      this.$emit('update:modelValue', e.target.value);
    },
    onBlur(e) {
      this.$emit('blur', e.target.value);
    },
  },
};
</script>

<template>
  <label class="input-container">
    <span v-if="label">{{ label }}</span>
    <input
      :value="modelValue"
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

<style scoped lang="scss">
.help-text {
  @apply mt-0.5 text-xs not-italic text-n-slate-11;
}

.message {
  margin-top: 0 !important;
}
</style>
