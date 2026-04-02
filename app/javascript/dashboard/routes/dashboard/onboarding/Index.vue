<script setup>
import { ref, computed, nextTick, onMounted, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert, useTrack } from 'dashboard/composables';
import { ONBOARDING_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import OnboardingLayout from './OnboardingLayout.vue';
import OnboardingSection from './OnboardingSection.vue';
import OnboardingFormRow from './OnboardingFormRow.vue';
import OnboardingFormSelect from './OnboardingFormSelect.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import {
  COMPANY_SIZE_OPTIONS,
  INDUSTRY_OPTIONS,
  REFERRAL_SOURCE_OPTIONS,
  USER_ROLE_OPTIONS,
} from './constants';

const { t } = useI18n();
const router = useRouter();
const { accountId, currentAccount, updateAccount } = useAccount();
const { enabledLanguages } = useConfig();
const currentUser = useMapGetter('getCurrentUser');

const userRole = ref('');
const website = ref('');
const locale = ref('en');
const timezone = ref('');
const companySize = ref('');
const industry = ref('');
const referralSource = ref('');
const isSubmitting = ref(false);
const isEditingWebsite = ref(false);
const websiteInput = ref(null);
const showErrorOnFields = ref(false);

const validationRules = {
  userRole: {},
  website: {},
  locale: {},
  timezone: {},
  companySize: {},
  industry: {},
  referralSource: {},
};

const v$ = useVuelidate(validationRules, {
  userRole,
  website,
  locale,
  timezone,
  companySize,
  industry,
  referralSource,
});

const userName = computed(() => currentUser.value?.name || '');
const userEmail = computed(() => currentUser.value?.email || '');
const accountName = computed(() => currentAccount.value?.name || '');
const isEnriching = computed(
  () =>
    currentAccount.value?.custom_attributes?.onboarding_step === 'enrichment'
);
const companyLogo = computed(() => {
  const logos = currentAccount.value?.custom_attributes?.brand_info?.logos;
  if (!logos?.length) return '';
  const square = logos.find(l => l.resolution?.aspect_ratio === 1);
  return (square || logos[0])?.url || '';
});

const languageOptions = computed(() => {
  const langs = [...(enabledLanguages || [])];
  return langs
    .sort((a, b) => a.iso_639_1_code.localeCompare(b.iso_639_1_code))
    .map(l => ({ value: l.iso_639_1_code, label: l.name }));
});

const timezoneOptions = computed(() => {
  try {
    return Intl.supportedValuesOf('timeZone').map(tz => ({
      value: tz,
      label: tz.replace(/_/g, ' '),
    }));
  } catch {
    return [];
  }
});

// Best-effort match browser language to enabled Chatwoot locales.
// Tries exact match first (e.g. 'pt_BR'), then base language (e.g. 'pt'),
// falls back to account locale or 'en'.
const detectBestLocale = () => {
  const codes = (enabledLanguages || []).map(l => l.iso_639_1_code);
  const browserLang = navigator.language?.replace('-', '_');
  if (!browserLang) return 'en';

  if (codes.includes(browserLang)) return browserLang;
  const base = browserLang.split('_')[0];
  if (codes.includes(base)) return base;

  return 'en';
};

// Snapshot of auto-populated values to detect user edits at submit time
const initialValues = ref({});

const snapshotInitialValues = () => {
  initialValues.value = {
    website: website.value,
    company_size: companySize.value,
    industry: industry.value,
  };
};

const populateFormFields = () => {
  if (!currentAccount.value) return;

  const brandInfo = currentAccount.value.custom_attributes?.brand_info;

  locale.value = detectBestLocale();
  website.value = currentAccount.value.domain || brandInfo?.domain || '';
  timezone.value =
    currentAccount.value.custom_attributes?.timezone ||
    Intl.DateTimeFormat().resolvedOptions().timeZone ||
    '';
  companySize.value =
    currentAccount.value.custom_attributes?.company_size || '';
  industry.value =
    currentAccount.value.custom_attributes?.industry ||
    brandInfo?.industries?.[0]?.industry ||
    '';
  referralSource.value =
    currentAccount.value.custom_attributes?.referral_source || '';

  snapshotInitialValues();
};

onMounted(() => {
  populateFormFields();
  useTrack(ONBOARDING_EVENTS.ACCOUNT_DETAILS_VISITED);
});

watch(isEnriching, newVal => {
  if (!newVal) populateFormFields();
});

const enableWebsiteEditing = () => {
  isEditingWebsite.value = true;
  nextTick(() => websiteInput.value?.focus());
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    useAlert(t('ONBOARDING_NEXT.VALIDATION_ERROR'));
    showErrorOnFields.value = true;
    setTimeout(() => {
      showErrorOnFields.value = false;
    }, 600);
    return;
  }

  isSubmitting.value = true;
  try {
    await updateAccount({
      name: accountName.value,
      locale: locale.value,
      domain: website.value,
      industry: industry.value,
      company_size: companySize.value,
      timezone: timezone.value,
      referral_source: referralSource.value,
    });

    const init = initialValues.value;
    const enrichableFields = {
      website: website.value,
      company_size: companySize.value,
      industry: industry.value,
    };

    useTrack(ONBOARDING_EVENTS.ACCOUNT_DETAILS_COMPLETED, {
      has_enriched_data: Boolean(
        currentAccount.value?.custom_attributes?.brand_info
      ),
      fields_changed: Object.entries(enrichableFields)
        .filter(([key, val]) => val !== init[key])
        .map(([key]) => key),
      user_role: userRole.value,
      company_size: companySize.value,
      industry: industry.value,
      referral_source: referralSource.value,
    });

    useAlert(t('ONBOARDING_NEXT.SUCCESS'));
    router.push({ name: 'home', params: { accountId: accountId.value } });
  } catch {
    useAlert(t('ONBOARDING_NEXT.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <OnboardingLayout
      :greeting="t('ONBOARDING_NEXT.GREETING', { name: userName })"
      :subtitle="t('ONBOARDING_NEXT.SUBTITLE')"
      :continue-label="t('ONBOARDING_NEXT.CONTINUE')"
      :is-loading="isSubmitting"
    >
      <OnboardingSection
        :title="t('ONBOARDING_NEXT.YOUR_DETAILS')"
        icon="i-lucide-user"
      >
        <div class="flex items-center gap-2 px-3 py-3">
          <Avatar :name="userName" :size="16" rounded-full />
          <span class="text-sm font-medium text-n-slate-12">
            {{ userName }}
          </span>
        </div>
        <OnboardingFormRow
          :title="t('ONBOARDING_NEXT.FIELDS.EMAIL')"
          icon="i-lucide-mail"
        >
          <div class="flex items-center justify-end gap-1.5">
            <span class="text-sm text-n-slate-12">{{ userEmail }}</span>
            <Icon
              v-tooltip="t('ONBOARDING_NEXT.EMAIL_VERIFIED')"
              icon="i-lucide-circle-check"
              class="size-4 text-n-teal-11 flex-shrink-0"
            />
          </div>
        </OnboardingFormRow>
        <OnboardingFormRow
          :title="t('ONBOARDING_NEXT.FIELDS.YOUR_ROLE')"
          icon="i-lucide-user"
        >
          <OnboardingFormSelect
            v-model="userRole"
            :has-error="showErrorOnFields && v$.userRole.$error"
            :options="USER_ROLE_OPTIONS"
            :placeholder="t('ONBOARDING_NEXT.PLACEHOLDERS.SELECT_ROLE')"
          />
        </OnboardingFormRow>
      </OnboardingSection>

      <OnboardingSection
        :title="t('ONBOARDING_NEXT.COMPANY_DETAILS')"
        icon="i-lucide-briefcase-business"
      >
        <div
          v-if="isEnriching"
          class="flex items-center justify-center gap-3 py-8"
        >
          <Spinner :size="16" class="text-n-blue-10" />
          <span class="text-sm text-n-slate-11">
            {{ t('ONBOARDING_NEXT.SETTING_UP') }}
          </span>
        </div>
        <template v-else>
          <div class="flex items-center gap-2 px-3 py-3">
            <img
              v-if="companyLogo"
              :src="companyLogo"
              :alt="accountName"
              class="size-4 object-contain"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ accountName }}
            </span>
          </div>
          <OnboardingFormRow
            :title="t('ONBOARDING_NEXT.FIELDS.WEBSITE')"
            icon="i-lucide-globe"
          >
            <div class="flex items-center justify-end gap-2">
              <input
                ref="websiteInput"
                v-model="website"
                type="text"
                :readonly="!isEditingWebsite"
                :placeholder="t('ONBOARDING_NEXT.PLACEHOLDERS.ENTER_WEBSITE')"
                class="reset-base w-auto text-sm text-right border-0 px-1 py-0.5 -my-0.5 mx-0 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-0 rounded"
                :class="[
                  isEditingWebsite
                    ? 'bg-n-slate-3'
                    : 'bg-transparent cursor-default',
                  { 'animate-shake': showErrorOnFields && v$.website.$error },
                ]"
                @keydown.enter.prevent="websiteInput?.blur()"
                @blur="isEditingWebsite = false"
              />
              <button
                type="button"
                class="flex-shrink-0 p-0 flex items-center"
                @click="enableWebsiteEditing"
              >
                <Icon icon="i-lucide-pencil" class="size-3.5 text-n-slate-9" />
              </button>
            </div>
          </OnboardingFormRow>
          <OnboardingFormRow
            :title="t('ONBOARDING_NEXT.FIELDS.LANGUAGE')"
            icon="i-lucide-languages"
          >
            <OnboardingFormSelect
              v-model="locale"
              :has-error="showErrorOnFields && v$.locale.$error"
              :options="languageOptions"
            />
          </OnboardingFormRow>
          <OnboardingFormRow
            :title="t('ONBOARDING_NEXT.FIELDS.TIMEZONE')"
            icon="i-lucide-clock"
          >
            <OnboardingFormSelect
              v-model="timezone"
              :has-error="showErrorOnFields && v$.timezone.$error"
              :options="timezoneOptions"
              :placeholder="t('ONBOARDING_NEXT.PLACEHOLDERS.SELECT_TIMEZONE')"
            />
          </OnboardingFormRow>
          <OnboardingFormRow
            :title="t('ONBOARDING_NEXT.FIELDS.INDUSTRY')"
            icon="i-lucide-factory"
          >
            <OnboardingFormSelect
              v-model="industry"
              :has-error="showErrorOnFields && v$.industry.$error"
              :options="INDUSTRY_OPTIONS"
              :placeholder="t('ONBOARDING_NEXT.PLACEHOLDERS.SELECT_INDUSTRY')"
            />
          </OnboardingFormRow>
          <OnboardingFormRow
            :title="t('ONBOARDING_NEXT.FIELDS.COMPANY_SIZE')"
            icon="i-lucide-users"
          >
            <OnboardingFormSelect
              v-model="companySize"
              :has-error="showErrorOnFields && v$.companySize.$error"
              :options="COMPANY_SIZE_OPTIONS"
              :placeholder="
                t('ONBOARDING_NEXT.PLACEHOLDERS.SELECT_COMPANY_SIZE')
              "
            />
          </OnboardingFormRow>
          <OnboardingFormRow
            :title="t('ONBOARDING_NEXT.FIELDS.REFERRAL_SOURCE')"
            icon="i-lucide-megaphone"
          >
            <OnboardingFormSelect
              v-model="referralSource"
              :has-error="showErrorOnFields && v$.referralSource.$error"
              :options="REFERRAL_SOURCE_OPTIONS"
              :placeholder="
                t('ONBOARDING_NEXT.PLACEHOLDERS.SELECT_REFERRAL_SOURCE')
              "
            />
          </OnboardingFormRow>
        </template>
      </OnboardingSection>
    </OnboardingLayout>
  </form>
</template>
