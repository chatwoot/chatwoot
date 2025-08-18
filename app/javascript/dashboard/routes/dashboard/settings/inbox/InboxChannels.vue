<script>
import { mapGetters } from 'vuex';
import { useBranding } from 'shared/composables/useBranding';

export default {
  setup() {
    const { replaceInstallationName } = useBranding();
    return {
      replaceInstallationName,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    createFlowSteps() {
      const steps = ['CHANNEL', 'INBOX', 'AGENT', 'FINISH'];

      const routes = {
        CHANNEL: 'settings_inbox_new',
        INBOX: 'settings_inboxes_page_channel',
        AGENT: 'settings_inboxes_add_agents',
        FINISH: 'settings_inbox_finish',
      };

      return steps.map(step => {
        return {
          title: this.$t(`INBOX_MGMT.CREATE_FLOW.${step}.TITLE`),
          body: this.$t(`INBOX_MGMT.CREATE_FLOW.${step}.BODY`),
          route: routes[step],
        };
      });
    },
    items() {
      return this.createFlowSteps.map(item => ({
        ...item,
        body: this.replaceInstallationName(item.body),
      }));
    },
  },
};
</script>

<template>
  <div class="grid grid-cols-1 md:grid-cols-8 overflow-auto h-full">
    <woot-wizard
      class="hidden md:block col-span-2"
      :global-config="globalConfig"
      :items="items"
    />
    <div class="col-span-6">
      <router-view />
    </div>
  </div>
</template>
