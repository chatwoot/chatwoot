<template>
  <multiple-integration-hooks
    v-if="integration.allow_multiple_hooks"
    :integration="integration"
  />
  <single-integration-hooks v-else :integration="integration" />
</template>
<script>
import { mapGetters } from 'vuex';
import MultipleIntegrationHooks from './MultipleIntegrationHooks';
import SingleIntegrationHooks from './SingleIntegrationHooks';

export default {
  components: {
    SingleIntegrationHooks,
    MultipleIntegrationHooks,
  },
  props: {
    integrationId: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'labels/getUIFlags',
    }),
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.$route.params.integration_id
      );
    },
  },
};
</script>
