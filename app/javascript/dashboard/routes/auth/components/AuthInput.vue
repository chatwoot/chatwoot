<template>
  <label class="auth-input--wrap">
    <div class="label-wrap">
      <fluent-icon v-if="iconName" :icon="iconName" size="16" />
      <span v-if="label">{{ label }}</span>
    </div>
    <div class="input--wrap">
      <input
        class="auth-input"
        :value="value"
        :type="type"
        :placeholder="placeholder"
        :readonly="readonly"
        @input="onChange"
        @blur="onBlur"
      />
      <p v-if="helpText" class="help-text" />
      <span v-if="error" class="message">
        {{ error }}
      </span>
    </div>
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
    iconName: {
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
<style lang="scss" scoped>
.auth-input--wrap {
  .label-wrap {
    display: flex;
    align-items: center;
    color: var(--s-900);
    margin-bottom: var(--space-smaller);

    span {
      margin-left: var(--space-smaller);
      font-size: var(--font-size-small);
    }
  }

  .auth-input {
    font-size: var(--font-size-small) !important;
    height: 4rem !important;
    padding: var(--space-small) !important;
    width: 100% !important;
    background: var(--s-50) !important;
  }
}
</style>
