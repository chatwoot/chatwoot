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
  <div class="overflow-auto p-4 h-full w-full">
    <div
      class="mx-auto max-w-[960px] flex flex-row overflow-auto shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2 px-6 py-5 mb-10"
    >
      <woot-wizard class="hidden md:block w-1/4" :items="items" />
      <router-view />
    </div>
  </div>
</template>
