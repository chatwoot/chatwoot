<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    options: {
      type: Array,
      default: () => [],
    },
    selected: {
      type: String,
      default: '',
    },
    action: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      value: this.selected,
    };
  },
};
</script>

<template>
  <div>
    <label for="dropdown-select">
      {{ label }}
    </label>
    <select
      id="dropdown-select"
      v-model="value"
      name="dropdown-select"
      @change="action(value)"
    >
      <option v-for="option in options" :key="option.key">
        {{ option.value }}
      </option>
    </select>
  </div>
</template>
