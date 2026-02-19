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
  <div class="flex flex-col gap-6 mb-8 max-w-7xl mx-auto w-full !px-6">
    <div
      class="grid grid-cols-1 lg:grid-cols-8 lg:divide-x lg:divide-n-weak rounded-xl border border-n-weak min-h-[43rem] w-full"
    >
      <woot-wizard
        class="hidden lg:block col-span-2 h-fit py-8 px-6"
        :items="items"
      />
      <router-view />
    </div>
  </div>
</template>
