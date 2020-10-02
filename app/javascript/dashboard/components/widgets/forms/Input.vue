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
    <p v-if="showErrorText" class="error-text">{{errorText}}</p>
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
    errorText: {
      type: String,
      default: '',
    },
    showErrorText: {
      type: Boolean,
      default: false,
    }
  },
  methods: {
    onChange(e) {
      this.$emit('input', e.target.value);
    },
  },
};
</script>
