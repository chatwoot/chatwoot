<template>
  <div class="flex flex-col h-auto overflow-auto">
    <form class="flex flex-wrap mx-0" @submit.prevent="onSubmit">
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
        @isInValid="handleIsInvalid(index, $event)"
      />

      <div class="flex items-center w-full gap-2">
        <input id="sla_bh" v-model="onlyDuringBusinessHours" type="checkbox" />
        <label for="sla_bh">
          {{ $t('SLA.FORM.BUSINESS_HOURS.PLACEHOLDER') }}
        </label>
      </div>

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
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
import { convertSecondsToTimeUnit } from '@chatwoot/utils';
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
      isSlaTimeInputsInvalid: false,
      slaTimeInputsValidation: {},
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
      return (
        this.$v.name.$invalid ||
        this.isSlaTimeInputsInvalid ||
        this.uiFlags.isUpdating
      );
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
      this.slaTimeInputs.forEach((input, index) => {
        const converted = convertSecondsToTimeUnit(thresholds[index], {
          minute: 'Minutes',
          hour: 'Hours',
          day: 'Days',
        });
        input.threshold = converted.time;
        input.unit = converted.unit;
      });
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
        first_response_time_threshold: this.convertToSeconds(0),
        next_response_time_threshold: this.convertToSeconds(1),
        resolution_time_threshold: this.convertToSeconds(2),
        only_during_business_hours: this.onlyDuringBusinessHours,
      };
      this.$emit('submit', payload);
    },
    convertToSeconds(index) {
      const { threshold, unit } = this.slaTimeInputs[index];
      if (threshold === null || threshold === 0) return null;
      const unitsToSeconds = { Minutes: 60, Hours: 3600, Days: 86400 };
      return Number(threshold * (unitsToSeconds[unit] || 1));
    },
    handleIsInvalid(index, isInvalid) {
      this.slaTimeInputsValidation = {
        ...this.slaTimeInputsValidation,
        [index]: isInvalid,
      };

      this.checkValidationState();
    },
    checkValidationState() {
      const isAnyInvalid = Object.values(this.slaTimeInputsValidation).some(
        isInvalid => isInvalid
      );
      this.isSlaTimeInputsInvalid = isAnyInvalid;
    },
  },
};
</script>
