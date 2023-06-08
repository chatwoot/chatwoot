<template>
  <select v-model="activeValue" class="status--filter" @change="onTabChange()">
    <option v-for="(value, status) in items" :key="status" :value="status">
      {{ $t(`${pathPrefix}.${status}.TEXT`) }}
    </option>
  </select>
</template>
<script>
export default {
  props: {
    selectedValue: {
      type: String,
      required: true,
    },
    items: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
    pathPrefix: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      activeValue: this.selectedValue,
    };
  },
  methods: {
    onTabChange() {
      if (this.type === 'status') {
        this.$store.dispatch('setChatStatusFilter', this.activeValue);
      } else {
        this.$store.dispatch('setChatSortFilter', this.activeValue);
      }
      this.$emit('onChangeFilter', this.activeValue, this.type);
    },
  },
};
</script>
<style lang="scss" scoped>
.status--filter {
  background-color: var(--color-background-light);
  border: 1px solid var(--color-border);
  font-size: var(--font-size-mini);
  height: var(--space-medium);
  margin: 0 var(--space-smaller);
  padding: 0 var(--space-medium) 0 var(--space-small);
  width: 126px;
}
</style>
