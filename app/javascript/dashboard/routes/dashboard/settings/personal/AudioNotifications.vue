<template>
  <div id="profile-settings-notifications" class="flex flex-col gap-6">
    <audio-alert-tone
      :alert-tone="alertTone"
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
      :audio-alert="audioAlert"
      @change="handleAudioInput"
    />

    <audio-alert-condition
      :label="
        $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.TITLE')
      "
      :play-audio-when-tab-is-inactive="playAudioWhenTabIsInactive"
      :alert-if-unread-conversation-exist="alertIfUnreadConversationExist"
      @change="handleAudioAlertConditions"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
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
      this.alertTone = alertTone || 'ding';
    },
    handleAudioInput(e) {
      this.audioAlert = e.target.value;
      this.updateUISettings({
        enable_audio_alerts: this.audioAlert,
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
  },
};
</script>
