<template>
  <div class="overflow-auto p-4 max-w-full my-auto flex flex-wrap h-full">
    <woot-wizard class="small-3 columns" :items="items" />
    <router-view />
  </div>
</template>

<script>
export default {
  computed: {
    items() {
      const data = this.$t('TEAMS_SETTINGS.CREATE_FLOW.WIZARD');
      return data;
    },
  },
};
</script>
