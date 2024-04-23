<template>
  <div id="profile-settings-notifications" class="flex flex-col gap-6">
    <div>
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <table-header-cell :span="6" label="Notification type">
          <span class="text-sm font-normal uppercase text-ash-900">
            {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPE_TITLE') }}
          </span>
        </table-header-cell>
        <table-header-cell :span="2" label="Email">
          <span class="text-sm font-medium uppercase text-ash-900">
            {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EMAIL') }}
          </span>
        </table-header-cell>
        <table-header-cell :span="4" label="Push notification">
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm font-medium uppercase text-ash-900">
              {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.PUSH') }}
            </span>
            <v3-switch :value="true" @input="onRequestPermissions()" />
          </div>
        </table-header-cell>
      </div>
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <div
          class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] rtl:text-right"
        >
          <span class="text-sm text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_CREATED'
              )
            }}
          </span>
        </div>
        <notification-check-box
          value="email_conversation_creation"
          :selected-flags="selectedEmailFlags"
          @input="handleEmailInput"
        />
        <notification-check-box
          :value="'push_conversation_creation'"
          :span="4"
          :selected-flags="selectedPushFlags"
          @input="handlePushInput"
        />
      </div>
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <div
          class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] rtl:text-right"
        >
          <span class="text-sm text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_ASSIGNED'
              )
            }}
          </span>
        </div>
        <notification-check-box
          :value="'email_conversation_assignment'"
          :selected-flags="selectedEmailFlags"
          @input="handleEmailInput"
        />
        <notification-check-box
          :value="'push_conversation_assignment'"
          :span="4"
          :selected-flags="selectedPushFlags"
          @input="handlePushInput"
        />
      </div>
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <div
          class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] rtl:text-right"
        >
          <span class="text-sm text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_MENTION'
              )
            }}
          </span>
        </div>
        <notification-check-box
          :value="'email_conversation_mention'"
          :selected-flags="selectedEmailFlags"
          @input="handleEmailInput"
        />
        <notification-check-box
          :value="'push_conversation_mention'"
          :span="4"
          :selected-flags="selectedPushFlags"
          @input="handlePushInput"
        />
      </div>
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <div
          class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] rtl:text-right"
        >
          <span class="text-sm text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.ASSIGNED_CONVERSATION_NEW_MESSAGE'
              )
            }}
          </span>
        </div>
        <notification-check-box
          :value="'email_assigned_conversation_new_message'"
          :selected-flags="selectedEmailFlags"
          @input="handleEmailInput"
        />
        <notification-check-box
          :value="'push_assigned_conversation_new_message'"
          :span="4"
          :selected-flags="selectedPushFlags"
          @input="handlePushInput"
        />
      </div>
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <div
          class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] rtl:text-right"
        >
          <span class="text-sm text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.PARTICIPATING_CONVERSATION_NEW_MESSAGE'
              )
            }}
          </span>
        </div>
        <notification-check-box
          :value="'email_participating_conversation_new_message'"
          :selected-flags="selectedEmailFlags"
          @input="handleEmailInput"
        />
        <notification-check-box
          :value="'push_participating_conversation_new_message'"
          :span="4"
          :selected-flags="selectedPushFlags"
          @input="handlePushInput"
        />
      </div>
      <div
        v-if="isSLAEnabled"
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <div
          class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] rtl:text-right"
        >
          <span class="text-sm text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_FIRST_RESPONSE'
              )
            }}
          </span>
        </div>
        <notification-check-box
          :value="'email_sla_missed_first_response'"
          :selected-flags="selectedEmailFlags"
          @input="handleEmailInput"
        />
        <notification-check-box
          :value="'push_sla_missed_first_response'"
          :span="4"
          :selected-flags="selectedPushFlags"
          @input="handlePushInput"
        />
      </div>
      <div
        v-if="isSLAEnabled"
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <div
          class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] rtl:text-right"
        >
          <span class="text-sm text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_NEXT_RESPONSE'
              )
            }}
          </span>
        </div>
        <notification-check-box
          :value="'email_sla_missed_next_response'"
          :selected-flags="selectedEmailFlags"
          @input="handleEmailInput"
        />
        <notification-check-box
          :value="'push_sla_missed_next_response'"
          :span="4"
          :selected-flags="selectedPushFlags"
          @input="handlePushInput"
        />
      </div>
      <div
        v-if="isSLAEnabled"
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <div
          class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-ash-900 rtl:text-right"
        >
          <span class="text-sm text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_RESOLUTION'
              )
            }}
          </span>
        </div>
        <notification-check-box
          :value="'email_sla_missed_resolution'"
          :selected-flags="selectedEmailFlags"
          @input="handleEmailInput"
        />
        <notification-check-box
          :value="'push_sla_missed_resolution'"
          :span="4"
          :selected-flags="selectedPushFlags"
          @input="handlePushInput"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import TableHeaderCell from 'dashboard/components/widgets/TableHeaderCell.vue';
import {
  hasPushPermissions,
  requestPushPermissions,
  verifyServiceWorkerExistence,
} from '../../../../helper/pushHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import V3Switch from 'v3/components/Form/Switch.vue';
import NotificationCheckBox from './NotificationCheckBox.vue';

export default {
  components: {
    TableHeaderCell,
    V3Switch,
    NotificationCheckBox,
  },
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
      accountId: 'getCurrentAccountId',
      emailFlags: 'userNotificationSettings/getSelectedEmailFlags',
      pushFlags: 'userNotificationSettings/getSelectedPushFlags',
      uiSettings: 'getUISettings',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    hasPushAPISupport() {
      return !!('Notification' in window);
    },
    isSLAEnabled() {
      return this.isFeatureEnabledonAccount(this.accountId, FEATURE_FLAGS.SLA);
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
        alert_if_unread_assigned_conversation_exist:
          alertIfUnreadConversationExist,
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
    handleAudioToneChange(value) {
      this.updateUISettings({ notification_tone: value });
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
