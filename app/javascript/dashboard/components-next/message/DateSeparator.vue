<script setup>
import { computed } from 'vue';
import { isToday, isYesterday, differenceInDays } from 'date-fns';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  date: {
    type: [String, Number],
    required: true,
  },
});

const { t, locale } = useI18n();

const formattedDate = computed(() => {
  const dateObj =
    typeof props.date === 'number'
      ? new Date(props.date * 1000)
      : new Date(props.date);
  const now = new Date();

  if (isToday(dateObj)) {
    return t('TODAY');
  }

  if (isYesterday(dateObj)) {
    return t('YESTERDAY');
  }

  const localeCode = locale.value ? locale.value.replace(/_/g, '-') : 'en-US';
  const daysDifference = differenceInDays(now, dateObj);

  if (daysDifference < 7) {
    return new Intl.DateTimeFormat(localeCode, { weekday: 'long' }).format(
      dateObj
    );
  }

  return new Intl.DateTimeFormat(localeCode, {
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
  }).format(dateObj);
});
</script>

<template>
  <li
    class="sticky top-2 z-10 mx-auto w-max mb-4 clear-both flex justify-center"
  >
    <div
      class="bg-n-solid-1 border border-n-weak shadow-sm rounded-full px-3 py-1 text-xs text-n-slate-11 font-medium"
    >
      {{ formattedDate }}
    </div>
  </li>
</template>
