<template>
  <div
    class="label-dropdown-item"
    :class="{ selected: isSelected }"
    @click="handleClick"
  >
    <span class="label-color" :style="{ backgroundColor: color }" />
    <span class="label-title">{{ title }}</span>
  </div>
</template>
<script>
export default {
  name: 'LabelDropdownItem',
  props: {
    title: {
      type: String,
      required: true,
    },
    color: {
      type: String,
      required: true,
    },
    selected: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    isSelected() {
      return this.selected;
    },
  },
  methods: {
    handleClick() {
      this.$emit('click');
    },
  },
};
</script>
<style lang="scss" scoped>
.label-dropdown-item {
  display: flex;
  align-items: center;
  padding: 0.5rem;
  cursor: pointer;
  border-radius: 4px;
  transition: background-color 0.2s ease-in-out;

  &.selected {
    background-color: var(--selected-bg-color, #e2e8f0);
  }

  &:hover {
    background-color: var(--hover-bg-color, #f1f5f9);
  }
}

.label-color {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  margin-right: 0.5rem;
}

.label-title {
  flex-grow: 1;
}
</style>
