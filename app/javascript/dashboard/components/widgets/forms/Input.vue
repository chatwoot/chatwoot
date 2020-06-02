<template>
  <label>
    <span v-if="label">{{ label }}</span>
    <input
      :value="value"
      :type="type"
      :placeholder="placeholder"
      @input="onChange"
    />
    <p v-if="helpText" class="help-text"></p>
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
  },
  methods: {
    onChange(e) {
      this.$emit('input', e.target.value);
    },
  },
};
</script>
