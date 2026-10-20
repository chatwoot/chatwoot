<script setup>
import { ref, computed, nextTick, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert, useTrack } from 'dashboard/composables';
import { ONBOARDING_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import OnboardingLayout from './shared/OnboardingLayout.vue';
import OnboardingSection from './shared/OnboardingSection.vue';
import OnboardingFormRow from './account-details/OnboardingFormRow.vue';
import OnboardingFormSelect from './account-details/OnboardingFormSelect.vue';
import { useAccountEnrichment } from './account-details/useAccountEnrichment';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import {
  COMPANY_SIZE_OPTIONS,
  INDUSTRY_OPTIONS,
  REFERRAL_SOURCE_OPTIONS,
  USER_ROLE_OPTIONS,
} from './shared/constants';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { accountId, currentAccount, finishOnboarding } = useAccount();

// Where each onboarding cursor routes. The backend owns which steps run where;
// the frontend just follows the cursor it advanced us to (no deployment checks).
const STEP_ROUTES = { inbox_setup: 'onboarding_inbox_setup' };
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
  // Website is required: the onboarding web-widget inbox can't be created
  // without a URL (Channel::WebWidget validates presence), so a blank value
  // would leave the "Live Chat widget" status polling forever.
  website: { required },
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
const { isEnriching, getChangedFields } = useAccountEnrichment({
  locale,
  website,
  timezone,
  companySize,
  industry,
  referralSource,
});

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

onMounted(() => {
  useTrack(ONBOARDING_EVENTS.ACCOUNT_DETAILS_VISITED);
});

const enableWebsiteEditing = () => {
  isEditingWebsite.value = true;
  nextTick(() => websiteInput.value?.focus());
};

const handleWebsiteEnter = () => {
  websiteInput.value?.blur();
};

const normalizeWebsiteUrl = raw => {
  const trimmed = (raw || '').trim();
  if (!trimmed) return '';
  return /^https?:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`;
};

const handleSubmit = async () => {
  // Block submit while enrichment is still running so users can't bypass
  // the form with empty values — the controller would otherwise clear
  // onboarding_step and persist incomplete data. Also guard against
  // re-entry while a submit is in flight (double-click/Enter), which would
  // fire parallel requests that can duplicate the auto-created inbox/portal.
  if (isEnriching.value || isSubmitting.value) return;

  v$.value.$touch();
  if (v$.value.$invalid) {
    useAlert(t('ONBOARDING_NEXT.VALIDATION_ERROR'));
    showErrorOnFields.value = true;
    setTimeout(() => {
      showErrorOnFields.value = false;
    }, 600);
    // The website field is read-only until edited; open it so a required-but-
    // empty value is immediately fixable rather than just shaking a locked field.
    if (v$.value.website.$error) enableWebsiteEditing();
    return;
  }

  // Capture which enrichable fields the user edited *before* normalizing the
  // website, so an untouched auto-filled domain isn't falsely flagged.
  const fieldsChanged = getChangedFields();

  // Persist with a scheme so downstream consumers (Firecrawl, portal
  // homepage_link) get a fully-qualified URL regardless of what the user typed.
  website.value = normalizeWebsiteUrl(website.value);

  isSubmitting.value = true;
  try {
    await finishOnboarding({
      name: accountName.value,
      locale: locale.value,
      website: website.value,
      industry: industry.value,
      company_size: companySize.value,
      timezone: timezone.value,
      referral_source: referralSource.value,
      user_role: userRole.value,
      onboarding_step: 'account_details',
    });

    useTrack(ONBOARDING_EVENTS.ACCOUNT_DETAILS_COMPLETED, {
      has_enriched_data: Boolean(
        currentAccount.value?.custom_attributes?.brand_info
      ),
      fields_changed: fieldsChanged,
      user_role: userRole.value,
      company_size: companySize.value,
      industry: industry.value,
      referral_source: referralSource.value,
    });

    useAlert(t('ONBOARDING_NEXT.SUCCESS'));
    // Follow the cursor the backend advanced us to. A next step routes there; no
    // next step means onboarding is complete, so refresh the user (so the router
    // guard sees the cleared cursor) and head to the dashboard.
    const nextStep = currentAccount.value?.custom_attributes?.onboarding_step;
    if (STEP_ROUTES[nextStep]) {
      router.push({
        name: STEP_ROUTES[nextStep],
        params: { accountId: accountId.value },
      });
    } else {
      await store.dispatch('setUser');
      router.push({ name: 'home', params: { accountId: accountId.value } });
    }
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
