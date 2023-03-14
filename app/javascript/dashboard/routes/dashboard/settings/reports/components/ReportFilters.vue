<template>
  <div class="flex-container flex-dir-column medium-flex-dir-row">
    <div
      v-if="type === 'agent'"
      class="small-12 medium-3 pull-right multiselect-wrap--small"
    >
      <p>
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
              :src="props.option.thumbnail"
              :status="props.option.availability_status"
              :username="props.option.name"
              size="22px"
            />
            <span class="reports-option__desc">
              <span class="reports-option__title">{{ props.option.name }}</span>
            </span>
          </div>
        </template>
        <template slot="option" slot-scope="props">
          <div class="reports-option__wrap">
            <thumbnail
              :src="props.option.thumbnail"
              :status="props.option.availability_status"
              :username="props.option.name"
              size="22px"
            />
            <p class="reports-option__title">{{ props.option.name }}</p>
          </div>
        </template>
      </multiselect>
    </div>
    <div
      v-else-if="type === 'label'"
      class="small-12 medium-3 pull-right multiselect-wrap--small"
    >
      <p>
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
              class="reports-option__rounded--item"
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
            />
            <span class="reports-option__desc">
              <span class="reports-option__title">
                {{ props.option.title }}
              </span>
            </span>
          </div>
        </template>
      </multiselect>
    </div>
    <div v-else class="small-12 medium-3 pull-right multiselect-wrap--small">
      <p>
        <template v-if="type === 'inbox'">
          {{ $t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL') }}
        </template>
        <template v-else-if="type === 'team'">
          {{ $t('TEAM_REPORTS.FILTER_DROPDOWN_LABEL') }}
        </template>
        <!-- handle default condition because the prop is not limited to the given 4 values -->
        <template v-else>
          {{ $t('FORMS.MULTISELECT.SELECT_ONE') }}
        </template>
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
    <div
      class="small-12 medium-3 pull-right margin-right-1 margin-left-1 multiselect-wrap--small"
    >
      <p>
        {{ $t('REPORT.DURATION_FILTER_LABEL') }}
      </p>
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
    <div v-if="isDateRangeSelected" class="">
      <p>
        {{ $t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER') }}
      </p>
      <woot-date-range-picker
        show-range
        :value="customDateRange"
        :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
        :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
        @change="onChange"
      />
    </div>
    <div
      v-if="notLast7Days"
      class="small-12 medium-3 pull-right margin-right-1 margin-left-1 multiselect-wrap--small"
    >
      <p>
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
    <div class="small-12 medium-3 business-hours">
      <span class="business-hours-text">
        {{ $t('REPORT.BUSINESS_HOURS') }}
      </span>
      <span>
        <woot-switch v-model="businessHoursSelected" />
      </span>
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
      businessHoursSelected: false,
    };
  },
  computed: {
    isDateRangeSelected() {
      return this.currentDateRangeSelection.id === CUSTOM_DATE_RANGE_ID;
    },
    to() {
      if (this.isDateRangeSelected) {
        return this.toCustomDate(this.customDateRange[1]);
      }
      return this.toCustomDate(new Date());
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
    businessHoursSelected() {
      this.$emit('business-hours-toggle', this.businessHoursSelected);
    },
  },
  mounted() {
    this.onDateRangeChange();
  },
  methods: {
    onDateRangeChange() {
      this.$emit('date-range-change', {
        from: this.from,
        to: this.to,
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
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/widgets/_reports';
</style>
