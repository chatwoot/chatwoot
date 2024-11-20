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
  <div class="overflow-auto p-4 h-full w-full">
    <div
      class="mx-auto max-w-[960px] flex flex-row overflow-auto shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2 px-6 py-5 mb-10"
    >
      <woot-wizard class="hidden md:block w-1/4" :items="items" />
      <router-view />
    </div>
  </div>
</template>
