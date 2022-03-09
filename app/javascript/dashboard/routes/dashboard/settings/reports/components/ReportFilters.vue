<template>
  <div class="flex-container flex-dir-column medium-flex-dir-row">
    <div v-if="type === 'agent'" class="small-12 medium-3 pull-right">
      <p aria-hidden="true" class="hide">
        {{ $t('AGENT_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        :placeholder="multiselectLabel"
        label="name"
        track-by="id"
        :options="filterItemsList"
        :option-height="24"
        :show-labels="false"
        @input="changeFilterSelection"
      >
        <template slot="singleLabel" slot-scope="props">
          <div class="reports-option__wrap">
            <thumbnail
              src="props.option.thumbnail"
              :username="props.option.name"
              size="22px"
              class="margin-right-small"
            />
            <span class="reports-option__desc">
              <span class="reports-option__title">{{ props.option.name }}</span>
            </span>
          </div>
        </template>
        <template slot="option" slot-scope="props">
          <div class="reports-option__wrap">
            <thumbnail
              src="props.option.thumbnail"
              :username="props.option.name"
              size="22px"
              class="margin-right-small"
            />
            <p>{{ props.option.name }}</p>
          </div>
        </template>
      </multiselect>
    </div>
    <div v-else-if="type === 'label'" class="small-12 medium-3 pull-right">
      <p aria-hidden="true" class="hide">
        {{ $t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        :placeholder="multiselectLabel"
        label="title"
        track-by="id"
        :options="filterItemsList"
        :option-height="24"
        :show-labels="false"
        @input="changeFilterSelection"
      >
        <template slot="singleLabel" slot-scope="props">
          <div class="reports-option__wrap">
            <div
              :style="{ backgroundColor: props.option.color }"
              class="reports-option__rounded--item margin-right-small"
            />
            <span class="reports-option__desc">
              <span class="reports-option__title">
                {{ props.option.title }}
              </span>
            </span>
          </div>
        </template>
        <template slot="option" slot-scope="props">
          <div class="reports-option__wrap">
            <div
              :style="{ backgroundColor: props.option.color }"
              class="
                reports-option__rounded--item
                reports-option__item
                reports-option__label--swatch
              "
            ></div>
            <span class="reports-option__desc">
              <span class="reports-option__title">
                {{ props.option.title }}
              </span>
            </span>
          </div>
        </template>
      </multiselect>
    </div>
    <div v-else class="small-12 medium-3 pull-right">
      <p aria-hidden="true" class="hide">
        {{ $t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        track-by="id"
        label="name"
        :placeholder="multiselectLabel"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        deselect-label=""
        :options="filterItemsList"
        :searchable="false"
        :allow-empty="false"
        @input="changeFilterSelection"
      />
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
    <div
      v-if="notLast7Days"
      class="small-12 medium-3 pull-right margin-left-small"
    >
      <p aria-hidden="true" class="hide">
        {{ $t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedGroupByFilter"
        track-by="id"
        label="groupBy"
        :placeholder="$t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL')"
        :options="groupByFilterItemsList"
        :allow-empty="false"
        :show-labels="false"
        @input="changeGroupByFilterSelection"
      />
    </div>
  </div>
</template>
<script>
import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';

import differenceInCalendarDays from 'date-fns/differenceInCalendarDays';

import { GROUP_BY_FILTER } from '../constants';
const CUSTOM_DATE_RANGE_ID = 5;

export default {
  components: {
    WootDateRangePicker,
    Thumbnail,
  },
  props: {
    filterItemsList: {
      type: Array,
      default: () => [],
    },
    groupByFilterItemsList: {
      type: Array,
      default: () => [],
    },
    type: {
      type: String,
      default: 'agent',
    },
    selectedGroupByFilter: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      currentSelectedFilter: null,
      currentDateRangeSelection: this.$t('REPORT.DATE_RANGE')[0],
      dateRange: this.$t('REPORT.DATE_RANGE'),
      customDateRange: [new Date(), new Date()],
      currentSelectedGroupByFilter: null,
    };
  },
  computed: {
    isDateRangeSelected() {
      return this.currentDateRangeSelection.id === CUSTOM_DATE_RANGE_ID;
    },
    currentDateRange() {
      let dateRange = {
        from: null,
        to: null,
      };
      if (this.isDateRangeSelected) {
        dateRange.from = this.fromCustomDate(this.customDateRange[0]);
        dateRange.to = this.toCustomDate(this.customDateRange[1]);
      } else {
        const fromDate = subDays(
          new Date(),
          this.daysRange(this.currentDateRangeSelection.id)
        );

        dateRange.from = this.fromCustomDate(fromDate);
        dateRange.to = this.toCustomDate(new Date());
      }
      return dateRange;
    },
    previousDateRange() {
      let dateRange = {
        from: null,
        to: null,
      };
      if (this.isDateRangeSelected) {
        const daysCount = differenceInCalendarDays(
          this.customDateRange[1],
          this.customDateRange[0]
        );
        const fromDate = subDays(new Date(), daysCount * 2);
        const toDate = subDays(new Date(), daysCount);
        dateRange.from = this.fromCustomDate(fromDate);
        dateRange.to = this.toCustomDate(toDate);
      } else {
        const fromDate = subDays(
          new Date(),
          this.daysRange(this.currentDateRangeSelection.id) * 2
        );
        const toDate = subDays(
          new Date(),
          this.daysRange(this.currentDateRangeSelection.id)
        );
        dateRange.from = this.fromCustomDate(fromDate);
        dateRange.to = this.toCustomDate(toDate);
      }
      return dateRange;
    },
    multiselectLabel() {
      const typeLabels = {
        agent: this.$t('AGENT_REPORTS.FILTER_DROPDOWN_LABEL'),
        label: this.$t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL'),
        inbox: this.$t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL'),
        team: this.$t('TEAM_REPORTS.FILTER_DROPDOWN_LABEL'),
      };
      return typeLabels[this.type] || this.$t('FORMS.MULTISELECT.SELECT_ONE');
    },
    groupBy() {
      if (this.isDateRangeSelected) {
        return GROUP_BY_FILTER[4].period;
      }
      const groupRange = {
        0: GROUP_BY_FILTER[1].period,
        1: GROUP_BY_FILTER[2].period,
        2: GROUP_BY_FILTER[3].period,
        3: GROUP_BY_FILTER[3].period,
        4: GROUP_BY_FILTER[3].period,
      };
      return groupRange[this.currentDateRangeSelection.id];
    },
    notLast7Days() {
      return this.groupBy !== GROUP_BY_FILTER[1].period;
    },
  },
  watch: {
    filterItemsList(val) {
      this.currentSelectedFilter = val[0];
      this.changeFilterSelection();
    },
    groupByFilterItemsList() {
      this.currentSelectedGroupByFilter = this.selectedGroupByFilter;
    },
  },
  mounted() {
    this.onDateRangeChange();
  },
  methods: {
    onDateRangeChange() {
      this.$emit('date-range-change', {
        currentDateRange: this.currentDateRange,
        previousDateRange: this.previousDateRange,
        groupBy: this.groupBy,
      });
    },
    fromCustomDate(date) {
      return getUnixTime(startOfDay(date));
    },
    toCustomDate(date) {
      return getUnixTime(endOfDay(date));
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
    changeGroupByFilterSelection() {
      this.$emit('group-by-filter-change', this.currentSelectedGroupByFilter);
    },
    daysRange(currentDateRangeId) {
      const dateRange = {
        0: 6,
        1: 29,
        2: 89,
        3: 179,
        4: 364,
      };
      return dateRange[currentDateRangeId];
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/widgets/_reports';
</style>
