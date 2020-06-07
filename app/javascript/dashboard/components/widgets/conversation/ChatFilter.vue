<template>
  <select :value="activeStatus" class="status--filter" @change="onTabChange">
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
  props: {
    activeStatus: {
      type: String,
      required: true,
    },
  },
  methods: {
    onTabChange(e) {
      this.$emit('statusFilterChange', e.target.value);
    },
  },
};
</script>
