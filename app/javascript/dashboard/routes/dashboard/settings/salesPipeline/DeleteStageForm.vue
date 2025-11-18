<template>
  <div class="space-y-4">
    <div class="p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
      <div class="flex">
        <div class="flex-shrink-0">
          <fluent-icon icon="warning" class="text-yellow-400" />
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
            {{ $t('SALES_PIPELINE_SETTINGS.DELETE.WARNING_TITLE') }}
          </h3>
          <div class="mt-2 text-sm text-yellow-700 dark:text-yellow-300">
            <p>{{ $t('SALES_PIPELINE_SETTINGS.DELETE.WARNING_MESSAGE', { stageName: stage.name }) }}</p>
            <p v-if="stage.conversations_count > 0" class="mt-1">
              {{ $t('SALES_PIPELINE_SETTINGS.DELETE.CONVERSATIONS_WARNING', { count: stage.conversations_count }) }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <form @submit.prevent="onSubmit">
      <!-- Migration Stage Selection -->
      <div v-if="stage.conversations_count > 0">
        <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
          {{ $t('SALES_PIPELINE_SETTINGS.DELETE.MIGRATE_STAGE') }} *
        </label>
        <select
          v-model="migrationStageId"
          required
          class="w-full rounded-lg border border-slate-300 dark:border-slate-600 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-50"
        >
          <option value="">
            {{ $t('SALES_PIPELINE_SETTINGS.DELETE.SELECT_STAGE') }}
          </option>
          <option
            v-for="availableStage in availableStages"
            :key="availableStage.id"
            :value="availableStage.id"
          >
            {{ availableStage.name }}
          </option>
        </select>
        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
          {{ $t('SALES_PIPELINE_SETTINGS.DELETE.MIGRATION_NOTE') }}
        </p>
      </div>

      <!-- Confirmation Text -->
      <div>
        <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
          {{ $t('SALES_PIPELINE_SETTINGS.DELETE.CONFIRMATION_LABEL') }}
        </label>
        <input
          v-model="confirmationText"
          type="text"
          required
          class="w-full rounded-lg border border-slate-300 dark:border-slate-600 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-50"
          :placeholder="stage.name"
        />
        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
          {{ $t('SALES_PIPELINE_SETTINGS.DELETE.TYPE_STAGE_NAME', { stageName: stage.name }) }}
        </p>
      </div>

      <!-- Form Actions -->
      <div class="flex justify-end space-x-3 pt-4 border-t border-slate-200 dark:border-slate-700 mt-6">
        <button
          type="button"
          class="btn btn--secondary"
          @click="$emit('cancel')"
        >
          {{ $t('SALES_PIPELINE_SETTINGS.DELETE.CANCEL') }}
        </button>
        <button
          type="submit"
          class="btn btn--danger"
          :disabled="!canDelete"
        >
          <spinner v-if="isDeleting" size="small" />
          {{ $t('SALES_PIPELINE_SETTINGS.DELETE.CONFIRM_DELETE') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'DeleteStageForm',
  components: {
    Spinner,
  },
  props: {
    stage: {
      type: Object,
      required: true,
    },
    stages: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      migrationStageId: '',
      confirmationText: '',
      isDeleting: false,
    };
  },
  computed: {
    availableStages() {
      return this.stages.filter(s => s.id !== this.stage.id);
    },
    canDelete() {
      if (this.stage.conversations_count > 0) {
        return this.migrationStageId && this.confirmationText === this.stage.name;
      }
      return this.confirmationText === this.stage.name;
    },
  },
  methods: {
    async onSubmit() {
      if (!this.canDelete) return;

      this.isDeleting = true;
      try {
        await this.$emit('confirm', this.migrationStageId);
      } finally {
        this.isDeleting = false;
      }
    },
  },
};
</script>