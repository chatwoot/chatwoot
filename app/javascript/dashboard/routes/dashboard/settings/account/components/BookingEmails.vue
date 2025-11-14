<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();

const currentAccount = useMapGetter('getCurrentAccountId');

const bookingEmails = ref([]);
const newEmail = ref('');
const emailError = ref('');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const validateEmail = email => {
  if (!email) {
    return false;
  }
  return EMAIL_REGEX.test(email.trim());
};

const saveBookingEmails = async () => {
  try {
    await store.dispatch('accounts/update', {
      id: currentAccount.value,
      booking_emails: bookingEmails.value,
      options: { silent: true },
    });
    useAlert(t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.API.ERROR'));
  }
};

const addEmail = () => {
  emailError.value = '';
  if (!newEmail.value.trim()) return;

  const email = newEmail.value.trim().toLowerCase();

  if (!validateEmail(email)) {
    emailError.value = t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.INVALID_EMAIL');
    return;
  }
  if (bookingEmails.value.includes(email)) {
    emailError.value = t(
      'GENERAL_SETTINGS.FORM.BOOKING_EMAILS.DUPLICATE_EMAIL'
    );
    return;
  }

  bookingEmails.value.push(email);
  newEmail.value = '';
  emailError.value = '';
  saveBookingEmails();
};

const removeEmail = index => {
  bookingEmails.value.splice(index, 1);
  saveBookingEmails();
};

onMounted(() => {
  const account = store.getters['accounts/getAccount'](currentAccount.value);
  bookingEmails.value = account.booking_emails || [];
});

const hasBookingEmails = computed(() => bookingEmails.value.length > 0);
</script>

<template>
  <SectionLayout :title="t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.TITLE')">
    <div class="space-y-4">
      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.LABEL')"
        :has-error="!!emailError"
        :error-message="emailError"
      >
        <div class="flex gap-2">
          <NextInput
            v-model="newEmail"
            type="email"
            class="flex-1"
            :placeholder="t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.PLACEHOLDER')"
            @keypress.enter="addEmail"
          />
          <NextButton blue @click="addEmail">
            {{ t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.ADD_BUTTON') }}
          </NextButton>
        </div>
      </WithLabel>

      <div v-if="hasBookingEmails" class="space-y-2">
        <p class="text-sm font-medium text-slate-700 dark:text-slate-200">
          {{ t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.CONFIGURED_EMAILS') }}
        </p>
        <div class="flex flex-wrap gap-2">
          <div
            v-for="(email, index) in bookingEmails"
            :key="index"
            class="inline-flex items-center gap-2 px-3 py-1.5 bg-slate-100 dark:bg-slate-700 rounded-full border border-slate-200 dark:border-slate-600 group hover:border-slate-300 dark:hover:border-slate-500 transition-colors"
          >
            <span class="text-sm text-slate-900 dark:text-slate-100">
              {{ email }}
            </span>
            <button
              class="text-slate-500 hover:text-red-600 dark:text-slate-400 dark:hover:text-red-400 transition-colors"
              :aria-label="`Remove ${email}`"
              @click="removeEmail(index)"
            >
              <fluent-icon icon="dismiss" size="14" />
            </button>
          </div>
        </div>
      </div>

      <div
        v-else
        class="p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg"
      >
        <p class="text-sm text-yellow-800 dark:text-yellow-200">
          {{ t('GENERAL_SETTINGS.FORM.BOOKING_EMAILS.EMPTY_STATE') }}
        </p>
      </div>
    </div>
  </SectionLayout>
</template>
