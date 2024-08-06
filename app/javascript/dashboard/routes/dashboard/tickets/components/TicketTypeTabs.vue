<template>
  <div class="ticket-type-tabs">
    <button
      v-for="tab in tabs"
      :key="tab.key"
      :class="{ active: activeTab === tab.key }"
      @click="onTabClick(tab.key)"
    >
      {{ tab.name }} ({{ tab.count }})
    </button>
  </div>
</template>

<script>
export default {
  props: {
    activeTab: {
      type: String,
      required: true,
    },
    tabs: {
      type: Array,
      required: true,
    },
  },
  methods: {
    onTabClick(tabKey) {
      this.$emit('tab-change', tabKey);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.ticket-type-tabs {
  display: flex;
  justify-content: space-around;
  margin-bottom: 10px;
}
.ticket-type-tabs button {
  padding: 10px;
  cursor: pointer;
}
.ticket-type-tabs button.active {
  font-weight: bold;
  border-bottom: 2px solid $color-woot;
}
</style>
