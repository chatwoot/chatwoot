<template>
  <div
    class="overflow-auto p-4 max-w-full my-auto flex flex-row flex-nowrap h-full"
  >
    <woot-wizard class="hidden md:block w-[25%]" :items="items" />
    <router-view />
  </div>
</template>

<script>
export default {
  computed: {
    items() {
      const data = this.$t('TEAMS_SETTINGS.EDIT_FLOW.WIZARD');
      return data;
    },
  },
};
</script>
