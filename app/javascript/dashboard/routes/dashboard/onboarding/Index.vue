<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
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

const userName = computed(() => currentUser.value?.name || '');
const userEmail = computed(() => currentUser.value?.email || '');
const accountName = computed(() => currentAccount.value?.name || '');

const languageOptions = computed(() => {
  const langs = [...(enabledLanguages.value || [])];
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
    website.value = currentAccount.value.domain || '';
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
  <div
    class="relative flex text-body-main items-start justify-center w-full min-h-screen bg-white py-12 px-4 overflow-hidden"
  >
    <div
      class="absolute inset-0 bg-[size:96px_96px] bg-[image:linear-gradient(to_right,rgb(var(--border-weak))_1px,transparent_1px),linear-gradient(to_bottom,rgb(var(--border-weak))_1px,transparent_1px)] [mask-image:radial-gradient(ellipse_80%_80%_at_100%_0%,black_5%,transparent_50%),radial-gradient(ellipse_80%_80%_at_0%_100%,black_5%,transparent_50%)] [mask-composite:add] [-webkit-mask-composite:source-over]"
    />
    <div class="relative w-full max-w-[580px]">
      <form @submit.prevent="handleSubmit">
        <div class="relative pl-12">
          <!-- Timeline dotted line -->
          <div
            class="absolute left-[15px] top-10 bottom-10 border-l border-dashed border-n-slate-3"
          />

          <!-- Greeting -->
          <div class="mb-6 -ml-12 flex items-start gap-4">
            <div
              class="flex items-center justify-center w-8 h-8 z-10 flex-shrink-0"
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 16 16"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M8.00008 14.0007C8.73646 14.0007 9.33341 13.4037 9.33341 12.6673C9.33341 11.9309 8.73646 11.334 8.00008 11.334C7.2637 11.334 6.66675 11.9309 6.66675 12.6673C6.66675 13.4037 7.2637 14.0007 8.00008 14.0007Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M8.00008 4.66667C8.73646 4.66667 9.33341 4.06971 9.33341 3.33333C9.33341 2.59695 8.73646 2 8.00008 2C7.2637 2 6.66675 2.59695 6.66675 3.33333C6.66675 4.06971 7.2637 4.66667 8.00008 4.66667Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M10.6666 9.33268C11.403 9.33268 11.9999 8.73573 11.9999 7.99935C11.9999 7.26297 11.403 6.66602 10.6666 6.66602C9.93021 6.66602 9.33325 7.26297 9.33325 7.99935C9.33325 8.73573 9.93021 9.33268 10.6666 9.33268Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M13.3333 14.0007C14.0697 14.0007 14.6667 13.4037 14.6667 12.6673C14.6667 11.9309 14.0697 11.334 13.3333 11.334C12.597 11.334 12 11.9309 12 12.6673C12 13.4037 12.597 14.0007 13.3333 14.0007Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M2.66659 14.0007C3.40297 14.0007 3.99992 13.4037 3.99992 12.6673C3.99992 11.9309 3.40297 11.334 2.66659 11.334C1.93021 11.334 1.33325 11.9309 1.33325 12.6673C1.33325 13.4037 1.93021 14.0007 2.66659 14.0007Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M5.33333 9.33268C6.06971 9.33268 6.66667 8.73573 6.66667 7.99935C6.66667 7.26297 6.06971 6.66602 5.33333 6.66602C4.59695 6.66602 4 7.26297 4 7.99935C4 8.73573 4.59695 9.33268 5.33333 9.33268Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>
            </div>
            <div>
              <h1 class="text-heading-1 text-n-slate-12">
                {{ t('ONBOARDING.GREETING', { name: userName }) }}
              </h1>
              <p class="text-sm text-n-slate-11">
                {{ t('ONBOARDING.SUBTITLE') }}
              </p>
            </div>
          </div>

          <!-- Your details header -->
          <div class="flex items-center gap-4 mb-3 -ml-12">
            <div class="flex flex-col items-center z-10 flex-shrink-0">
              <svg width="6" height="5" viewBox="0 0 6 5" fill="none">
                <path d="M3 0L6 5H0L3 0Z" fill="rgb(var(--border-weak))" />
              </svg>
              <div
                class="flex items-center justify-center w-8 h-8 rounded-lg bg-white border border-n-container"
              >
                <Icon icon="i-lucide-user" class="size-4 text-n-slate-11" />
              </div>
              <svg width="6" height="5" viewBox="0 0 6 5" fill="none">
                <path d="M3 5L0 0H6L3 5Z" fill="rgb(var(--border-weak))" />
              </svg>
            </div>
            <span class="text-heading-3 text-n-slate-12">
              {{ t('ONBOARDING.YOUR_DETAILS') }}
            </span>
          </div>

          <!-- Your details card -->
          <div
            class="border border-n-container rounded-xl mb-5 overflow-hidden bg-n-surface-1"
          >
            <div class="flex items-center gap-2 px-3 py-3">
              <Avatar :name="userName" :size="16" rounded-full />
              <span class="text-sm font-medium text-n-slate-12">{{
                userName
              }}</span>
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
          </div>

          <!-- Company details header -->
          <div class="flex items-center gap-4 mb-3 -ml-12">
            <div class="flex flex-col items-center z-10 flex-shrink-0">
              <svg width="6" height="5" viewBox="0 0 6 5" fill="none">
                <path d="M3 0L6 5H0L3 0Z" fill="rgb(var(--border-weak))" />
              </svg>
              <div
                class="flex items-center justify-center w-8 h-8 rounded-lg bg-white border border-n-container"
              >
                <Icon
                  icon="i-lucide-briefcase-business"
                  class="size-4 text-n-slate-11"
                />
              </div>
              <svg width="6" height="5" viewBox="0 0 6 5" fill="none">
                <path d="M3 5L0 0H6L3 5Z" fill="rgb(var(--border-weak))" />
              </svg>
            </div>
            <span class="text-heading-3 text-n-slate-12">
              {{ t('ONBOARDING.COMPANY_DETAILS') }}
            </span>
          </div>

          <!-- Company details card -->
          <div
            class="border border-n-container rounded-xl mb-5 overflow-hidden bg-n-surface-1"
          >
            <div class="flex items-center gap-2 px-3 py-3">
              <Avatar :name="accountName" :size="16" rounded-full />
              <span class="text-sm font-medium text-n-slate-12">{{
                accountName
              }}</span>
            </div>
            <OnboardingFormRow
              :title="t('ONBOARDING.FIELDS.WEBSITE')"
              icon="i-lucide-globe"
            >
              <div class="flex items-center justify-end gap-1.5">
                <input
                  v-model="website"
                  type="text"
                  :placeholder="t('ONBOARDING.PLACEHOLDERS.ENTER_WEBSITE')"
                  class="reset-base text-sm text-right bg-transparent border-0 p-0 m-0 w-full text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-0"
                />
                <Icon
                  icon="i-lucide-pencil"
                  class="size-3.5 text-n-slate-9 flex-shrink-0"
                />
              </div>
            </OnboardingFormRow>
            <OnboardingFormRow
              :title="t('ONBOARDING.FIELDS.LANGUAGE')"
              icon="i-lucide-languages"
            >
              <OnboardingFormSelect
                v-model="locale"
                :options="languageOptions"
              />
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
                :placeholder="
                  t('ONBOARDING.PLACEHOLDERS.SELECT_REFERRAL_SOURCE')
                "
              />
            </OnboardingFormRow>
          </div>
        </div>

        <!-- Continue button -->
        <div class="pl-10">
          <NextButton
            type="submit"
            blue
            :is-loading="isSubmitting"
            class="w-full justify-center"
          >
            {{ t('ONBOARDING.CONTINUE') }}
          </NextButton>
        </div>
      </form>
    </div>
  </div>
</template>
