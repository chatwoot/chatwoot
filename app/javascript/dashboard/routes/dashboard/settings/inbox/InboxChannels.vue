<script>
import { mapGetters } from 'vuex';
import { useInstallationName } from 'shared/helpers/installationHelper';

export default {
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    items() {
      return this.$t('INBOX_MGMT.CREATE_FLOW').map(item => ({
        ...item,
        body: this.useInstallationName(
          item.body,
          this.globalConfig.installationName
        ),
      }));
    },
  },
  methods: {
    useInstallationName,
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
