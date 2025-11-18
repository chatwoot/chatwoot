<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div class="border-b border-slate-200 dark:border-slate-700 px-4 py-3">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-medium text-slate-900 dark:text-slate-50">
          {{ $t('SALES_PIPELINE_SETTINGS.TITLE') }}
        </h2>
        
        <button
          class="btn btn--primary"
          @click="showCreateStageModal = true"
        >
          <fluent-icon icon="add-circle" />
          {{ $t('SALES_PIPELINE_SETTINGS.ADD_STAGE') }}
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto p-4">
      <div v-if="uiFlags.isFetching" class="flex items-center justify-center h-64">
        <spinner size="large" />
      </div>

      <div v-else class="max-w-6xl mx-auto">
        <!-- Pipeline Info -->
        <div class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-6 mb-6">
          <h3 class="text-lg font-medium text-slate-900 dark:text-slate-50 mb-4">
            {{ $t('SALES_PIPELINE_SETTINGS.PIPELINE_INFO') }}
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                {{ $t('SALES_PIPELINE_SETTINGS.PIPELINE_NAME') }}
              </label>
              <input
                v-model="pipelineName"
                type="text"
                class="w-full rounded-lg border border-slate-300 dark:border-slate-600 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-50"
                @blur="updatePipelineName"
              />
            </div>
            <div class="flex items-end">
              <div class="text-sm text-slate-600 dark:text-slate-400">
                <div>{{ $t('SALES_PIPELINE_SETTINGS.TOTAL_STAGES') }}: {{ stages.length }}</div>
                <div>{{ $t('SALES_PIPELINE_SETTINGS.ACTIVE_STAGES') }}: {{ activeStagesCount }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Stages List -->
        <div class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700">
          <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
            <h3 class="text-lg font-medium text-slate-900 dark:text-slate-50">
              {{ $t('SALES_PIPELINE_SETTINGS.STAGES_LIST') }}
            </h3>
          </div>

          <div v-if="stages.length === 0" class="p-8 text-center">
            <div class="text-slate-500 dark:text-slate-400 mb-4">
              {{ $t('SALES_PIPELINE_SETTINGS.NO_STAGES') }}
            </div>
            <button
              class="btn btn--primary"
              @click="showCreateStageModal = true"
            >
              {{ $t('SALES_PIPELINE_SETTINGS.CREATE_FIRST_STAGE') }}
            </button>
          </div>

          <div v-else class="divide-y divide-slate-200 dark:divide-slate-700">
            <draggable
              v-model="localStages"
              group="stages"
              @end="onStageOrderChange"
              handle=".drag-handle"
            >
              <div
                v-for="stage in localStages"
                :key="stage.id"
                class="p-4 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center space-x-4">
                    <!-- Drag Handle -->
                    <div class="drag-handle cursor-move text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
                      <fluent-icon icon="drag" />
                    </div>

                    <!-- Stage Color -->
                    <div class="flex items-center space-x-2">
                      <div
                        class="w-8 h-8 rounded-full border-2 border-white dark:border-slate-900 shadow-sm"
                        :style="{ backgroundColor: stage.color }"
                      />
                    </div>

                    <!-- Stage Info -->
                    <div>
                      <div class="flex items-center space-x-2">
                        <h4 class="font-medium text-slate-900 dark:text-slate-50">
                          {{ stage.name }}
                        </h4>
                        <span
                          v-if="stage.is_default"
                          class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
                        >
                          {{ $t('SALES_PIPELINE_SETTINGS.DEFAULT_STAGE') }}
                        </span>
                        <span
                          v-if="stage.is_closed_won"
                          class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                        >
                          {{ $t('SALES_PIPELINE_SETTINGS.CLOSED_WON') }}
                        </span>
                        <span
                          v-if="stage.is_closed_lost"
                          class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                        >
                          {{ $t('SALES_PIPELINE_SETTINGS.CLOSED_LOST') }}
                        </span>
                      </div>
                      <div class="text-sm text-slate-500 dark:text-slate-400">
                        {{ $t('SALES_PIPELINE_SETTINGS.POSITION') }}: {{ stage.position }}
                        {{ stage.conversations_count ? `• ${stage.conversations_count} ${$t('SALES_PIPELINE_SETTINGS.CONVERSATIONS')}` : '' }}
                      </div>
                    </div>
                  </div>

                  <!-- Actions -->
                  <div class="flex items-center space-x-2">
                    <button
                      class="btn btn--secondary btn--sm"
                      @click="editStage(stage)"
                    >
                      <fluent-icon icon="edit" />
                    </button>
                    <button
                      class="btn btn--secondary btn--sm"
                      @click="deleteStage(stage)"
                      :disabled="stage.conversations_count > 0"
                    >
                      <fluent-icon icon="delete" />
                    </button>
                  </div>
                </div>
              </div>
            </draggable>
          </div>
        </div>
      </div>
    </div>

    <!-- Create/Edit Stage Modal -->
    <woot-modal
      :show.sync="showCreateStageModal"
      :on-close="hideStageModal"
      :title="editingStage ? $t('SALES_PIPELINE_SETTINGS.EDIT_STAGE') : $t('SALES_PIPELINE_SETTINGS.CREATE_STAGE')"
    >
      <stage-form
        :stage="editingStage"
        :stages="stages"
        @submit="handleStageSubmit"
        @cancel="hideStageModal"
      />
    </woot-modal>

    <!-- Delete Stage Modal -->
    <woot-modal
      :show.sync="showDeleteModal"
      :on-close="hideDeleteModal"
      :title="$t('SALES_PIPELINE_SETTINGS.DELETE_STAGE_TITLE')"
    >
      <delete-stage-form
        :stage="deletingStage"
        :stages="stages"
        @confirm="handleDeleteConfirm"
        @cancel="hideDeleteModal"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import draggable from 'vuedraggable';
import Spinner from 'shared/components/Spinner.vue';
import StageForm from './StageForm.vue';
import DeleteStageForm from './DeleteStageForm.vue';

export default {
  name: 'SalesPipelineSettings',
  components: {
    Spinner,
    draggable,
    StageForm,
    DeleteStageForm,
  },
  data() {
    return {
      pipelineName: '',
      showCreateStageModal: false,
      showDeleteModal: false,
      editingStage: null,
      deletingStage: null,
      localStages: [],
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'salesPipeline/getUIFlags',
      stages: 'salesPipeline/getStages',
      salesPipeline: 'salesPipeline/getSalesPipeline',
      currentAccountId: 'getCurrentAccountId',
    }),
    activeStagesCount() {
      return this.stages.filter(stage => !stage.is_closed_won && !stage.is_closed_lost).length;
    },
  },
  watch: {
    stages: {
      handler(newStages) {
        this.localStages = [...newStages];
      },
      immediate: true,
    },
    salesPipeline: {
      handler(newPipeline) {
        if (newPipeline) {
          this.pipelineName = newPipeline.name;
        }
      },
      immediate: true,
    },
  },
  mounted() {
    this.loadPipelineData();
  },
  methods: {
    async loadPipelineData() {
      try {
        await this.$store.dispatch('salesPipeline/fetchSalesPipeline', {
          accountId: this.currentAccountId,
        });
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE_SETTINGS.ERROR.LOAD_FAILED'));
      }
    },

    async updatePipelineName() {
      if (!this.salesPipeline || this.pipelineName === this.salesPipeline.name) {
        return;
      }

      try {
        await this.$store.dispatch('salesPipeline/updatePipeline', {
          accountId: this.currentAccountId,
          pipelineId: this.salesPipeline.id,
          pipelineData: { name: this.pipelineName },
        });
        this.showSuccessMessage(this.$t('SALES_PIPELINE_SETTINGS.SUCCESS.PIPELINE_UPDATED'));
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE_SETTINGS.ERROR.UPDATE_FAILED'));
      }
    },

    editStage(stage) {
      this.editingStage = { ...stage };
      this.showCreateStageModal = true;
    },

    deleteStage(stage) {
      this.deletingStage = stage;
      this.showDeleteModal = true;
    },

    async handleStageSubmit(stageData) {
      try {
        if (this.editingStage) {
          await this.$store.dispatch('salesPipeline/updateStage', {
            accountId: this.currentAccountId,
            stageId: this.editingStage.id,
            stageData,
          });
          this.showSuccessMessage(this.$t('SALES_PIPELINE_SETTINGS.SUCCESS.STAGE_UPDATED'));
        } else {
          await this.$store.dispatch('salesPipeline/createStage', {
            accountId: this.currentAccountId,
            stageData,
          });
          this.showSuccessMessage(this.$t('SALES_PIPELINE_SETTINGS.SUCCESS.STAGE_CREATED'));
        }
        this.hideStageModal();
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE_SETTINGS.ERROR.STAGE_SAVE_FAILED'));
      }
    },

    async handleDeleteConfirm(migrationStageId) {
      try {
        await this.$store.dispatch('salesPipeline/deleteStage', {
          accountId: this.currentAccountId,
          stageId: this.deletingStage.id,
          migrationStageId,
        });
        this.showSuccessMessage(this.$t('SALES_PIPELINE_SETTINGS.SUCCESS.STAGE_DELETED'));
        this.hideDeleteModal();
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE_SETTINGS.ERROR.STAGE_DELETE_FAILED'));
      }
    },

    async onStageOrderChange() {
      try {
        const stages = this.localStages.map((stage, index) => ({
          id: stage.id,
          position: index + 1,
        }));

        await this.$store.dispatch('salesPipeline/reorderStages', {
          accountId: this.currentAccountId,
          stages,
        });
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE_SETTINGS.ERROR.REORDER_FAILED'));
        // Revert to original order
        this.localStages = [...this.stages];
      }
    },

    hideStageModal() {
      this.showCreateStageModal = false;
      this.editingStage = null;
    },

    hideDeleteModal() {
      this.showDeleteModal = false;
      this.deletingStage = null;
    },

    showErrorMessage(message) {
      this.$root.$emit('newToastMessage', {
        message,
        type: 'error',
      });
    },

    showSuccessMessage(message) {
      this.$root.$emit('newToastMessage', {
        message,
        type: 'success',
      });
    },
  },
};
</script>