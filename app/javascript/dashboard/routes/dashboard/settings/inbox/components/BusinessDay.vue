<script>
import parse from 'date-fns/parse';
import differenceInMinutes from 'date-fns/differenceInMinutes';
import { generateTimeSlots } from '../helpers/businessHour';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextSelect from 'dashboard/components-next/select/Select.vue';

const timeSlots = generateTimeSlots(30);
const timeReferenceDate = new Date(2000, 0, 1);
const parseTime = time => parse(time, 'hh:mm a', timeReferenceDate);

const formatTime = (time, locale) => {
  const date = parseTime(time);
  return new Intl.DateTimeFormat(locale.replace(/_/g, '-'), {
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
};

const groupByPeriod = (slots, locale, translate) =>
  ['AM', 'PM']
    .map(period => ({
      label: translate(`INBOX_MGMT.BUSINESS_HOURS.PERIOD.${period}`),
      options: slots
        .filter(s => s.endsWith(period))
        .map(s => ({ value: s, label: formatTime(s, locale) })),
    }))
    .filter(g => g.options.length);

export default {
  components: {
    Icon,
    NextSelect,
  },
  props: {
    dayName: {
      type: String,
      required: true,
    },
    timeSlot: {
      type: Object,
      default: () => ({
        from: '',
        to: '',
      }),
    },
  },
  emits: ['update'],
  computed: {
    fromTimeSlots() {
      return groupByPeriod(timeSlots, this.$i18n.locale, this.$t);
    },
    toTimeSlots() {
      return groupByPeriod(
        timeSlots.filter(slot => slot !== '12:00 AM'),
        this.$i18n.locale,
        this.$t
      );
    },
    isDayEnabled: {
      get() {
        return Boolean(this.timeSlot.from && this.timeSlot.to);
      },
      set(value) {
        const newSlot = value
          ? {
              ...this.timeSlot,
              from: timeSlots[0],
              to: timeSlots[16],
              valid: true,
              openAllDay: false,
            }
          : {
              ...this.timeSlot,
              from: '',
              to: '',
              valid: false,
              openAllDay: false,
            };
        this.$emit('update', newSlot);
      },
    },
    fromTime: {
      get() {
        return this.timeSlot.from;
      },
      set(value) {
        const fromDate = parseTime(value);
        const valid = differenceInMinutes(this.toDate, fromDate) / 60 > 0;
        this.$emit('update', {
          ...this.timeSlot,
          from: value,
          valid,
        });
      },
    },
    toTime: {
      get() {
        return this.timeSlot.to;
      },
      set(value) {
        const toDate = parseTime(value);
        if (value === '12:00 AM') {
          this.$emit('update', {
            ...this.timeSlot,
            to: value,
            valid: true,
          });
        } else {
          const valid = differenceInMinutes(toDate, this.fromDate) / 60 > 0;
          this.$emit('update', {
            ...this.timeSlot,
            to: value,
            valid,
          });
        }
      },
    },
    fromDate() {
      return parseTime(this.fromTime);
    },
    toDate() {
      return parseTime(this.toTime);
    },
    totalHours() {
      if (this.timeSlot.openAllDay) return '24h';

      const totalMinutes = differenceInMinutes(this.toDate, this.fromDate);
      const [h, m] = [Math.floor(totalMinutes / 60), totalMinutes % 60];

      return (
        [
          h &&
            this.$t('INBOX_MGMT.BUSINESS_HOURS.DURATION.HOURS', {
              count: h,
            }),
          m &&
            this.$t('INBOX_MGMT.BUSINESS_HOURS.DURATION.MINUTES', {
              count: m,
            }),
        ]
          .filter(Boolean)
          .join(' ') ||
        this.$t('INBOX_MGMT.BUSINESS_HOURS.DURATION.MINUTES', {
          count: 0,
        })
      );
    },
    hasError() {
      return !this.timeSlot.valid;
    },
    isOpenAllDay: {
      get() {
        return this.timeSlot.openAllDay;
      },
      set(value) {
        if (value) {
          this.$emit('update', {
            ...this.timeSlot,
            from: '12:00 AM',
            to: '11:59 PM',
            valid: true,
            openAllDay: value,
          });
        } else {
          this.$emit('update', {
            ...this.timeSlot,
            from: '09:00 AM',
            to: '05:00 PM',
            valid: true,
            openAllDay: value,
          });
        }
      },
    },
  },
};
</script>

<template>
  <tr>
    <td class="ltr:pl-4 ltr:pr-3 rtl:pl-3 rtl:pr-4">
      <div class="flex items-center gap-2 min-h-16">
        <input
          v-model="isDayEnabled"
          name="enable-day"
          class="m-0"
          type="checkbox"
          :title="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.ENABLE')"
        />
        <span class="text-body-main text-n-slate-12 font-medium">
          {{ dayName }}
        </span>
      </div>
    </td>
    <td class="py-3 ltr:pr-3 rtl:pl-3">
      <div v-if="isDayEnabled" class="flex flex-col gap-1.5">
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2">
            <input
              v-model="isOpenAllDay"
              name="enable-open-all-day"
              class="m-0"
              type="checkbox"
              :title="$t('INBOX_MGMT.BUSINESS_HOURS.ALL_DAY')"
            />
            <span class="text-body-main text-n-slate-12">{{
              $t('INBOX_MGMT.BUSINESS_HOURS.ALL_DAY')
            }}</span>
          </div>
          <NextSelect
            v-model="fromTime"
            :groups="fromTimeSlots"
            :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
            :disabled="isOpenAllDay"
          />
          <div class="flex items-center">
            <Icon icon="i-lucide-minus size-4" />
          </div>
          <NextSelect
            v-model="toTime"
            :groups="toTimeSlots"
            :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
            :disabled="isOpenAllDay"
          />
        </div>
        <span v-if="hasError" class="error text-label-small text-n-ruby-9">
          {{ $t('INBOX_MGMT.BUSINESS_HOURS.DAY.VALIDATION_ERROR') }}
        </span>
      </div>
      <span v-else class="text-body-main text-n-slate-11">
        {{ $t('INBOX_MGMT.BUSINESS_HOURS.DAY.UNAVAILABLE') }}
      </span>
    </td>
    <td class="py-3 ltr:pr-3 rtl:pl-3">
      <span
        v-if="isDayEnabled && !hasError"
        class="label bg-n-blue-3 text-n-blue-11 text-label-small inline-block px-2 py-1 rounded-lg cursor-default whitespace-nowrap"
      >
        {{ totalHours }}
      </span>
    </td>
  </tr>
</template>
