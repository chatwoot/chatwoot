<template>
  <modal-layout
    :title="$t('ONBOARDING.COMPANY.TITLE')"
    :body="$t('ONBOARDING.COMPANY.BODY')"
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
        <with-label
          name="locale"
          :label="$t('ONBOARDING.COMPANY.LOCALE.LABEL')"
        >
          <select
            v-model="locale"
            name="locale"
            :class="{
              'text-slate-400': !locale,
              'text-slate-900 dark:text-slate-100': locale,
            }"
            class="block w-full px-3 py-2 border-0 rounded-md shadow-sm outline-none appearance-none ring-1 ring-inset placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-woot-500 sm:text-sm sm:leading-6 dark:bg-slate-700 dark:ring-slate-600 dark:focus:ring-woot-500 ring-slate-200"
          >
            <option value="" disabled selected class="hidden">
              {{ $t('ONBOARDING.COMPANY.LOCALE.PLACEHOLDER') }}
            </option>
            <option
              v-for="lang in languagesSortedByCode"
              :key="lang.iso_639_1_code"
              :value="lang.iso_639_1_code"
            >
              {{ lang.name }}
            </option>
          </select>
        </with-label>
        <with-label
          name="companySize"
          :label="$t('ONBOARDING.COMPANY.SIZE.LABEL')"
        >
          <select
            v-model="companySize"
            name="companySize"
            :class="{
              'text-slate-400': !companySize,
              'text-slate-900 dark:text-slate-100': companySize,
            }"
            class="block w-full px-3 py-2 border-0 rounded-md shadow-sm outline-none appearance-none ring-1 ring-inset text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-woot-500 sm:text-sm sm:leading-6 dark:bg-slate-700 dark:ring-slate-600 dark:focus:ring-woot-500 ring-slate-200"
          >
            <option value="" disabled selected class="hidden">
              {{ $t('ONBOARDING.COMPANY.SIZE.PLACEHOLDER') }}
            </option>
            <option
              v-for="sizeOption in companySizeOptions"
              :key="sizeOption.value"
              :value="sizeOption.value"
            >
              {{ sizeOption.label }}
            </option>
          </select>
        </with-label>
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
import WithLabel from '../../../components/Form/WithLabel.vue';
import SubmitButton from '../../../components/Button/SubmitButton';
import ModalLayout from './components/ModalLayout.vue';
import configMixin from 'shared/mixins/configMixin';

export default {
  components: {
    FormInput,
    SubmitButton,
    ModalLayout,
    WithLabel,
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
        { value: '5001+', label: '5001+' },
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
