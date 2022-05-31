<template>
  <div class="input-container">
    <input
      v-model="from"
      type="text"
      class="text-input"
      placeholder="from value (optional)"
    />
    <input
      v-model="to"
      type="text"
      class="text-input"
      placeholder="to value (optional)"
    />
  </div>
</template>

<script>
export default {
  // eslint-disable-next-line vue/require-prop-types
  props: ['value'],
  computed: {
    from: {
      get() {
        if (!this.value) return '';
        return this.value.from;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, from: value });
      },
    },
    to: {
      get() {
        if (!this.value) return '';
        return this.value.to;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, to: value });
      },
    },
  },
};
</script>

<style lang="scss" scoped>
.input-container {
  display: flex;
  margin-top: var(--space-small);
  input {
    flex: 1;
    margin-right: var(--space-smaller);
  }
}
</style>
