<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import aiAgents from '../../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
});

async function fetchKnowledge(idAgent) {
  try {
    const data = await aiAgents.getKnowledgeSources(idAgent);
    docs.value = data.data?.knowledge_source_texts || [];
  } catch (e) {
    useAlert('Gagal mendapatkan dapat');
  }
}

async function updateKnowledge(data) {
  const summerNoteBtn = document.getElementsByClassName(
    'save-btn-summernote'
  )[0];
  try {
    summerNoteBtn.setAttribute('disabled', '');
    await aiAgents.updateKnowledgeText(props.data.id, data);
    useAlert('Berhasil disimpan');
  } catch (e) {
    useAlert('Gagal simpan dapat');
  } finally {
    summerNoteBtn.removeAttribute('disabled');
  }
}

const docs = ref([]);
const selectedDocIndex = ref(0);
const selectedDoc = computed(() =>
  docs.value.find((v, i) => i === selectedDocIndex.value)
);
watch(
  () => props.data,
  v => {
    const idAgent = v?.id;
    if (idAgent) {
      fetchKnowledge(idAgent);
    }
  },
  {
    immediate: true,
    deep: true,
  }
);
watch(
  docs,
  v => {
    selectedDocIndex.value = 0;
  },
  {
    once: true,
  }
);
watch(
  selectedDoc,
  (newValue, prevValue) => {
    var markupStr = $('#summernote').summernote('code');
    if (prevValue) {
      prevValue.text = markupStr;
    }

    nextTick(() => {
      const text = newValue?.text || '';
      $('#summernote').summernote('code', text);
    });
  },
  {
    immediate: true,
  }
);

onMounted(() => {
  var SaveButton = function (context) {
    var ui = $.summernote.ui;

    // create button
    var button = ui.button({
      contents: 'Simpan',
      tooltip: 'Simpan',
      className:
        'save-btn-summernote bg-n-brand text-white hover:bg-n-brand hover:text-white font-[Inter]',
      click: function () {
        var markupStr = $('#summernote').summernote('code');
        updateKnowledge({
          ...selectedDoc.value,
          text: markupStr,
        });
      },
    });

    return button.render(); // return button as jquery object
  };

  $('#summernote').summernote({
    shortcuts: false,
    tabsize: 2,
    height: 300,
    width: '100%',
    callbacks: {
      onChange: function (contents, $editable) {
        const summerNoteBtn = document.getElementsByClassName(
          'save-btn-summernote'
        )[0];
        if (contents && contents !== '<br>') {
          summerNoteBtn.removeAttribute('disabled');
        } else {
          summerNoteBtn.setAttribute('disabled', '');
        }
      },
    },
    toolbar: [
      // ['style', ['style']],
      ['font', ['bold', 'underline', 'clear']],
      // ['color', ['color']],
      ['para', ['ul', 'ol', 'paragraph']],
      // ['table', ['table']],
      // ['insert', ['link', 'picture', 'video']],
      // ['view', ['fullscreen', 'codeview', 'help']]
      ['mybutton', ['SaveButton']],
    ],
    buttons: {
      SaveButton: SaveButton,
    },
  });
});

const loadingAdd = ref(false);
async function addDoc() {
  loadingAdd.value = true;
  const maxTaNum =
    docs.value.reduce(function (prev, current) {
      return prev > current.tab ? prev : current;
    }, 0) || undefined;
  const nextTabNum = (maxTaNum?.tab || 0) + 1;
  const request = {
    id: null,
    text: '<br>',
    tab: nextTabNum,
  };
  try {
    await aiAgents
      .addKnowledgeText(props.data.id, {
        ...request,
      })
      .then(v => {
        docs.value.push({
          ...v.data,
        });
        selectedDocIndex.value = docs.value.findIndex(
          v => v.tab === nextTabNum
        );
        useAlert('Berhasil ditambahkan');
      })
      .catch(v => {
        useAlert('Gagal menambahkan');
      });
  } catch (e) {
    useAlert('Gagal menambahkan');
  } finally {
    loadingAdd.value = false;
  }
}

function selectDoc(index) {
  selectedDocIndex.value = index;
}

const showDeleteModal = ref();
const deleteModalData = ref();
function deleteDoc(index) {
  showDeleteModal.value = true;
  deleteModalData.value = docs.value.find((v, i) => i === index);
}
async function deleteData() {
  try {
    showDeleteModal.value = false;
    await aiAgents.deleteKnowledgeText(props.data.id, deleteModalData.value.id);
    docs.value = docs.value.filter(v => v.id !== deleteModalData.value.id);
    selectedDocIndex.value = 0;
    useAlert('Berhasil hapus data');
  } catch (e) {
    useAlert('Gagal hapus data');
  }
}
</script>

<template>
  <div class="flex flex-col justify-stretch gap-4">
    <div class="flex flex-row gap-2">
      <Button
        icon="i-lucide-plus"
        :disabled="loadingAdd"
        @click="() => addDoc()"
      />
      <div class="flex-1 min-w-0 flex flex-row gap-2">
        <div
          v-for="(item, index) in docs"
          :key="index"
          class="cursor-pointer flex flex-row gap-2 rounded bg-n-gray-3 dark:bg-n-solid-3 px-3 items-center"
          :class="{
            border: selectedDocIndex === index,
          }"
          @click="
            e => {
              selectDoc(index);
            }
          "
        >
          <span>Tab {{ item.tab }}</span>
          <Button
            icon="i-lucide-x"
            variant="link"
            @click="
              e => {
                e.stopPropagation();
                deleteDoc(index);
              }
            "
          />
        </div>
      </div>
    </div>
    <div v-show="selectedDoc">
      <div id="summernote" />
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
      title="Are you sure you want to delete this AI Agent?"
      message="You cannot undo this action"
      :confirm-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.DELETE')"
      :reject-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.CANCEL')"
    />
  </div>
</template>

<style lang="css">
.note-editing-area {
  background: white;
}
</style>
