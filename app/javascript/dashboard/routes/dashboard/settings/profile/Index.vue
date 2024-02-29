<template>
  <div class="overflow-auto p-6">
    <form @submit.prevent="updateUser('profile')">
      <div
        class="flex flex-row border-b border-slate-50 dark:border-slate-700 items-center flex p-4"
      >
        <div class="w-1/4 py-4 pr-6 ml-0">
          <h4 class="text-lg text-black-900 dark:text-slate-200">
            {{ $t('PROFILE_SETTINGS.FORM.PROFILE_SECTION.TITLE') }}
          </h4>
          <p>{{ $t('PROFILE_SETTINGS.FORM.PROFILE_SECTION.NOTE') }}</p>
        </div>
        <div class="p-4 w-[45%]">
          <woot-avatar-uploader
            :label="$t('PROFILE_SETTINGS.FORM.PROFILE_IMAGE.LABEL')"
            :src="avatarUrl"
            @change="handleImageUpload"
          />
          <div v-if="showDeleteButton" class="avatar-delete-btn">
            <woot-button
              type="button"
              color-scheme="alert"
              variant="hollow"
              size="small"
              @click="deleteAvatar"
            >
              {{ $t('PROFILE_SETTINGS.DELETE_AVATAR') }}
            </woot-button>
          </div>
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
        </div>
      </div>
    </form>
    <message-signature />
    <div
      class="border-b border-slate-50 dark:border-slate-700 items-center flex p-4 text-black-900 dark:text-slate-300 row"
    >
      <div class="w-1/4 py-4 pr-6 ml-0">
        <h4 class="text-lg text-black-900 dark:text-slate-200">
          {{ $t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.TITLE') }}
        </h4>
        <p>
          {{ $t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.NOTE') }}
        </p>
      </div>
      <div class="p-4 w-[45%] flex gap-4 flex-row">
        <button
          v-for="keyOption in keyOptions"
          :key="keyOption.key"
          class="cursor-pointer p-0"
          @click="toggleEditorMessageKey(keyOption.key)"
        >
          <preview-card
            :heading="keyOption.heading"
            :content="keyOption.content"
            :src="keyOption.src"
            :active="isEditorHotKeyEnabled(uiSettings, keyOption.key)"
          />
        </button>
      </div>
    </div>
    <change-password v-if="!globalConfig.disableUserProfileUpdate" />
    <notification-settings />
    <div
      class="border-b border-slate-50 dark:border-slate-700 items-center flex p-4 text-black-900 dark:text-slate-300 row"
    >
      <div class="w-1/4 py-4 pr-6 ml-0">
        <h4 class="text-lg text-black-900 dark:text-slate-200">
          {{ $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.TITLE') }}
        </h4>
        <p>
          {{
            useInstallationName(
              $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.NOTE'),
              globalConfig.installationName
            )
          }}
        </p>
      </div>
      <div class="p-4 w-[45%]">
        <masked-text :value="currentUser.access_token" />
      </div>
    </div>
  </div>
</template>

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import { clearCookiesOnLogout } from '../../../../store/utils/api';
import { hasValidAvatarUrl } from 'dashboard/helper/URLHelper';
import NotificationSettings from './NotificationSettings.vue';
import alertMixin from 'shared/mixins/alertMixin';
import ChangePassword from './ChangePassword.vue';
import MessageSignature from './MessageSignature.vue';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import uiSettingsMixin, {
  isEditorHotKeyEnabled,
} from 'dashboard/mixins/uiSettings';
import MaskedText from 'dashboard/components/MaskedText.vue';
import PreviewCard from 'dashboard/components/ui/PreviewCard.vue';

export default {
  components: {
    NotificationSettings,
    ChangePassword,
    MessageSignature,
    PreviewCard,
    MaskedText,
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
          src: '/assets/images/dashboard/editor/enter-editor.png',
          heading: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.HEADING'
          ),
          content: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.CONTENT'
          ),
        },
        {
          key: 'cmd_enter',
          src: '/assets/images/dashboard/editor/cmd-editor.png',
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
