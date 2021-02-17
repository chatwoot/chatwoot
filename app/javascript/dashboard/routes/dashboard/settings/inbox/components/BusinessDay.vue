<template>
  <div class="day-wrap">
    <div class="checkbox-wrap">
      <input
        v-model="isDayEnabled"
        name="enable-day"
        class="enable-day"
        type="checkbox"
        :title="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.ENABLE')"
      />
    </div>
    <div class="day">
      <span>{{ dayName }}</span>
    </div>
    <div v-if="isDayEnabled" class="hours-select-wrap">
      <div class="hours-range">
        <multiselect
          v-model="fromTime"
          :options="timeSlots"
          deselect-label=""
          select-label=""
          selected-label=""
          :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
          :allow-empty="false"
        />
        <div class="separator-icon">
          <i class="ion-minus-round" />
        </div>
        <multiselect
          v-model="toTime"
          :options="timeSlots"
          deselect-label=""
          select-label=""
          selected-label=""
          :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
          :allow-empty="false"
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
    timeSlots() {
      return timeSlots;
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
            }
          : {
              ...this.timeSlot,
              from: '',
              to: '',
            };
        this.$emit('update', newSlot);
      },
    },
    fromTime: {
      get() {
        return this.timeSlot.from;
      },
      set(value) {
        this.$emit('update', {
          ...this.timeSlot,
          from: value,
        });
      },
    },
    toTime: {
      get() {
        return this.timeSlot.to;
      },
      set(value) {
        this.$emit('update', {
          ...this.timeSlot,
          to: value,
        });
      },
    },
    fromDate() {
      return parse(this.fromTime, 'hh:mm a', new Date());
    },
    toDate() {
      return parse(this.toTime, 'hh:mm a', new Date());
    },
    totalHours() {
      return differenceInMinutes(this.toDate, this.fromDate) / 60;
    },
    hasError() {
      return this.totalHours < 0;
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
  padding: var(--space-normal);
  height: var(--space-larger);
  box-sizing: content-box;
  border-bottom: 1px solid var(--color-border-light);
}
.enable-day {
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
  padding: var(--space-small) 0;
}

.error {
  font-size: var(--font-size-mini);
  color: var(--r-300);
}
</style>
