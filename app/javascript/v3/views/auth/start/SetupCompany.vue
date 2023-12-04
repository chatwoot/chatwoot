<template>
  <modal-layout
    :title="$t('ONBOARDING.COMPANY.TITLE')"
    :body="$t('ONBOARDING.COMPANY.BODY')"
  >
    <form class="space-y-8">
      <div class="space-y-3">
        <form-input
          v-model="companyName"
          name="full_name"
          class="flex-1"
          :label="$t('ONBOARDING.COMPANY.COMPANY_NAME.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.COMPANY_NAME.PLACEHOLDER')"
          :error-message="$t('ONBOARDING.COMPANY.COMPANY_NAME.ERROR')"
        />
        <form-input
          v-model="timezone"
          name="timezone"
          class="flex-1"
          :label="$t('ONBOARDING.COMPANY.TIMEZONE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.TIMEZONE.PLACEHOLDER')"
        />
        <form-input
          v-model="locale"
          name="locale"
          class="flex-1"
          :label="$t('ONBOARDING.COMPANY.LOCALE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.LOCALE.PLACEHOLDER')"
        />
        <form-input
          v-model="companySize"
          name="company_size"
          class="flex-1"
          :label="$t('ONBOARDING.COMPANY.SIZE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.SIZE.PLACEHOLDER')"
        />
      </div>
      <submit-button
        button-class="text-sm"
        :button-text="$t('ONBOARDING.COMPANY.SUBMIT')"
      />
    </form>
  </modal-layout>
</template>

<script>
import FormInput from '../../../components/Form/Input.vue';
import SubmitButton from '../../../components/Button/SubmitButton';
import ModalLayout from './components/ModalLayout.vue';

export default {
  components: {
    FormInput,
    SubmitButton,
    ModalLayout,
  },
  data() {
    return {
      companyName: '',
      timezone: '',
      locale: '',
      companySize: '',
    };
  },
};
</script>
