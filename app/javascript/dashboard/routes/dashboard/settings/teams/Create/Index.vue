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
  <div class="mx-0 mb-8 flex flex-col gap-6">
    <div
      class="grid min-h-[43rem] grid-cols-1 overflow-hidden rounded-2xl border border-outline-variant/10 bg-surface-container-low shadow-xl lg:grid-cols-8 lg:divide-x lg:divide-outline-variant/15"
    >
      <div
        class="hidden h-full bg-surface-container-high/25 py-8 px-6 lg:col-span-2 lg:block"
      >
        <woot-wizard class="h-fit" :items="items" />
      </div>
      <div class="min-w-0 lg:col-span-6">
        <router-view />
      </div>
    </div>
  </div>
</template>
