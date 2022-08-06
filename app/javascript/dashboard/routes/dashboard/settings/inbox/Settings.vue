<template>
  <div class="settings columns container">
    <setting-intro-banner
      :header-image="inbox.avatarUrl"
      :header-title="inboxName"
    >
      <woot-tabs
        :index="selectedTabIndex"
        :border="false"
        @change="onTabChange"
      >
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
          class="settings-item"
          delete-avatar
          @change="handleImageUpload"
          @onAvatarDelete="handleAvatarDelete"
        />
        <woot-input
          v-model.trim="selectedInboxName"
          class="medium-9 columns settings-item"
          :class="{ error: $v.selectedInboxName.$error }"
          :label="inboxNameLabel"
          :placeholder="inboxNamePlaceHolder"
          :error="
            $v.selectedInboxName.$error
              ? $t('INBOX_MGMT.ADD.CHANNEL_NAME.ERROR')
              : ''
          "
          @blur="$v.selectedInboxName.$touch"
        />
        <label
          v-if="isATwitterInbox"
          for="toggle-business-hours"
          class="toggle-input-wrap"
        >
          <input
            v-model="tweetsEnabled"
            type="checkbox"
            name="toggle-business-hours"
          />
          {{ $t('INBOX_MGMT.ADD.TWITTER.TWEETS.ENABLE') }}
        </label>
        <woot-input
          v-if="isAPIInbox"
          v-model.trim="webhookUrl"
          class="medium-9 columns settings-item"
          :class="{ error: $v.webhookUrl.$error }"
          :label="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.LABEL')
          "
          :placeholder="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.PLACEHOLDER')
          "
          :error="
            $v.webhookUrl.$error
              ? $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.ERROR')
              : ''
          "
          @blur="$v.webhookUrl.$touch"
        />
        <woot-input
          v-if="isAWebWidgetInbox"
          v-model.trim="channelWebsiteUrl"
          class="medium-9 columns settings-item"
          :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL')"
          :placeholder="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER')
          "
        />
        <woot-input
          v-if="isAWebWidgetInbox"
          v-model.trim="channelWelcomeTitle"
          class="medium-9 columns settings-item"
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
          class="medium-9 columns settings-item"
          :label="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.LABEL')
          "
          :placeholder="
            $t(
              'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.PLACEHOLDER'
            )
          "
        />

        <label v-if="isAWebWidgetInbox" class="medium-9 columns settings-item">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL') }}
          <woot-color-picker v-model="inbox.widget_color" />
        </label>

        <label class="medium-9 columns settings-item">
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
        <div v-if="greetingEnabled" class="settings-item">
          <greetings-editor
            v-model.trim="greetingMessage"
            :label="
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.LABEL'
              )
            "
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.PLACEHOLDER'
              )
            "
            :richtext="!textAreaChannels"
          />
        </div>
        <label v-if="isAWebWidgetInbox" class="medium-9 columns settings-item">
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

        <label v-if="isAWebWidgetInbox" class="medium-9 columns settings-item">
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

        <label class="medium-9 columns settings-item">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_CSAT') }}
          <select v-model="csatSurveyEnabled">
            <option :value="true">
              {{ $t('INBOX_MGMT.EDIT.ENABLE_CSAT.ENABLED') }}
            </option>
            <option :value="false">
              {{ $t('INBOX_MGMT.EDIT.ENABLE_CSAT.DISABLED') }}
            </option>
          </select>
          <p class="help-text">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_CSAT_SUB_TEXT') }}
          </p>
        </label>

        <label v-if="isAWebWidgetInbox" class="medium-9 columns settings-item">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.ALLOW_MESSAGES_AFTER_RESOLVED') }}
          <select v-model="allowMessagesAfterResolved">
            <option :value="true">
              {{ $t('INBOX_MGMT.EDIT.ALLOW_MESSAGES_AFTER_RESOLVED.ENABLED') }}
            </option>
            <option :value="false">
              {{ $t('INBOX_MGMT.EDIT.ALLOW_MESSAGES_AFTER_RESOLVED.DISABLED') }}
            </option>
          </select>
          <p class="help-text">
            {{
              $t(
                'INBOX_MGMT.SETTINGS_POPUP.ALLOW_MESSAGES_AFTER_RESOLVED_SUB_TEXT'
              )
            }}
          </p>
        </label>

        <label v-if="isAWebWidgetInbox" class="medium-9 columns settings-item">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_CONTINUITY_VIA_EMAIL') }}
          <select v-model="continuityViaEmail">
            <option :value="true">
              {{ $t('INBOX_MGMT.EDIT.ENABLE_CONTINUITY_VIA_EMAIL.ENABLED') }}
            </option>
            <option :value="false">
              {{ $t('INBOX_MGMT.EDIT.ENABLE_CONTINUITY_VIA_EMAIL.DISABLED') }}
            </option>
          </select>
          <p class="help-text">
            {{
              $t(
                'INBOX_MGMT.SETTINGS_POPUP.ENABLE_CONTINUITY_VIA_EMAIL_SUB_TEXT'
              )
            }}
          </p>
        </label>

        <label v-if="isAWebWidgetInbox">
          {{ $t('INBOX_MGMT.FEATURES.LABEL') }}
        </label>
        <div
          v-if="isAWebWidgetInbox"
          class="widget--feature-flag settings-item"
        >
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
        <div v-if="isAWebWidgetInbox" class="settings-item settings-item">
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
        <div v-if="isAWebWidgetInbox" class="settings-item settings-item">
          <input
            v-model="selectedFeatureFlags"
            type="checkbox"
            value="end_conversation"
            @input="handleFeatureFlag"
          />
          <label for="end_conversation">
            {{ $t('INBOX_MGMT.FEATURES.ALLOW_END_CONVERSATION') }}
          </label>
        </div>

        <woot-submit-button
          v-if="isAPIInbox"
          type="submit"
          :disabled="$v.webhookUrl.$invalid"
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :loading="uiFlags.isUpdating"
          @click="updateInbox"
        />
        <woot-submit-button
          v-else
          type="submit"
          :disabled="$v.$invalid"
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :loading="uiFlags.isUpdating"
          @click="updateInbox"
        />
      </settings-section>
      <facebook-reauthorize v-if="isAFacebookInbox" :inbox-id="inbox.id" />
    </div>

    <div v-if="selectedTabKey === 'collaborators'" class="settings--content">
      <collaborators-page :inbox="inbox" />
    </div>
    <div v-if="selectedTabKey === 'configuration'">
      <configuration-page :inbox="inbox" />
    </div>
    <div v-if="selectedTabKey === 'preChatForm'">
      <pre-chat-form-settings :inbox="inbox" />
    </div>
    <div v-if="selectedTabKey === 'businesshours'">
      <weekly-availability :inbox="inbox" />
    </div>
    <div v-if="selectedTabKey === 'widgetBuilder'">
      <widget-builder :inbox="inbox" />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { shouldBeUrl } from 'shared/helpers/Validators';
import configMixin from 'shared/mixins/configMixin';
import alertMixin from 'shared/mixins/alertMixin';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner';
import SettingsSection from '../../../../components/SettingsSection';
import inboxMixin from 'shared/mixins/inboxMixin';
import FacebookReauthorize from './facebook/Reauthorize';
import PreChatFormSettings from './PreChatForm/Settings';
import WeeklyAvailability from './components/WeeklyAvailability';
import GreetingsEditor from 'shared/components/GreetingsEditor';
import ConfigurationPage from './settingsPage/ConfigurationPage';
import CollaboratorsPage from './settingsPage/CollaboratorsPage';
import WidgetBuilder from './WidgetBuilder';

export default {
  components: {
    SettingIntroBanner,
    SettingsSection,
    FacebookReauthorize,
    PreChatFormSettings,
    WeeklyAvailability,
    GreetingsEditor,
    ConfigurationPage,
    CollaboratorsPage,
    WidgetBuilder,
  },
  mixins: [alertMixin, configMixin, inboxMixin],
  data() {
    return {
      avatarFile: null,
      avatarUrl: '',
      greetingEnabled: true,
      tweetsEnabled: true,
      greetingMessage: '',
      emailCollectEnabled: false,
      csatSurveyEnabled: false,
      allowMessagesAfterResolved: true,
      continuityViaEmail: true,
      selectedInboxName: '',
      channelWebsiteUrl: '',
      webhookUrl: '',
      channelWelcomeTitle: '',
      channelWelcomeTagline: '',
      selectedFeatureFlags: [],
      replyTime: '',
      selectedTabIndex: 0,
    };
  },
  computed: {
    ...mapGetters({
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
        {
          key: 'businesshours',
          name: this.$t('INBOX_MGMT.TABS.BUSINESS_HOURS'),
        },
      ];

      if (this.isAWebWidgetInbox) {
        return [
          ...visibleToAllChannelTabs,
          {
            key: 'preChatForm',
            name: this.$t('INBOX_MGMT.TABS.PRE_CHAT_FORM'),
          },
          {
            key: 'configuration',
            name: this.$t('INBOX_MGMT.TABS.CONFIGURATION'),
          },
          {
            key: 'widgetBuilder',
            name: this.$t('INBOX_MGMT.TABS.WIDGET_BUILDER'),
          },
        ];
      }

      if (
        this.isATwilioChannel ||
        this.isALineChannel ||
        this.isAPIInbox ||
        this.isAnEmailChannel ||
        this.isAWhatsappChannel
      ) {
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
        return `${this.inbox.name} (${this.inbox.messaging_service_sid ||
          this.inbox.phone_number})`;
      }
      if (this.isAWhatsappChannel) {
        return `${this.inbox.name} (${this.inbox.phone_number})`;
      }
      if (this.isAnEmailChannel) {
        return `${this.inbox.name} (${this.inbox.email})`;
      }
      return this.inbox.name;
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
    textAreaChannels() {
      if (
        this.isATwilioChannel ||
        this.isATwitterInbox ||
        this.isAFacebookInbox
      )
        return true;
      return false;
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
      this.$store.dispatch('labels/get');
      this.$store.dispatch('inboxes/get').then(() => {
        this.avatarUrl = this.inbox.avatar_url;
        this.selectedInboxName = this.inbox.name;
        this.webhookUrl = this.inbox.webhook_url;
        this.greetingEnabled = this.inbox.greeting_enabled || false;
        this.tweetsEnabled = this.inbox.tweets_enabled || false;
        this.greetingMessage = this.inbox.greeting_message || '';
        this.emailCollectEnabled = this.inbox.enable_email_collect;
        this.csatSurveyEnabled = this.inbox.csat_survey_enabled;
        this.allowMessagesAfterResolved = this.inbox.allow_messages_after_resolved;
        this.continuityViaEmail = this.inbox.continuity_via_email;
        this.channelWebsiteUrl = this.inbox.website_url;
        this.channelWelcomeTitle = this.inbox.welcome_title;
        this.channelWelcomeTagline = this.inbox.welcome_tagline;
        this.selectedFeatureFlags = this.inbox.selected_feature_flags || [];
        this.replyTime = this.inbox.reply_time;
      });
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.currentInboxId,
          name: this.selectedInboxName,
          enable_email_collect: this.emailCollectEnabled,
          csat_survey_enabled: this.csatSurveyEnabled,
          allow_messages_after_resolved: this.allowMessagesAfterResolved,
          greeting_enabled: this.greetingEnabled,
          greeting_message: this.greetingMessage || '',
          channel: {
            widget_color: this.inbox.widget_color,
            website_url: this.channelWebsiteUrl,
            webhook_url: this.webhookUrl,
            welcome_title: this.channelWelcomeTitle || '',
            welcome_tagline: this.channelWelcomeTagline || '',
            selectedFeatureFlags: this.selectedFeatureFlags,
            reply_time: this.replyTime || 'in_a_few_minutes',
            tweets_enabled: this.tweetsEnabled,
            continuity_via_email: this.continuityViaEmail,
          },
        };
        if (this.avatarFile) {
          payload.avatar = this.avatarFile;
        }
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(
          error.message || this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
        );
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    async handleAvatarDelete() {
      try {
        await this.$store.dispatch(
          'inboxes/deleteInboxAvatar',
          this.currentInboxId
        );
        this.avatarFile = null;
        this.avatarUrl = '';
        this.showAlert(this.$t('INBOX_MGMT.DELETE.API.AVATAR_SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(
          error.message
            ? error.message
            : this.$t('INBOX_MGMT.DELETE.API.AVATAR_ERROR_MESSAGE')
        );
      }
    },
  },
  validations: {
    webhookUrl: {
      shouldBeUrl,
    },
    selectedInboxName: {},
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

.settings-item {
  padding-bottom: var(--space-normal);

  .help-text {
    font-style: normal;
    color: var(--b-500);
    padding-bottom: var(--space-smaller);
  }
}
</style>
