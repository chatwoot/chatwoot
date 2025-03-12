<script>
export default {
  computed: {
    items() {
      const steps = ['WIZARD_CREATE', 'WIZARD_ADD_AGENTS', 'WIZARD_FINISH'];

      const routes = {
        WIZARD_CREATE: 'settings_teams_new',
        WIZARD_ADD_AGENTS: 'settings_teams_add_agents',
        WIZARD_FINISH: 'settings_teams_finish',
      };

      return steps.map(step => {
        return {
          title: this.$t(`TEAMS_SETTINGS.CREATE_FLOW.${step}.TITLE`),
          body: this.$t(`TEAMS_SETTINGS.CREATE_FLOW.${step}.BODY`),
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
