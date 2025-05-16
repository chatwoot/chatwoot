<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import aiAgents from '../../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n()

const files = ref([]);
const detectedCharacters = computed(() =>
  files.value.reduce((p, i) => p + i.total_chars, 0)
);
const isFetching = ref(false);
async function fetchKnowledge() {
  try {
    isFetching.value = true;
    const data = await aiAgents.getKnowledgeSources(props.data.id);
    files.value = data.data?.knowledge_source_files || [];
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
function deleteFile(data) {
  deleteModalData.value = files.value.find(v => v.id === data.id);
  showDeleteModal.value = true;
}
const deleteLoadingIds = ref({});
async function deleteData() {
  const dataId = deleteModalData.value.id;
  try {
    showDeleteModal.value = false;
    deleteLoadingIds.value[dataId] = true;
    await aiAgents.deleteKnowledgeFile(props.data.id, dataId);
    files.value = files.value.filter(v => v.id !== dataId);
    fetchKnowledge();
    useAlert('Berhasil hapus data');
  } catch (e) {
    useAlert('Gagal hapus data');
  } finally {
    deleteLoadingIds.value[dataId] = false;
  }
}

const newFiles = ref([]);
function inputFile() {
  return document.getElementById('inputfile');
}
function openPicker() {
  inputFile().click();
}
function onInputChanged(files) {
  if (!files.target.files || !files.target.files.length) {
    return;
  }
  addFile(files.target.files[0])
  inputFile().value = '';
}

function addFile(file) {
  if (!file.name.endsWith('.pdf')) {
    return
  }
  if (file.size > 5242880) {
    useAlert(t('CONVERSATION.UPLOAD_MAX_REACHED'))
    return
  }
  newFiles.value.push(file);
}

const isSaving = ref(false);
async function save() {
  if (!newFiles.value.length) {
    return;
  }

  try {
    isSaving.value = true;

    const calls = newFiles.value.map(async v => {
      const formData = new FormData();
      for (const element of newFiles.value) {
        formData.append('file', element);
      }

      await aiAgents.addKnowledgeFile(props.data.id, formData);
    });
    await Promise.all(calls);
    newFiles.value = [];
    fetchKnowledge();
    useAlert('Berhasil simpan data');
  } catch (e) {
    useAlert('Gagal simpan data');
  } finally {
    isSaving.value = false;
  }
}

const handleDragOver = () => {
}

const handleDragLeave = () => {
}

const handleDrop = (event) => {
    const files = event.dataTransfer?.files
    if (!files || !files.length || files.length > 1) {
        return
    }
    addFile(files.item(0))
}
</script>

<template>
  <div class="flex flex-row gap-4">
    <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-4">
      <div v-if="isFetching" class="text-center">
        <span class="mt-4 mb-4 spinner" />
      </div>
      <div
        class="border border-dashed rounded px-5 p-10 flex items-center justify-center cursor-pointer"
        @click="openPicker"
        @dragover.prevent="handleDragOver" @dragleave="handleDragLeave"
        @drop.prevent="handleDrop"
      >
        <input
          id="inputfile"
          type="file"
          class="hidden"
          accept=".pdf"
          @change="v => onInputChanged(v)"
        />
        <span class="text-center">
          <span> {{ $t("CONVERSATION.PLACEHOLDER_UPLOAD.PART_1") }} </span>
          <br />
          <span> {{ $t("CONVERSATION.PLACEHOLDER_UPLOAD.PART_2") }} </span>
        </span>
      </div>

      <div>
        <span> File yg sudah ditambahkan: </span>
        <div class="py-2">
          <div
            v-for="(item, index) in files"
            :key="index"
            class="flex flex-row gap-2 items-center"
          >
            <span>- {{ item.file_name }}</span>
            <span class="font-bold">{{ item.total_chars }} karakter</span>
            <Button
              variant="ghost"
              color="ruby"
              size="sm"
              icon="i-lucide-trash"
              :is-loading="deleteLoadingIds[item.id]"
              @click="() => deleteFile(item)"
            />
          </div>
        </div>
      </div>

      <div>
        <span> File yang akan ditambahkan: </span>
        <div class="py-2">
          <div
            v-for="(item, index) in newFiles"
            :key="index"
            class="flex flex-row gap-2 items-center"
          >
            <span>- {{ item?.name }} </span>
            <Button
              variant="ghost"
              color="ruby"
              size="sm"
              icon="i-lucide-trash"
              @click="
                () => {
                  newFiles.splice(index, 1);
                }
              "
            />
          </div>
        </div>
      </div>

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
      <div class="flex flex-col gap-0">
        <span>Files</span>
        <span class="text-xl font-bold">{{ files.length }}</span>
      </div>
      <!-- <div class="flex flex-col gap-0">
                <span>Input Karakter</span>
                <span class="text-3xl font-bold">6</span>
            </div>
            <div class="flex flex-col gap-0">
                <span>Links</span>
                <span class="text-3xl font-bold">6</span>
            </div> -->
      <!-- <div class="flex flex-col gap-0">
                <span>Q&A</span>
                <span class="text-3xl font-bold">6</span>
            </div> -->
      <div class="flex flex-col gap-0">
        <span>Karakter yg terdeteksi</span>
        <span class="text-xl font-bold">{{ detectedCharacters }}</span>
      </div>
      <Button
        class="w-full mt-2"
        :is-loading="isSaving"
        :disabled="isSaving || !newFiles.length"
        @click="() => save()"
      >
        Simpan
      </Button>
    </div>
  </div>
</template>

<style lang="css">
.note-editing-area {
  background: white;
}
</style>
