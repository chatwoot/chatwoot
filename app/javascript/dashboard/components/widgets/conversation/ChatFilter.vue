<template>
  <select v-model="activeStatus" class="status--filter" @change="onTabChange()">
    <option
      v-for="item in $t('CHAT_LIST.CHAT_STATUS_ITEMS')"
      :key="item['VALUE']"
      :value="item['VALUE']"
    >
      {{ item['TEXT'] }}
    </option>
  </select>
</template>

<script>
export default {
  data: () => ({
    activeStatus: 'open',
  }),
  methods: {
    onTabChange() {
      this.$store.dispatch('setChatFilter', this.activeStatus);
      this.$emit('statusFilterChange', this.activeStatus);
    },
  },
};
</script>
