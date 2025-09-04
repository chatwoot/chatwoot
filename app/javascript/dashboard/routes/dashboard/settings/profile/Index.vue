<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useFontSize } from 'dashboard/composables/useFontSize';
import { useBranding } from 'shared/composables/useBranding';
import { clearCookiesOnLogout } from 'dashboard/store/utils/api.js';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import UserProfilePicture from './UserProfilePicture.vue';
import UserBasicDetails from './UserBasicDetails.vue';
import MessageSignature from './MessageSignature.vue';
import FontSize from './FontSize.vue';
import HotKeyCard from './HotKeyCard.vue';
import ChangePassword from './ChangePassword.vue';
import NotificationPreferences from './NotificationPreferences.vue';
import AudioNotifications from './AudioNotifications.vue';
import FormSection from 'dashboard/components/FormSection.vue';
import AccessToken from './AccessToken.vue';
import Policy from 'dashboard/components/policy.vue';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

export default {
  components: {
    MessageSignature,
    FormSection,
    FontSize,
    UserProfilePicture,
    Policy,
    UserBasicDetails,
    HotKeyCard,
    ChangePassword,
    NotificationPreferences,
    AudioNotifications,
    AccessToken,
  },
  setup() {
    const { isEditorHotKeyEnabled, updateUISettings } = useUISettings();
    const { currentFontSize, updateFontSize } = useFontSize();
    const { replaceInstallationName } = useBranding();

    return {
      currentFontSize,
      updateFontSize,
      isEditorHotKeyEnabled,
      updateUISettings,
      replaceInstallationName,
    };
  },
  data() {
    return {
      avatarFile: '',
      avatarUrl: '',
      name: '',
      displayName: '',
      email: '',
      messageSignature: '',
      hotKeys: [
        {
          key: 'enter',
          title: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.HEADING'
          ),
          description: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.CONTENT'
          ),
          lightImage: '/assets/images/dashboard/profile/hot-key-enter.svg',
          darkImage: '/assets/images/dashboard/profile/hot-key-enter-dark.svg',
        },
        {
          key: 'cmd_enter',
          title: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.HEADING'
          ),
          description: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.CONTENT'
          ),
          lightImage: '/assets/images/dashboard/profile/hot-key-ctrl-enter.svg',
          darkImage:
            '/assets/images/dashboard/profile/hot-key-ctrl-enter-dark.svg',
        },
      ],
      notificationPermissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      audioNotificationPermissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserId: 'getCurrentUserID',
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    if (this.currentUserId) {
      this.initializeUser();
    }
  },
  methods: {
    initializeUser() {
      this.name = this.currentUser.name;
      this.email = this.currentUser.email;
      this.avatarUrl = this.currentUser.avatar_url;
      this.displayName = this.currentUser.display_name;
      this.messageSignature = this.currentUser.message_signature;
    },
    async dispatchUpdate(payload, successMessage, errorMessage) {
      let alertMessage = '';
      try {
        await this.$store.dispatch('updateProfile', payload);
        alertMessage = successMessage;

        return true; // return the value so that the status can be known
      } catch (error) {
        alertMessage = parseAPIErrorResponse(error) || errorMessage;

        return false; // return the value so that the status can be known
      } finally {
        useAlert(alertMessage);
      }
    },
    async updateProfile(userAttributes) {
      const { name, email, displayName } = userAttributes;
      const hasEmailChanged = this.currentUser.email !== email;
      this.name = name || this.name;
      this.email = email || this.email;
      this.displayName = displayName || this.displayName;

      const updatePayload = {
        name: this.name,
        email: this.email,
        displayName: this.displayName,
        avatar: this.avatarFile,
      };

      const success = await this.dispatchUpdate(
        updatePayload,
        hasEmailChanged
          ? this.$t('PROFILE_SETTINGS.AFTER_EMAIL_CHANGED')
          : this.$t('PROFILE_SETTINGS.UPDATE_SUCCESS'),
        this.$t('RESET_PASSWORD.API.ERROR_MESSAGE')
      );

      if (hasEmailChanged && success) clearCookiesOnLogout();
    },
    async updateSignature(signature) {
      const payload = { message_signature: signature };
      let successMessage = this.$t(
        'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_SUCCESS'
      );
      let errorMessage = this.$t(
        'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_ERROR'
      );

      await this.dispatchUpdate(payload, successMessage, errorMessage);
    },
    updateProfilePicture({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    async deleteProfilePicture() {
      try {
        await this.$store.dispatch('deleteAvatar');
        this.avatarUrl = '';
        this.avatarFile = '';
        useAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_FAILED'));
      }
    },
    toggleHotKey(key) {
      this.hotKeys = this.hotKeys.map(hotKey =>
        hotKey.key === key ? { ...hotKey, active: !hotKey.active } : hotKey
      );
      this.updateUISettings({ editor_message_key: key });
      useAlert(this.$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.UPDATE_SUCCESS'));
    },
    async onCopyToken(value) {
      await copyTextToClipboard(value);
      useAlert(this.$t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
    },
    async resetAccessToken() {
      const success = await this.$store.dispatch('resetAccessToken');
      if (success) {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.RESET_SUCCESS'));
      } else {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.RESET_ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="grid py-16 px-5 font-inter mx-auto gap-16 sm:max-w-screen-md">
    <div class="flex flex-col gap-6">
      <h2 class="text-2xl font-medium text-n-slate-12">
        {{ $t('PROFILE_SETTINGS.TITLE') }}
      </h2>
      <UserProfilePicture
        :src="avatarUrl"
        :name="name"
        @change="updateProfilePicture"
        @delete="deleteProfilePicture"
      />
      <UserBasicDetails
        :name="name"
        :display-name="displayName"
        :email="email"
        :email-enabled="!globalConfig.disableUserProfileUpdate"
        @update-user="updateProfile"
      />
    </div>
    <FormSection
      :title="$t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TITLE')"
      :description="
        replaceInstallationName(
          $t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.NOTE')
        )
      "
    >
      <FontSize
        :value="currentFontSize"
        :label="$t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.TITLE')"
        :description="
          $t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.NOTE')
        "
        @change="updateFontSize"
      />
    </FormSection>
    <FormSection
      :title="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.TITLE')"
      :description="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.NOTE')"
    >
      <MessageSignature
        :message-signature="messageSignature"
        @update-signature="updateSignature"
      />
    </FormSection>
    <FormSection
      :title="$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.TITLE')"
      :description="$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.NOTE')"
    >
      <div
        class="flex flex-col justify-between w-full gap-5 sm:gap-4 sm:flex-row"
      >
        <button
          v-for="hotKey in hotKeys"
          :key="hotKey.key"
          class="px-0 reset-base w-full sm:flex-1 rounded-xl outline-1 outline"
          :class="
            isEditorHotKeyEnabled(hotKey.key)
              ? 'outline-n-brand/30'
              : 'outline-n-weak'
          "
        >
          <HotKeyCard
            :key="hotKey.title"
            :title="hotKey.title"
            :description="hotKey.description"
            :light-image="hotKey.lightImage"
            :dark-image="hotKey.darkImage"
            :active="isEditorHotKeyEnabled(hotKey.key)"
            @click="toggleHotKey(hotKey.key)"
          />
        </button>
      </div>
    </FormSection>
    <FormSection
      v-if="!globalConfig.disableUserProfileUpdate"
      :title="$t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.TITLE')"
    >
      <ChangePassword />
    </FormSection>
    <FormSection
      :title="$t('PROFILE_SETTINGS.FORM.SECURITY_SECTION.TITLE')"
      :description="$t('PROFILE_SETTINGS.FORM.SECURITY_SECTION.NOTE')"
    >
      <div class="flex flex-col space-y-4">
        <div
          class="bg-slate-50 dark:bg-slate-900 rounded-lg p-4 border border-slate-200 dark:border-slate-700"
        >
          <div class="flex items-start justify-between">
            <div class="flex items-start space-x-3">
              <div class="flex-shrink-0">
                <svg
                  class="w-6 h-6 text-slate-600 dark:text-slate-400 mt-0.5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
              </div>
              <div class="flex-1">
                <h5
                  class="text-sm font-semibold text-slate-900 dark:text-slate-100"
                >
                  {{ $t('MFA_SETTINGS.TITLE') }}
                </h5>
                <p class="mt-1 text-sm text-slate-600 dark:text-slate-400">
                  {{ $t('MFA_SETTINGS.DESCRIPTION') }}
                </p>
              </div>
            </div>
            <router-link
              :to="`/app/accounts/${$route.params.accountId}/profile/mfa`"
              class="inline-flex items-center px-4 py-2 text-sm font-medium text-woot-600 bg-woot-50 border border-woot-200 rounded-lg hover:bg-woot-100 hover:border-woot-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-woot-500 transition-colors"
            >
              <svg
                class="w-4 h-4 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              {{ $t('PROFILE_SETTINGS.FORM.SECURITY_SECTION.MFA_BUTTON') }}
            </router-link>
          </div>
        </div>
      </div>
    </FormSection>
    <Policy :permissions="audioNotificationPermissions">
      <FormSection
        :title="$t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.TITLE')"
        :description="
          $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.NOTE')
        "
      >
        <AudioNotifications />
      </FormSection>
    </Policy>
    <Policy :permissions="notificationPermissions">
      <FormSection :title="$t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.TITLE')">
        <NotificationPreferences />
      </FormSection>
    </Policy>
    <FormSection
      :title="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.TITLE')"
      :description="
        replaceInstallationName($t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.NOTE'))
      "
    >
      <AccessToken
        :value="currentUser.access_token"
        @on-copy="onCopyToken"
        @on-reset="resetAccessToken"
      />
    </FormSection>
  </div>
</template>
