<template>
  <onboarding-layout
    :intro="$t('ONBOARDING.PROFILE.INTRO')"
    :title="$t('ONBOARDING.COMPANY.TITLE')"
    :body="$t('ONBOARDING.COMPANY.BODY')"
    current-step="company"
  >
    <form class="space-y-8" @submit.prevent="onSubmit">
      <div class="space-y-3">
        <form-input
          v-model="companyName"
          icon="building-bank"
          name="companyName"
          spacing="compact"
          :has-error="$v.companyName.$error"
          :label="$t('ONBOARDING.COMPANY.COMPANY_NAME.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.COMPANY_NAME.PLACEHOLDER')"
          :error-message="$t('ONBOARDING.COMPANY.COMPANY_NAME.ERROR')"
        />
        <form-select
          v-model="locale"
          name="locale"
          icon="local-language"
          :label="$t('ONBOARDING.COMPANY.LOCALE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.LOCALE.PLACEHOLDER')"
        >
          <option
            v-for="lang in languagesSortedByCode"
            :key="lang.iso_639_1_code"
            :value="lang.iso_639_1_code"
            :selected="locale === lang.iso_639_1_code"
          >
            {{ lang.name }}
          </option>
        </form-select>
        <form-select
          v-model="timezone"
          name="timezone"
          icon="globe-clock"
          spacing="compact"
          :label="$t('ONBOARDING.COMPANY.TIMEZONE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.TIMEZONE.PLACEHOLDER')"
        >
          <option
            v-for="zone in timeZones"
            :key="zone.label"
            :value="zone.value"
            :selected="timezone === zone.value"
          >
            {{ zone.value }}
          </option>
        </form-select>
        <form-radio-tags
          v-model="industry"
          name="industry"
          :label="$t('ONBOARDING.COMPANY.INDUSTRY.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.SIZE.PLACEHOLDER')"
          :options="industryOptions"
        />
        <form-radio-tags
          v-model="companySize"
          name="companySize"
          :label="$t('ONBOARDING.COMPANY.SIZE.LABEL')"
          :placeholder="$t('ONBOARDING.COMPANY.SIZE.PLACEHOLDER')"
          :options="companySizeOptions"
        />
      </div>
      <submit-button
        button-class="flex justify-center w-full text-sm text-center"
        :button-text="$t('ONBOARDING.COMPANY.SUBMIT.BUTTON')"
      />
    </form>
  </onboarding-layout>
</template>

<script>
import FormInput from 'v3/components/Form/Input.vue';
import FormSelect from 'v3/components/Form/Select.vue';
import FormRadioTags from 'v3/components/Form/RadioTags.vue';
import { required, minLength } from 'vuelidate/lib/validators';

import SubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import OnboardingLayout from './Layout.vue';
import { timeZoneOptions } from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
export default {
  components: {
    FormInput,
    SubmitButton,
    OnboardingLayout,
    FormSelect,
    FormRadioTags,
  },
  mixins: [configMixin, alertMixin],
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
        { value: '51-500', label: '51-500' },
        { value: '501-1000', label: '501-1000' },
        { value: '1001+', label: 'Over 1000' },
      ],
      industryOptions: [
        { value: 'information_technology', label: 'Information technology' },
        { value: 'finance', label: 'Finance' },
        { value: 'health_medicine', label: 'Health & Medicine' },
        { value: 'education', label: 'Education' },
        { value: 'other', label: 'Other' },
      ],
    };
  },
  validations: {
    companyName: {
      required,
      minLength: minLength(2),
    },
  },
  computed: {
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
    timeZones() {
      return [...timeZoneOptions()];
    },
  },
  watch: {
    locale(val) {
      this.setLocale(val);
    },
  },
  mounted() {
    const localeWithVariant = window.navigator.language.replace('-', '_');
    const localeWithoutVariant = localeWithVariant.split('_')[0];

    const { iso_639_1_code: locale } =
      this.enabledLanguages.find(
        lang =>
          lang.iso_639_1_code === localeWithVariant ||
          lang.iso_639_1_code === localeWithoutVariant
      ) || {};

    if (locale) {
      this.locale = locale;
      this.setLocale(locale);
    }

    this.setTimezone();
  },

  methods: {
    async onSubmit(event) {
      event.stopPropagation();
      event.preventDefault();
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        await this.$store.dispatch('updateProfile', {
          companyName: this.companyName,
          // phone
          // avatar
        });
        this.showAlert(this.$t('ONBOARDING.COMPANY.SUBMIT.SUCCESS'));
        this.$router.push({ name: 'onboarding_invite_team' });
      } catch (error) {
        this.showAlert(this.$t('ONBOARDING.COMPANY.SUBMIT.ERROR'));
      }
    },
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
    setTimezone() {
      this.timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    },
  },
};
</script>
