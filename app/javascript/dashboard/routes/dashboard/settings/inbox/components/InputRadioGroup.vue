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

<template>
  <div>
    <label class="radio-group-label">{{ label }}</label>
    <div class="radio-group">
      <div v-for="item in items" :key="item.id" class="radio-group-item">
        <label class="radio-group-item-label">
          <input
            class="radio-input"
            :name="`${name} -radio-input`"
            type="radio"
            :checked="item.checked"
            @change="action({ ...item, checked: true })"
          />
          <span>{{ item.title }}</span>
        </label>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.radio-group-label {
  margin-bottom: 0.25rem;
}
.radio-group {
  display: inline-block;
  margin-bottom: 0.5rem;
}
.radio-group-item {
  float: left;
  margin-right: 0.625rem;
  .radio-group-item-label {
    display: flex;
    align-items: center;
    cursor: pointer;

    .radio-input {
      margin: 0 0.625rem 0 0;
    }
  }
}
</style>
