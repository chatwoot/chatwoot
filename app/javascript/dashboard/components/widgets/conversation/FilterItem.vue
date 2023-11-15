<template>
  <select
    v-model="activeValue"
    class="bg-slate-25 dark:bg-slate-700 text-xs h-6 my-0 mx-1 py-0 pr-6 pl-2 w-32 border border-solid border-slate-75 dark:border-slate-600 text-slate-800 dark:text-slate-100"
    @change="onTabChange()"
  >
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
