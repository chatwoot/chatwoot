<script>
export default {
  props: {
    selectedValue: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
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
  emits: ['onChangeFilter'],
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

<template>
  <select
    v-model="activeValue"
    class="w-32 h-6 py-0 pl-2 pr-6 mx-1 my-0 text-xs border border-solid bg-n-slate-3 dark:bg-n-solid-3 border-n-weak dark:border-n-weak text-n-slate-12"
    @change="onTabChange()"
  >
    <option v-for="value in items" :key="value" :value="value">
      {{ $t(`${pathPrefix}.${value}.TEXT`) }}
    </option>
  </select>
</template>
