<script>
import { mapGetters } from 'vuex';
import OneHashInternalApp from './OneHashInternalApp.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
    OneHashInternalApp,
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
    }),
    integration() {
      return this.$store.getters['integrations/getIntegration']('onehash_apps');
    },
  },
  methods: {
    async connectOneHashCal() {
      await this.$store.dispatch('integrations/connectOneHashCal');
    },
    getTranslationKey(internalAppId, suffix) {
      const map = {
        onehash_cal: 'ONEHASH_CAL',
      };
      return `INTEGRATION_SETTINGS.${map[internalAppId]}.${suffix}`;
    },
  },
};
</script>

<template>
  <div v-if="!uiFlags.isCreating" class="flex flex-col flex-1 overflow-auto">
    <div
      class="p-4 bg-white border-b border-solid rounded-sm dark:bg-slate-800 border-slate-75 dark:border-slate-700/50"
    >
      <div
        v-for="(internalApp, key) in integration.internal_apps"
        :key="key"
        class="mb-4"
      >
        <OneHashInternalApp
          :integration-id="internalApp.id"
          :integration-logo="internalApp.logo"
          :integration-name="internalApp.name"
          :integration-description="internalApp.description"
          :integration-enabled="internalApp.enabled"
          :delete-button-text="$t(getTranslationKey(internalApp.id, 'DELETE'))"
          :delete-confirmation-text="{
            title: $t(
              getTranslationKey(internalApp.id, 'DELETE_CONFIRMATION.TITLE')
            ),
            message: $t(
              getTranslationKey(internalApp.id, 'DELETE_CONFIRMATION.MESSAGE')
            ),
          }"
        />
      </div>
    </div>
  </div>
  <div v-else class="flex items-center justify-center flex-1">
    <Spinner size="" color-scheme="primary" />
  </div>
</template>
