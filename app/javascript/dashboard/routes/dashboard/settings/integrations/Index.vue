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
                  {{ $t('INTEGRATION_SETTINGS.WEBHOOK.INTEGRATION_TXT') }}
                </p>
              </div>
              <div class="small-2 column button-wrap">
                <router-link :to="frontendURL('settings/integrations/webhook')">
                  <button class="button success nice">
                    {{ $t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE') }}
                  </button>
                </router-link>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- <div class="small-4 columns help-wrap">
        <span v-html="$t('INTEGRATION_SETTINGS.SIDEBAR_TXT')"></span>
      </div> -->
    </div>
  </div>
</template>
<script>
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  methods: {
    frontendURL,
  },
};
</script>
