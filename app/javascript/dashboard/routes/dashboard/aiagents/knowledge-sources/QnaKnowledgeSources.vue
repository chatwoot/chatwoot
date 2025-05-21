<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import aiAgents from '../../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
});

const qnas = ref([]);
const reachedMaxQnas = computed(() => qnas.value.length >= 25)
const isFetching = ref(false);
async function fetchKnowledge() {
  try {
    isFetching.value = true;
    const data = await aiAgents.getKnowledgeSources(props.data.id);
    qnas.value = data.data?.knowledge_source_qnas || [];
  } catch (e) {
    useAlert('Gagal mendapatkan dapat');
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
      useAlert('Berhasil hapus data');
    }
    qnas.value = qnas.value.filter((v, i) => v.id !== dataId || i != itemIndex);
  } catch (e) {
    useAlert('Gagal hapus data');
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
    useAlert('Berhasil simpan data');
  } catch (e) {
    useAlert('Gagal simpan data');
  } finally {
    isSaving.value = false;
  }
}

function addQna() {
  if (reachedMaxQnas.value) {
    return
  }
  qnas.value.push({});
  nextTick(() => {
    document.getElementById('btnAddQna').scrollIntoView({
      behavior: 'smooth',
      block: 'end',
    });
  });
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

      <div class="flex flex-col gap-5">
        <div
          v-for="(item, index) in qnas"
          :key="index"
          class="rounded-lg bg-n-gray-3/30 px-6 py-3 flex flex-col gap-2"
        >
          <div class="flex gap-6">
            <div class="flex flex-col gap-2 w-full">
              <span class="text-sm"> Pertanyaan </span>
              <TextArea v-model="item.question" showCharacterCount="true" :maxLength="maxCharQuestion" />
            </div>
            <div class="flex flex-col gap-2 w-full">
              <span class="text-sm"> Jawaban </span>
              <TextArea v-model="item.answer" showCharacterCount="true" :maxLength="maxCharAnswer" />
            </div>
          </div>
          <div class="flex flex-row">
            <Button
              variant="ghost"
              color="ruby"
              icon="i-lucide-trash"
              :is-loading="deleteLoadingIds[item.id]"
              :disabled="deleteLoadingIds[item.id]"
              @click="() => deleteQna(item, index)"
            />
          </div>
        </div>
      </div>

      <Button id="btnAddQna" :disabled="reachedMaxQnas" class="scroll-m-4" @click="addQna">
        Tambah QnA
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
    <div class="w-[200px] flex flex-col gap-2 px-2">
      <div class="sticky top-0 flex flex-col gap-2 px-2">
        <div class="flex flex-col gap-0">
          <span>QnA</span>
          <span class="text-xl font-bold">{{ qnas.length }}</span>
        </div>
        <Button
          class="w-full mt-2"
          :is-loading="isSaving"
          :disabled="isSaving"
          @click="() => save()"
        >
          Simpan
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
