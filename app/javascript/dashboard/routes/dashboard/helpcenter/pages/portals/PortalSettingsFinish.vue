<template>
  <div
    class="pt-3 bg-white dark:bg-slate-900 h-full border border-solid border-transparent px-6 pb-6 dark:border-transparent w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <empty-state
      :title="$t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.TITLE')"
      :message="
        $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.MESSAGE')
      "
    >
      <div class="w-full text-center">
        <router-link
          class="button success nice rounded"
          :to="{
            name: 'list_all_portals',
          }"
        >
          {{ $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.FINISH') }}
        </router-link>
      </div>
    </empty-state>
  </div>
</template>

<script>
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
export default {
  components: {
    EmptyState,
  },
  methods: {
    changeRoute() {
      this.$router.push({
        name: 'list_all_portals',
      });
    },
  },
};
</script>
