<script>
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import AudioAlertTone from './AudioAlertTone.vue';
import AudioAlertEvent from './AudioAlertEvent.vue';
import AudioAlertCondition from './AudioAlertCondition.vue';
import DashboardAudioNotificationHelper from 'dashboard/helper/AudioAlerts/DashboardAudioNotificationHelper';

export default {
  components: {
    AudioAlertEvent,
    AudioAlertTone,
    AudioAlertCondition,
  },
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();

    return {
      uiSettings,
      updateUISettings,
    };
  },
  data() {
    return {
      audioAlert: '',
      playAudioWhenTabIsInactive: false,
      alertIfUnreadConversationExist: false,
      alertTone: 'ding',
      audioAlertConditions: [],
    };
  },
  watch: {
    uiSettings(value) {
      this.notificationUISettings(value);
    },
  },
  mounted() {
    this.notificationUISettings(this.uiSettings);
    this.$store.dispatch('userNotificationSettings/get');
  },
  methods: {
    updateAudioAlertInstanceValues() {
      const {
        enable_audio_alerts: audioAlert = '',
        always_play_audio_alert: alwaysPlayAudioAlert,
        alert_if_unread_assigned_conversation_exist:
          alertIfUnreadConversationExist,
        notification_tone: alertTone,
      } = this.uiSettings;
      DashboardAudioNotificationHelper.updateInstanceValues({
        audioAlertType: audioAlert,
        alwaysPlayAudioAlert: alwaysPlayAudioAlert,
        alertIfUnreadConversationExist: alertIfUnreadConversationExist,
        audioAlertTone: alertTone,
      });
    },
    notificationUISettings(uiSettings) {
      const {
        enable_audio_alerts: audioAlert = '',
        always_play_audio_alert: alwaysPlayAudioAlert,
        alert_if_unread_assigned_conversation_exist:
          alertIfUnreadConversationExist,
        notification_tone: alertTone,
      } = uiSettings;
      this.audioAlert = audioAlert;
      this.playAudioWhenTabIsInactive = !alwaysPlayAudioAlert;
      this.alertIfUnreadConversationExist = alertIfUnreadConversationExist;
      this.audioAlertConditions = [
        {
          id: 'audio1',
          label: this.$t(
            'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.CONDITION_ONE'
          ),
          model: this.playAudioWhenTabIsInactive,
          value: 'tab_is_inactive',
        },
        {
          id: 'audio2',
          label: this.$t(
            'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.CONDITION_TWO'
          ),
          model: this.alertIfUnreadConversationExist,
          value: 'conversations_are_read',
        },
      ];
      this.alertTone = alertTone || 'ding';
    },
    async handAudioAlertChange(value) {
      this.audioAlert = value;
      await this.updateUISettings({
        enable_audio_alerts: this.audioAlert,
      });
      this.updateAudioAlertInstanceValues();
      useAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
    async handleAudioAlertConditions(id, value) {
      if (id === 'tab_is_inactive') {
        await this.updateUISettings({
          always_play_audio_alert: !value,
        });
        this.updateAudioAlertInstanceValues();
      } else if (id === 'conversations_are_read') {
        await this.updateUISettings({
          alert_if_unread_assigned_conversation_exist: value,
        });
        this.updateAudioAlertInstanceValues();
      }
      useAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
    async handleAudioToneChange(value) {
      await this.updateUISettings({ notification_tone: value });
      this.updateAudioAlertInstanceValues();
      useAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
  },
};
</script>

<template>
  <div id="profile-settings-notifications" class="flex flex-col gap-6">
    <AudioAlertTone
      :value="alertTone"
      :label="
        $t(
          'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.DEFAULT_TONE.TITLE'
        )
      "
      @change="handleAudioToneChange"
    />

    <AudioAlertEvent
      :label="
        $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.TITLE')
      "
      :value="audioAlert"
      @update="handAudioAlertChange"
    />

    <AudioAlertCondition
      :items="audioAlertConditions"
      :label="
        $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.TITLE')
      "
      @change="handleAudioAlertConditions"
    />
  </div>
</template>
