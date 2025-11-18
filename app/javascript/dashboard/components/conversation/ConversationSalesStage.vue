<template>
  <div class="mb-4">
    <div class="flex items-center justify-between mb-2">
      <h4 class="text-sm font-medium text-slate-700 dark:text-slate-300">
        {{ $t('CONVERSATION_SIDEBAR.SALES_STAGE') }}
      </h4>
      <button
        v-if="stages.length > 0"
        v-tooltip.top="$t('CONVERSATION_SIDEBAR.REMOVE_STAGE')"
        class="text-slate-400 hover:text-slate-600 dark:text-slate-500 dark:hover:text-slate-300"
        @click="removeStage"
      >
        <fluent-icon icon="dismiss" size="14" />
      </button>
    </div>

    <div v-if="uiFlags.isFetching" class="flex items-center justify-center py-3">
      <spinner size="small" />
    </div>

    <div v-else-if="stages.length === 0" class="text-center py-3">
      <div class="text-sm text-slate-500 dark:text-slate-400 mb-2">
        {{ $t('CONVERSATION_SIDEBAR.NO_PIPELINE_CONFIGURED') }}
      </div>
      <router-link
        :to="settingsRoute"
        class="text-xs text-woot-500 hover:text-woot-600 dark:text-woot-400 dark:hover:text-woot-300"
      >
        {{ $t('CONVERSATION_SIDEBAR.CONFIGURE_PIPELINE') }}
      </router-link>
    </div>

    <div v-else>
      <!-- Current Stage Display -->
      <div v-if="currentStage" class="mb-3">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <div
              class="w-3 h-3 rounded-full"
              :style="{ backgroundColor: currentStage.color }"
            />
            <span class="text-sm font-medium text-slate-900 dark:text-slate-50">
              {{ currentStage.name }}
            </span>
          </div>
          <button
            v-tooltip.top="$t('CONVERSATION_SIDEBAR.CHANGE_STAGE')"
            class="text-slate-400 hover:text-slate-600 dark:text-slate-500 dark:hover:text-slate-300"
            @click="showStageSelector = !showStageSelector"
          >
            <fluent-icon icon="chevron-down" size="14" />
          </button>
        </div>
      </div>

      <!-- No Stage Selected -->
      <div v-else class="mb-3">
        <button
          class="w-full text-left px-3 py-2 border border-dashed border-slate-300 dark:border-slate-600 rounded-lg text-sm text-slate-500 dark:text-slate-400 hover:border-slate-400 dark:hover:border-slate-500 hover:text-slate-600 dark:hover:text-slate-300 transition-colors"
          @click="showStageSelector = !showStageSelector"
        >
          {{ $t('CONVERSATION_SIDEBAR.SELECT_STAGE') }}
        </button>
      </div>

      <!-- Stage Selector Dropdown -->
      <div v-if="showStageSelector" class="mb-3">
        <div class="relative">
          <div class="absolute inset-0 bg-black opacity-25 z-10" @click="showStageSelector = false" />
          <div class="relative z-20 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg shadow-lg">
            <div class="max-h-48 overflow-y-auto">
              <button
                v-for="stage in stages"
                :key="stage.id"
                class="w-full text-left px-3 py-2 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors border-b border-slate-100 dark:border-slate-700 last:border-b-0"
                @click="selectStage(stage)"
              >
                <div class="flex items-center space-x-2">
                  <div
                    class="w-3 h-3 rounded-full flex-shrink-0"
                    :style="{ backgroundColor: stage.color }"
                  />
                  <div class="flex-1">
                    <div class="text-sm font-medium text-slate-900 dark:text-slate-50">
                      {{ stage.name }}
                    </div>
                    <div v-if="stage.is_default" class="text-xs text-slate-500 dark:text-slate-400">
                      {{ $t('CONVERSATION_SIDEBAR.DEFAULT_STAGE') }}
                    </div>
                    <div v-else-if="stage.is_closed_won" class="text-xs text-green-600 dark:text-green-400">
                      {{ $t('CONVERSATION_SIDEBAR.CLOSED_WON') }}
                    </div>
                    <div v-else-if="stage.is_closed_lost" class="text-xs text-red-600 dark:text-red-400">
                      {{ $t('CONVERSATION_SIDEBAR.CLOSED_LOST') }}
                    </div>
                  </div>
                  <div v-if="currentStage && currentStage.id === stage.id">
                    <fluent-icon icon="checkmark" class="text-green-500" />
                  </div>
                </div>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div v-if="currentStage && !showStageSelector" class="flex flex-wrap gap-1">
        <button
          v-for="quickStage in quickActionStages"
          :key="quickStage.id"
          class="inline-flex items-center px-2 py-1 rounded text-xs font-medium transition-colors"
          :style="{
            backgroundColor: quickStage.color + '20',
            color: quickStage.color,
            border: `1px solid ${quickStage.color}40`
          }"
          @click="selectStage(quickStage)"
        >
          {{ quickStage.name }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';
import FluentIcon from 'shared/components/FluentIcon.vue';

export default {
  name: 'ConversationSalesStage',
  components: {
    Spinner,
    FluentIcon,
  },
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      currentStage: null,
      showStageSelector: false,
      isUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'salesPipeline/getUIFlags',
      stages: 'salesPipeline/getStages',
      defaultStage: 'salesPipeline/getDefaultStage',
      currentAccountId: 'getCurrentAccountId',
    }),
    settingsRoute() {
      return frontendURL(`accounts/${this.currentAccountId}/settings/sales-pipeline`);
    },
    quickActionStages() {
      // Show next 2 stages as quick actions, or previous 2 if at the end
      if (!this.currentStage) return [];
      
      const currentIndex = this.stages.findIndex(s => s.id === this.currentStage.id);
      const nextStages = this.stages.slice(currentIndex + 1, currentIndex + 3);
      
      if (nextStages.length > 0) return nextStages;
      
      // If no next stages, show previous ones
      const prevStages = this.stages.slice(Math.max(0, currentIndex - 2), currentIndex);
      return prevStages.reverse();
    },
  },
  mounted() {
    this.loadCurrentStage();
  },
  methods: {
    async loadCurrentStage() {
      try {
        const response = await this.$store.dispatch('salesPipeline/fetchConversationStage', {
          accountId: this.currentAccountId,
          conversationId: this.conversationId,
        });
        this.currentStage = response.data.current_stage;
      } catch (error) {
        // Conversation might not have a stage, that's okay
        this.currentStage = null;
      }
    },

    async selectStage(stage) {
      if (this.isUpdating || this.currentStage?.id === stage.id) {
        this.showStageSelector = false;
        return;
      }

      this.isUpdating = true;
      try {
        await this.$store.dispatch('salesPipeline/updateConversationStage', {
          accountId: this.currentAccountId,
          conversationId: this.conversationId,
          stageId: stage.id,
        });
        
        this.currentStage = stage;
        this.showStageSelector = false;
        
        // Show success message
        this.$root.$emit('newToastMessage', {
          message: this.$t('CONVERSATION_SIDEBAR.STAGE_UPDATED', { stageName: stage.name }),
          type: 'success',
        });
      } catch (error) {
        this.$root.$emit('newToastMessage', {
          message: this.$t('CONVERSATION_SIDEBAR.ERROR.UPDATE_FAILED'),
          type: 'error',
        });
      } finally {
        this.isUpdating = false;
      }
    },

    async removeStage() {
      if (this.isUpdating || !this.currentStage) return;

      this.isUpdating = true;
      try {
        await this.$store.dispatch('salesPipeline/removeConversationStage', {
          accountId: this.currentAccountId,
          conversationId: this.conversationId,
        });
        
        this.currentStage = null;
        this.showStageSelector = false;
        
        // Show success message
        this.$root.$emit('newToastMessage', {
          message: this.$t('CONVERSATION_SIDEBAR.STAGE_REMOVED'),
          type: 'success',
        });
      } catch (error) {
        this.$root.$emit('newToastMessage', {
          message: this.$t('CONVERSATION_SIDEBAR.ERROR.REMOVE_FAILED'),
          type: 'error',
        });
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>