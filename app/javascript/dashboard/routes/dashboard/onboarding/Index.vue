<script setup>
import { ref, computed, nextTick, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import OnboardingLayout from './OnboardingLayout.vue';
import OnboardingSection from './OnboardingSection.vue';
import OnboardingFormRow from './OnboardingFormRow.vue';
import OnboardingFormSelect from './OnboardingFormSelect.vue';
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

const userName = computed(() => currentUser.value?.name || '');
const userEmail = computed(() => currentUser.value?.email || '');
const accountName = computed(() => currentAccount.value?.name || '');
const companyLogo = computed(
  () => currentAccount.value?.custom_attributes?.branding?.favicon || ''
);

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
  if (currentAccount.value) {
    locale.value = currentAccount.value.locale || 'en';
    website.value =
      currentAccount.value.domain ||
      currentAccount.value.custom_attributes?.website ||
      '';
    timezone.value =
      currentAccount.value.custom_attributes?.timezone ||
      Intl.DateTimeFormat().resolvedOptions().timeZone ||
      '';
    companySize.value =
      currentAccount.value.custom_attributes?.company_size || '';
    industry.value = currentAccount.value.custom_attributes?.industry || '';
    referralSource.value =
      currentAccount.value.custom_attributes?.referral_source || '';
  }
});

const enableWebsiteEditing = () => {
  isEditingWebsite.value = true;
  nextTick(() => websiteInput.value?.focus());
};

const handleSubmit = async () => {
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
    useAlert(t('ONBOARDING.SUCCESS'));
    router.push({ name: 'home', params: { accountId: accountId.value } });
  } catch {
    useAlert(t('ONBOARDING.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <OnboardingLayout
      :greeting="t('ONBOARDING.GREETING', { name: userName })"
      :subtitle="t('ONBOARDING.SUBTITLE')"
      :continue-label="t('ONBOARDING.CONTINUE')"
      :is-loading="isSubmitting"
    >
      <OnboardingSection
        :title="t('ONBOARDING.YOUR_DETAILS')"
        icon="i-lucide-user"
      >
        <div class="flex items-center gap-4 px-3 py-3">
          <Avatar :name="userName" :size="16" rounded-full />
          <span class="text-sm font-medium text-n-slate-12">
            {{ userName }}
          </span>
        </div>
        <OnboardingFormRow
          :title="t('ONBOARDING.FIELDS.EMAIL')"
          icon="i-lucide-mail"
        >
          <div class="flex items-center justify-end gap-1.5">
            <span class="text-sm text-n-slate-12">{{ userEmail }}</span>
            <Icon
              icon="i-lucide-circle-check"
              class="size-4 text-n-teal-11 flex-shrink-0"
            />
          </div>
        </OnboardingFormRow>
        <OnboardingFormRow
          :title="t('ONBOARDING.FIELDS.YOUR_ROLE')"
          icon="i-lucide-user"
        >
          <OnboardingFormSelect
            v-model="userRole"
            :options="USER_ROLE_OPTIONS"
            :placeholder="t('ONBOARDING.PLACEHOLDERS.SELECT_ROLE')"
          />
        </OnboardingFormRow>
      </OnboardingSection>

      <OnboardingSection
        :title="t('ONBOARDING.COMPANY_DETAILS')"
        icon="i-lucide-briefcase-business"
      >
        <div class="flex items-center gap-4 px-3 py-3">
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
          :title="t('ONBOARDING.FIELDS.WEBSITE')"
          icon="i-lucide-globe"
        >
          <div class="flex items-center justify-end gap-1.5">
            <input
              ref="websiteInput"
              v-model="website"
              type="text"
              :readonly="!isEditingWebsite"
              :placeholder="t('ONBOARDING.PLACEHOLDERS.ENTER_WEBSITE')"
              class="reset-base text-sm text-right border-0 p-0 m-0 w-full text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-0 rounded"
              :class="
                isEditingWebsite
                  ? 'bg-n-alpha-black1 px-2 py-0.5'
                  : 'bg-transparent cursor-default'
              "
              @blur="isEditingWebsite = false"
            />
            <button
              type="button"
              class="flex-shrink-0"
              @click="enableWebsiteEditing"
            >
              <Icon icon="i-lucide-pencil" class="size-3.5 text-n-slate-9" />
            </button>
          </div>
        </OnboardingFormRow>
        <OnboardingFormRow
          :title="t('ONBOARDING.FIELDS.LANGUAGE')"
          icon="i-lucide-languages"
        >
          <OnboardingFormSelect v-model="locale" :options="languageOptions" />
        </OnboardingFormRow>
        <OnboardingFormRow
          :title="t('ONBOARDING.FIELDS.TIMEZONE')"
          icon="i-lucide-clock"
        >
          <OnboardingFormSelect
            v-model="timezone"
            :options="timezoneOptions"
            :placeholder="t('ONBOARDING.PLACEHOLDERS.SELECT_TIMEZONE')"
          />
        </OnboardingFormRow>
        <OnboardingFormRow
          :title="t('ONBOARDING.FIELDS.COMPANY_SIZE')"
          icon="i-lucide-users"
        >
          <OnboardingFormSelect
            v-model="companySize"
            :options="COMPANY_SIZE_OPTIONS"
            :placeholder="t('ONBOARDING.PLACEHOLDERS.SELECT_COMPANY_SIZE')"
          />
        </OnboardingFormRow>
        <OnboardingFormRow
          :title="t('ONBOARDING.FIELDS.INDUSTRY')"
          icon="i-lucide-factory"
        >
          <OnboardingFormSelect
            v-model="industry"
            :options="INDUSTRY_OPTIONS"
            :placeholder="t('ONBOARDING.PLACEHOLDERS.SELECT_INDUSTRY')"
          />
        </OnboardingFormRow>
        <OnboardingFormRow
          :title="t('ONBOARDING.FIELDS.REFERRAL_SOURCE')"
          icon="i-lucide-megaphone"
        >
          <OnboardingFormSelect
            v-model="referralSource"
            :options="REFERRAL_SOURCE_OPTIONS"
            :placeholder="t('ONBOARDING.PLACEHOLDERS.SELECT_REFERRAL_SOURCE')"
          />
        </OnboardingFormRow>
      </OnboardingSection>
    </OnboardingLayout>
  </form>
</template>
