<script>
import md5 from 'md5';
import { ref, computed, onMounted, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, helpers } from '@vuelidate/validators';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import parsePhoneNumber from 'libphonenumber-js';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';

import WithLabel from 'v3/components/Form/WithLabel.vue';
import FormInput from 'v3/components/Form/Input.vue';
import OnboardingBaseModal from 'v3/views/onboarding/BaseModal.vue';
import SubmitButton from 'dashboard/components-next/button/Button.vue';

const MAXIMUM_FILE_UPLOAD_SIZE = 4;

export default {
  components: {
    WithLabel,
    FormInput,
    SubmitButton,
    OnboardingBaseModal,
  },
  setup() {
    const store = useStore();
    const router = useRouter();
    // const { t } = useI18n();

    const avatarUrl = ref('');
    const avatarFile = ref('');
    const fullName = ref('');
    const displayName = ref('');
    const phoneNumber = ref('');
    const signature = ref('');

    const validations = {
      fullName: {
        required,
        minLength: minLength(2),
      },
      displayName: {
        required,
        minLength: minLength(2),
      },
      phoneNumber: {
        validOrNoPhone: value =>
          !helpers.req(value) || parsePhoneNumber(value, 'US').isValid(),
      },
    };

    const v$ = useVuelidate(validations, {
      fullName,
      displayName,
      phoneNumber,
    });

    const currentUser = computed(() => store.getters.getCurrentUser);
    const getAccount = computed(() => store.getters['accounts/getAccount']);
    const intelligentData = computed(() => {
      const { clearbit_data: data } = getAccount.value;
      return data;
    });

    onMounted(() => {
      const {
        email,
        name: fullNameValue,
        display_name: displayNameValue,
        message_signature: signatureValue,
        custom_attributes: { phone_number: phoneNumberValue } = {},
      } = currentUser.value || {};

      if (
        !fullNameValue &&
        intelligentData.value &&
        intelligentData.value.name
      ) {
        fullName.value = intelligentData.value.name;
      } else {
        fullName.value = fullNameValue;
      }

      phoneNumber.value = phoneNumberValue;
      displayName.value = displayNameValue;
      signature.value = signatureValue;
      avatarUrl.value = `https://gravatar.com/avatar/${md5(email)}?s=400&d=robohash&r=x`;
    });

    watch(currentUser, (user = {}) => {
      if (!user.name && intelligentData.value && intelligentData.value.name) {
        fullName.value = intelligentData.value.name;
      }
    });

    const onSubmit = async event => {
      event.stopPropagation();
      event.preventDefault();
      v$.value.$touch();
      if (v$.value.$invalid) {
        return;
      }
      try {
        await store.dispatch('updateProfile', {
          name: fullName.value,
          displayName: displayName.value,
          phone_number: phoneNumber.value,
          avatar: avatarFile.value,
          message_signature: signature.value || '',
        });

        await store.dispatch('accounts/update', {
          onboarding_step: 'add-agent',
        });
        router.push({ name: 'onboarding_add_agent' });
      } catch (error) {
        useAlert(error.message);
      }
    };

    const deleteAvatar = event => {
      event.stopPropagation();
      event.preventDefault();
      const { email } = currentUser.value;
      avatarUrl.value = `https://gravatar.com/avatar/${md5(email)}?s=400&d=robohash&r=x`;
      avatarFile.value = '';
      const imageUpload = document.getElementById('user_avatar');
      if (imageUpload) imageUpload.value = '';
    };

    const handleImageUpload = event => {
      const file = event.target.files[0];
      if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
        avatarFile.value = file;
        avatarUrl.value = URL.createObjectURL(file);
      } else {
        // showAlert(
        //   t(
        //     'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SIZE_ERROR',
        //     {
        //       size: MAXIMUM_FILE_UPLOAD_SIZE,
        //     }
        //   )
        // );
      }
      event.target.value = '';
    };

    const onFileBrowse = event => {
      event.preventDefault();
      const fileInputElement = document.getElementById('user_avatar');
      fileInputElement.click();
    };

    // const showAlert = message => {
    //   store.dispatch('showAlert', message);
    // };

    return {
      avatarUrl,
      avatarFile,
      fullName,
      displayName,
      phoneNumber,
      signature,
      $v: v$,
      onSubmit,
      deleteAvatar,
      handleImageUpload,
      onFileBrowse,
    };
  },
};
</script>

<template>
  <OnboardingBaseModal
    :title="$t('START_ONBOARDING.PROFILE.TITLE')"
    :subtitle="$t('START_ONBOARDING.PROFILE.BODY')"
  >
    <form class="space-y-6" @submit="onSubmit">
      <div class="space-y-6">
        <div>
          <WithLabel name="user_avatar">
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
                :has-border
              />
              <div
                v-else
                class="flex items-center justify-center w-10 h-10 rounded-xl bg-slate-200"
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M18.8574 20.5714H5.14307V18.8571C5.14307 17.7205 5.5946 16.6304 6.39832 15.8267C7.20205 15.0229 8.29214 14.5714 9.42878 14.5714H14.5716C15.7083 14.5714 16.7984 15.0229 17.6021 15.8267C18.4058 16.6304 18.8574 17.7205 18.8574 18.8571V20.5714ZM12.0002 12.8571C11.3248 12.8571 10.6561 12.7241 10.0321 12.4656C9.40816 12.2072 8.84122 11.8284 8.36366 11.3508C7.8861 10.8733 7.50728 10.3063 7.24883 9.68235C6.99038 9.05839 6.85735 8.38964 6.85735 7.71427C6.85735 7.0389 6.99038 6.37014 7.24883 5.74618C7.50728 5.12222 7.8861 4.55528 8.36366 4.07772C8.84122 3.60016 9.40816 3.22134 10.0321 2.96289C10.6561 2.70444 11.3248 2.57141 12.0002 2.57141C13.3642 2.57141 14.6723 3.11325 15.6368 4.07772C16.6012 5.04219 17.1431 6.3503 17.1431 7.71427C17.1431 9.07824 16.6012 10.3863 15.6368 11.3508C14.6723 12.3153 13.3642 12.8571 12.0002 12.8571Z"
                    fill="#B9BBC6"
                  />
                </svg>
              </div>
              <input
                id="user_avatar"
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
          </WithLabel>
        </div>
        <FormInput
          v-model="fullName"
          name="full_name"
          spacing="compact"
          :has-error="$v.fullName.$error"
          :label="$t('START_ONBOARDING.PROFILE.FULL_NAME.LABEL')"
          :placeholder="$t('START_ONBOARDING.PROFILE.FULL_NAME.PLACEHOLDER')"
          :error-message="$t('START_ONBOARDING.PROFILE.FULL_NAME.ERROR')"
        />
        <FormInput
          v-model="displayName"
          name="display_name"
          spacing="compact"
          :has-error="$v.displayName.$error"
          :label="$t('START_ONBOARDING.PROFILE.DISPLAY_NAME.LABEL')"
          :placeholder="$t('START_ONBOARDING.PROFILE.DISPLAY_NAME.PLACEHOLDER')"
          :error-message="$t('START_ONBOARDING.PROFILE.DISPLAY_NAME.ERROR')"
        />
        <!-- <form-input
          v-model="phoneNumber"
          name="phone_number"
          spacing="compact"
          :has-error="$v.phoneNumber.$error"
          :label="$t('START_ONBOARDING.PROFILE.PHONE_NUMBER.LABEL')"
          :placeholder="$t('START_ONBOARDING.PROFILE.PHONE_NUMBER.PLACEHOLDER')"
          :error-message="$t('CONTACT_FORM.FORM.PHONE_NUMBER.ERROR')"
          @blur="$v.phoneNumber.$touch"
        />
        <form-text-area
          v-model="signature"
          name="signature"
          spacing="compact"
          :allow-resize="false"
          :label="$t('START_ONBOARDING.PROFILE.SIGNATURE.LABEL')"
          :placeholder="$t('START_ONBOARDING.PROFILE.SIGNATURE.PLACEHOLDER')"
        /> -->
      </div>
      <SubmitButton
        button-class="flex justify-center w-full text-sm text-center"
        :label="$t('START_ONBOARDING.PROFILE.SUBMIT.BUTTON')"
      />
    </form>
  </OnboardingBaseModal>
</template>
