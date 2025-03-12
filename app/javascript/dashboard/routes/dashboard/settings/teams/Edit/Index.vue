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
  <div
    class="overflow-auto p-4 max-w-full my-auto flex flex-row flex-nowrap h-full bg-slate-25 dark:bg-slate-800"
  >
    <woot-wizard class="hidden md:block w-1/4" :items="items" />
    <router-view />
  </div>
</template>
