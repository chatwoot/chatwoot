<template>
  <div class="day-wrap">
    <div class="checkbox-wrap">
      <input
        v-model="isDayEnabled"
        name="enable-day"
        class="enable-checkbox"
        type="checkbox"
        :title="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.ENABLE')"
      />
    </div>
    <div class="day">
      <span>{{ dayName }}</span>
    </div>
    <div v-if="isDayEnabled" class="hours-select-wrap">
      <div class="hours-range">
        <div class="checkbox-wrap open-all-day">
          <input
            v-model="isOpenAllDay"
            name="enable-open-all-day"
            class="enable-checkbox"
            type="checkbox"
            :title="$t('INBOX_MGMT.BUSINESS_HOURS.ALL_DAY')"
          />
          <span>{{ $t('INBOX_MGMT.BUSINESS_HOURS.ALL_DAY') }}</span>
        </div>
        <multiselect
          v-model="fromTime"
          :options="fromTimeSlots"
          deselect-label=""
          select-label=""
          selected-label=""
          :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
          :allow-empty="false"
          :disabled="isOpenAllDay"
        />
        <div class="separator-icon">
          <fluent-icon icon="subtract" type="solid" size="16" />
        </div>
        <multiselect
          v-model="toTime"
          :options="toTimeSlots"
          deselect-label=""
          select-label=""
          selected-label=""
          :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
          :allow-empty="false"
          :disabled="isOpenAllDay"
        />
      </div>
      <div v-if="hasError" class="date-error">
        <span class="error">{{
          $t('INBOX_MGMT.BUSINESS_HOURS.DAY.VALIDATION_ERROR')
        }}</span>
      </div>
    </div>
    <div v-else class="day-unavailable">
      <span>
        {{ $t('INBOX_MGMT.BUSINESS_HOURS.DAY.UNAVAILABLE') }}
      </span>
    </div>
    <div>
      <span v-if="isDayEnabled && !hasError" class="label">
        {{ totalHours }} {{ $t('INBOX_MGMT.BUSINESS_HOURS.DAY.HOURS') }}
      </span>
    </div>
  </div>
</template>

<script>
import parse from 'date-fns/parse';
import differenceInMinutes from 'date-fns/differenceInMinutes';
import { generateTimeSlots } from '../helpers/businessHour';

const timeSlots = generateTimeSlots(30);

export default {
  components: {},
  props: {
    dayName: {
      type: String,
      default: '',
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
  computed: {
    fromTimeSlots() {
      return timeSlots;
    },
    toTimeSlots() {
      return timeSlots.filter(slot => {
        return slot !== '12:00 AM';
      });
    },
    isDayEnabled: {
      get() {
        return this.timeSlot.from && this.timeSlot.to;
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
        const fromDate = parse(value, 'hh:mm a', new Date());
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
        const toDate = parse(value, 'hh:mm a', new Date());
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
      return parse(this.fromTime, 'hh:mm a', new Date());
    },
    toDate() {
      return parse(this.toTime, 'hh:mm a', new Date());
    },
    totalHours() {
      if (this.timeSlot.openAllDay) {
        return 24;
      }
      const totalHours = differenceInMinutes(this.toDate, this.fromDate) / 60;
      return totalHours;
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
<style lang="scss" scoped>
.day-wrap::v-deep .multiselect {
  margin: 0;
  width: 12rem;

  > .multiselect__tags {
    padding-left: var(--space-slab);

    .multiselect__single {
      font-size: var(--font-size-small);
      line-height: var(--space-medium);
      padding: var(--space-small) 0;
    }
  }
}
.day-wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-small) 0;
  min-height: var(--space-larger);
  box-sizing: content-box;
  border-bottom: 1px solid var(--color-border-light);
}
.enable-checkbox {
  margin: 0;
}

.hours-select-wrap {
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  flex-grow: 1;
  position: relative;
}

.hours-range,
.day-unavailable {
  display: flex;
  align-items: center;
  flex-shrink: 0;
  flex-grow: 1;
}

.day-unavailable {
  font-size: var(--font-size-small);
  color: var(--s-500);
}

.checkbox-wrap {
  display: flex;
  align-items: center;
}

.separator-icon,
.day {
  display: flex;
  align-items: center;
  padding: 0 var(--space-slab);
  height: 100%;
}

.day {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  width: 13rem;
}

.label {
  font-size: var(--font-size-mini);
  color: var(--w-700);
  background: var(--w-50);
}

.date-error {
  padding-top: var(--space-smaller);
}

.error {
  font-size: var(--font-size-mini);
  color: var(--r-300);
}

.open-all-day {
  margin-right: var(--space-medium);
  span {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    margin-left: var(--space-smaller);
  }
  input {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
  }
}
</style>
