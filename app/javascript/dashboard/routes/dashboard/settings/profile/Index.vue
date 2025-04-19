<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useFontSize } from 'dashboard/composables/useFontSize';
import { clearCookiesOnLogout } from 'dashboard/store/utils/api.js';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
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
  mixins: [globalConfigMixin],
  setup() {
    const { isEditorHotKeyEnabled, updateUISettings } = useUISettings();
    const { currentFontSize, updateFontSize } = useFontSize();

    return {
      currentFontSize,
      updateFontSize,
      isEditorHotKeyEnabled,
      updateUISettings,
    };
  },
  data() {
    return {
      avatarFile: '',
      avatarUrl: '',
      azarAvatarFile: '',
      azarAvatarUrl: '',
      monoAvatarFile: '',
      monoAvatarUrl: '',
      gbitsAvatarFile: '',
      gbitsAvatarUrl: '',
      name: '',
      displayName: '',
      azarDisplayName: '',
      monoDisplayName: '',
      gbitsDisplayName: '',
      email: '',
      messageSignature: '',
      azarMessageSignature: '',
      monoMessageSignature: '',
      gbitsMessageSignature: '',
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
      this.azarDisplayName = this.currentUser.azar_display_name;
      this.monoDisplayName = this.currentUser.mono_display_name;
      this.gbitsDisplayName = this.currentUser.gbits_display_name;
      this.email = this.currentUser.email;
      this.avatarUrl = this.currentUser.avatar_url;
      this.azarAvatarUrl = this.currentUser.azar_avatar_url;
      this.monoAvatarUrl = this.currentUser.mono_avatar_url;
      this.gbitsAvatarUrl = this.currentUser.gbits_avatar_url;
      this.displayName = this.currentUser.display_name;
      this.messageSignature = this.currentUser.message_signature;
      this.azarMessageSignature = this.currentUser.azar_message_signature;
      this.monoMessageSignature = this.currentUser.mono_message_signature;
      this.gbitsMessageSignature = this.currentUser.gbits_message_signature;
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
      const {
        name,
        email,
        displayName,
        azarDisplayName,
        monoDisplayName,
        gbitsDisplayName,
      } = userAttributes;
      const hasEmailChanged = this.currentUser.email !== email;
      this.name = name || this.name;
      this.email = email || this.email;
      this.displayName = displayName || this.displayName;
      this.azarDisplayName = azarDisplayName || this.azarDisplayName;
      this.monoDisplayName = monoDisplayName || this.monoDisplayName;
      this.gbitsDisplayName = gbitsDisplayName || this.gbitsDisplayName;

      const updatePayload = {
        name: this.name,
        email: this.email,
        displayName: this.displayName,
        azarDisplayName: this.azarDisplayName,
        monoDisplayName: this.monoDisplayName,
        gbitsDisplayName: this.gbitsDisplayName,
        avatar: this.avatarFile,
        azar_avatar: this.azarAvatarFile,
        mono_avatar: this.monoAvatarFile,
        gbits_avatar: this.gbitsAvatarFile,
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
    async updateSignature(
      signature,
      azarSignature,
      monoSignature,
      gbitsSignature
    ) {
      const payload = {
        displayName: this.displayName,
        azarDisplayName: this.azarDisplayName,
        monoDisplayName: this.monoDisplayName,
        gbitsDisplayName: this.gbitsDisplayName,
        message_signature: signature,
        azar_message_signature: azarSignature,
        mono_message_signature: monoSignature,
        gbits_message_signature: gbitsSignature,
      };
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
    updateAzarProfilePicture({ file, url }) {
      this.azarAvatarFile = file;
      this.azarAvatarUrl = url;
    },
    updateMonoProfilePicture({ file, url }) {
      this.monoAvatarFile = file;
      this.monoAvatarUrl = url;
    },
    updateGbitsProfilePicture({ file, url }) {
      this.gbitsAvatarFile = file;
      this.gbitsAvatarUrl = url;
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
    async deleteAzarProfilePicture() {
      try {
        await this.$store.dispatch('deleteAzarAvatar');
        this.azarAvatarUrl = '';
        this.azarAvatarFile = '';
        useAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_FAILED'));
      }
    },
    async deleteMonoProfilePicture() {
      try {
        await this.$store.dispatch('deleteMonoAvatar');
        this.monoAvatarUrl = '';
        this.monoAvatarFile = '';
        useAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_FAILED'));
      }
    },
    async deleteGbitsProfilePicture() {
      try {
        await this.$store.dispatch('deleteGbitsAvatar');
        this.gbitsAvatarUrl = '';
        this.gbitsAvatarFile = '';
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
  },
};
</script>

<template>
  <div class="grid py-16 px-5 font-inter mx-auto gap-16 sm:max-w-screen-md">
    <div class="flex flex-col gap-6">
      <h2 class="text-2xl font-medium text-ash-900">
        {{ $t('PROFILE_SETTINGS.TITLE') }}
      </h2>
      <div class="flex flex-col gap-4">
        <h3 class="text-lg font-medium text-ash-900">
          {{ $t('PROFILE_SETTINGS.AVATAR.TITLE') }}
        </h3>
        <UserProfilePicture
          :src="avatarUrl"
          :name="name"
          @change="updateProfilePicture"
          @delete="deleteProfilePicture"
        />
      </div>
      <div class="flex flex-col gap-4">
        <h3 class="text-lg font-medium text-ash-900">
          {{ $t('PROFILE_SETTINGS.AZAR_AVATAR.TITLE') }}
        </h3>
        <UserProfilePicture
          :src="azarAvatarUrl"
          :name="azarDisplayName"
          @change="updateAzarProfilePicture"
          @delete="deleteAzarProfilePicture"
        />
      </div>
      <div class="flex flex-col gap-4">
        <h3 class="text-lg font-medium text-ash-900">
          {{ $t('PROFILE_SETTINGS.MONO_AVATAR.TITLE') }}
        </h3>
        <UserProfilePicture
          :src="monoAvatarUrl"
          :name="monoDisplayName"
          @change="updateMonoProfilePicture"
          @delete="deleteMonoProfilePicture"
        />
      </div>
      <div class="flex flex-col gap-4">
        <h3 class="text-lg font-medium text-ash-900">
          {{ $t('PROFILE_SETTINGS.GBITS_AVATAR.TITLE') }}
        </h3>
        <UserProfilePicture
          :src="gbitsAvatarUrl"
          :name="gbitsDisplayName"
          @change="updateGbitsProfilePicture"
          @delete="deleteGbitsProfilePicture"
        />
      </div>
      <UserBasicDetails
        :name="name"
        :display-name="displayName"
        :email="email"
        :azar-display-name="azarDisplayName"
        :mono-display-name="monoDisplayName"
        :gbits-display-name="gbitsDisplayName"
        :email-enabled="!globalConfig.disableUserProfileUpdate"
        @update-user="updateProfile"
      />
    </div>
    <FormSection
      :title="$t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TITLE')"
      :description="$t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.NOTE')"
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
        :azar-message-signature="azarMessageSignature"
        :mono-message-signature="monoMessageSignature"
        :gbits-message-signature="gbitsMessageSignature"
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
          class="px-0 reset-base w-full sm:flex-1"
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
        useInstallationName(
          $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.NOTE'),
          globalConfig.installationName
        )
      "
    >
      <AccessToken :value="currentUser.access_token" @on-copy="onCopyToken" />
    </FormSection>
  </div>
</template>
