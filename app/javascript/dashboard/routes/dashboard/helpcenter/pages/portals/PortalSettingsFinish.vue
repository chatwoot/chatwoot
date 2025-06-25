<template>
  <div class="wizard-body height-auto small-9 columns">
    <empty-state
      :title="$t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.TITLE')"
      :message="
        $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.MESSAGE')
      "
    >
      <div class="medium-12 columns text-center">
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
import EmptyState from 'dashboard/components/widgets/EmptyState';
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
  padding-top: var(--space-slab);
  border: 1px solid transparent;
}
</style>
