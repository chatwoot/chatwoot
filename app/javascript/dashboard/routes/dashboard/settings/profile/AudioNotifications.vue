<template>
  <div id="profile-settings-notifications" class="flex flex-col gap-6">
    <audio-alert-tone
      :value="alertTone"
      :label="
        $t(
          'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.DEFAULT_TONE.TITLE'
        )
      "
      @change="handleAudioToneChange"
    />

    <audio-alert-event
      :label="
        $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.TITLE')
      "
      :value="audioAlert"
      @update="handAudioAlertChange"
    />

    <audio-alert-condition
      :items="audioAlertConditions"
      :label="
        $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.TITLE')
      "
      @change="handleAudioAlertConditions"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import DashboardAudioNotificationHelper from 'dashboard/helper/AudioAlerts/DashboardAudioNotificationHelper';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import AudioAlertTone from './AudioAlertTone.vue';
import AudioAlertEvent from './AudioAlertEvent.vue';
import AudioAlertCondition from './AudioAlertCondition.vue';

export default {
  components: {
    AudioAlertEvent,
    AudioAlertTone,
    AudioAlertCondition,
  },
  mixins: [alertMixin, configMixin, uiSettingsMixin],
  data() {
    return {
      audioAlert: '',
      playAudioWhenTabIsInactive: false,
      alertIfUnreadConversationExist: false,
      alertTone: 'ding',
      audioAlertConditions: [],
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      uiSettings: 'getUISettings',
    }),
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
      await this.updateAudioAlertInstanceValues();
      this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
    async handleAudioAlertConditions(id, value) {
      if (id === 'tab_is_inactive') {
        await this.updateUISettings({
          always_play_audio_alert: !value,
        });
        await this.updateAudioAlertInstanceValues();
      } else if (id === 'conversations_are_read') {
        await this.updateUISettings({
          alert_if_unread_assigned_conversation_exist: value,
        });
        await this.updateAudioAlertInstanceValues();
      }
      this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
    async handleAudioToneChange(value) {
      await this.updateUISettings({ notification_tone: value });
      await this.updateAudioAlertInstanceValues();
      this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
    },
  },
};
</script>
