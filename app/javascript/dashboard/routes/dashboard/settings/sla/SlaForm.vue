<template>
  <div class="h-auto overflow-auto flex flex-col">
    <form class="mx-0 flex flex-wrap" @submit.prevent="onSubmit">
      <woot-input
        v-model.trim="name"
        :class="{ error: $v.name.$error }"
        class="w-full"
        :sla="$t('SLA.FORM.NAME.LABEL')"
        :placeholder="$t('SLA.FORM.NAME.PLACEHOLDER')"
        :error="getSlaNameErrorMessage"
        @input="$v.name.$touch"
      />
      <woot-input
        v-model.trim="description"
        class="w-full"
        :label="$t('SLA.FORM.DESCRIPTION.LABEL')"
        :placeholder="$t('SLA.FORM.DESCRIPTION.PLACEHOLDER')"
        data-testid="sla-description"
      />

      <woot-input
        v-model.trim="firstResponseTimeThreshold"
        class="w-full"
        :label="$t('SLA.FORM.FIRST_RESPONSE_TIME.LABEL')"
        :placeholder="$t('SLA.FORM.FIRST_RESPONSE_TIME.PLACEHOLDER')"
        data-testid="sla-firstResponseTimeThreshold"
      />

      <woot-input
        v-model.trim="nextResponseTimeThreshold"
        class="w-full"
        :label="$t('SLA.FORM.NEXT_RESPONSE_TIME.LABEL')"
        :placeholder="$t('SLA.FORM.NEXT_RESPONSE_TIME.PLACEHOLDER')"
        data-testid="sla-nextResponseTimeThreshold"
      />

      <woot-input
        v-model.trim="resolutionTimeThreshold"
        class="w-full"
        :label="$t('SLA.FORM.RESOLUTION_TIME.LABEL')"
        :placeholder="$t('SLA.FORM.RESOLUTION_TIME.PLACEHOLDER')"
        data-testid="sla-resolutionTimeThreshold"
      />

      <div class="w-full">
        <input id="sla_bh" v-model="onlyDuringBusinessHours" type="checkbox" />
        <label for="sla_bh">
          {{ $t('SLA.FORM.BUSINESS_HOURS.PLACEHOLDER') }}
        </label>
      </div>

      <div class="flex justify-end items-center py-2 px-0 gap-2 w-full">
        <woot-button
          :is-disabled="$v.name.$invalid || uiFlags.isUpdating"
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

export default {
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
      firstResponseTimeThreshold: '',
      nextResponseTimeThreshold: '',
      resolutionTimeThreshold: '',
      onlyDuringBusinessHours: false,
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'sla/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('SLA.EDIT.TITLE')} - ${
        this.selectedResponse?.name || ''
      }`;
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
      this.firstResponseTimeThreshold = firstResponseTimeThreshold;
      this.nextResponseTimeThreshold = nextResponseTimeThreshold;
      this.resolutionTimeThreshold = resolutionTimeThreshold;
      this.onlyDuringBusinessHours = onlyDuringBusinessHours;
    },
    onSubmit() {
      this.$emit('submit', {
        name: this.name,
        description: this.description,
        first_response_time_threshold: this.firstResponseTimeThreshold,
        next_response_time_threshold: this.nextResponseTimeThreshold,
        resolution_time_threshold: this.resolutionTimeThreshold,
        only_during_business_hours: this.onlyDuringBusinessHours,
      });
    },
  },
};
</script>
