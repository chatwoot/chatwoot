<template>
  <div id="profile-settings-notifications" class="flex flex-col gap-6">
    <form-select
      v-model="notificationTone"
      name="timezone"
      spacing="compact"
      label="Alert tone"
      placeholder="Ding"
      class="max-w-xl"
      @input="handleAudioToneChange"
    >
      <option
        v-for="file in notificationAlertTones"
        :key="file.label"
        :value="file.value"
      >
        {{ file.label }}
      </option>
    </form-select>

    <div>
      <label
        class="flex justify-between pb-1 text-sm font-medium leading-6 text-ash-900"
      >
        {{
          $t(
            'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.TITLE'
          )
        }}
      </label>
      <div
        class="flex flex-row justify-between h-10 max-w-xl p-2 border border-solid rounded-md border-ash-200"
      >
        <div
          class="flex flex-row items-center justify-center gap-2 px-4 border-r border-ash-200 grow"
        >
          <input
            id="audio_enable_alert_none"
            v-model="enableAudioAlerts"
            class="notification--checkbox accent-primary-600"
            type="radio"
            value="none"
            @input="handleAudioInput"
          />
          <label
            class="text-sm font-medium text-ash-900"
            :class="{ 'text-ash-400': enableAudioAlerts !== 'none' }"
          >
            {{
              $t(
                'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.NONE'
              )
            }}
          </label>
        </div>
        <div
          class="flex flex-row items-center justify-center gap-2 px-4 border-r border-ash-200 grow"
        >
          <input
            id="audio_enable_alert_mine"
            v-model="enableAudioAlerts"
            class="notification--checkbox accent-primary-600"
            type="radio"
            value="mine"
            @input="handleAudioInput"
          />
          <label
            class="text-sm font-medium text-ash-900"
            :class="{ 'text-ash-400': enableAudioAlerts !== 'mine' }"
          >
            {{
              $t(
                'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.ASSIGNED'
              )
            }}
          </label>
        </div>
        <div class="flex flex-row items-center justify-center gap-2 px-4 grow">
          <input
            id="audio_enable_alert_all"
            v-model="enableAudioAlerts"
            class="notification--checkbox accent-primary-600"
            type="radio"
            value="all"
            @input="handleAudioInput"
          />
          <label
            class="text-sm font-medium text-ash-900"
            :class="{ 'text-ash-400': enableAudioAlerts !== 'all' }"
          >
            {{
              $t(
                'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.ALL_CONVERSATIONS'
              )
            }}
          </label>
        </div>
      </div>
    </div>
    <div>
      <label
        class="flex justify-between pb-1 text-sm font-medium leading-6 text-slate-900 dark:text-white"
      >
        {{
          $t(
            'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.TITLE'
          )
        }}
      </label>
      <div class="flex flex-col gap-2">
        <div class="flex flex-row items-start gap-2">
          <input
            id="audio_alert_when_tab_is_inactive"
            v-model="playAudioWhenTabIsInactive"
            type="checkbox"
            value="tab_is_inactive"
            class="mb-0 mt-0.5 border-[1.5px] flex-shrink-0 shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-primary-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
            @input="handleAudioAlertConditions"
          />
          <label class="text-sm font-normal text-ash-900">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.CONDITIONS.CONDITION_ONE'
              )
            }}
          </label>
        </div>
        <div class="flex flex-row items-start gap-2">
          <input
            v-model="alertIfUnreadConversationExist"
            class="mb-0 mt-0.5 border-[1.5px] flex-shrink-0 shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-primary-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
            type="checkbox"
            value="conversations_are_read"
            @input="handleAudioAlertConditions"
          />
          <label class="text-sm font-normal text-ash-900">
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
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import FormSelect from 'v3/components/Form/Select.vue';
import {
  hasPushPermissions,
  requestPushPermissions,
  verifyServiceWorkerExistence,
} from '../../../../helper/pushHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export default {
  components: {
    FormSelect,
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

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables.scss';

.notification--checkbox {
  font-size: $font-size-large;
}

.push-notification--button {
  margin-bottom: var(--space-one);
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
