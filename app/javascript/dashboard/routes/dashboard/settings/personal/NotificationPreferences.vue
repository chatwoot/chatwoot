<template>
  <div id="profile-settings-notifications" class="flex flex-col gap-6">
    <div class="hidden sm:block">
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
      >
        <table-header-cell :span="7" label="Notification type">
          <span class="text-sm font-normal uppercase text-ash-900">
            {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPE_TITLE') }}
          </span>
        </table-header-cell>
        <table-header-cell :span="2" label="Email">
          <span class="text-sm font-medium uppercase text-ash-900">
            {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EMAIL') }}
          </span>
        </table-header-cell>
        <table-header-cell :span="3" label="Push notification">
          <div class="flex items-center justify-between gap-1">
            <span
              class="text-sm font-medium uppercase text-ash-900 whitespace-nowrap"
            >
              {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.PUSH') }}
            </span>
            <form-switch :value="true" @input="onRequestPermissions()" />
          </div>
        </table-header-cell>
      </div>
      <div v-for="(notification, index) in notificationTypes" :key="index">
        <div
          class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
        >
          <div
            class="flex flex-row items-start gap-2 col-span-7 px-0 py-2 text-sm tracking-[0.5] rtl:text-right"
          >
            <span class="text-sm text-ash-900">
              {{ $t(notification.label) }}
            </span>
          </div>
          <notification-check-box
            v-for="(type, typeIndex) in ['email', 'push']"
            :key="typeIndex"
            :type="type"
            :value="`${type}_${notification.value}`"
            :span="type === 'push' ? 3 : 2"
            :selected-flags="
              type === 'email' ? selectedEmailFlags : selectedPushFlags
            "
            @input="handleInput"
          />
        </div>
      </div>
    </div>

    <div class="flex flex-col gap-6 sm:hidden">
      <span class="text-sm font-medium uppercase text-ash-900">
        {{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.TITLE') }}
      </span>
      <div class="flex flex-col gap-4">
        <div
          v-for="(notification, index) in notificationTypes"
          :key="index"
          class="flex flex-row items-start gap-2"
        >
          <notification-check-box
            type="email"
            :value="`email_${notification.value}`"
            :selected-flags="selectedEmailFlags"
            @input="handleEmailInput"
          />
          <span class="text-sm text-ash-900">{{ $t(notification.label) }}</span>
        </div>
      </div>

      <div class="flex items-center justify-start gap-2">
        <span class="text-sm font-medium uppercase text-ash-900">
          {{ $t('PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.TITLE') }}
        </span>
        <form-switch :value="true" @input="onRequestPermissions()" />
      </div>

      <div class="flex flex-col gap-4">
        <div
          v-for="(notification, index) in notificationTypes"
          :key="index"
          class="flex flex-row items-start gap-2"
        >
          <notification-check-box
            type="push"
            :value="`push_${notification.value}`"
            :selected-flags="selectedPushFlags"
            @input="handleInput"
          />
          <span class="text-sm text-ash-900">{{ $t(notification.label) }}</span>
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
import TableHeaderCell from 'dashboard/components/widgets/TableHeaderCell.vue';
import {
  hasPushPermissions,
  requestPushPermissions,
  verifyServiceWorkerExistence,
} from '../../../../helper/pushHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import FormSwitch from 'v3/components/Form/Switch.vue';
import NotificationCheckBox from './NotificationCheckBox.vue';

export default {
  components: {
    TableHeaderCell,
    FormSwitch,
    NotificationCheckBox,
  },
  mixins: [alertMixin, configMixin, uiSettingsMixin],
  data() {
    return {
      selectedEmailFlags: [],
      selectedPushFlags: [],
      enableAudioAlerts: false,
      hasEnabledPushPermissions: false,
      notificationTypes: [
        {
          label:
            'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_CREATED',
          value: 'conversation_creation',
        },
        {
          label:
            'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_ASSIGNED',
          value: 'conversation_assignment',
        },
        {
          label:
            'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_MENTION',
          value: 'conversation_mention',
        },
        {
          label:
            'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.ASSIGNED_CONVERSATION_NEW_MESSAGE',
          value: 'assigned_conversation_new_message',
        },
        {
          label:
            'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.PARTICIPATING_CONVERSATION_NEW_MESSAGE',
          value: 'participating_conversation_new_message',
        },
        {
          label:
            'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_FIRST_RESPONSE',
          value: 'sla_missed_first_response',
        },
        {
          label:
            'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_NEXT_RESPONSE',
          value: 'sla_missed_next_response',
        },
        {
          label:
            'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_RESOLUTION',
          value: 'sla_missed_resolution',
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
  },
  mounted() {
    if (hasPushPermissions()) {
      this.getPushSubscription();
    }
    this.$store.dispatch('userNotificationSettings/get');
  },
  methods: {
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
    handleInput(type, e) {
      if (type === 'email') {
        this.handleEmailInput(e);
      } else {
        this.handlePushInput(e);
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
