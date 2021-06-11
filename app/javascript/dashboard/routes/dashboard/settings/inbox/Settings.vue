<template>
  <div class="settings columns container">
    <setting-intro-banner
      :header-image="inbox.avatarUrl"
      :header-title="inboxName"
    >
      <woot-tabs :index="selectedTabIndex" @change="onTabChange">
        <woot-tabs-item
          v-for="tab in tabs"
          :key="tab.key"
          :name="tab.name"
          :show-badge="false"
        />
      </woot-tabs>
    </setting-intro-banner>

    <div v-if="selectedTabKey === 'inbox_settings'" class="settings--content">
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_UPDATE_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_UPDATE_SUB_TEXT')"
      >
        <woot-avatar-uploader
          :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_AVATAR.LABEL')"
          :src="avatarUrl"
          @change="handleImageUpload"
        />
        <woot-input
          v-model.trim="selectedInboxName"
          class="medium-9 columns"
          :label="inboxNameLabel"
          :placeholder="inboxNamePlaceHolder"
        />
        <woot-input
          v-if="isAWebWidgetInbox"
          v-model.trim="channelWebsiteUrl"
          class="medium-9 columns"
          :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL')"
          :placeholder="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER')
          "
        />
        <woot-input
          v-if="isAWebWidgetInbox"
          v-model.trim="channelWelcomeTitle"
          class="medium-9 columns"
          :label="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.LABEL')
          "
          :placeholder="
            $t(
              'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.PLACEHOLDER'
            )
          "
        />

        <woot-input
          v-if="isAWebWidgetInbox"
          v-model.trim="channelWelcomeTagline"
          class="medium-9 columns"
          :label="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.LABEL')
          "
          :placeholder="
            $t(
              'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.PLACEHOLDER'
            )
          "
        />

        <label v-if="isAWebWidgetInbox" class="medium-9 columns">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL') }}
          <woot-color-picker v-model="inbox.widget_color" />
        </label>

        <label class="medium-9 columns">
          {{
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.LABEL')
          }}
          <select v-model="greetingEnabled">
            <option :value="true">
              {{
                $t(
                  'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.ENABLED'
                )
              }}
            </option>
            <option :value="false">
              {{
                $t(
                  'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.DISABLED'
                )
              }}
            </option>
          </select>
          <p class="help-text">
            {{
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.HELP_TEXT'
              )
            }}
          </p>
        </label>

        <woot-input
          v-if="greetingEnabled"
          v-model.trim="greetingMessage"
          class="medium-9 columns"
          :label="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.LABEL')
          "
          :placeholder="
            $t(
              'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.PLACEHOLDER'
            )
          "
        />

        <label class="medium-9 columns">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.TITLE') }}
          <select v-model="replyTime">
            <option key="in_a_few_minutes" value="in_a_few_minutes">
              {{
                $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_MINUTES')
              }}
            </option>
            <option key="in_a_few_hours" value="in_a_few_hours">
              {{
                $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_HOURS')
              }}
            </option>
            <option key="in_a_day" value="in_a_day">
              {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_DAY') }}
            </option>
          </select>

          <p class="help-text">
            {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.HELP_TEXT') }}
          </p>
        </label>

        <label v-if="isAWebWidgetInbox" class="medium-9 columns">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_EMAIL_COLLECT_BOX') }}
          <select v-model="emailCollectEnabled">
            <option :value="true">
              {{ $t('INBOX_MGMT.EDIT.EMAIL_COLLECT_BOX.ENABLED') }}
            </option>
            <option :value="false">
              {{ $t('INBOX_MGMT.EDIT.EMAIL_COLLECT_BOX.DISABLED') }}
            </option>
          </select>
          <p class="help-text">
            {{
              $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_EMAIL_COLLECT_BOX_SUB_TEXT')
            }}
          </p>
        </label>

        <label class="medium-9 columns">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT') }}
          <select v-model="autoAssignment">
            <option :value="true">
              {{ $t('INBOX_MGMT.EDIT.AUTO_ASSIGNMENT.ENABLED') }}
            </option>
            <option :value="false">
              {{ $t('INBOX_MGMT.EDIT.AUTO_ASSIGNMENT.DISABLED') }}
            </option>
          </select>
          <p class="help-text">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT') }}
          </p>
        </label>

        <label v-if="isAWebWidgetInbox">
          {{ $t('INBOX_MGMT.FEATURES.LABEL') }}
        </label>
        <div v-if="isAWebWidgetInbox" class="widget--feature-flag">
          <input
            v-model="selectedFeatureFlags"
            type="checkbox"
            value="attachments"
            @input="handleFeatureFlag"
          />
          <label for="attachments">
            {{ $t('INBOX_MGMT.FEATURES.DISPLAY_FILE_PICKER') }}
          </label>
        </div>
        <div v-if="isAWebWidgetInbox">
          <input
            v-model="selectedFeatureFlags"
            type="checkbox"
            value="emoji_picker"
            @input="handleFeatureFlag"
          />
          <label for="emoji_picker">
            {{ $t('INBOX_MGMT.FEATURES.DISPLAY_EMOJI_PICKER') }}
          </label>
        </div>

        <woot-submit-button
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :loading="uiFlags.isUpdatingInbox"
          @click="updateInbox"
        />
      </settings-section>
      <facebook-reauthorize
        v-if="isAFacebookInbox && inbox.reauthorization_required"
        :inbox-id="inbox.id"
      />
    </div>

    <!-- update agents in inbox -->

    <div v-if="selectedTabKey === 'collaborators'" class="settings--content">
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
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
          @select="$v.selectedAgents.$touch"
        />

        <woot-submit-button
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :loading="isAgentListUpdating"
          @click="updateAgents"
        />
      </settings-section>
    </div>
    <div v-if="selectedTabKey === 'configuration'">
      <div v-if="isATwilioChannel" class="settings--content">
        <settings-section
          :title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.TITLE')"
          :sub-title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE')"
        >
          <woot-code :script="twilioCallbackURL" lang="html"></woot-code>
        </settings-section>
      </div>
      <div v-else-if="isAWebWidgetInbox">
        <div class="settings--content">
          <settings-section
            :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
            :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
          >
            <woot-code :script="inbox.web_widget_script"></woot-code>
          </settings-section>

          <settings-section
            :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
            :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION')"
          >
            <woot-code :script="inbox.hmac_token"></woot-code>
          </settings-section>
        </div>
      </div>
    </div>
    <div v-if="selectedTabKey === 'preChatForm'">
      <pre-chat-form-settings :inbox="inbox" />
    </div>
    <div v-if="selectedTabKey === 'businesshours'">
      <weekly-availability :inbox="inbox" />
    </div>
    <div v-if="selectedTabKey === 'campaign'">
      <campaign :selected-agents="selectedAgents" />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { createMessengerScript } from 'dashboard/helper/scriptGenerator';
import configMixin from 'shared/mixins/configMixin';
import alertMixin from 'shared/mixins/alertMixin';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner';
import SettingsSection from '../../../../components/SettingsSection';
import inboxMixin from 'shared/mixins/inboxMixin';
import FacebookReauthorize from './facebook/Reauthorize';
import PreChatFormSettings from './PreChatForm/Settings';
import WeeklyAvailability from './components/WeeklyAvailability';
import Campaign from './components/Campaign';

export default {
  components: {
    SettingIntroBanner,
    SettingsSection,
    FacebookReauthorize,
    PreChatFormSettings,
    WeeklyAvailability,
    Campaign,
  },
  mixins: [alertMixin, configMixin, inboxMixin],
  data() {
    return {
      avatarFile: null,
      avatarUrl: '',
      selectedAgents: [],
      greetingEnabled: true,
      greetingMessage: '',
      autoAssignment: false,
      emailCollectEnabled: false,
      isAgentListUpdating: false,
      selectedInboxName: '',
      channelWebsiteUrl: '',
      channelWelcomeTitle: '',
      channelWelcomeTagline: '',
      selectedFeatureFlags: [],
      replyTime: '',
      autoAssignmentOptions: [
        {
          value: true,
          label: this.$t('INBOX_MGMT.EDIT.AUTO_ASSIGNMENT.ENABLED'),
        },
        {
          value: false,
          label: this.$t('INBOX_MGMT.EDIT.AUTO_ASSIGNMENT.DISABLED'),
        },
      ],
      selectedTabIndex: 0,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
      uiFlags: 'inboxes/getUIFlags',
    }),
    selectedTabKey() {
      return this.tabs[this.selectedTabIndex]?.key;
    },
    tabs() {
      const visibleToAllChannelTabs = [
        {
          key: 'inbox_settings',
          name: this.$t('INBOX_MGMT.TABS.SETTINGS'),
        },
        {
          key: 'collaborators',
          name: this.$t('INBOX_MGMT.TABS.COLLABORATORS'),
        },
      ];

      if (this.isAWebWidgetInbox) {
        return [
          ...visibleToAllChannelTabs,
          {
            key: 'campaign',
            name: this.$t('INBOX_MGMT.TABS.CAMPAIGN'),
          },
          {
            key: 'preChatForm',
            name: this.$t('INBOX_MGMT.TABS.PRE_CHAT_FORM'),
          },
          {
            key: 'businesshours',
            name: this.$t('INBOX_MGMT.TABS.BUSINESS_HOURS'),
          },
          {
            key: 'configuration',
            name: this.$t('INBOX_MGMT.TABS.CONFIGURATION'),
          },
        ];
      }

      if (this.isATwilioChannel) {
        return [
          ...visibleToAllChannelTabs,
          {
            key: 'configuration',
            name: this.$t('INBOX_MGMT.TABS.CONFIGURATION'),
          },
        ];
      }

      return visibleToAllChannelTabs;
    },
    currentInboxId() {
      return this.$route.params.inboxId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentInboxId);
    },
    inboxName() {
      if (this.isATwilioSMSChannel || this.isATwilioWhatsappChannel) {
        return `${this.inbox.name} (${this.inbox.phone_number})`;
      }
      return this.inbox.name;
    },
    messengerScript() {
      return createMessengerScript(this.inbox.page_id);
    },
    inboxNameLabel() {
      if (this.isAWebWidgetInbox) {
        return this.$t('INBOX_MGMT.ADD.WEBSITE_NAME.LABEL');
      }
      return this.$t('INBOX_MGMT.ADD.CHANNEL_NAME.LABEL');
    },
    inboxNamePlaceHolder() {
      if (this.isAWebWidgetInbox) {
        return this.$t('INBOX_MGMT.ADD.WEBSITE_NAME.PLACEHOLDER');
      }
      return this.$t('INBOX_MGMT.ADD.CHANNEL_NAME.PLACEHOLDER');
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
    handleFeatureFlag(e) {
      this.selectedFeatureFlags = this.toggleInput(
        this.selectedFeatureFlags,
        e.target.value
      );
    },
    toggleInput(selected, current) {
      if (selected.includes(current)) {
        const newSelectedFlags = selected.filter(flag => flag !== current);
        return newSelectedFlags;
      }
      return [...selected, current];
    },
    onTabChange(selectedTabIndex) {
      this.selectedTabIndex = selectedTabIndex;
    },
    fetchInboxSettings() {
      this.selectedTabIndex = 0;
      this.selectedAgents = [];
      this.$store.dispatch('agents/get');
      this.$store.dispatch('teams/get');
      this.$store.dispatch('inboxes/get').then(() => {
        this.fetchAttachedAgents();
        this.avatarUrl = this.inbox.avatar_url;
        this.selectedInboxName = this.inbox.name;
        this.greetingEnabled = this.inbox.greeting_enabled;
        this.greetingMessage = this.inbox.greeting_message;
        this.autoAssignment = this.inbox.enable_auto_assignment;
        this.emailCollectEnabled = this.inbox.enable_email_collect;
        this.channelWebsiteUrl = this.inbox.website_url;
        this.channelWelcomeTitle = this.inbox.welcome_title;
        this.channelWelcomeTagline = this.inbox.welcome_tagline;
        this.selectedFeatureFlags = this.inbox.selected_feature_flags || [];
        this.replyTime = this.inbox.reply_time;
      });
    },
    async fetchAttachedAgents() {
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.currentInboxId,
        });
        const {
          data: { payload: inboxMembers },
        } = response;
        this.selectedAgents = inboxMembers;
      } catch (error) {
        //  Handle error
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
        const payload = {
          id: this.currentInboxId,
          name: this.selectedInboxName,
          enable_auto_assignment: this.autoAssignment,
          enable_email_collect: this.emailCollectEnabled,
          greeting_enabled: this.greetingEnabled,
          greeting_message: this.greetingMessage || '',
          channel: {
            widget_color: this.inbox.widget_color,
            website_url: this.channelWebsiteUrl,
            welcome_title: this.channelWelcomeTitle || '',
            welcome_tagline: this.channelWelcomeTagline || '',
            selectedFeatureFlags: this.selectedFeatureFlags,
            reply_time: this.replyTime || 'in_a_few_minutes',
          },
        };
        if (this.avatarFile) {
          payload.avatar = this.avatarFile;
        }
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
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
    div:last-child {
      border-bottom: 0;
    }
  }

  .tabs {
    padding: 0;
    margin-bottom: -1px;
  }
}

.widget--feature-flag {
  padding-top: var(--space-small);
}
</style>
