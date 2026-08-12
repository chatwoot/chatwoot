<script>
import { mapGetters } from 'vuex';
import validations from './validations';
import SlaTimeInput from './SlaTimeInput.vue';
import SlaAlertRecipients from './SlaAlertRecipients.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import { useVuelidate } from '@vuelidate/core';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

const DEFAULT_TIME_INPUTS = [
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
];

export default {
  components: {
    SlaTimeInput,
    SlaAlertRecipients,
    NextButton,
    SidePanel,
    ToggleSwitch,
  },
  props: {
    mode: {
      type: String,
      default: 'create',
    },
  },
  emits: ['submitSla'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      name: '',
      description: '',
      isSlaTimeInputsInvalid: false,
      slaTimeInputsValidation: {},
      slaTimeInputs: structuredClone(DEFAULT_TIME_INPUTS),
      onlyDuringBusinessHours: false,
      notifyUserIds: [],
      isAlertRecipientsInvalid: false,
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'sla/getUIFlags',
    }),
    isEditing() {
      return this.mode === 'edit';
    },
    panelTitle() {
      return this.isEditing
        ? this.$t('SLA.EDIT.TITLE')
        : this.$t('SLA.ADD.TITLE');
    },
    panelDescription() {
      return this.isEditing
        ? this.$t('SLA.EDIT.DESC')
        : this.$t('SLA.ADD.DESC');
    },
    submitLabel() {
      return this.isEditing
        ? this.$t('SLA.FORM.EDIT')
        : this.$t('SLA.FORM.CREATE');
    },
    isSubmitDisabled() {
      return (
        this.v$.name.$invalid ||
        this.isSlaTimeInputsInvalid ||
        this.isAlertRecipientsInvalid ||
        this.uiFlags.isUpdating
      );
    },
    slaNameErrorMessage() {
      let errorMessage = '';
      if (this.v$.name.$error) {
        if (!this.v$.name.required) {
          errorMessage = this.$t('SLA.FORM.NAME.REQUIRED_ERROR');
        } else if (!this.v$.name.minLength) {
          errorMessage = this.$t('SLA.FORM.NAME.MINIMUM_LENGTH_ERROR');
        }
      }
      return errorMessage;
    },
  },
  methods: {
    // The record is passed in on open, the prop on the parent updates only a tick later
    open(sla) {
      this.resetForm();
      if (sla) this.setFormValues(sla);
      this.$refs.panelRef.open();
    },
    close() {
      this.$refs.panelRef.close();
    },
    resetForm() {
      this.name = '';
      this.description = '';
      this.notifyUserIds = [];
      this.onlyDuringBusinessHours = false;
      this.slaTimeInputs = structuredClone(DEFAULT_TIME_INPUTS);
      this.slaTimeInputsValidation = {};
      this.isSlaTimeInputsInvalid = false;
      this.v$.$reset();
    },
    setFormValues({ name, description, notify_user_ids: notifyUserIds }) {
      this.name = name;
      this.description = description;
      this.notifyUserIds = notifyUserIds || [];
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
        notify_user_ids: this.notifyUserIds,
      };

      // Thresholds and business hours are locked once the SLA is created
      if (!this.isEditing) {
        payload.first_response_time_threshold = this.convertToSeconds(0);
        payload.next_response_time_threshold = this.convertToSeconds(1);
        payload.resolution_time_threshold = this.convertToSeconds(2);
        payload.only_during_business_hours = this.onlyDuringBusinessHours;
      }

      this.$emit('submitSla', payload);
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

<template>
  <SidePanel
    ref="panelRef"
    width="xl"
    :title="panelTitle"
    :description="panelDescription"
  >
    <div class="flex flex-wrap w-full mx-0">
      <woot-input
        v-model="name"
        :class="{ error: v$.name.$error }"
        class="w-full"
        :styles="{
          borderRadius: '0.75rem',
          padding: '0.375rem 0.75rem',
          fontSize: '0.875rem',
        }"
        :label="$t('SLA.FORM.NAME.LABEL')"
        :placeholder="$t('SLA.FORM.NAME.PLACEHOLDER')"
        :error="slaNameErrorMessage"
        @input="v$.name.$touch"
        @blur="v$.name.$touch"
      />
      <woot-input
        v-model="description"
        class="w-full"
        :styles="{
          borderRadius: '0.75rem',
          padding: '0.375rem 0.75rem',
          fontSize: '0.875rem',
        }"
        :label="$t('SLA.FORM.DESCRIPTION.LABEL')"
        :placeholder="$t('SLA.FORM.DESCRIPTION.PLACEHOLDER')"
      />

      <template v-if="!isEditing">
        <SlaTimeInput
          v-for="(input, index) in slaTimeInputs"
          :key="index"
          :threshold="input.threshold"
          :threshold-unit="input.unit"
          :label="$t(input.label)"
          :placeholder="$t(input.placeholder)"
          @update-threshold="updateThreshold(index, $event)"
          @unit="updateUnit(index, $event)"
          @is-in-valid="handleIsInvalid(index, $event)"
        />

        <div
          class="mt-3 flex h-10 items-center text-sm w-full gap-2 border border-solid border-n-strong px-3 py-1.5 rounded-xl justify-between"
        >
          <span for="sla_bh" class="text-n-slate-11">
            {{ $t('SLA.FORM.BUSINESS_HOURS.PLACEHOLDER') }}
          </span>
          <ToggleSwitch id="sla_bh" v-model="onlyDuringBusinessHours" />
        </div>
      </template>

      <SlaAlertRecipients
        v-model="notifyUserIds"
        @is-invalid="isAlertRecipientsInvalid = $event"
      />
    </div>
    <template #footer>
      <div class="flex flex-row justify-end w-full gap-2">
        <NextButton
          faded
          slate
          type="button"
          :label="$t('SLA.FORM.CANCEL')"
          @click="close"
        />
        <NextButton
          type="button"
          :label="submitLabel"
          :disabled="isSubmitDisabled"
          :is-loading="uiFlags.isUpdating"
          @click="onSubmit"
        />
      </div>
    </template>
  </SidePanel>
</template>
