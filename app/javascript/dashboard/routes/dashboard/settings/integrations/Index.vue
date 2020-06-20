<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-8 columns integrations-wrap">
        <div class="row integrations">
          <div
            v-for="item in integrationsList"
            :key="item.id"
            class="small-12 columns integration"
          >
            <div class="row">
              <div class="integration--image">
                <img :src="'/assets/dashboard/integrations/' + item.logo" />
              </div>
              <div class="column">
                <h3 class="integration--title">
                  {{ item.name }}
                </h3>
                <p class="integration--description">
                  {{ item.description }}
                </p>
              </div>
              <div class="small-2 column button-wrap">
                <router-link
                  :to="
                    frontendURL(
                      `accounts/${accountId}/settings/integrations/` + item.id
                    )
                  "
                >
                  <div v-if="item.enabled">
                    <button class="button nice">
                      {{ $t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE') }}
                    </button>
                  </div>
                </router-link>
                <div v-if="!item.enabled">
                  <a :href="item.action" class="button success nice">
                    {{ $t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT') }}
                  </a>
                </div>
              </div>
            </div>
          </div>
          <div class="small-12 columns integration">
            <div class="row">
              <div class="integration--image">
                <img src="/assets/dashboard/integrations/cable.svg" />
              </div>
              <div class="column">
                <h3 class="integration--title">
                  {{ $t('INTEGRATION_SETTINGS.WEBHOOK.TITLE') }}
                </h3>
                <p class="integration--description">
                  {{
                    useInstallationName(
                      $t('INTEGRATION_SETTINGS.WEBHOOK.INTEGRATION_TXT'),
                      globalConfig.installationName
                    )
                  }}
                </p>
              </div>
              <div class="small-2 column button-wrap">
                <router-link
                  :to="
                    frontendURL(
                      `accounts/${accountId}/settings/integrations/webhook`
                    )
                  "
                >
                  <button class="button nice">
                    {{ $t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE') }}
                  </button>
                </router-link>
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
import { frontendURL } from '../../../../helper/URLHelper';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
      integrationsList: 'integrations/getIntegrations',
    }),
  },
  mounted() {
    this.$store.dispatch('integrations/get');
  },
  methods: {
    frontendURL,
  },
};
</script>
