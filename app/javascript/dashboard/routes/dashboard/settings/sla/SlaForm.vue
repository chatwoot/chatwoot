<template>
  <div class="h-auto overflow-auto flex flex-col">
    <form class="mx-0 flex flex-wrap" @submit.prevent="onSubmit">
      <woot-input
        v-model="name"
        :class="{ error: $v.name.$error }"
        class="w-full"
        :label="$t('SLA.FORM.NAME.LABEL')"
        :placeholder="$t('SLA.FORM.NAME.PLACEHOLDER')"
        :error="getSlaNameErrorMessage"
        @input="$v.name.$touch"
      />
      <woot-input
        v-model="description"
        class="w-full"
        :label="$t('SLA.FORM.DESCRIPTION.LABEL')"
        :placeholder="$t('SLA.FORM.DESCRIPTION.PLACEHOLDER')"
      />

      <sla-time-input
        v-for="(input, index) in slaTimeInputs"
        :key="index"
        :threshold="input.threshold"
        :threshold-unit="input.unit"
        :label="$t(input.label)"
        :placeholder="$t(input.placeholder)"
        @input="updateThreshold(index, $event)"
        @unit="updateUnit(index, $event)"
      />

      <div class="w-full">
        <input id="sla_bh" v-model="onlyDuringBusinessHours" type="checkbox" />
        <label for="sla_bh">
          {{ $t('SLA.FORM.BUSINESS_HOURS.PLACEHOLDER') }}
        </label>
      </div>

      <div class="flex justify-end items-center py-2 px-0 gap-2 w-full">
        <woot-button
          :is-disabled="isSubmitDisabled"
          :is-loading="uiFlags.isUpdating"
        >
          {{ submitLabel }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="onClose">
          {{ $t('SLA.FORM.CANCEL') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import validationMixin from './validationMixin';
import validations from './validations';
import SlaTimeInput from './SlaTimeInput.vue';

export default {
  components: {
    SlaTimeInput,
  },
  mixins: [validationMixin],
  props: {
    selectedResponse: {
      type: Object,
      default: () => {},
    },
    submitLabel: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      name: '',
      description: '',
      slaTimeInputs: [
        {
          threshold: null,
          unit: 'Minutes',
          label: 'SLA.FORM.FIRST_RESPONSE_TIME.LABEL',
          placeholder: 'SLA.FORM.FIRST_RESPONSE_TIME.PLACEHOLDER',
        },
        {
          threshold: null,
          unit: 'Minutes',
          label: 'SLA.FORM.NEXT_RESPONSE_TIME.LABEL',
          placeholder: 'SLA.FORM.NEXT_RESPONSE_TIME.PLACEHOLDER',
        },
        {
          threshold: null,
          unit: 'Minutes',
          label: 'SLA.FORM.RESOLUTION_TIME.LABEL',
          placeholder: 'SLA.FORM.RESOLUTION_TIME.PLACEHOLDER',
        },
      ],
      onlyDuringBusinessHours: false,
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'sla/getUIFlags',
    }),
    isSubmitDisabled() {
      return this.$v.name.$invalid || this.uiFlags.isUpdating;
    },
  },
  mounted() {
    if (this.selectedResponse) this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    setFormValues() {
      const {
        name,
        description,
        first_response_time_threshold: firstResponseTimeThreshold,
        next_response_time_threshold: nextResponseTimeThreshold,
        resolution_time_threshold: resolutionTimeThreshold,
        only_during_business_hours: onlyDuringBusinessHours,
      } = this.selectedResponse;

      this.name = name;
      this.description = description;
      this.onlyDuringBusinessHours = onlyDuringBusinessHours;

      const thresholds = [
        firstResponseTimeThreshold,
        nextResponseTimeThreshold,
        resolutionTimeThreshold,
      ];

      const labels = [
        'SLA.FORM.FIRST_RESPONSE_TIME.LABEL',
        'SLA.FORM.NEXT_RESPONSE_TIME.LABEL',
        'SLA.FORM.RESOLUTION_TIME.LABEL',
      ];
      const placeholders = [
        'SLA.FORM.FIRST_RESPONSE_TIME.PLACEHOLDER',
        'SLA.FORM.NEXT_RESPONSE_TIME.PLACEHOLDER',
        'SLA.FORM.RESOLUTION_TIME.PLACEHOLDER',
      ];

      this.slaTimeInputs = thresholds.map((threshold, index) => ({
        threshold: this.convertToUnit(threshold).time,
        unit: this.convertToUnit(threshold).unit,
        label: labels[index],
        placeholder: placeholders[index],
      }));
    },
    updateThreshold(index, value) {
      this.slaTimeInputs[index].threshold = value;
    },
    updateUnit(index, unit) {
      this.slaTimeInputs[index].unit = unit;
    },
    onSubmit() {
      const payload = {
        name: this.name,
        description: this.description,
        first_response_time_threshold: this.convertToSeconds(
          this.slaTimeInputs[0].threshold,
          this.slaTimeInputs[0].unit
        ),
        next_response_time_threshold: this.convertToSeconds(
          this.slaTimeInputs[1].threshold,
          this.slaTimeInputs[1].unit
        ),
        resolution_time_threshold: this.convertToSeconds(
          this.slaTimeInputs[2].threshold,
          this.slaTimeInputs[2].unit
        ),
        only_during_business_hours: this.onlyDuringBusinessHours,
      };
      this.$emit('submit', payload);
    },
    convertToSeconds(time, unit) {
      const unitsToSeconds = { Minutes: 60, Hours: 3600, Days: 86400 };
      return Number(time * (unitsToSeconds[unit] || 1));
    },
    convertToUnit(seconds) {
      if (seconds < 3600) return { time: seconds / 60, unit: 'Minutes' };
      if (seconds < 86400) return { time: seconds / 3600, unit: 'Hours' };
      return { time: Number(seconds / 86400), unit: 'Days' };
    },
  },
};
</script>
