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
  },
  data() {
    return {
      activeTab: 0,
    };
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
  border-bottom: 1px solid var(--s-50);
}
</style>
