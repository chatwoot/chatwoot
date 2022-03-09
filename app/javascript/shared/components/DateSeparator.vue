<template>
  <div class="date--separator" :class="dateSeparatorDarkMode">
    {{ formattedDate }}
  </div>
</template>

<script>
import { formatDate } from 'shared/helpers/DateHelper';
import isDarkOrWhiteOrAutoMode from 'widget/mixins/darkModeMixin.js';
export default {
  mixins: [isDarkOrWhiteOrAutoMode],
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
    dateSeparatorDarkMode() {
      return this.isDarkOrWhiteOrAutoMode({
        dark: 'dark:text-slate-200',
        light: 'text-slate-700',
      });
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables';

.date--separator {
  font-size: $font-size-default;
  height: 50px;
  line-height: 50px;
  position: relative;
  text-align: center;
  width: 100%;
}

.date--separator::before,
.date--separator::after {
  background-color: $color-border;
  content: '';
  height: 1px;
  position: absolute;
  top: 24px;
  width: calc((100% - 120px) / 2);
}

.date--separator::before {
  left: 0;
}

.date--separator::after {
  right: 0;
}
</style>
