<template>
  <div class="flex-container flex-dir-column medium-flex-dir-row">
    <div v-if="type === 'agent'" class="small-12 medium-3 pull-right">
      <p aria-hidden="true" class="hide">
        {{ $t('AGENT_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        :placeholder="$t('AGENT_REPORTS.FILTER_DROPDOWN_LABEL')"
        label="name"
        track-by="id"
        :options="filterItemsList"
        :option-height="24"
        :show-labels="false"
        @input="changeFilterSelection"
      >
        <template slot="singleLabel" slot-scope="props">
          <div class="display-flex">
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
          <div class="display-flex">
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
    <div v-if="type === 'label'" class="small-12 medium-3 pull-right">
      <p aria-hidden="true" class="hide">
        {{ $t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        :placeholder="$t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL')"
        label="title"
        track-by="id"
        :options="filterItemsList"
        :option-height="24"
        :show-labels="false"
        @input="changeFilterSelection"
      >
        <template slot="singleLabel" slot-scope="props">
          <div class="display-flex">
            <div
              :style="{ backgroundColor: props.option.color }"
              class="reports-option__rounded--item margin-right-small"
            ></div>
            <span class="reports-option__desc">
              <span class="reports-option__title">{{
                props.option.title
              }}</span>
            </span>
          </div>
        </template>
        <template slot="option" slot-scope="props">
          <div class="display-flex">
            <div
              :style="{ backgroundColor: props.option.color }"
              class="
                reports-option__rounded--item
                reports-option__item
                reports-option__label--swatch
              "
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
    <div v-if="type === 'inbox'" class="small-12 medium-3 pull-right">
      <p aria-hidden="true" class="hide">
        {{ $t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        track-by="id"
        label="name"
        :placeholder="$t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL')"
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
  </div>
</template>
<script>
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';
const CUSTOM_DATE_RANGE_ID = 5;
import subDays from 'date-fns/subDays';
import startOfDay from 'date-fns/startOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

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
    currentSelectedFilter() {
      this.changeFilterSelection();
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
@import '~dashboard/assets/scss/widgets/_reports';
</style>
