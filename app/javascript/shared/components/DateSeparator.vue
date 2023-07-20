<template>
  <div
    class="text-xs h-12 font-medium leading-12 text-center w-full relative date--separator"
    :class="$dm('text-slate-700', 'dark:text-slate-200')"
  >
    {{ formattedDate }}
  </div>
</template>

<script>
import { formatDate } from 'shared/helpers/DateHelper';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  mixins: [darkModeMixin],
  props: {
    date: {
      type: String,
      required: true,
    },
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

<style lang="scss" scoped>
@import '~widget/assets/scss/variables';

.date--separator::before,
.date--separator::after {
  background-color: var(--s-50);
  content: '';
  height: 1px;
  position: absolute;
  top: 16px;
  width: calc((100% - 120px) / 2);
}

.date--separator::before {
  left: 0;
}

.date--separator::after {
  right: 0;
}
</style>
