<script>
export default {
  props: {
    tabs: {
      type: Array,
      default: () => [],
    },
    selectedTab: {
      type: Number,
      default: 0,
    },
  },
  emits: ['tabChange'],
  data() {
    return {
      activeTab: 0,
    };
  },
  watch: {
    selectedTab(value, oldValue) {
      if (value !== oldValue) {
        this.activeTab = this.selectedTab;
      }
    },
  },
  methods: {
    onTabChange(index) {
      this.activeTab = index;
      this.$emit('tabChange', this.tabs[index].key);
    },
  },
};
</script>

<template>
  <div class="tab-container">
    <woot-tabs :index="activeTab" :border="false" @change="onTabChange">
      <woot-tabs-item
        v-for="(item, index) in tabs"
        :key="item.key"
        :index="index"
        :name="item.name"
        :count="item.count"
      />
    </woot-tabs>
  </div>
</template>

<style lang="scss" scoped>
.tab-container {
  @apply mt-1 border-b border-solid border-slate-100 dark:border-slate-800/50;
}
</style>
