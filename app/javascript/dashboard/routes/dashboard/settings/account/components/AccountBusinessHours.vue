<script setup>
import { ref, watch, computed, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import AccountAPI from 'dashboard/api/account';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import BusinessDay from '../../inbox/components/BusinessDay.vue';
import {
  timeSlotParse,
  timeSlotTransform,
  defaultTimeSlot,
  dynamicTimeZoneOptions,
} from '../../inbox/helpers/businessHour';

const DEFAULT_TIMEZONE = {
  label: 'Pacific Time (US & Canada) (GMT-07:00)',
  value: 'America/Los_Angeles',
};

const { t, locale } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const isExpanded = ref(false);
const isSubmitting = ref(false);
const businessHoursEnabled = ref(false);
const timezone = ref(DEFAULT_TIMEZONE);
const timeSlots = ref([...defaultTimeSlot]);
const currentTime = ref(new Date());
let clockInterval = null;

const formattedDateTime = computed(() => {
  if (!timezone.value?.value) return '';

  const dateFormatter = new Intl.DateTimeFormat(locale.value, {
    timeZone: timezone.value.value,
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  const timeFormatter = new Intl.DateTimeFormat(locale.value, {
    timeZone: timezone.value.value,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: true,
  });

  return {
    date: dateFormatter.format(currentTime.value),
    time: timeFormatter.format(currentTime.value),
  };
});

const startClock = () => {
  clockInterval = setInterval(() => {
    currentTime.value = new Date();
  }, 1000);
};

const stopClock = () => {
  if (clockInterval) {
    clearInterval(clockInterval);
    clockInterval = null;
  }
};

onMounted(() => {
  startClock();
});

onUnmounted(() => {
  stopClock();
});

const dayNames = {
  0: 'SUNDAY',
  1: 'MONDAY',
  2: 'TUESDAY',
  3: 'WEDNESDAY',
  4: 'THURSDAY',
  5: 'FRIDAY',
  6: 'SATURDAY',
};

const timeZones = computed(() => [...dynamicTimeZoneOptions()]);

const hasError = computed(() => {
  if (!businessHoursEnabled.value) return false;
  return timeSlots.value.filter(slot => slot.from && !slot.valid).length > 0;
});

const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value;
};

const onSlotUpdate = (slotIndex, slotData) => {
  timeSlots.value = timeSlots.value.map(item =>
    item.day === slotIndex ? slotData : item
  );
};

watch(
  currentAccount,
  () => {
    const account = currentAccount.value;
    if (account) {
      businessHoursEnabled.value = account.business_hours_enabled || false;

      const savedTimezone = account.business_hours_timezone;
      timezone.value =
        timeZones.value.find(item => savedTimezone === item.value) ||
        DEFAULT_TIMEZONE;

      const businessHours = account.business_hours || [];
      const slots = timeSlotParse(businessHours).length
        ? timeSlotParse(businessHours)
        : [...defaultTimeSlot];
      timeSlots.value = slots.sort((a, b) => a.day - b.day);
    }
  },
  { deep: true, immediate: true }
);

const handleSubmit = async () => {
  if (hasError.value) {
    useAlert(t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.ERROR'));
    return;
  }

  try {
    isSubmitting.value = true;
    const payload = {
      business_hours_enabled: businessHoursEnabled.value,
      business_hours_timezone: timezone.value.value,
      business_hours: timeSlotTransform(timeSlots.value),
    };
    const response = await AccountAPI.update('', payload);
    store.commit('accounts/EDIT_ACCOUNT', response.data);
    useAlert(t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.API.SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message ||
        t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.API.ERROR')
    );
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="grid grid-cols-1 pt-8 gap-5 border-t border-n-weak pb-8">
    <button
      type="button"
      class="w-full flex items-center justify-between text-left cursor-pointer group"
      @click="toggleExpanded"
    >
      <div class="flex-1">
        <h4 class="text-lg font-medium text-n-slate-12">
          {{ t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.TITLE') }}
        </h4>
        <p class="text-n-slate-11 text-sm mt-2">
          {{ t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.NOTE') }}
        </p>
      </div>
      <fluent-icon
        icon="chevron-down"
        size="20"
        class="ml-4 text-n-slate-11 transition-transform duration-200"
        :class="{ 'rotate-180': isExpanded }"
      />
    </button>

    <transition
      enter-active-class="transition-all duration-200 ease-out"
      leave-active-class="transition-all duration-200 ease-in"
      enter-from-class="opacity-0 max-h-0"
      enter-to-class="opacity-100 max-h-[2000px]"
      leave-from-class="opacity-100 max-h-[2000px]"
      leave-to-class="opacity-0 max-h-0"
    >
      <form
        v-show="isExpanded"
        class="grid gap-4 mt-4 overflow-hidden"
        @submit.prevent="handleSubmit"
      >
        <label for="toggle-business-hours" class="flex items-center gap-2">
          <input
            id="toggle-business-hours"
            v-model="businessHoursEnabled"
            type="checkbox"
            name="toggle-business-hours"
          />
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.ENABLE') }}
          </span>
        </label>

        <div v-if="businessHoursEnabled" class="space-y-4">
          <WithLabel :label="t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.TIMEZONE')">
            <div class="flex items-center gap-4 mt-2">
              <multiselect
                v-model="timezone"
                :options="timeZones"
                deselect-label=""
                select-label=""
                selected-label=""
                track-by="value"
                label="label"
                close-on-select
                :placeholder="t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
                :allow-empty="false"
                class="flex-1"
              />
              <div
                v-if="timezone?.value"
                class="px-3 py-2 bg-n-alpha-black2 dark:bg-n-solid-1 rounded-md border border-n-weak inline-flex items-center gap-3 shrink-0"
              >
                <span class="text-base font-mono font-medium text-n-slate-12">
                  {{ formattedDateTime.time }}
                </span>
                <span class="text-xs text-n-slate-11 capitalize">
                  {{ formattedDateTime.date }}
                </span>
              </div>
            </div>
          </WithLabel>

          <div>
            <label class="text-sm font-medium text-n-slate-12 mb-2 block">
              {{ t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.WEEKLY_SCHEDULE') }}
            </label>
            <BusinessDay
              v-for="timeSlot in timeSlots"
              :key="timeSlot.day"
              :day-name="t(`GENERAL_SETTINGS.FORM.BUSINESS_HOURS.DAYS.${dayNames[timeSlot.day]}`)"
              :time-slot="timeSlot"
              @update="data => onSlotUpdate(timeSlot.day, data)"
            />
          </div>
        </div>

        <div class="flex gap-2">
          <NextButton
            blue
            type="submit"
            :is-loading="isSubmitting"
            :disabled="hasError"
            :label="t('GENERAL_SETTINGS.FORM.BUSINESS_HOURS.UPDATE_BUTTON')"
          />
        </div>
      </form>
    </transition>
  </div>
</template>

<style lang="scss" scoped>
::v-deep .multiselect {
  @apply m-0;
}
</style>
