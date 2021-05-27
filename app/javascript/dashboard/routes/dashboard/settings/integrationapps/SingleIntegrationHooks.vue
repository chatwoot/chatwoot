<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-12 columns integrations-wrap">
        <div class="row integrations">
          <div class="small-12 columns integration">
            <div class="row">
              <div class="integration--image">
                <img
                  :src="'/dashboard/images/integrations/' + integration.logo"
                />
              </div>
              <div class="column">
                <h3 class="integration--title">
                  {{ integration.name }}
                </h3>
                <p class="integration--description">
                  {{ integration.description }}
                </p>
              </div>
              <div class="small-2 column button-wrap">
                <woot-button>
                  Configure
                </woot-button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  props: {
    integration: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      integrationLoaded: false,
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
    }),
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
