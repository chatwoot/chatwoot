<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header
      :header-title="$t('SLA.ADD.TITLE')"
      :header-content="$t('SLA.ADD.DESC')"
    />
    <form class="mx-0 flex flex-wrap" @submit.prevent="addSLA">
      <woot-input
        v-model.trim="name"
        :class="{ error: $v.name.$error }"
        class="w-full sla-name--input"
        :label="$t('SLA.FORM.NAME.LABEL')"
        :placeholder="$t('SLA.FORM.NAME.PLACEHOLDER')"
        :error="getSlaNameErrorMessage"
        data-testid="sla-name"
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

      <woot-input
        v-model.trim="onlyDuringBusinessHours"
        class="w-full"
        :label="$t('SLA.FORM.BUSINESS_HOURS.LABEL')"
        :placeholder="$t('SLA.FORM.BUSINESS_HOURS.PLACEHOLDER')"
        data-testid="sla-onlyDuringBusinessHours"
      />

      <div class="flex justify-end items-center py-2 px-0 gap-2 w-full">
        <woot-button
          :is-disabled="$v.name.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
          data-testid="sla-submit"
        >
          {{ $t('SLA.FORM.CREATE') }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="onClose">
          {{ $t('SLA.FORM.CANCEL') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import validationMixin from './validationMixin';
import { mapGetters } from 'vuex';
import validations from './validations';

export default {
  mixins: [alertMixin, validationMixin],
  props: {},
  data() {
    return {
      name: '',
      description: '',
      firstResponseTimeThreshold: '',
      nextResponseTimeThreshold: '',
      resolutionTimeThreshold: '',
      onlyDuringBusinessHours: '',
      showOnSidebar: true,
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'sla/getUIFlags',
    }),
  },
  mounted() {},
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addSLA() {
      try {
        await this.$store.dispatch('sla/create', {
          name: this.name,
          description: this.description,
          first_response_time_threshold: this.firstResponseTimeThreshold,
          next_response_time_threshold: this.nextResponseTimeThreshold,
          resolution_time_threshold: this.resolutionTimeThreshold,
          only_during_business_hours: this.onlyDuringBusinessHours,
        });
        this.showAlert(this.$t('SLA.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('SLA.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
  },
};
</script>
<style lang="scss" scoped></style>
