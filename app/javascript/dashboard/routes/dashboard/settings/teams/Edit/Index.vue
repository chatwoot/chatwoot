<script>
export default {
  computed: {
    items() {
      const routes = {
        EDIT_WIZARD_DETAILS: 'settings_teams_edit',
        EDIT_WIZARD_AGENTS: 'settings_teams_edit_members',
        EDIT_WIZARD_FINISH: 'settings_teams_edit_finish',
      };

      const steps = [
        'EDIT_WIZARD_DETAILS',
        'EDIT_WIZARD_AGENTS',
        'EDIT_WIZARD_FINISH',
      ];

      return steps.map(step => {
        return {
          title: this.$t(`TEAMS_SETTINGS.EDIT_FLOW.${step}.TITLE`),
          body: this.$t(`TEAMS_SETTINGS.EDIT_FLOW.${step}.BODY`),
          route: routes[step],
        };
      });
    },
  },
};
</script>

<template>
  <div class="mx-2 flex flex-col gap-6 mb-8">
    <div
      class="grid grid-cols-1 lg:grid-cols-8 lg:divide-x lg:divide-n-weak rounded-xl border border-n-weak min-h-[43rem]"
    >
      <woot-wizard
        class="hidden lg:block col-span-2 h-fit py-8 px-6"
        :items="items"
      />
      <router-view />
    </div>
  </div>
</template>
