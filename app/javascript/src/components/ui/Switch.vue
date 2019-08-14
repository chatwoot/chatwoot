
<template>
  <label class="switch" :class="classObject">
    <input class="switch-input" :name="name" :id="id" :disabled="disabled" v-model="value" type="checkbox">
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
  beforeMount() {
    this.value = this.checked;
  },
  mounted() {
    this.$emit('input', this.value = !!this.checked);
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
};
</script>
