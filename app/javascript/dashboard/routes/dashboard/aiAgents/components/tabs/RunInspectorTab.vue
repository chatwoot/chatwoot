<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import AiAgentsAPI from 'dashboard/api/saas/aiAgents';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  agent: { type: Object, required: true },
});

const { t } = useI18n();

const runs = ref([]);
const isLoading = ref(false);
const selectedRun = ref(null);
const selectedRunDetail = ref(null);
const isLoadingDetail = ref(false);

async function fetchRuns() {
  isLoading.value = true;
  try {
    const response = await AiAgentsAPI.getWorkflowRuns(props.agent.id);
    runs.value = response.data?.data || [];
  } catch {
    runs.value = [];
  } finally {
    isLoading.value = false;
  }
}

async function selectRun(run) {
  selectedRun.value = run;
  isLoadingDetail.value = true;
  try {
    const response = await AiAgentsAPI.getWorkflowRun(props.agent.id, run.id);
    selectedRunDetail.value = response.data;
  } catch {
    selectedRunDetail.value = null;
  } finally {
    isLoadingDetail.value = false;
  }
}

function statusColor(status) {
  const colors = {
    running: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
    waiting:
      'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
    completed:
      'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300',
    failed: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300',
    handed_off:
      'bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300',
  };
  return colors[status] || colors.running;
}

function nodeStatusIcon(status) {
  return status === 'completed'
    ? 'i-lucide-check-circle text-green-500'
    : 'i-lucide-x-circle text-red-500';
}

function formatDuration(ms) {
  if (!ms) return '-';
  if (ms < 1000) return `${ms}ms`;
  return `${(ms / 1000).toFixed(1)}s`;
}

function formatTime(iso) {
  if (!iso) return '-';
  return new Date(iso).toLocaleString();
}

onMounted(fetchRuns);
</script>

<template>
  <div
    class="flex h-[calc(100vh-12rem)] overflow-hidden rounded-xl border border-n-weak"
  >
    <!-- Left: Run list -->
    <div class="flex w-80 flex-col border-r border-n-weak bg-n-background">
      <div class="border-b border-n-weak px-4 py-3">
        <h3 class="text-sm font-semibold text-n-slate-12">
          {{ t('AI_AGENTS.WORKFLOW.RUNS.TITLE') }}
        </h3>
      </div>

      <div v-if="isLoading" class="flex flex-1 items-center justify-center">
        <Spinner />
      </div>

      <div
        v-else-if="runs.length === 0"
        class="flex flex-1 items-center justify-center p-4"
      >
        <p class="text-center text-sm text-n-slate-8">
          {{ t('AI_AGENTS.WORKFLOW.RUNS.EMPTY') }}
        </p>
      </div>

      <div v-else class="flex-1 overflow-y-auto">
        <button
          v-for="run in runs"
          :key="run.id"
          class="flex w-full items-center gap-3 border-b border-n-weak px-4 py-3 text-left transition-colors hover:bg-n-alpha-1"
          :class="{ 'bg-n-alpha-2': selectedRun?.id === run.id }"
          @click="selectRun(run)"
        >
          <span
            class="inline-flex shrink-0 rounded-full px-2 py-0.5 text-[10px] font-semibold"
            :class="statusColor(run.status)"
          >
            {{ run.status }}
          </span>
          <div class="min-w-0 flex-1">
            <div class="truncate text-xs text-n-slate-11">
              {{
                t('AI_AGENTS.WORKFLOW.RUNS.CONVERSATION_LABEL', {
                  id: run.conversation_id,
                })
              }}
            </div>
            <div class="text-[10px] text-n-slate-8">
              {{ formatTime(run.started_at) }}
            </div>
          </div>
          <span class="text-[10px] text-n-slate-8">
            {{ formatDuration(run.duration_ms) }}
          </span>
        </button>
      </div>
    </div>

    <!-- Right: Run detail -->
    <div class="flex flex-1 flex-col bg-white dark:bg-n-solid-3">
      <div v-if="!selectedRun" class="flex flex-1 items-center justify-center">
        <p class="text-sm text-n-slate-8">
          {{ t('AI_AGENTS.WORKFLOW.RUNS.SELECT_RUN') }}
        </p>
      </div>

      <div
        v-else-if="isLoadingDetail"
        class="flex flex-1 items-center justify-center"
      >
        <Spinner />
      </div>

      <div
        v-else-if="selectedRunDetail"
        class="flex flex-1 flex-col overflow-hidden"
      >
        <!-- Detail header -->
        <div class="flex items-center gap-3 border-b border-n-weak px-6 py-4">
          <span
            class="inline-flex rounded-full px-2 py-0.5 text-xs font-semibold"
            :class="statusColor(selectedRunDetail.status)"
          >
            {{ selectedRunDetail.status }}
          </span>
          <div class="flex-1 text-xs text-n-slate-10">
            <span>{{
              t('AI_AGENTS.WORKFLOW.RUNS.DURATION_LABEL', {
                value: formatDuration(selectedRunDetail.duration_ms),
              })
            }}</span>
            {{ ' \u00B7 ' }}
            <span>{{
              t('AI_AGENTS.WORKFLOW.RUNS.TOKENS_LABEL', {
                count: selectedRunDetail.total_tokens || 0,
              })
            }}</span>
          </div>
        </div>

        <!-- Execution timeline -->
        <div class="flex-1 overflow-y-auto p-6">
          <h4
            class="mb-3 text-xs font-semibold uppercase tracking-wider text-n-slate-8"
          >
            {{ t('AI_AGENTS.WORKFLOW.RUNS.EXECUTION_LOG') }}
          </h4>
          <div class="space-y-2">
            <div
              v-for="(entry, idx) in selectedRunDetail.execution_log"
              :key="idx"
              class="flex items-start gap-3 rounded-lg border border-n-weak p-3"
            >
              <span
                :class="nodeStatusIcon(entry.status)"
                class="mt-0.5 shrink-0 text-sm"
              />
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-semibold text-n-slate-12">
                    {{ entry.node_type }}
                  </span>
                  <span class="text-[10px] text-n-slate-8">
                    {{ entry.node_id }}
                  </span>
                  <span class="ml-auto text-[10px] text-n-slate-8">
                    {{ formatDuration(entry.duration_ms) }}
                  </span>
                </div>
                <div v-if="entry.error" class="mt-1 text-xs text-red-600">
                  {{ entry.error }}
                </div>
                <pre
                  v-if="entry.output"
                  class="mt-1 max-h-32 overflow-auto rounded bg-n-alpha-2 p-2 font-mono text-[10px] text-n-slate-10"
                  >{{ JSON.stringify(entry.output, null, 2) }}</pre
                >
              </div>
            </div>
          </div>

          <!-- Variables -->
          <h4
            v-if="
              selectedRunDetail.variables &&
              Object.keys(selectedRunDetail.variables).length
            "
            class="mb-3 mt-6 text-xs font-semibold uppercase tracking-wider text-n-slate-8"
          >
            {{ t('AI_AGENTS.WORKFLOW.RUNS.VARIABLES') }}
          </h4>
          <pre
            v-if="
              selectedRunDetail.variables &&
              Object.keys(selectedRunDetail.variables).length
            "
            class="max-h-48 overflow-auto rounded-lg border border-n-weak bg-n-alpha-2 p-4 font-mono text-xs text-n-slate-10"
            >{{ JSON.stringify(selectedRunDetail.variables, null, 2) }}</pre
          >
        </div>
      </div>
    </div>
  </div>
</template>
