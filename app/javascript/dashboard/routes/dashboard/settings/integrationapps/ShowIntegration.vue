<template>
  <multiple-integration-hooks
    v-if="integration.allow_multiple_hooks"
    :integration="integration"
  />
  <single-integration-hooks v-else :integration="integration" />
</template>
<script>
import MultipleIntegrationHooks from './MultipleIntegrationHooks';
import SingleIntegrationHooks from './SingleIntegrationHooks';

export default {
  components: {
    SingleIntegrationHooks,
    MultipleIntegrationHooks,
  },
  props: ['integrationId', 'code'],
  computed: {
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.integrationId
      );
    },
  },
};
</script>
