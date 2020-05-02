<template>
  <div class="settings columns container">
    <woot-modal-header
      :header-image="inbox.avatarUrl"
      :header-title="inboxName"
    />

    <div class="settings--content">
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_UPDATE_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_UPDATE_SUB_TEXT')"
      >
        <div v-if="inbox.channel_type === 'Channel::WebWidget'">
          <div class="medium-12 columns">
            <label>
              {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_NAME.LABEL') }}
              <input
                v-model.trim="inboxName"
                type="text"
                :placeholder="
                  $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
                "
              />
            </label>
          </div>
          <div class="medium-12 columns">
            <label>
              {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL') }}
              <input
                v-model.trim="channelWebsiteUrl"
                type="text"
                :placeholder="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER'
                  )
                "
              />
            </label>
          </div>
          <div class="medium-12 columns">
            <label>
              {{
                $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.LABEL')
              }}
              <input
                v-model.trim="channelWelcomeTitle"
                type="text"
                :placeholder="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.PLACEHOLDER'
                  )
                "
              />
            </label>
          </div>
          <div class="medium-12 columns">
            <label>
              {{
                $t(
                  'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.LABEL'
                )
              }}
              <input
                v-model.trim="channelWelcomeTagline"
                type="text"
                :placeholder="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.PLACEHOLDER'
                  )
                "
              />
            </label>
          </div>
          <div class="medium-12 columns">
            <label>
              {{
                $t(
                  'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_AGENT_AWAY_MESSAGE.LABEL'
                )
              }}
              <input
                v-model.trim="channelAgentAwayMessage"
                type="text"
                :placeholder="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_AGENT_AWAY_MESSAGE.PLACEHOLDER'
                  )
                "
              />
            </label>
          </div>

          <div class="medium-12 columns">
            <label>
              {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL') }}
              <compact
                v-model="inbox.widget_color"
                class="widget-color--selector"
              />
            </label>
          </div>
        </div>
        <div>
          <label>
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT') }}
            <select v-model="autoAssignment">
              <option value="true">
                {{ $t('INBOX_MGMT.EDIT.AUTO_ASSIGNMENT.ENABLED') }}
              </option>
              <option value="false">
                {{ $t('INBOX_MGMT.EDIT.AUTO_ASSIGNMENT.DISABLED') }}
              </option>
            </select>
            <p class="help-text">
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT') }}
            </p>
          </label>
        </div>

        <woot-submit-button
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :loading="uiFlags.isUpdatingInbox"
          @click="updateInbox"
        >
        </woot-submit-button>
      </settings-section>
    </div>

    <!-- update agents in inbox -->

    <div class="settings--content">
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
      >
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

        <woot-submit-button
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :loading="isAgentListUpdating"
          @click="updateAgents"
        >
        </woot-submit-button>
      </settings-section>
    </div>

    <div
      v-if="inbox.channel_type === 'Channel::TwilioSms'"
      class="settings--content"
    >
      <settings-section
        :title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.TITLE')"
        :sub-title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE')"
      >
        <woot-code :script="twilioCallbackURL" lang="html"></woot-code>
      </settings-section>
    </div>

    <div
      v-if="inbox.channel_type === 'Channel::FacebookPage'"
      class="settings--content"
    >
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
      >
        <woot-code :script="messengerScript"></woot-code>
      </settings-section>
    </div>
    <div v-else-if="inbox.channel_type === 'Channel::WebWidget'">
      <div class="settings--content">
        <settings-section
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
        >
          <woot-code :script="inbox.web_widget_script"></woot-code>
        </settings-section>
      </div>
    </div>
  </div>
</template>

<script>
/* eslint no-console: 0 */
/* global bus */
import { mapGetters } from 'vuex';
import { createMessengerScript } from 'dashboard/helper/scriptGenerator';
import { Compact } from 'vue-color';
import configMixin from 'shared/mixins/configMixin';
import SettingsSection from '../../../../components/SettingsSection';

export default {
  components: {
    Compact,
    SettingsSection,
  },
  mixins: [configMixin],
  data() {
    return {
      selectedAgents: [],
      autoAssignment: false,
      isUpdating: false,
      isAgentListUpdating: false,
      channelWebsiteUrl: '',
      channelWelcomeTitle: '',
      channelWelcomeTagline: '',
      channelAgentAwayMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
      uiFlags: 'inboxes/getUIFlags',
    }),
    currentInboxId() {
      return this.$route.params.inboxId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentInboxId);
    },
    inboxName() {
      if (this.inbox.channel_type === 'Channel::TwilioSms') {
        return `${this.inbox.name} (${this.inbox.phone_number})`;
      }
      return this.inbox.name;
    },
    messengerScript() {
      return createMessengerScript(this.inbox.page_id);
    },
  },
  watch: {
    $route(to) {
      if (to.name === 'settings_inbox_show') {
        this.fetchInboxSettings();
      }
    },
  },
  mounted() {
    this.fetchInboxSettings();
  },
  methods: {
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
    fetchInboxSettings() {
      this.selectedAgents = [];
      this.$store.dispatch('agents/get');
      this.$store.dispatch('inboxes/get').then(() => {
        this.fetchAttachedAgents();
        this.autoAssignment = this.inbox.enable_auto_assignment;
        this.channelWebsiteUrl = this.inbox.website_url;
        this.channelWelcomeTitle = this.inbox.welcome_title;
        this.channelWelcomeTagline = this.inbox.welcome_tagline;
        this.channelAgentAwayMessage = this.inbox.agent_away_message;
      });
    },
    async fetchAttachedAgents() {
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.currentInboxId,
        });
        const {
          data: { payload },
        } = response;
        payload.forEach(el => {
          const [item] = this.agentList.filter(
            agent => agent.id === el.user_id
          );
          if (item) {
            this.selectedAgents.push(item);
          }
        });
      } catch (error) {
        console.log(error);
      }
    },
    async updateAgents() {
      const agentList = this.selectedAgents.map(el => el.id);
      this.isAgentListUpdating = true;
      try {
        await this.$store.dispatch('inboxMembers/create', {
          inboxId: this.currentInboxId,
          agentList,
        });
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
      this.isAgentListUpdating = false;
    },
    async updateInbox() {
      try {
        await this.$store.dispatch('inboxes/updateInbox', {
          id: this.currentInboxId,
          name: this.inboxName,
          enable_auto_assignment: this.autoAssignment,
          channel: {
            widget_color: this.getWidgetColor(this.inbox.widget_color),
            website_url: this.channelWebsiteUrl,
            welcome_title: this.channelWelcomeTitle,
            welcome_tagline: this.channelWelcomeTagline,
            agent_away_message: this.channelAgentAwayMessage,
          },
        });
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
    getWidgetColor() {
      return typeof this.inbox.widget_color !== 'object'
        ? this.inbox.widget_color
        : this.inbox.widget_color.hex;
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

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.settings {
  background: $color-white;

  .settings--content {
    &:last-child {
      .settings--section {
        border-bottom: 0;
      }
    }
  }

  .page-top-bar {
    @include background-light;
    @include border-normal-bottom;
    padding: $space-normal $space-larger;
  }
}
</style>
