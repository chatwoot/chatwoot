<template>
  <woot-modal class-name="settings-modal" :show.sync="show" :on-close="onClose">
    <div class="settings">
      <woot-modal-header
        :header-image="inbox.avatarUrl"
        :header-title="inbox.label"
      />
      <div v-if="inbox.channelType === 'FacebookPage'" class="code-wrapper">
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
/* global bus, __FB_ID__ */
/* eslint no-console: 0 */
/* eslint-disable no-useless-escape */
import { mapGetters } from 'vuex';

export default {
  components: {},
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    inbox: {
      type: Object,
      default: () => {},
    },
    show: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      selectedAgents: [],
      isUpdating: false,
      messengerScript: `<script>

        window.fbAsyncInit = function() {
          FB.init({
            appId: "${__FB_ID__}",
            xfbml: true,
            version: "v2.6"
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
        messenger_app_id="${__FB_ID__}"
        page_id="${this.inbox.pageId}"
        color="blue"
        size="standard" >
      </div>`,
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
