<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%] h-auto">
    <empty-state
      :title="$t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.TITLE')"
      :message="
        $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.MESSAGE')
      "
    >
      <div class="w-full text-center">
        <router-link
          class="button success nice"
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
<style lang="scss" scoped>
.wizard-body {
  @apply pb-3;
}
</style>
