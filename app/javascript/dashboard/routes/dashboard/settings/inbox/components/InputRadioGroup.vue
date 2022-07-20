<template>
  <div>
    <label class="radio-group-label">{{ label }}</label>
    <div class="radio-group">
      <div class="radio-group-item" v-for="item in items" :key="item.id">
        <input
          :name="`${name} -radio-input`"
          type="radio"
          :checked="item.checked"
          @change="action({ ...item, checked: true })"
        />
        <label>{{ item.title }}</label>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    name: {
      type: String,
      default: 'string',
    },
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
  display: inline-block;
}
.radio-group-item {
  float: left;
}
</style>
