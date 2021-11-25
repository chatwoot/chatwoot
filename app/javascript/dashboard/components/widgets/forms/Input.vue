<template>
  <label>
    <span v-if="label">{{ label }}</span>
    <input
      :value="value"
      :type="type"
      :placeholder="placeholder"
      :readonly="readonly"
      @input="onChange"
      @blur="onBlur"
    />
    <p v-if="helpText" class="help-text"></p>
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
      deafaut: false,
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
