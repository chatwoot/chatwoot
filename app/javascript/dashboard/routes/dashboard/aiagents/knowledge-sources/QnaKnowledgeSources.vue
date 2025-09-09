<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import aiAgents from '../../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n()

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
});

const maxQna = 25
const qnas = ref([]);
const expandedQnas = ref({}); // Track expanded state for each QnA
const reachedMaxQnas = computed(() => qnas.value.length >= maxQna)
const isFetching = ref(false);
async function fetchKnowledge() {
  try {
    isFetching.value = true;
    const data = await aiAgents.getKnowledgeSources(props.data.id);
    qnas.value = data.data?.knowledge_source_qnas || [];
  } catch (e) {
    useAlert(t('AGENT_MGMT.QNA.FETCH_ERROR'));
  } finally {
    isFetching.value = false;
  }
}

watch(
  () => props.data,
  v => {
    if (!v) {
      return;
    }
    fetchKnowledge();
  },
  {
    immediate: true,
    deep: true,
  }
);

const showDeleteModal = ref();
const deleteModalData = ref();
function deleteQna(data, index) {
  deleteModalData.value = {
    ...data,
    itemIndex: index,
  };
  showDeleteModal.value = true;
}
const deleteLoadingIds = ref({});
async function deleteData() {
  const dataId = deleteModalData.value.id;
  const itemIndex = deleteModalData.value.itemIndex;
  try {
    showDeleteModal.value = false;
    deleteLoadingIds.value[dataId] = true;
    if (dataId) {
      await aiAgents.deleteKnowledgeQna(props.data.id, dataId);
      fetchKnowledge();
      useAlert(t('AGENT_MGMT.QNA.SAVE_SUCCESS'));
    }
    qnas.value = qnas.value.filter((v, i) => v.id !== dataId || i != itemIndex);
  } catch (e) {
    useAlert(t('AGENT_MGMT.QNA.SAVE_ERROR'));
  } finally {
    deleteLoadingIds.value[dataId] = false;
  }
}

const isSaving = ref(false);
async function save() {
  try {
    isSaving.value = true;

    const request = qnas.value
      .map(e => {
        return {
          id: e.id || null,
          question: e.question?.trim(),
          answer: e.answer?.trim(),
        };
      })
      .filter(t => t.question && t.answer);
    await aiAgents.createOrUpdateKnowledgeQna(props.data.id, request);
    fetchKnowledge();
    useAlert(t('AGENT_MGMT.QNA.SAVE_SUCCESS'));
  } catch (e) {
    useAlert(t('AGENT_MGMT.QNA.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
}

function addQna() {
  if (reachedMaxQnas.value) {
    return
  }
  const newIndex = qnas.value.length;
  qnas.value.push({});
  // Auto-expand the newly added QnA
  expandedQnas.value[newIndex] = true;
  nextTick(() => {
    document.getElementById('btnAddQna').scrollIntoView({
      behavior: 'smooth',
      block: 'end',
    });
  });
}

function toggleQnaExpand(index) {
  expandedQnas.value[index] = !expandedQnas.value[index];
}

const maxCharQuestion = 150
const maxCharAnswer = 700
</script>

<template>
  <div class="flex flex-row gap-4">
    <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-4">
      <div v-if="isFetching" class="text-center">
        <span class="mt-4 mb-4 spinner" />
      </div>

      <div class="space-y-4">
        <div
          v-for="(item, index) in qnas"
          :key="index"
          class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl hover:shadow-md transition-all duration-200 hover:border-slate-300 dark:hover:border-slate-600"
        >
          <div 
            class="flex items-center justify-between p-4 cursor-pointer"
            @click="() => toggleQnaExpand(index)"
          >
            <div class="flex items-center gap-3">
              <div class="w-2 h-2 bg-green-500 rounded-full"></div>
              <h3 class="text-sm font-medium text-slate-700 dark:text-slate-300">
                QnA #{{ index + 1 }}
              </h3>
              <span v-if="item.question" class="text-xs text-slate-500 dark:text-slate-400 truncate max-w-xs">
                - {{ item.question }}
              </span>
            </div>
            <div class="flex items-center gap-2">
              <Button
                variant="ghost"
                color="ruby"
                icon="i-lucide-trash"
                size="sm"
                :is-loading="deleteLoadingIds[item.id]"
                :disabled="deleteLoadingIds[item.id]"
                @click.stop="() => deleteQna(item, index)"
                class="opacity-70 hover:opacity-100"
              />
              <svg 
                class="w-4 h-4 text-slate-400 transition-transform duration-200"
                :class="{ 'rotate-180': expandedQnas[index] }"
                fill="none" 
                stroke="currentColor" 
                viewBox="0 0 24 24"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
              </svg>
            </div>
          </div>
          
          <div 
            v-show="expandedQnas[index]"
            class="px-4 pb-4 border-t border-slate-200 dark:border-slate-700"
          >
            <div class="pt-4 grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">
                  {{ $t('AGENT_MGMT.QUESTION_LABEL') }} <span class="text-red-500">*</span>
                </label>
                <div class="relative">
                  <TextArea 
                    v-model="item.question" 
                    showCharacterCount="true" 
                    :maxLength="maxCharQuestion" 
                    :placeholder="$t('AGENT_MGMT.QNA_PLACEHOLDER.QUESTION')"
                    class="w-full"
                  />
                </div>
              </div>
              
              <div class="space-y-2">
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">
                  {{ $t('AGENT_MGMT.ANSWER_LABEL') }} <span class="text-red-500">*</span>
                </label>
                <div class="relative">
                  <TextArea 
                    v-model="item.answer" 
                    showCharacterCount="true" 
                    :maxLength="maxCharAnswer" 
                    :placeholder="$t('AGENT_MGMT.QNA_PLACEHOLDER.ANSWER')"
                    class="w-full"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <Button 
        id="btnAddQna" 
        :disabled="reachedMaxQnas" 
        class="w-full py-3 border-2 border-dashed border-slate-300 dark:border-slate-600 text-slate-500 dark:text-slate-400 hover:border-green-400 hover:text-green-600 transition-all duration-200 rounded-xl bg-transparent hover:bg-green-50 dark:hover:bg-green-900/10 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:border-slate-300 disabled:hover:text-slate-500 disabled:hover:bg-transparent" 
        variant="ghost"
        @click="addQna"
      >
        <span class="flex items-center gap-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          {{ $t('AGENT_MGMT.QNA.ADD_QNA') }}
        </span>
      </Button>

      <woot-delete-modal
        v-if="showDeleteModal"
        v-model:show="showDeleteModal"
        class="context-menu--delete-modal"
        :on-close="
          () => {
            showDeleteModal = false;
          }
        "
        :on-confirm="() => deleteData()"
        title="Apakah kamu akan menghapus data ini?"
        message="Kamu tidak akan mengembalikan data ini"
        :confirm-text="
          $t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.DELETE')
        "
        :reject-text="
          $t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.CANCEL')
        "
      />
    </div>
    <div class="w-[240px] flex flex-col gap-3">
      <div class="sticky top-4 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 shadow-sm">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
            <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
          </div>
          <div>
            <h3 class="font-semibold text-slate-700 dark:text-slate-300">QnA</h3>
            <p class="text-sm text-slate-500 dark:text-slate-400">{{ qnas.length }}/{{ maxQna }}</p>
          </div>
        </div>
        
        <Button
          class="w-full"
          :is-loading="isSaving"
          :disabled="isSaving"
          @click="() => save()"
        >
          <span class="flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            {{ $t('AGENT_MGMT.CSBOT.TICKET.SAVE_BUTTON') }}
          </span>
        </Button>
      </div>
    </div>
  </div>
</template>

<style lang="css">
.note-editing-area {
  background: white;
}
</style>
