<template>
  <select v-model="activeStatus" class="status--filter" @change="onTabChange()">
    <option v-for="item in chatStatusList" :key="item.name" :value="item.name">
      {{ item.name }}
    </option>
  </select>
</template>

<script>
import wootConstants from '../../../constants';
import { mapGetters } from 'vuex';

export default {
  data: () => ({
    activeStatus: wootConstants.STATUS_TYPE.OPEN,
  }),
  computed: {
    ...mapGetters({
      chatStatusItems: 'chatStatus/getChatStatusItems',
    }),
    chatStatusList() {
      let chatStatusList = [];
      chatStatusList = this.chatStatusItems.slice();
      return chatStatusList;
    },
  },
  methods: {
    onTabChange() {
      this.$store.dispatch('setChatFilter', this.activeStatus);
      this.$emit('statusFilterChange', this.activeStatus);
    },
  },
};
</script>
