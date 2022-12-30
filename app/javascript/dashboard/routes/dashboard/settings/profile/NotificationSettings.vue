<template>
  <div>
    <div class="profile--settings--row row">
      <div class="columns small-3 ">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.TITLE') }}
        </h4>
        <p>
          {{ $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.NOTE') }}
        </p>
      </div>
      <div class="columns small-9">
        <div class="notification-items--wrapper">
          <span class="text-block-title notification-label">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.TITLE'
              )
            }}
          </span>
          <div>
            <input
              id="audio_enable_alert_none"
              v-model="enableAudioAlerts"
              class="notification--checkbox"
              type="radio"
              value="none"
              @input="handleAudioInput"
            />
            <label for="audio_enable_alert_none">
              {{
                $t(
                  'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.NONE'
                )
              }}
            </label>
          </div>
          <div>
            <input
              id="audio_enable_alert_mine"
              v-model="enableAudioAlerts"
              class="notification--checkbox"
              type="radio"
              value="mine"
              @input="handleAudioInput"
            />
            <label for="audio_enable_alert_mine">
              {{
                $t(
                  'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.ASSIGNED'
                )
              }}
            </label>
          </div>
          <div>
            <input
              id="audio_enable_alert_all"
              v-model="enableAudioAlerts"
              class="notification--checkbox"
              type="radio"
              value="all"
              @input="handleAudioInput"
            />
            <label for="audio_enable_alert_all">
              {{
                $t(
                  'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.ALL_CONVERSATIONS'
                )
              }}
            </label>
          </div>
        </div>
        <div class="notification-items--wrapper">
          <span class="text-block-title notification-label">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.DEFAULT_TONE.TITLE'
              )
            }}
          </span>
          <div>
            <select
              v-model="notificationTone"
              class="tone-selector"
              @change="handleAudioToneChange"
            >
              <option
                v-for="tone in notificationAlertTones"
                :key="tone.value"
                :value="tone.value"
              >
                {{ tone.label }}
              </option>
            </select>
          </div>
        </div>
        <div class="notification-items--wrapper">
          <span class="text-block-title notification-label">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.TITLE'
              )
            }}
          </span>
          <div>
            <input
              id="audio_alert_when_tab_is_inactive"
              v-model="playAudioWhenTabIsInactive"
              class="notification--checkbox"
              type="checkbox"
              value="tab_is_inactive"
              @input="handleAudioAlertConditions"
            />
            <label for="audio_alert_when_tab_is_inactive">
              {{
                $t(
                  'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.CONDITION_ONE'
                )
              }}
            </label>
          </div>
          <div>
            <input
              id="audio_alert_until_all_conversations_are_read"
              v-model="alertIfUnreadConversationExist"
              class="notification--checkbox"
              type="checkbox"
              value="conversations_are_read"
              @input="handleAudioAlertConditions"
            />
            <label for="audio_alert_until_all_conversations_are_read">
              {{
                $t(
                  'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.CONDITION_TWO'
                )
              }}
            </label>
          </div>
        </div>
      </div>
    </div>
    <div class="profile--settings--row row">
      <div class="columns small-3 ">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.TITLE') }}
        </h4>
        <p>
          {{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.NOTE') }}
        </p>
      </div>
      <div class="columns small-9">
        <div>
          <input
            v-model="selectedEmailFlags"
            class="notification--checkbox"
            type="checkbox"
            value="email_conversation_creation"
            @input="handleEmailInput"
          />
          <label for="conversation_creation">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.CONVERSATION_CREATION'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedEmailFlags"
            class="notification--checkbox"
            type="checkbox"
            value="email_conversation_assignment"
            @input="handleEmailInput"
          />
          <label for="conversation_assignment">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.CONVERSATION_ASSIGNMENT'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedEmailFlags"
            class="notification--checkbox"
            type="checkbox"
            value="email_conversation_mention"
            @input="handleEmailInput"
          />
          <label for="conversation_mention">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.CONVERSATION_MENTION'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedEmailFlags"
            class="notification--checkbox"
            type="checkbox"
            value="email_assigned_conversation_new_message"
            @input="handleEmailInput"
          />
          <label for="assigned_conversation_new_message">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.ASSIGNED_CONVERSATION_NEW_MESSAGE'
              )
            }}
          </label>
        </div>
      </div>
    </div>
    <div
      v-if="vapidPublicKey && !isBrowserSafari"
      class="profile--settings--row row push-row"
    >
      <div class="columns small-3 ">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.TITLE') }}
        </h4>
        <p>{{ $t('PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.NOTE') }}</p>
      </div>
      <div class="columns small-9">
        <p v-if="hasEnabledPushPermissions">
          {{
            $t(
              'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.HAS_ENABLED_PUSH'
            )
          }}
        </p>
        <div v-else class="push-notification--button">
          <woot-submit-button
            :button-text="
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.REQUEST_PUSH'
              )
            "
            class="button nice small"
            type="button"
            @click="onRequestPermissions"
          />
        </div>
        <div>
          <input
            v-model="selectedPushFlags"
            class="notification--checkbox"
            type="checkbox"
            value="push_conversation_creation"
            @input="handlePushInput"
          />
          <label for="conversation_creation">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.CONVERSATION_CREATION'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedPushFlags"
            class="notification--checkbox"
            type="checkbox"
            value="push_conversation_assignment"
            @input="handlePushInput"
          />
          <label for="conversation_assignment">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.CONVERSATION_ASSIGNMENT'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedPushFlags"
            class="notification--checkbox"
            type="checkbox"
            value="push_conversation_mention"
            @input="handlePushInput"
          />
          <label for="conversation_mention">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.CONVERSATION_MENTION'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedPushFlags"
            class="notification--checkbox"
            type="checkbox"
            value="push_assigned_conversation_new_message"
            @input="handlePushInput"
          />
          <label for="assigned_conversation_new_message">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.ASSIGNED_CONVERSATION_NEW_MESSAGE'
              )
            }}
          </label>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import {
  hasPushPermissions,
  requestPushPermissions,
  verifyServiceWorkerExistence,
} from '../../../../helper/pushHelper';

export default {
  mixins: [alertMixin, configMixin, uiSettingsMixin],
  data() {
    return {
      selectedEmailFlags: [],
      selectedPushFlags: [],
      enableAudioAlerts: false,
      hasEnabledPushPermissions: false,
      playAudioWhenTabIsInactive: false,
      alertIfUnreadConversationExist: false,
      notificationTone: 'ding',
      notificationAlertTones: [
        {
          value: 'ding',
          label: 'Ding',
        },
        {
          value: 'bell',
          label: 'Bell',
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      emailFlags: 'userNotificationSettings/getSelectedEmailFlags',
      pushFlags: 'userNotificationSettings/getSelectedPushFlags',
      uiSettings: 'getUISettings',
    }),
    isBrowserSafari() {
      if (window.browserConfig) {
        return window.browserConfig.is_safari === 'true';
      }
      return false;
    },
  },
  watch: {
    emailFlags(value) {
      this.selectedEmailFlags = value;
    },
    pushFlags(value) {
      this.selectedPushFlags = value;
    },
    uiSettings(value) {
      this.notificationUISettings(value);
    },
  },
  mounted() {
    if (hasPushPermissions()) {
      this.getPushSubscription();
    }
    this.notificationUISettings(this.uiSettings);
    this.$store.dispatch('userNotificationSettings/get');
  },
  methods: {
    notificationUISettings(uiSettings) {
      const {
        enable_audio_alerts: enableAudio = false,
        always_play_audio_alert: alwaysPlayAudioAlert,
        alert_if_unread_assigned_conversation_exist: alertIfUnreadConversationExist,
        notification_tone: notificationTone,
      } = uiSettings;
      this.enableAudioAlerts = enableAudio;
      this.playAudioWhenTabIsInactive = !alwaysPlayAudioAlert;
      this.alertIfUnreadConversationExist = alertIfUnreadConversationExist;
      this.notificationTone = notificationTone || 'ding';
    },
    onRegistrationSuccess() {
      this.hasEnabledPushPermissions = true;
    },
    onRequestPermissions() {
      requestPushPermissions({
        onSuccess: this.onRegistrationSuccess,
      });
    },
    getPushSubscription() {
      verifyServiceWorkerExistence(registration =>
        registration.pushManager
          .getSubscription()
          .then(subscription => {
            if (!subscription) {
              this.hasEnabledPushPermissions = false;
            } else {
              this.hasEnabledPushPermissions = true;
            }
          })
          // eslint-disable-next-line no-console
          .catch(error => console.log(error))
      );
    },
    async updateNotificationSettings() {
      try {
        this.$store.dispatch('userNotificationSettings/update', {
          selectedEmailFlags: this.selectedEmailFlags,
          selectedPushFlags: this.selectedPushFlags,
        });
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
      } catch (error) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_ERROR'));
      }
    },
    handleEmailInput(e) {
      this.selectedEmailFlags = this.toggleInput(
        this.selectedEmailFlags,
        e.target.value
      );

      this.updateNotificationSettings();
    },
    handlePushInput(e) {
      this.selectedPushFlags = this.toggleInput(
        this.selectedPushFlags,
        e.target.value
      );

      this.updateNotificationSettings();
    },
    handleAudioInput(e) {
      this.enableAudioAlerts = e.target.value;
      this.updateUISettings({
        enable_audio_alerts: this.enableAudioAlerts,
      });
      this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
    handleAudioAlertConditions(e) {
      let condition = e.target.value;
      if (condition === 'tab_is_inactive') {
        this.updateUISettings({
          always_play_audio_alert: !e.target.checked,
        });
      } else if (condition === 'conversations_are_read') {
        this.updateUISettings({
          alert_if_unread_assigned_conversation_exist: e.target.checked,
        });
      }
      this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
    handleAudioToneChange(e) {
      this.updateUISettings({ notification_tone: e.target.value });
      this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
    toggleInput(selected, current) {
      if (selected.includes(current)) {
        const newSelectedFlags = selected.filter(flag => flag !== current);
        return newSelectedFlags;
      }
      return [...selected, current];
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables.scss';

.notification--checkbox {
  font-size: $font-size-large;
}

.push-notification--button {
  margin-bottom: var(--space-one);
}

.notification-items--wrapper {
  margin-bottom: var(--space-smaller);
}

.notification-label {
  display: flex;
  font-weight: var(--font-weight-bold);
  margin-bottom: var(--space-small);
}

.tone-selector {
  height: var(--space-large);
  padding-bottom: var(--space-micro);
  padding-top: var(--space-micro);
  width: var(--space-mega);
}
</style>
