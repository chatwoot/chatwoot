<template>
  <div class="flex items-center w-full overflow-y-auto">
    <div
      class="flex flex-col h-full p-5 pt-16 mx-auto my-0 bg-white dark:bg-slate-900 font-inter"
    >
      <div class="flex flex-col gap-8 sm:max-w-3xl">
        <h2 class="text-2xl font-medium text-slate-900 dark:text-white">
          Profile Settings
        </h2>
        <user-basic-profile
          :src="avatarUrl"
          :display-name="displayName"
          size="72px"
          @change="handleImageUpload"
          @update="updateUser"
        />

        <form @submit.prevent="updateUser('profile')">
          <label :class="{ error: $v.name.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model="name"
              type="text"
              :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
              @input="$v.name.$touch"
            />
            <span v-if="$v.name.$error" class="message">
              {{ $t('PROFILE_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <label :class="{ error: $v.displayName.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.LABEL') }}
            <input
              v-model="displayName"
              type="text"
              :placeholder="
                $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.PLACEHOLDER')
              "
              @input="$v.displayName.$touch"
            />
          </label>
          <label
            v-if="!globalConfig.disableUserProfileUpdate"
            :class="{ error: $v.email.$error }"
          >
            {{ $t('PROFILE_SETTINGS.FORM.EMAIL.LABEL') }}
            <input
              v-model.trim="email"
              type="email"
              :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
              @input="$v.email.$touch"
            />
            <span v-if="$v.email.$error" class="message">
              {{ $t('PROFILE_SETTINGS.FORM.EMAIL.ERROR') }}
            </span>
          </label>
          <woot-button type="submit" :is-loading="isProfileUpdating">
            {{ $t('PROFILE_SETTINGS.BTN_TEXT') }}
          </woot-button>
        </form>

        <personal-wrapper
          header="Personal message signature"
          description="Create a unique message signature to appear at the end of every message you send from any inbox. You can also include an inline image, which is supported in live-chat, email, and API inboxes."
          :show-action-button="false"
        >
          <template #settingsItem>
            <message-signature />
          </template>
        </personal-wrapper>

        <personal-wrapper
          header="Hot key to send messages"
          description="You can select a hotkey (either Enter or Cmd/Ctrl+Enter) based on your
          preference of writing."
          :show-action-button="false"
        >
          <template #settingsItem>
            <div class="flex flex-col justify-between w-full gap-4 sm:flex-row">
              <button
                v-for="keyOption in keyOptions"
                :key="keyOption.key"
                class="p-0 cursor-pointer"
              >
                <hot-key-card
                  :heading="keyOption.heading"
                  :content="keyOption.content"
                  :src="keyOption.src"
                  :active="keyOption.key === 'enter'"
                />
              </button>
            </div>
          </template>
        </personal-wrapper>
        <change-password />
        <personal-wrapper
          header="Audio notifications"
          description="Enable audio notifications in dashboard for new messages and conversations."
          :show-action-button="false"
        >
          <template #settingsItem>
            <audio-notifications />
          </template>
        </personal-wrapper>
        <personal-wrapper
          header="Notification preferences"
          :show-action-button="false"
        >
          <template #settingsItem>
            <notification-preferences />
          </template>
        </personal-wrapper>
        <personal-wrapper
          header="Access Token"
          description="This token can be used if you are building an API based integration."
          :show-action-button="false"
        >
          <template #settingsItem>
            <access-token />
          </template>
        </personal-wrapper>
      </div>
    </div>
  </div>
</template>
<script>
import UserBasicProfile from './UserBasicProfile.vue';
import MessageSignature from './MessageSignature.vue';
import PersonalWrapper from './PersonalWrapper.vue';
import HotKeyCard from './HotKeyCard.vue';
import ChangePassword from './ChangePassword.vue';
import NotificationPreferences from './NotificationPreferences.vue';
import AudioNotifications from './AudioNotifications.vue';
import AccessToken from './AccessToken.vue';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import uiSettingsMixin, {
  isEditorHotKeyEnabled,
} from 'dashboard/mixins/uiSettings';
import alertMixin from 'shared/mixins/alertMixin';
import { required, minLength, email } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import { clearCookiesOnLogout } from '../../../../store/utils/api';
import { hasValidAvatarUrl } from 'dashboard/helper/URLHelper';

export default {
  components: {
    UserBasicProfile,
    MessageSignature,
    PersonalWrapper,
    HotKeyCard,
    ChangePassword,
    NotificationPreferences,
    AudioNotifications,
    AccessToken,
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
          heading: 'Enter (↵)',
          content:
            'Send messages by pressing Enter key instead of clicking send button.',
        },
        {
          key: 'cmd_enter',
          src: '/assets/images/dashboard/profile/hot-key-ctrl-enter.svg',
          heading: 'CMD / Ctrl + Enter (⌘ + ↵)',
          content:
            'Send messages by pressing Enter key instead of clicking send button.',
        },
      ],
    };
  },
  validations: {
    name: {
      required,
      minLength: minLength(1),
    },
    displayName: {},
    email: {
      required,
      email,
    },
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
    async updateUser() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }

      this.isProfileUpdating = true;
      const hasEmailChanged = this.currentUser.email !== this.email;
      try {
        await this.$store.dispatch('updateProfile', {
          name: this.name,
          email: this.email,
          avatar: this.avatarFile,
          displayName: this.displayName,
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
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    async deleteAvatar() {
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
