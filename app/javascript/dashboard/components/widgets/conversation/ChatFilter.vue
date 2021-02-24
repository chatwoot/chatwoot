<template>
  <select v-model="activeStatus" class="status--filter" @change="onTabChange()">
    <option
      v-for="(StatusItem, index) in records"
      :key="StatusItem.name"
      :value="StatusItem.name"
    >
      {{ StatusItem.name }}
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
      records: 'getStatus',
      uiFlags: 'getUIFlags',
    }),
  },
  methods: {
    onTabChange() {
      this.$store.dispatch('setChatFilter', this.activeStatus);
      this.$emit('statusFilterChange', this.activeStatus);
    },
  },
};
</script>
