<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-8 columns integrations-wrap">
        <div class="row integrations">
          <div class="small-12 columns integration">
            <div class="row">
              <div class="integration--image">
                <img src="~dashboard/assets/images/integrations/cable.svg" />
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
                  <button class="button success nice">
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
    }),
    accountId() {
      return this.currentUser.account_id;
    },
  },
  methods: {
    frontendURL,
  },
};
</script>
