<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert, useTrack } from 'dashboard/composables';
import { ONBOARDING_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { frontendURL } from 'dashboard/helper/URLHelper';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import OnboardingLayout from './OnboardingLayout.vue';
import OnboardingSection from './OnboardingSection.vue';
import OnboardingFormRow from './OnboardingFormRow.vue';
import OnboardingFormSelect from './OnboardingFormSelect.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import {
  COMPANY_SIZE_OPTIONS,
  INDUSTRY_OPTIONS,
  REFERRAL_SOURCE_OPTIONS,
  USER_ROLE_OPTIONS,
} from './constants';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { accountId, currentAccount, updateAccount } = useAccount();
const { enabledLanguages } = useConfig();
const currentUser = useMapGetter('getCurrentUser');

const userRole = ref('');
const website = ref('');
const locale = ref('');
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
const enrichmentTimedOut = ref(false);
const isEnriching = computed(
  () =>
    !enrichmentTimedOut.value &&
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
  const accountLocale = currentAccount.value?.locale || 'en';
  if (!browserLang) return accountLocale;

  if (codes.includes(browserLang)) return browserLang;
  const base = browserLang.split('_')[0];
  if (codes.includes(base)) return base;

  return accountLocale;
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

// Idempotent: only fills empty fields, so late-arriving enrichment data
// populates untouched fields without clobbering user edits.
const populateFormFields = () => {
  const account = currentAccount.value;
  const attrs = account?.custom_attributes || {};
  const brandInfo = attrs.brand_info;

  if (!locale.value) locale.value = detectBestLocale();
  if (!website.value) {
    website.value = account?.domain || brandInfo?.domain || '';
  }
  if (!timezone.value) {
    timezone.value =
      attrs.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone || '';
  }
  if (!companySize.value) companySize.value = attrs.company_size || '';
  if (!industry.value) {
    industry.value =
      attrs.industry || brandInfo?.industries?.[0]?.industry || '';
  }
  if (!referralSource.value) referralSource.value = attrs.referral_source || '';

  snapshotInitialValues();
};

let enrichmentTimer = null;

const startEnrichmentTimer = () => {
  if (enrichmentTimer) clearTimeout(enrichmentTimer);
  enrichmentTimer = setTimeout(() => {
    enrichmentTimedOut.value = true;
    populateFormFields();
  }, 30000);
};

onMounted(() => {
  populateFormFields();
  useTrack(ONBOARDING_EVENTS.ACCOUNT_DETAILS_VISITED);
  if (isEnriching.value) startEnrichmentTimer();
});

onUnmounted(() => {
  if (enrichmentTimer) clearTimeout(enrichmentTimer);
});

watch(isEnriching, newVal => {
  if (newVal) {
    startEnrichmentTimer();
  } else {
    if (enrichmentTimer) clearTimeout(enrichmentTimer);
    populateFormFields();
  }
});

// Re-populate when account data arrives after mount, or when brand_info
// appears after enrichment. populateFormFields is idempotent so this is safe.
watch(
  () => currentAccount.value?.custom_attributes,
  () => populateFormFields()
);

const enableWebsiteEditing = () => {
  isEditingWebsite.value = true;
  nextTick(() => websiteInput.value?.focus());
};

const handleWebsiteEnter = () => {
  websiteInput.value?.blur();
};

const handleSubmit = async () => {
  // Block submit while enrichment is still running so users can't bypass
  // the form with empty values — the controller would otherwise clear
  // onboarding_step and persist incomplete data.
  if (isEnriching.value) return;

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
      user_role: userRole.value,
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
    store.commit('RESET_ONBOARDING', accountId.value);
    router.push(frontendURL(`accounts/${accountId.value}/dashboard`));
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
      :disabled="isEnriching"
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
              <InlineInput
                ref="websiteInput"
                v-model="website"
                :readonly="!isEditingWebsite"
                :placeholder="t('ONBOARDING_NEXT.PLACEHOLDERS.ENTER_WEBSITE')"
                :custom-input-class="[
                  'w-auto text-end px-1 py-0.5 -my-0.5 mx-0 placeholder:text-n-slate-9 rounded',
                  { 'animate-shake': showErrorOnFields && v$.website.$error },
                ]"
                @enter-press="handleWebsiteEnter"
                @blur="isEditingWebsite = false"
              />
              <NextButton
                type="button"
                icon="i-lucide-pencil"
                slate
                xs
                ghost
                @click="enableWebsiteEditing"
              />
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
