<template>
  <div class="tab-container">
    <woot-tabs :index="activeTab" :border="false" @change="onTabChange">
      <woot-tabs-item
        v-for="item in tabs"
        :key="item.key"
        :name="item.name"
        :count="item.count"
      />
    </woot-tabs>
  </div>
</template>

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
      this.$emit('tab-change', this.tabs[index].key);
    },
  },
};
</script>
<style lang="scss" scoped>
.tab-container {
  margin-top: var(--space-smaller);
  border-bottom: 1px solid var(--s-100);
}
</style>
