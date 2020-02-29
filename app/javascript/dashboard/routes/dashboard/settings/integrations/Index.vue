<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-8 columns integrations-wrap">
        <div class="row integrations">
          <div class="small-12 columns integration">
            <div class="row">
              <div class="image-wrap">
                <img
                  class="image"
                  src="~dashboard/assets/images/integrations/cable.svg"
                />
              </div>
              <div class="column">
                <h3 class="page-sub-title">
                  WebHooks
                </h3>
                <p>
                  Webhooks lets you notify your app whenever an event happens at
                  chatwoot.Currently we support Website live chat widgets,
                  Facebook Pages and Twitter profiles as platforms.
                </p>
              </div>
              <div class="small-2 column button-wrap">
                <router-link :to="frontendURL('settings/integrations/webhook')">
                  <button class="button success nice">
                    Configure
                  </button>
                </router-link>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="small-4 columns help-wrap">
        <span v-html="$t('AGENT_MGMT.SIDEBAR_TXT')"></span>
      </div>
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
