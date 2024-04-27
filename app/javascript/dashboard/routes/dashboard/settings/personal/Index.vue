<template>
  <div class="flex items-center w-full overflow-y-auto">
    <div class="flex flex-col h-full p-5 pt-16 mx-auto my-0 font-inter">
      <div class="flex flex-col gap-16 sm:max-w-[720px]">
        <div class="flex flex-col gap-6">
          <h2 class="mt-4 text-2xl font-medium text-ash-900">
            {{ $t('PROFILE_SETTINGS.TITLE') }}
          </h2>
          <user-profile-picture
            :src="avatarUrl"
            :name="name"
            size="72px"
            @change="updateProfilePicture"
            @delete="deleteProfilePicture"
          />
          <user-basic-details
            :name="name"
            :display-name="displayName"
            :email="email"
            :email-enabled="!globalConfig.disableUserProfileUpdate"
            @update-user="updateProfile"
          />
        </div>

        <base-personal-item
          :header="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.TITLE')"
          :description="
            $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.NOTE')
          "
        >
          <template #settingsItem>
            <message-signature
              :message-signature="messageSignature"
              @update-signature="updateProfile"
            />
          </template>
        </base-personal-item>
        <base-personal-item
          :header="$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.TITLE')"
          :description="$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.NOTE')"
        >
          <template #settingsItem>
            <div
              class="flex flex-col justify-between w-full gap-5 sm:gap-4 sm:flex-row"
            >
              <button
                v-for="hotKey in hotKeys"
                :key="hotKey.key"
                class="reset-base"
              >
                <hot-key-card
                  :key="hotKey.title"
                  :title="hotKey.title"
                  :description="hotKey.description"
                  :light-image="hotKey.lightImage"
                  :dark-image="hotKey.darkImage"
                  :active="isEditorHotKeyEnabled(uiSettings, hotKey.key)"
                  @click="toggleHotKey(hotKey.key)"
                />
              </button>
            </div>
          </template>
        </base-personal-item>
        <base-personal-item
          :header="$t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.TITLE')"
        >
          <template #settingsItem>
            <change-password v-if="!globalConfig.disableUserProfileUpdate" />
          </template>
        </base-personal-item>

        <base-personal-item
          :header="
            $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.TITLE')
          "
          :description="
            $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.NOTE')
          "
        >
          <template #settingsItem>
            <audio-notifications />
          </template>
        </base-personal-item>
        <base-personal-item
          :header="$t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.TITLE')"
        >
          <template #settingsItem>
            <notification-preferences />
          </template>
        </base-personal-item>
      </div>
    </div>
  </div>
</template>
<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import uiSettingsMixin, {
  isEditorHotKeyEnabled,
} from 'dashboard/mixins/uiSettings';
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';
import { clearCookiesOnLogout } from '../../../../store/utils/api';

import UserProfilePicture from './UserProfilePicture.vue';
import UserBasicDetails from './UserBasicDetails.vue';
import MessageSignature from './MessageSignature.vue';
import BasePersonalItem from './BasePersonalItem.vue';
import HotKeyCard from './HotKeyCard.vue';
import ChangePassword from './ChangePassword.vue';
import NotificationPreferences from './NotificationPreferences.vue';
import AudioNotifications from './AudioNotifications.vue';

export default {
  components: {
    MessageSignature,
    BasePersonalItem,
    UserProfilePicture,
    UserBasicDetails,
    HotKeyCard,
    ChangePassword,
    NotificationPreferences,
    AudioNotifications,
  },
  mixins: [alertMixin, globalConfigMixin, uiSettingsMixin],
  data() {
    return {
      avatarFile: '',
      avatarUrl: '',
      name: '',
      displayName: '',
      email: '',
      alertMessage: '',
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
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserId: 'getCurrentUserID',
      globalConfig: 'globalConfig/get',
    }),
  },
  watch: {
    currentUserId(newCurrentUserId, prevCurrentUserId) {
      if (prevCurrentUserId !== newCurrentUserId) {
        this.initializeUser();
      }
    },
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
    isEditorHotKeyEnabled,
    async updateProfile(userAttributes, type = 'profile') {
      const { name, email, displayName, signature } = userAttributes;
      const hasEmailChanged =
        this.currentUser.email !== email && type === 'profile';
      this.name = name || this.name;
      this.email = email || this.email;
      this.displayName = displayName || this.displayName;
      this.messageSignature = signature || this.messageSignature;
      try {
        await this.$store.dispatch('updateProfile', {
          name: this.name,
          email: this.email,
          display_name: this.displayName,
          message_signature: signature,
          avatar: this.avatarFile,
        });
        if (hasEmailChanged) {
          clearCookiesOnLogout();
          this.alertMessage = this.$t('PROFILE_SETTINGS.AFTER_EMAIL_CHANGED');
        }
        this.alertMessage =
          type !== 'signature'
            ? this.$t('PROFILE_SETTINGS.UPDATE_SUCCESS')
            : this.$t(
                'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_SUCCESS'
              );
      } catch (error) {
        this.alertMessage =
          type === 'signature'
            ? this.$t('RESET_PASSWORD.API.ERROR_MESSAGE')
            : this.$t(
                'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_ERROR'
              );
        if (error?.response?.data?.error) {
          this.alertMessage = error.response.data.error;
        }
      } finally {
        this.showAlert(this.alertMessage);
      }
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
        this.showAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_SUCCESS'));
      } catch (error) {
        this.showAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_FAILED'));
      }
    },
    toggleHotKey(key) {
      this.hotKeys = this.hotKeys.map(hotKey =>
        hotKey.key === key ? { ...hotKey, active: !hotKey.active } : hotKey
      );
      this.updateUISettings({ editor_message_key: key });
      this.showAlert(
        this.$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.UPDATE_SUCCESS')
      );
    },
  },
};
</script>
