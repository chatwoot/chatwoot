<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import AccountAPI from 'dashboard/api/account';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SectionLayout from './SectionLayout.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const appointmentTypes = ref([
  {
    key: 'physical_visit',
    enabled: false,
  },
  {
    key: 'digital_meeting',
    enabled: false,
  },
  {
    key: 'phone_call',
    enabled: false,
  },
]);

const isUpdating = ref(false);

watch(
  currentAccount,
  () => {
    const account = currentAccount.value;
    if (account) {
      const enabledTypes = account.settings?.enabled_appointment_types || [
        'physical_visit',
        'digital_meeting',
        'phone_call',
      ];

      appointmentTypes.value.forEach(type => {
        type.enabled = enabledTypes.includes(type.key);
      });
    }
  },
  { deep: true, immediate: true }
);

const updateAppointmentTypes = async () => {
  isUpdating.value = true;
  try {
    const enabledTypes = appointmentTypes.value
      .filter(type => type.enabled)
      .map(type => type.key);

    const payload = {
      enabled_appointment_types: enabledTypes,
    };

    const response = await AccountAPI.update('', payload);
    store.commit('accounts/EDIT_ACCOUNT', response.data);
    useAlert(t('GENERAL_SETTINGS.FORM.APPOINTMENT_TYPES.API.SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message ||
        t('GENERAL_SETTINGS.FORM.APPOINTMENT_TYPES.API.ERROR')
    );
  } finally {
    isUpdating.value = false;
  }
};

const toggleType = key => {
  const type = appointmentTypes.value.find(t => t.key === key);
  if (type) {
    type.enabled = !type.enabled;
  }
};
</script>

<template>
  <SectionLayout
    :title="$t('GENERAL_SETTINGS.FORM.APPOINTMENT_TYPES.TITLE')"
    :description="$t('GENERAL_SETTINGS.FORM.APPOINTMENT_TYPES.NOTE')"
  >
    <div class="grid gap-4">
      <div
        v-for="type in appointmentTypes"
        :key="type.key"
        class="flex items-start gap-3 p-4 border border-slate-100 dark:border-slate-700 rounded-lg"
      >
        <input
          :id="`appointment-type-${type.key}`"
          type="checkbox"
          :checked="type.enabled"
          class="mt-1"
          @change="toggleType(type.key)"
        />
        <label :for="`appointment-type-${type.key}`" class="flex-1 cursor-pointer">
          <div class="font-medium text-slate-800 dark:text-slate-100">
            {{ $t(`GENERAL_SETTINGS.FORM.APPOINTMENT_TYPES.${type.key.toUpperCase()}`) }}
          </div>
          <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">
            {{ $t(`GENERAL_SETTINGS.FORM.APPOINTMENT_TYPES.${type.key.toUpperCase()}_DESCRIPTION`) }}
          </div>
        </label>
      </div>

      <div>
        <NextButton blue :is-loading="isUpdating" @click="updateAppointmentTypes">
          {{ $t('GENERAL_SETTINGS.FORM.APPOINTMENT_TYPES.UPDATE_BUTTON') }}
        </NextButton>
      </div>
    </div>
  </SectionLayout>
</template>
