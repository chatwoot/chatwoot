<script>
import { formatDate } from 'shared/helpers/DateHelper';
import { useDarkMode } from 'widget/composables/useDarkMode';

export default {
  props: {
    date: {
      type: String,
      required: true,
    },
  },
  setup() {
    const { getThemeClass } = useDarkMode();
    return { getThemeClass };
  },
  computed: {
    formattedDate() {
      return formatDate({
        date: this.date,
        todayText: this.$t('TODAY'),
        yesterdayText: this.$t('YESTERDAY'),
      });
    },
  },
};
</script>

<template>
  <div
    class="text-sm text-n-slate-11 h-[50px] leading-[50px] relative text-center w-full before:content-[''] before:h-px before:absolute before:top-6 before:w-[calc((100%-120px)/2)] before:bg-n-slate-4 before:dark:bg-n-slate-6 before:left-0 after:content-[''] after:h-px after:absolute after:top-6 after:w-[calc((100%-120px)/2)] after:bg-n-slate-4 after:dark:bg-n-slate-6 after:right-0"
  >
    {{ formattedDate }}
  </div>
</template>
