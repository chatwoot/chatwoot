<template>
  <div class="flex items-center w-full overflow-y-auto">
    <div
      class="flex flex-col h-full p-5 pt-16 mx-auto my-0 bg-white dark:bg-slate-900 font-inter"
    >
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
            @update-user="updateUser"
          />
        </div>

        <personal-wrapper
          :header="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.TITLE')"
          :description="
            $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.NOTE')
          "
          :show-action-button="false"
        >
          <template #settingsItem>
            <message-signature />
          </template>
        </personal-wrapper>

        <personal-wrapper
          :header="$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.TITLE')"
          :description="$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.NOTE')"
          :show-action-button="false"
        >
          <template #settingsItem>
            <div
              class="flex flex-col justify-between w-full gap-5 sm:gap-4 sm:flex-row"
            >
              <button
                v-for="keyOption in keyOptions"
                :key="keyOption.key"
                class="reset-base"
              >
                <hot-key-card
                  :heading="keyOption.heading"
                  :content="keyOption.content"
                  :src="keyOption.src"
                  :active="isEditorHotKeyEnabled(uiSettings, keyOption.key)"
                  @click="toggleEditorMessageKey(keyOption.key)"
                />
              </button>
            </div>
          </template>
        </personal-wrapper>
        <change-password v-if="!globalConfig.disableUserProfileUpdate" />
        <personal-wrapper
          :header="
            $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.TITLE')
          "
          :description="
            $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.NOTE')
          "
          :show-action-button="false"
        >
          <template #settingsItem>
            <notification-settings />
          </template>
        </personal-wrapper>
        <personal-wrapper
          :header="$t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.TITLE')"
          :show-action-button="false"
        >
          <template #settingsItem>
            <notification-preferences />
          </template>
        </personal-wrapper>
        <personal-wrapper
          :header="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.TITLE')"
          :description="
            useInstallationName(
              $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.NOTE'),
              globalConfig.installationName
            )
          "
          :show-action-button="false"
        >
          <template #settingsItem>
            <access-token :value="currentUser.access_token" />
          </template>
        </personal-wrapper>
      </div>
    </div>
  </div>
</template>
<script>
import MessageSignature from './MessageSignature.vue';
import PersonalWrapper from './PersonalWrapper.vue';
import HotKeyCard from './HotKeyCard.vue';
import ChangePassword from './ChangePassword.vue';
import AccessToken from './AccessToken.vue';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import uiSettingsMixin, {
  isEditorHotKeyEnabled,
} from 'dashboard/mixins/uiSettings';
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';
import { clearCookiesOnLogout } from '../../../../store/utils/api';
import { hasValidAvatarUrl } from 'dashboard/helper/URLHelper';
import NotificationSettings from './NotificationSettings.vue';
import NotificationPreferences from './NotificationPreferences.vue';
import UserProfilePicture from './UserProfilePicture.vue';
import UserBasicDetails from './UserBasicDetails.vue';

export default {
  components: {
    MessageSignature,
    PersonalWrapper,
    HotKeyCard,
    ChangePassword,
    NotificationSettings,
    AccessToken,
    NotificationPreferences,
    UserProfilePicture,
    UserBasicDetails,
  },
  mixins: [alertMixin, globalConfigMixin, uiSettingsMixin],
  data() {
    return {
      avatarFile: '',
      avatarUrl: '',
      name: '',
      displayName: '',
      email: '',
      isProfileUpdating: false,
      errorMessage: '',
      keyOptions: [
        {
          key: 'enter',
          src: '/assets/images/dashboard/profile/hot-key-enter.svg',
          heading: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.HEADING'
          ),
          content: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.CONTENT'
          ),
        },
        {
          key: 'cmd_enter',
          src: '/assets/images/dashboard/profile/hot-key-ctrl-enter.svg',
          heading: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.HEADING'
          ),
          content: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.CONTENT'
          ),
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
    showDeleteButton() {
      return hasValidAvatarUrl(this.avatarUrl);
    },
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
    },
    isEditorHotKeyEnabled,
    async updateUser(user) {
      const { name, email, displayName } = user;
      this.isProfileUpdating = true;
      const hasEmailChanged = this.currentUser.email !== email;
      try {
        await this.$store.dispatch('updateProfile', {
          name: name,
          email: email,
          avatar: this.avatarFile,
          displayName: displayName,
        });
        this.isProfileUpdating = false;
        if (hasEmailChanged) {
          clearCookiesOnLogout();
          this.errorMessage = this.$t('PROFILE_SETTINGS.AFTER_EMAIL_CHANGED');
        }
        this.errorMessage = this.$t('PROFILE_SETTINGS.UPDATE_SUCCESS');
      } catch (error) {
        this.errorMessage = this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
        if (error?.response?.data?.error) {
          this.errorMessage = error.response.data.error;
        }
      } finally {
        this.isProfileUpdating = false;
        this.showAlert(this.errorMessage);
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
    toggleEditorMessageKey(key) {
      this.updateUISettings({ editor_message_key: key });
      this.showAlert(
        this.$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.UPDATE_SUCCESS')
      );
    },
  },
};
</script>
