<template>
  <multiple-integration-hooks :integration="integration" />
</template>
<script>
import MultipleIntegrationHooks from './MultipleIntegrationHooks';
// import SingleIntegrationHooks from './SingleIntegrationHooks';

export default {
  components: {
    MultipleIntegrationHooks,
  },
  props: {
    integrationId: {
      type: String,
      default: '',
    },
  },
  computed: {
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.$route.params.integration_id
      );
    },
  },
};
</script>
