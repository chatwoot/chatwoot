
<template>
  <select class="status--filter" v-model="activeIndex" @change="onTabChange()">
    <option v-for="(item, index) in $t('CHAT_LIST.CHAT_STAUTUS_ITEMS')" :value="item['VALUE']">{{item["TEXT"]}}</option>
  </select>
</template>

<script>
export default {
  data: () => ({
    activeIndex: 0,
  }),
  mounted() {
  },
  methods: {
    onTabChange() {
      this.$store.dispatch('setChatFilter', this.activeIndex);
      this.$emit('statusFilterChange', this.activeIndex);
    },
  },
};
</script>
