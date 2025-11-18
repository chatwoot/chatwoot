<template>
  <div class="space-y-4">
    <form @submit.prevent="onSubmit">
      <div class="space-y-4">
        <!-- Stage Name -->
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
            {{ $t('SALES_PIPELINE_SETTINGS.FORM.NAME') }} *
          </label>
          <input
            v-model="form.name"
            type="text"
            required
            class="w-full rounded-lg border border-slate-300 dark:border-slate-600 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-50"
            :placeholder="$t('SALES_PIPELINE_SETTINGS.FORM.NAME_PLACEHOLDER')"
          />
        </div>

        <!-- Stage Color -->
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
            {{ $t('SALES_PIPELINE_SETTINGS.FORM.COLOR') }} *
          </label>
          <div class="flex items-center space-x-3">
            <input
              v-model="form.color"
              type="color"
              class="h-10 w-20 rounded border border-slate-300 dark:border-slate-600"
            />
            <input
              v-model="form.color"
              type="text"
              required
              class="flex-1 rounded-lg border border-slate-300 dark:border-slate-600 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-50"
              placeholder="#1f93ff"
            />
          </div>
        </div>

        <!-- Position -->
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
            {{ $t('SALES_PIPELINE_SETTINGS.FORM.POSITION') }} *
          </label>
          <select
            v-model.number="form.position"
            required
            class="w-full rounded-lg border border-slate-300 dark:border-slate-600 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-50"
          >
            <option
              v-for="i in availablePositions"
              :key="i"
              :value="i"
            >
              {{ i }}
            </option>
          </select>
        </div>

        <!-- Stage Type Flags -->
        <div class="space-y-3">
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">
            {{ $t('SALES_PIPELINE_SETTINGS.FORM.STAGE_TYPE') }}
          </label>

          <div class="space-y-2">
            <label class="flex items-center">
              <input
                v-model="form.is_default"
                type="checkbox"
                class="rounded border-slate-300 text-woot-500 focus:ring-woot-500 dark:border-slate-600 dark:bg-slate-800"
                @change="handleDefaultChange"
              />
              <span class="ml-2 text-sm text-slate-700 dark:text-slate-300">
                {{ $t('SALES_PIPELINE_SETTINGS.FORM.IS_DEFAULT') }}
              </span>
            </label>

            <label class="flex items-center">
              <input
                v-model="form.is_closed_won"
                type="checkbox"
                class="rounded border-slate-300 text-woot-500 focus:ring-woot-500 dark:border-slate-600 dark:bg-slate-800"
                @change="handleClosedWonChange"
              />
              <span class="ml-2 text-sm text-slate-700 dark:text-slate-300">
                {{ $t('SALES_PIPELINE_SETTINGS.FORM.IS_CLOSED_WON') }}
              </span>
            </label>

            <label class="flex items-center">
              <input
                v-model="form.is_closed_lost"
                type="checkbox"
                class="rounded border-slate-300 text-woot-500 focus:ring-woot-500 dark:border-slate-600 dark:bg-slate-800"
                @change="handleClosedLostChange"
              />
              <span class="ml-2 text-sm text-slate-700 dark:text-slate-300">
                {{ $t('SALES_PIPELINE_SETTINGS.FORM.IS_CLOSED_LOST') }}
              </span>
            </label>
          </div>
        </div>
      </div>

      <!-- Form Actions -->
      <div class="flex justify-end space-x-3 pt-4 border-t border-slate-200 dark:border-slate-700 mt-6">
        <button
          type="button"
          class="btn btn--secondary"
          @click="$emit('cancel')"
        >
          {{ $t('SALES_PIPELINE_SETTINGS.FORM.CANCEL') }}
        </button>
        <button
          type="submit"
          class="btn btn--primary"
          :disabled="isSubmitting"
        >
          <spinner v-if="isSubmitting" size="small" />
          {{ stage ? $t('SALES_PIPELINE_SETTINGS.FORM.UPDATE') : $t('SALES_PIPELINE_SETTINGS.FORM.CREATE') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';
import FluentIcon from 'shared/components/FluentIcon.vue';

export default {
  name: 'StageForm',
  components: {
    Spinner,
    FluentIcon,
  },
  props: {
    stage: {
      type: Object,
      default: () => null,
    },
    stages: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      form: {
        name: '',
        color: '#1f93ff',
        position: 1,
        is_default: false,
        is_closed_won: false,
        is_closed_lost: false,
      },
      isSubmitting: false,
    };
  },
  computed: {
    availablePositions() {
      if (this.stage) {
        return this.stages.length;
      }
      return this.stages.length + 1;
    },
  },
  mounted() {
    if (this.stage) {
      this.form = { ...this.stage };
    } else {
      this.form.position = this.stages.length + 1;
    }
  },
  methods: {
    handleDefaultChange() {
      if (this.form.is_default) {
        this.form.is_closed_won = false;
        this.form.is_closed_lost = false;
      }
    },

    handleClosedWonChange() {
      if (this.form.is_closed_won) {
        this.form.is_default = false;
        this.form.is_closed_lost = false;
      }
    },

    handleClosedLostChange() {
      if (this.form.is_closed_lost) {
        this.form.is_default = false;
        this.form.is_closed_won = false;
      }
    },

    async onSubmit() {
      this.isSubmitting = true;
      try {
        await this.$emit('submit', { ...this.form });
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>