<template>
  <onboarding-layout
    :title="$t('ONBOARDING.PROFILE.TITLE')"
    :body="$t('ONBOARDING.PROFILE.BODY')"
    current-step="profile"
  >
    <form class="mt-8 space-y-8">
      <div class="space-y-3">
        <form-input
          v-model="fullName"
          name="full_name"
          spacing="compact"
          :label="$t('ONBOARDING.PROFILE.FULL_NAME.LABEL')"
          :placeholder="$t('ONBOARDING.PROFILE.FULL_NAME.PLACEHOLDER')"
          :error-message="$t('ONBOARDING.PROFILE.FULL_NAME.ERROR')"
        />
        <form-input
          v-model="displayName"
          name="display_name"
          spacing="compact"
          :label="$t('ONBOARDING.PROFILE.DISPLAY_NAME.LABEL')"
          :placeholder="$t('ONBOARDING.PROFILE.DISPLAY_NAME.PLACEHOLDER')"
        />
        <form-input
          v-model="phoneNumber"
          name="phone_number"
          spacing="compact"
          :label="$t('ONBOARDING.PROFILE.PHONE_NUMBER.LABEL')"
          :placeholder="$t('ONBOARDING.PROFILE.PHONE_NUMBER.PLACEHOLDER')"
        />
        <form-text-area
          v-model="signature"
          name="signature"
          spacing="compact"
          :allow-resize="false"
          :label="$t('ONBOARDING.PROFILE.SIGNATURE.LABEL')"
          :placeholder="$t('ONBOARDING.PROFILE.SIGNATURE.PLACEHOLDER')"
        />
      </div>
      <submit-button
        button-class="flex justify-center w-full text-sm text-center"
        :button-text="$t('ONBOARDING.PROFILE.SUBMIT')"
      />
    </form>
  </onboarding-layout>
</template>

<script>
import FormInput from '../../../components/form/Input.vue';
import FormTextArea from '../../../components/form/TextArea.vue';
import SubmitButton from '../../../components/buttons/FormSubmitButton.vue';
import OnboardingLayout from './components/OnboardingLayout.vue';

export default {
  components: {
    FormInput,
    SubmitButton,
    OnboardingLayout,
    FormTextArea,
  },
  data() {
    return {
      fullName: '',
      displayName: '',
      phoneNumber: '',
      signature: '',
    };
  },
};
</script>
