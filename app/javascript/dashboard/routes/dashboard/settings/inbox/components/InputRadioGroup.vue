<template>
  <div>
    <label class="radio-group-label">{{ label }}</label>
    <div class="radio-group">
      <div v-for="item in items" :key="item.id">
        <input
          name="radio-input"
          type="radio"
          :checked="item.checked"
          @change="action(item)"
        />
        <label>{{ item.title }}</label>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    items: {
      type: Array,
      default: () => [],
    },
    action: {
      type: Function,
      default: () => {},
    },
  },
};
</script>

<style lang="scss" scoped>
.radio-group-label {
  margin-bottom: var(--space-small);
}
.radio-group {
  display: flex;
  align-items: center;
}
</style>
