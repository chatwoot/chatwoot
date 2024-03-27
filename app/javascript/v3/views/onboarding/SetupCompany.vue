<template>
  <onboarding-base-modal
    :title="$t('START_ONBOARDING.COMPANY.TITLE')"
    :subtitle="$t('START_ONBOARDING.COMPANY.BODY')"
  >
    <div class="space-y-3">
      <form-input
        v-model="companyName"
        icon="building-bank"
        name="companyName"
        spacing="compact"
        :has-error="$v.companyName.$error"
        :label="$t('START_ONBOARDING.COMPANY.COMPANY_NAME.LABEL')"
        :placeholder="$t('START_ONBOARDING.COMPANY.COMPANY_NAME.PLACEHOLDER')"
        :error-message="$t('START_ONBOARDING.COMPANY.COMPANY_NAME.ERROR')"
      />
      <form-select
        v-model="locale"
        name="locale"
        icon="local-language"
        :label="$t('START_ONBOARDING.COMPANY.LOCALE.LABEL')"
        :placeholder="$t('START_ONBOARDING.COMPANY.LOCALE.PLACEHOLDER')"
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
        :label="$t('START_ONBOARDING.COMPANY.TIMEZONE.LABEL')"
        :placeholder="$t('START_ONBOARDING.COMPANY.TIMEZONE.PLACEHOLDER')"
      >
        <option
          v-for="zone in timeZones"
          :key="zone.label"
          :value="zone.value"
          :selected="timezone === zone.value"
        >
          {{ zone.label }}
        </option>
      </form-select>
      <form-radio-tags
        v-model="industry"
        name="industry"
        :label="$t('START_ONBOARDING.COMPANY.INDUSTRY.LABEL')"
        :placeholder="$t('START_ONBOARDING.COMPANY.SIZE.PLACEHOLDER')"
        :options="industryOptions"
      />
      <form-radio-tags
        v-model="companySize"
        name="companySize"
        :label="$t('START_ONBOARDING.COMPANY.SIZE.LABEL')"
        :placeholder="$t('START_ONBOARDING.COMPANY.SIZE.PLACEHOLDER')"
        :options="companySizeOptions"
      />
    </div>
    <submit-button
      button-class="flex justify-center w-full text-sm text-center"
      :button-text="$t('START_ONBOARDING.COMPANY.SUBMIT.BUTTON')"
      @click="onSubmit"
    />
  </onboarding-base-modal>
</template>

<script>
import FormInput from 'v3/components/Form/Input.vue';
import FormSelect from 'v3/components/Form/Select.vue';
import FormRadioTags from 'v3/components/Form/RadioTags.vue';
import OnboardingBaseModal from 'v3/views/onboarding/BaseModal.vue';
import { required, minLength } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';

import SubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import { timeZoneOptions } from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import {
  getBrowserLocale,
  getIANATimezoneFromOffset,
} from 'v3/helpers/BrowserHelper';
import {
  findMatchingOption,
  findIndustryOptions,
  companySizeOptions,
  industryOptions,
} from 'v3/helpers/OnboardingHelper';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
export default {
  components: {
    FormInput,
    SubmitButton,
    FormSelect,
    FormRadioTags,
    OnboardingBaseModal,
  },
  mixins: [configMixin, alertMixin],
  data() {
    return {
      companyName: '',
      timezone: '',
      locale: '',
      companySize: '',
      industry: '',
      companySizeOptions,
      industryOptions,
    };
  },
  validations: {
    companyName: {
      required,
      minLength: minLength(2),
    },
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      currentAccountId: 'getCurrentAccountId',
    }),
    accountDetails() {
      return this.getAccount(this.currentAccountId);
    },
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
    timeZones() {
      return [...timeZoneOptions()];
    },
    accountAttributes() {
      const { name: companyName, locale } = this.accountDetails;
      const {
        company_size: companySize,
        industry,
        timezone,
      } = this.accountDetails.custom_attributes || {};

      return { companyName, locale, companySize, industry, timezone };
    },
  },

  watch: {
    locale(val) {
      this.setLocale(val);
    },
    accountDetails() {
      this.initFormData();
    },
  },
  mounted() {
    this.initFormData();
  },

  methods: {
    async onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      const { industry } = this.accountAttributes;
      const industryValue =
        this.industry === 'Other' ? industry : this.industry;

      try {
        await this.$store.dispatch('accounts/update', {
          name: this.companyName,
          timezone: this.timezone,
          locale: this.locale,
          company_size: this.companySize,
          industry: industryValue,
          onboarding_step: 'account_update',
        });

        this.showAlert(this.$t('START_ONBOARDING.COMPANY.SUBMIT.SUCCESS'));
        this.$router.push({ name: 'onboarding_invite_team' });
      } catch (error) {
        this.showAlert(this.$t('START_ONBOARDING.COMPANY.SUBMIT.ERROR'));
      }
    },
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
    setLocaleFromBrowser() {
      const locale = getBrowserLocale(this.enabledLanguages);

      if (locale) {
        this.locale = locale;
        this.setLocale(locale);
      }
    },
    initFormData() {
      if (!this.accountDetails) return;

      const { companyName, industry, companySize, timezone, locale } =
        this.accountAttributes;

      this.companyName = companyName;
      this.industry = findIndustryOptions(industry);
      this.companySize = companySize;
      this.locale = locale || this.setLocaleFromBrowser();

      const browserTimezone = getIANATimezoneFromOffset();
      const allTimezones = this.timeZones.map(zone => zone.value);
      this.timezone = findMatchingOption(
        timezone,
        allTimezones,
        browserTimezone
      );

      this.setLocale(locale);
    },
  },
};
</script>
