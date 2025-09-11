<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
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

const charLimit = 2500

const textCounter = ref(0)

function getLengthElement(e) {
  return e.currentTarget.innerText?.trim()?.length || 0
}

function countCharacter(e) {
  textCounter.value = getLengthElement(e)
}

onMounted(() => {
  var SaveButton = function (context) {
    var ui = $.summernote.ui;

    // create button
    var button = ui.button({
      contents: 'Simpan',
      tooltip: 'Simpan',
      className:
        'save-btn-summernote bg-primary-green text-white hover:bg-primary-green hover:text-white font-[Inter]',
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

  let prevKeyCode = undefined

  $('#summernote').summernote({
    shortcuts: false,
    tabsize: 2,
    height: 300,
    width: '100%',
    placeholder: t('AGENT_MGMT.TEXT_KNOWLEDGE_PLACEHOLDER'),
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
      onKeydown: function(e) {
        if (getLengthElement(e) >= charLimit) {
          const selectAll = (prevKeyCode === 17 || prevKeyCode === 224) && e.keyCode === 65
          if (e.keyCode != 8 && !selectAll && !(e.keyCode >= 37 && e.keyCode <= 40) && e.keyCode != 46 && !(e.keyCode == 88 && e.ctrlKey) && !(e.keyCode == 67 && e.ctrlKey)) {
            e.preventDefault()
          }
        }
        prevKeyCode = e.keyCode
      },
      onKeyup: function(e) {
        if (e.keyCode === prevKeyCode) {
          prevKeyCode = undefined
        }
        countCharacter(e)
      },
      onPaste: function(e) {
        const tlength = getLengthElement(e)
        countCharacter(e)
        var t = e.currentTarget.innerText;
        var bufferText = ((e.originalEvent || e).clipboardData || window.clipboardData).getData('Text');
        e.preventDefault();
        var maxPaste = bufferText.length;
        if (t.length + bufferText.length > charLimit) {
          maxPaste = charLimit - t.length;
        }
        if (maxPaste > 0) {
          document.execCommand('insertText', false, bufferText.substring(0, maxPaste));
        }
        $('#summernote').text(charLimit - tlength);
      }
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
    let knowledgeId = data.id
    if (!docs.value.length) {
      const request = {
        id: null,
        text: '<br>',
        tab: 1,
      };
      let addResponse = await aiAgents
        .addKnowledgeText(props.data.id, {
          ...request,
        })
      knowledgeId = addResponse.data?.id
    }

    await aiAgents.updateKnowledgeText(props.data.id, {
      id: knowledgeId,
      tab: 1,
      text: data.text,
    });
    useAlert('Berhasil disimpan');
  } catch (e) {
    useAlert('Gagal simpan dapat');
  } finally {
    summerNoteBtn.removeAttribute('disabled');
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
    <!-- <div class="flex flex-row gap-2">
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
    </div> -->
    <div>
      <div id="summernote" />
      <div class="flex flex-row items-end justify-end">
        <span>{{ textCounter }} / {{ charLimit }}</span>
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
