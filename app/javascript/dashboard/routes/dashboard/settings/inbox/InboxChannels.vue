<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
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
        body: this.useInstallationName(
          item.body,
          this.globalConfig.installationName
        ),
      }));
    },
  },
};
</script>

<template>
  <div
    class="flex flex-row overflow-auto p-4 h-full bg-slate-25 dark:bg-slate-800"
  >
    <woot-wizard
      class="hidden md:block w-1/4"
      :global-config="globalConfig"
      :items="items"
    />
    <router-view />
  </div>
</template>
