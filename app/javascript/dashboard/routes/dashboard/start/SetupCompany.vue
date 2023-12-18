<template>
  <modal-layout
    :title="$t('ONBOARDING.COMPANY.TITLE')"
    :body="$t('ONBOARDING.COMPANY.BODY')"
    current-step="company"
  >
    <form class="space-y-8">
      <div class="space-y-3">
        <form-input
          v-model="companyName"
          name="companyName"
          spacing="compact"
          :label="$t('ONBOARDING.COMPANY.COMPANY_NAME.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.COMPANY_NAME.PLACEHOLDER')"
          :error-message="$t('ONBOARDING.COMPANY.COMPANY_NAME.ERROR')"
        />
        <form-input
          v-model="industry"
          name="industry"
          spacing="compact"
          :label="$t('ONBOARDING.COMPANY.INDUSTRY.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.INDUSTRY.PLACEHOLDER')"
        />
        <form-input
          v-model="timezone"
          name="timezone"
          spacing="compact"
          :label="$t('ONBOARDING.COMPANY.TIMEZONE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.TIMEZONE.PLACEHOLDER')"
        />
        <form-select
          v-model="locale"
          name="locale"
          :label="$t('ONBOARDING.COMPANY.LOCALE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.LOCALE.PLACEHOLDER')"
        >
          <option
            v-for="lang in languagesSortedByCode"
            :key="lang.iso_639_1_code"
            :value="lang.iso_639_1_code"
          >
            {{ lang.name }}
          </option>
        </form-select>
        <form-select
          v-model="companySize"
          name="companySize"
          :label="$t('ONBOARDING.COMPANY.SIZE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.SIZE.PLACEHOLDER')"
          :options="companySizeOptions"
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
import FormInput from '../../../components/form/Input.vue';
import FormSelect from '../../../components/form/Select.vue';
import SubmitButton from '../../../components/buttons/FormSubmitButton.vue';
import ModalLayout from './components/ModalLayout.vue';
import configMixin from 'shared/mixins/configMixin';

export default {
  components: {
    FormInput,
    SubmitButton,
    ModalLayout,
    FormSelect,
  },
  mixins: [configMixin],
  data() {
    return {
      companyName: '',
      timezone: '',
      locale: '',
      companySize: '',
      industry: '',
      companySizeOptions: [
        { value: '1-10', label: '1-10' },
        { value: '11-50', label: '11-50' },
        { value: '51-200', label: '51-200' },
        { value: '201-500', label: '201-500' },
        { value: '501-1000', label: '501-1000' },
        { value: '1001-5000', label: '1001-5000' },
        { value: '5001+', label: 'Over 5000' },
      ],
    };
  },
  computed: {
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
  },
};
</script>
