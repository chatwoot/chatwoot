<template>
  <label class="switch" :class="classObject">
    <input
      :id="id"
      v-model="value"
      class="switch-input"
      :name="name"
      :disabled="disabled"
      type="checkbox"
    />
    <div class="switch-paddle" :for="name">
      <span class="show-for-sr">on off</span>
    </div>
  </label>
</template>

<script>
export default {
  props: {
    disabled: Boolean,
    isFullwidth: Boolean,
    type: String,
    size: String,
    checked: Boolean,
    name: String,
    id: String,
  },
  data() {
    return {
      value: null,
    };
  },
  computed: {
    classObject() {
      const { type, size, value } = this;
      return {
        [`is-${type}`]: type,
        [`${size}`]: size,
        checked: value,
      };
    },
  },
  watch: {
    value(val) {
      this.$emit('input', val);
    },
  },
  beforeMount() {
    this.value = this.checked;
  },
  mounted() {
    this.$emit('input', (this.value = !!this.checked));
  },
};
</script>
