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
import { clearCookiesOnLogout } from 'dashboard/store/utils/api.js';

import UserProfilePicture from './UserProfilePicture.vue';
import UserBasicDetails from './UserBasicDetails.vue';
import MessageSignature from './MessageSignature.vue';
import BasePersonalItem from './BasePersonalItem.vue';

export default {
  components: {
    MessageSignature,
    BasePersonalItem,
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
      alertMessage: '',
      messageSignature: '',
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
  },
};
</script>
