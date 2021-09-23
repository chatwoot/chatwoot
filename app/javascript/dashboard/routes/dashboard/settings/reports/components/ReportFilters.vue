<template>
  <div class="flex-container flex-dir-column medium-flex-dir-row">
    <div v-if="type === 'agent'" class="small-12 medium-3 pull-right">
      <multiselect
        v-model="currentSelectedFilter"
        placeholder="Select Agent"
        label="name"
        track-by="id"
        :options="filterItemsList"
        :option-height="24"
        :show-labels="false"
        @input="changeFilterSelection"
      >
        <template slot="singleLabel" slot-scope="props">
          <img class="reports-option__image" :src="props.option.thumbnail" />
          <span class="reports-option__desc">
            <span class="reports-option__title">{{ props.option.name }}</span>
          </span>
        </template>
        <template slot="option" slot-scope="props">
          <img class="reports-option__image" :src="props.option.thumbnail" />
          <div class="reports-option__desc">
            <span class="reports-option__title">{{ props.option.name }}</span>
          </div>
        </template>
      </multiselect>
    </div>
    <div v-if="type === 'label'" class="small-12 medium-3 pull-right">
      <multiselect
        v-model="currentSelectedFilter"
        placeholder="Select Label"
        label="title"
        track-by="id"
        :options="filterItemsList"
        :option-height="24"
        :show-labels="false"
        @input="changeFilterSelection"
      >
        <template slot="singleLabel" slot-scope="props">
          <div style="display: flex">
            <div
              :style="{ backgroundColor: props.option.color }"
              style="margin-right: 8px"
              class="reports-option__image"
            ></div>
            <span class="reports-option__desc">
              <span class="reports-option__title">{{
                props.option.title
              }}</span>
            </span>
          </div>
        </template>
        <template slot="option" slot-scope="props">
          <div style="display: flex">
            <div
              :style="{ backgroundColor: props.option.color }"
              style="margin-right: 8px; border: 1px solid white; flex-shrink: 0"
              class="reports-option__image"
            ></div>
            <span class="reports-option__desc">
              <span class="reports-option__title">{{
                props.option.title
              }}</span>
            </span>
          </div>
        </template>
      </multiselect>
    </div>
    <div class="small-12 medium-3 pull-right margin-left-small">
      <multiselect
        v-model="currentDateRangeSelection"
        track-by="name"
        label="name"
        :placeholder="$t('FORMS.MULTISELECT.SELECT_ONE')"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        deselect-label=""
        :options="dateRange"
        :searchable="false"
        :allow-empty="false"
        @select="changeDateSelection"
      />
    </div>
    <woot-date-range-picker
      v-if="isDateRangeSelected"
      show-range
      :value="customDateRange"
      :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
      :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
      @change="onChange"
    />
  </div>
</template>
<script>
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';
const CUSTOM_DATE_RANGE_ID = 5;
import subDays from 'date-fns/subDays';
import startOfDay from 'date-fns/startOfDay';
import getUnixTime from 'date-fns/getUnixTime';

export default {
  components: {
    WootDateRangePicker,
  },
  props: {
    filterItemsList: {
      type: Array,
      default: () => [],
    },
    type: {
      type: String,
      default: 'agent',
    },
  },
  data() {
    return {
      currentSelectedFilter: null,
      currentDateRangeSelection: this.$t('REPORT.DATE_RANGE')[0],
      dateRange: this.$t('REPORT.DATE_RANGE'),
      customDateRange: [new Date(), new Date()],
    };
  },
  computed: {
    isDateRangeSelected() {
      return this.currentDateRangeSelection.id === CUSTOM_DATE_RANGE_ID;
    },
    to() {
      if (this.isDateRangeSelected) {
        return this.fromCustomDate(this.customDateRange[1]);
      }
      return this.fromCustomDate(new Date());
    },
    from() {
      if (this.isDateRangeSelected) {
        return this.fromCustomDate(this.customDateRange[0]);
      }
      const dateRange = {
        0: 6,
        1: 29,
        2: 89,
        3: 179,
        4: 364,
      };
      const diff = dateRange[this.currentDateRangeSelection.id];
      const fromDate = subDays(new Date(), diff);
      return this.fromCustomDate(fromDate);
    },
  },
  watch: {
    filterItemsList(val) {
      this.currentSelectedFilter = val[0];
    },
  },
  mounted() {
    this.onDateRangeChange();
  },
  methods: {
    onDateRangeChange() {
      this.$emit('date-range-change', { from: this.from, to: this.to });
    },
    fromCustomDate(date) {
      return getUnixTime(startOfDay(date));
    },
    changeDateSelection(selectedRange) {
      this.currentDateRangeSelection = selectedRange;
      this.onDateRangeChange();
    },
    changeFilterSelection() {
      this.$emit('filter-change', this.currentSelectedFilter);
    },
    onChange(value) {
      this.customDateRange = value;
      this.onDateRangeChange();
    },
  },
};
</script>

<style lang="scss">
.date-picker {
  margin-left: var(--space-smaller);
}
.margin-left-small {
  margin-left: var(--space-smaller);
}
.reports-option__image {
  height: 20px;
  width: 20px;
  border-radius: 100%;
}
</style>
