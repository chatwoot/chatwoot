<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-12 columns integrations-wrap">
        <div class="row integrations">
          <div v-if="integrationLoaded" class="small-12 columns integration">
            <integration
              :integration-id="integration.id"
              :integration-logo="integration.logo"
              :integration-name="integration.name"
              :integration-description="integration.description"
              :integration-enabled="integration.enabled"
              :integration-action="integrationAction()"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import Integration from './Integration';

export default {
  components: {
    Integration,
  },
  mixins: [globalConfigMixin],
  props: ['integrationId', 'code'],
  data() {
    return {
      integrationLoaded: false,
    };
  },
  computed: {
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.integrationId
      );
    },
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    this.intializeSlackIntegration();
  },
  methods: {
    integrationAction() {
      if (this.integration.enabled) {
        return 'disconnect';
      }
      return this.integration.action;
    },
    async intializeSlackIntegration() {
      await this.$store.dispatch('integrations/get', this.integrationId);
      if (this.code) {
        await this.$store.dispatch('integrations/connectSlack', this.code);
        // we are clearing code from the path as subsequent request would throw error
        this.$router.replace(this.$route.path);
      }
      this.integrationLoaded = true;
    },
  },
};
</script>
