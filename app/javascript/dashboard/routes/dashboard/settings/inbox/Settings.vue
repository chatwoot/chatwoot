<template>
  <woot-modal class-name="settings-modal" :show.sync="show" :on-close="onClose">
    <div class="settings">
      <woot-modal-header
        :header-image="inbox.avatarUrl"
        :header-title="inbox.label"
      />
      <div
        v-if="inbox.channelType === 'Channel::FacebookPage'"
        class="code-wrapper"
      >
        <p class="title">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING') }}
        </p>
        <p class="sub-head">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD') }}
        </p>
        <p class="code">
          <code>
            {{ messengerScript }}
          </code>
        </p>
      </div>
      <div
        v-else-if="inbox.channelType === 'Channel::WebWidget'"
        class="code-wrapper"
      >
        <p class="title">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING') }}
        </p>
        <p class="sub-head">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD') }}
        </p>
        <highlight-code lang="javascript">
          {{ webWidgetScript }}
        </highlight-code>
      </div>
      <div class="agent-wrapper">
        <p class="title">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS') }}
        </p>
        <p class="sub-head">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT') }}
        </p>
        <multiselect
          v-model="selectedAgents"
          :options="agentList"
          track-by="id"
          label="name"
          :multiple="true"
          :close-on-select="false"
          :clear-on-select="false"
          :hide-selected="true"
          placeholder="Pick some"
          @select="$v.selectedAgents.$touch"
        />
        <div @click="updateAgents()">
          <woot-submit-button
            :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
            :loading="isUpdating"
          />
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<script>
/* eslint no-console: 0 */
/* eslint-disable no-useless-escape */
/* global bus */
import { mapGetters } from 'vuex';
import 'highlight.js/styles/default.css';

export default {
  props: ['onClose', 'inbox', 'show'],
  data() {
    return {
      selectedAgents: [],
      isUpdating: false,
      messengerScript: `<script>
        window.fbAsyncInit = function() {
          FB.init({
            appId: "${window.chatwootConfig.fbAppId}",
            xfbml: true,
            version: "v4.0"
          });
        };
        (function(d, s, id){
           var js, fjs = d.getElementsByTagName(s)[0];
           if (d.getElementById(id)) { return; }
           js = d.createElement(s); js.id = id;
           js.src = "//connect.facebook.net/en_US/sdk.js";
           fjs.parentNode.insertBefore(js, fjs);
        }(document, 'script', 'facebook-jssdk'));

      <\/script>
      <div class="fb-messengermessageus"
        messenger_app_id="${window.chatwootConfig.fbAppId}"
        page_id="${this.inbox.pageId}"
        color="blue"
        size="standard" >
      </div>`,
      webWidgetScript: `
        (function(d,t) {
          var BASE_URL = '${window.location.origin}';
          var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
          g.src= BASE_URL + "/packs/js/sdk.js";
          s.parentNode.insertBefore(g,s);
          g.onload=function(){
            window.chatwootSDK.run({
              websiteToken: '${this.inbox.websiteToken}',
              baseUrl: BASE_URL
            })
          }
        })(document,"script");
      `,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'getAgents',
    }),
  },
  mounted() {
    this.$store.dispatch('fetchAgents').then(() => {
      this.fetchAttachedAgents();
    });
  },
  methods: {
    fetchAttachedAgents() {
      this.$store
        .dispatch('listInboxAgents', {
          inboxId: this.inbox.channel_id,
        })
        .then(response => {
          const { payload } = response.data;
          payload.forEach(el => {
            const [item] = this.agentList.filter(
              agent => agent.id === el.user_id
            );
            if (item) this.selectedAgents.push(item);
          });
        })
        .catch(error => {
          console.log(error);
        });
    },
    updateAgents() {
      const agentList = this.selectedAgents.map(el => el.id);
      this.isUpdating = true;
      this.$store
        .dispatch('updateInboxAgents', {
          inboxId: this.inbox.channel_id,
          agentList,
        })
        .then(() => {
          this.isUpdating = false;
          bus.$emit(
            'newToastMessage',
            this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE')
          );
        })
        .catch(() => {
          this.isUpdating = false;
          bus.$emit(
            'newToastMessage',
            this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE')
          );
        });
    },
  },
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
  },
};
</script>
