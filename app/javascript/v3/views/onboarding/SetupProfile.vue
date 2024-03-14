<template>
  <onboarding-base-modal
    :title="$t('START_ONBOARDING.PROFILE.TITLE')"
    :subtitle="$t('START_ONBOARDING.PROFILE.BODY')"
  >
    <form class="space-y-5" @submit="onSubmit">
      <div class="space-y-3">
        <div>
          <with-label name="user_avatar">
            <template #label>
              {{ $t('START_ONBOARDING.PROFILE.AVATAR.LABEL') }}
            </template>
            <div class="flex gap-2">
              <woot-thumbnail
                v-if="avatarUrl"
                size="40px"
                :src="avatarUrl"
                :username="fullName"
                variant="square"
                :has-border="true"
              />
              <div
                v-else
                class="flex items-center justify-center w-10 h-10 rounded-md bg-slate-200"
              >
                <svg
                  v-once
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <g id="user-3-fill">
                    <path
                      id="Vector"
                      d="M18.8574 20.5714H5.14307V18.8571C5.14307 17.7205 5.5946 16.6304 6.39832 15.8267C7.20205 15.0229 8.29214 14.5714 9.42878 14.5714H14.5716C15.7083 14.5714 16.7984 15.0229 17.6021 15.8267C18.4058 16.6304 18.8574 17.7205 18.8574 18.8571V20.5714ZM12.0002 12.8571C11.3248 12.8571 10.6561 12.7241 10.0321 12.4656C9.40816 12.2072 8.84122 11.8284 8.36366 11.3508C7.8861 10.8733 7.50728 10.3063 7.24883 9.68235C6.99038 9.05839 6.85735 8.38964 6.85735 7.71427C6.85735 7.0389 6.99038 6.37014 7.24883 5.74618C7.50728 5.12222 7.8861 4.55528 8.36366 4.07772C8.84122 3.60016 9.40816 3.22134 10.0321 2.96289C10.6561 2.70444 11.3248 2.57141 12.0002 2.57141C13.3642 2.57141 14.6723 3.11325 15.6368 4.07772C16.6012 5.04219 17.1431 6.3503 17.1431 7.71427C17.1431 9.07824 16.6012 10.3863 15.6368 11.3508C14.6723 12.3153 13.3642 12.8571 12.0002 12.8571Z"
                      fill="#B9BBC6"
                    />
                  </g>
                </svg>
              </div>
              <input
                id="user_avatar"
                ref="imageUpload"
                name="user_avatar"
                class="invisible w-0 h-0"
                type="file"
                accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
                @change="handleImageUpload"
              />
              <woot-button
                v-if="!avatarFile"
                color-scheme="secondary"
                variant="hollow"
                @click="onFileBrowse"
              >
                {{ $t('START_ONBOARDING.PROFILE.AVATAR.PLACEHOLDER') }}
              </woot-button>
              <woot-button
                v-else
                type="button"
                color-scheme="alert"
                variant="hollow"
                @click="deleteAvatar"
              >
                {{ $t('PROFILE_SETTINGS.DELETE_AVATAR') }}
              </woot-button>
            </div>
          </with-label>
        </div>
        <form-input
          v-model="fullName"
          name="full_name"
          spacing="compact"
          :has-error="$v.fullName.$error"
          :label="$t('START_ONBOARDING.PROFILE.FULL_NAME.LABEL')"
          :placeholder="$t('START_ONBOARDING.PROFILE.FULL_NAME.PLACEHOLDER')"
          :error-message="$t('START_ONBOARDING.PROFILE.FULL_NAME.ERROR')"
        />
        <form-input
          v-model="displayName"
          name="display_name"
          spacing="compact"
          :has-error="$v.displayName.$error"
          :label="$t('START_ONBOARDING.PROFILE.DISPLAY_NAME.LABEL')"
          :placeholder="$t('START_ONBOARDING.PROFILE.DISPLAY_NAME.PLACEHOLDER')"
          :error-message="$t('START_ONBOARDING.PROFILE.DISPLAY_NAME.ERROR')"
        />
        <with-label
          :label="$t('START_ONBOARDING.PROFILE.PHONE_NUMBER.LABEL')"
          name="phone_number"
        >
          <phone-input
            v-model="phoneNumber"
            :value="phoneNumber"
            :error="$v.phoneNumber.$error"
            :placeholder="
              $t('START_ONBOARDING.PROFILE.PHONE_NUMBER.PLACEHOLDER')
            "
            font-size="text-sm"
            class="w-full"
            @blur="$v.phoneNumber.$touch"
            @setCode="setPhoneCode"
          />
        </with-label>
        <form-text-area
          v-model="signature"
          name="signature"
          spacing="compact"
          :allow-resize="false"
          :label="$t('START_ONBOARDING.PROFILE.SIGNATURE.LABEL')"
          :placeholder="$t('START_ONBOARDING.PROFILE.SIGNATURE.PLACEHOLDER')"
        />
      </div>
      <submit-button
        button-class="flex justify-center w-full text-sm text-center"
        :button-text="$t('START_ONBOARDING.PROFILE.SUBMIT.BUTTON')"
      />
    </form>
  </onboarding-base-modal>
</template>

<script>
import { required, minLength, helpers } from 'vuelidate/lib/validators';
import { isPossiblePhoneNumber } from 'libphonenumber-js';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { validationMixin } from 'vuelidate';
import { mapGetters } from 'vuex';

import alertMixin from 'shared/mixins/alertMixin';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import FormInput from 'v3/components/Form/Input.vue';
import FormTextArea from 'v3/components/Form/Textarea.vue';
import OnboardingBaseModal from 'v3/views/onboarding/BaseModal.vue';
import SubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import PhoneInput from 'dashboard/components/widgets/forms/PhoneInput.vue';
const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB

export default {
  components: {
    WithLabel,
    FormInput,
    SubmitButton,
    FormTextArea,
    PhoneInput,
    OnboardingBaseModal,
  },
  mixins: [validationMixin, alertMixin],
  data() {
    return {
      avatarUrl: '',
      avatarFile: '',
      fullName: '',
      displayName: '',
      phoneNumber: '',
      signature: '',
      phoneCode: '',
    };
  },
  validations: {
    fullName: {
      required,
      minLength: minLength(2),
    },
    displayName: {
      minLength: minLength(2),
    },
    phoneNumber: {
      validOrNoPhone: value =>
        !helpers.req(value) || isPossiblePhoneNumber(value, 'US'),
    },
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      currentUser: 'getCurrentUser',
    }),
    intelligentData() {
      const { clearbit_data: data } = this.getAccount;
      return data;
    },
  },
  watch: {
    currentUser(user = {}) {
      if (!user.name && this.intelligentData && this.intelligentData.name) {
        this.fullName = this.intelligentData.name;
      }
    },
  },
  mounted() {
    const {
      name: fullName,
      avatar_url: avatarUrl,
      display_name: displayName,
      message_signature: signature,
      custom_attributes: { phone_number: phoneNumber } = {},
    } = this.currentUser || {};

    if (!fullName && this.intelligentData && this.intelligentData.name) {
      this.fullName = this.intelligentData.name;
    } else {
      this.fullName = fullName;
    }

    this.phoneNumber = phoneNumber;
    this.displayName = displayName;
    this.signature = signature;
    this.avatarUrl = avatarUrl;
  },

  methods: {
    async onSubmit(event) {
      event.stopPropagation();
      event.preventDefault();
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      const phoneNumberWithCode = `${this.phoneCode} ${this.phoneNumber}`;
      try {
        await this.$store.dispatch('updateProfile', {
          name: this.fullName,
          displayName: this.displayName,
          phone_number: phoneNumberWithCode,
          avatar: this.avatarFile,
          message_signature: this.signature || '',
        });
        this.showAlert(this.$t('START_ONBOARDING.PROFILE.SUBMIT.SUCCESS'));

        document.startViewTransition(() => {
          this.$router.push({ name: 'onboarding_setup_company' });
        });
      } catch (error) {
        this.showAlert(this.$t('START_ONBOARDING.PROFILE.SUBMIT.ERROR'));
      }
    },
    async deleteAvatar(event) {
      event.stopPropagation();
      event.preventDefault();
      this.avatarUrl = '';
      this.avatarFile = '';
      this.$refs.imageUpload.value = '';
    },
    handleImageUpload() {
      const file = this.$refs.imageUpload.files[0];
      if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
        this.avatarFile = file;
        this.avatarUrl = URL.createObjectURL(file);
      } else {
        this.showAlert(
          this.$t(
            'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SIZE_ERROR',
            {
              size: MAXIMUM_FILE_UPLOAD_SIZE,
            }
          )
        );
      }

      this.$refs.imageUpload.value = '';
    },
    onFileBrowse(event) {
      event.preventDefault();
      const fileInputElement = this.$refs.imageUpload;
      fileInputElement.click();
    },
    setPhoneCode(code) {
      this.phoneCode = code;
    },
  },
};
</script>
