<template>
  <div class="column content-box">
    <div class="small-12 columns integrations-wrap">
      <div class="small-12 columns integration">
        <div class="row">
          <div class="integration--image">
            <img :src="'/dashboard/images/integrations/' + integration.logo" />
          </div>
          <div class="integration--type column">
            <h3 class="integration--title">
              {{ integration.name }}
            </h3>
            <p>
              {{ integration.description }}
            </p>
          </div>
          <div class="small-2 column button-wrap">
            <div v-if="hasConnectedHooks">
              <div @click="redirectToDouyinAuthUrl()">
                <woot-button class="nice">
                  绑定企业号
                </woot-button>
              </div>
            </div>
            <div v-if="hasConnectedHooks">
              <div @click="$emit('delete', integration.hooks[0])">
                <woot-button class="nice alert">
                  {{ $t('INTEGRATION_APPS.DISCONNECT.BUTTON_TEXT') }}
                </woot-button>
              </div>
            </div>
            <div v-else>
              <woot-button class="button nice" @click="$emit('add')">
                {{ $t('INTEGRATION_APPS.CONNECT.BUTTON_TEXT') }}
              </woot-button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import hookMixin from './hookMixin';
import store from '../../../../store';
export default {
  mixins: [hookMixin],
  props: {
    integration: {
      type: Object,
      default: () => ({}),
    },
  },
  methods: {
    redirectToDouyinAuthUrl() {
      const baseUrl = 'https://open.douyin.com/platform/oauth/connect';
      const clientKey = 'aw92klegpruawqra';
      const redirectUri = 'https://crm-tommytech-online.test/douyin/callback';
      const responseType = 'code';
      const scope =
        'trial.whitelist,user_info,item.comment,data.external.item,video.search,video.search.comment';
      // eslint-disable-next-line
      const { isLoggedIn, getCurrentUser: user } = store.getters;

      // Build the query string
      const queryString = new URLSearchParams({
        client_key: clientKey,
        redirect_uri: redirectUri,
        response_type: responseType,
        scope: scope,
        state: user.account_id.toString(),
      }).toString();

      // Construct the full URL
      let url = `${baseUrl}?${queryString}`;
      window.location.href = url;
    },
  },
};
</script>
