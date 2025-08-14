<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import aiAgents from '../../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import * as XLSX from 'xlsx';
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
  const fileData = deleteModalData.value;
  
  try {
    showDeleteModal.value = false;
    deleteLoadingIds.value[dataId] = true;
    
    // Check if it's an Excel file by file name or type
    const isExcelFile = fileData.file_name?.endsWith('.xlsx') || 
                       fileData.file_name?.endsWith('.xls') ||
                       fileData.file_type === 'excel_import';
    
    if (isExcelFile) {
      // Use Excel-specific delete API
      await aiAgents.deleteExcelKnowledgeFile(props.data.id, dataId);
    } else {
      // Use regular file delete API
      await aiAgents.deleteKnowledgeFile(props.data.id, dataId);
    }
    
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
const showExcelPreviewModal = ref(false);
const excelPreviewData = ref([]);
const excelHeaders = ref([]);
const pendingExcelFile = ref(null);
const parsedExcelData = ref(null); // Store parsed data to avoid double parsing
const excelDescription = ref(''); // Store description text for Excel file
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
  if (!file.name.endsWith('.pdf') && !file.name.endsWith('.xlsx') && !file.name.endsWith('.xls')) {
    useAlert('Only PDF and Excel files are allowed')
    return
  }
  if (file.size > 5242880) {
    useAlert(t('CONVERSATION.UPLOAD_MAX_REACHED'))
    return
  }
  
  // If it's an Excel file, show preview modal
  if (file.name.endsWith('.xlsx') || file.name.endsWith('.xls')) {
    previewExcelFile(file);
  } else {
    // For PDF files, add directly
    newFiles.value.push(file);
  }
}

async function previewExcelFile(file) {
  try {
    const arrayBuffer = await file.arrayBuffer();
    const workbook = XLSX.read(arrayBuffer, { type: 'array' });
    
    // Get the first worksheet
    const firstSheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[firstSheetName];
    
    // Convert to JSON
    const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    
    if (jsonData.length > 0) {
      const headers = jsonData[0] || [];
      const rows = jsonData.slice(1);
      
      // Store full parsed data for later use
      parsedExcelData.value = {
        headers,
        rows,
        file_name: file.name,
        file_type: file.type || 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        file_size: file.size
      };
      
      // Set preview data (first 10 rows)
      excelHeaders.value = headers;
      excelPreviewData.value = rows.slice(0, 10);
      pendingExcelFile.value = file;
      showExcelPreviewModal.value = true;
    } else {
      useAlert('Excel file appears to be empty');
    }
  } catch (error) {
    useAlert('Error reading Excel file: ' + error.message);
  }
}

function closeExcelPreview() {
  showExcelPreviewModal.value = false;
  excelPreviewData.value = [];
  excelHeaders.value = [];
  pendingExcelFile.value = null;
  parsedExcelData.value = null; // Clear parsed data
  excelDescription.value = ''; // Clear description
}

function confirmExcelUpload() {
  if (pendingExcelFile.value && parsedExcelData.value) {
    // Add both the file and parsed data to newFiles, preserving original file properties
    const fileWithParsedData = {
      // Preserve all original file properties first
      name: pendingExcelFile.value.name,
      size: pendingExcelFile.value.size,
      type: pendingExcelFile.value.type,
      lastModified: pendingExcelFile.value.lastModified,
      // Add any other file properties
      ...pendingExcelFile.value,
      // Then add our parsed data
      parsedData: parsedExcelData.value,
      description: excelDescription.value // Include description
    };
    newFiles.value.push(fileWithParsedData);
    closeExcelPreview();
  }
}

const isSaving = ref(false);
async function save() {
  if (!newFiles.value.length) {
    return;
  }

  try {
    isSaving.value = true;

    // Process each file separately based on type
    for (const file of newFiles.value) {
      if (file.name.endsWith('.xlsx') || file.name.endsWith('.xls')) {
        // Handle Excel files
        await handleExcelFileUpload(file);
      } else {
        // Handle PDF files (existing logic)
        const formData = new FormData();
        formData.append('file', file);
        await aiAgents.addKnowledgeFile(props.data.id, formData);
      }
    }

    newFiles.value = [];
    fetchKnowledge();
    useAlert('Berhasil simpan data');
  } catch (e) {
    useAlert('Gagal simpan data');
  } finally {
    isSaving.value = false;
  }
}

async function handleExcelFileUpload(file) {
  try {
    // Use already parsed data instead of parsing again
    if (file.parsedData) {
      const { headers, rows, file_name, file_type, file_size } = file.parsedData;
      
      // Convert to array of objects
      const dataArray = rows.map(row => {
        const obj = {};
        headers.forEach((header, index) => {
          obj[header] = row[index] || '';
        });
        return obj;
      });
      
      // Call Excel-specific API with description
      const payload = {
        file_name,
        file_type,
        file_size,
        data: dataArray,
        description: file.description || '' // Include description
      };
      
      await aiAgents.addExcelKnowledgeFile(props.data.id, payload);
    } else {
      throw new Error('No parsed data found for Excel file');
    }
  } catch (error) {
    console.error('Error processing Excel file:', error);
    throw error;
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
          accept=".pdf, .xlsx, .xls"
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

      <woot-modal
        class="max-h-screen flex flex-col"
        :show="showExcelPreviewModal"
        :on-close="() => closeExcelPreview()"
      >
        <woot-modal-header 
          class="mb-4"
          :header-title="`Excel File Preview: ${pendingExcelFile?.name}`"
          :header-content="`Menampilkan 10 baris pertama. Total baris dalam file mungkin lebih banyak.`"
        />
        
        <!-- Scrollable container for table + description -->
        <div class="flex flex-col max-h-96 p-6 overflow-auto mb-4 flex-1">
          
          <table class="min-w-full border-collapse border border-gray-300">
            <thead>
              <tr class="bg-gray-50">
                <th
                  v-for="(header, index) in excelHeaders"
                  :key="index"
                  class="border border-gray-300 px-4 py-2 text-left text-sm font-medium text-gray-700"
                >
                  {{ header || `Column ${index + 1}` }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(row, rowIndex) in excelPreviewData"
                :key="rowIndex"
                :class="rowIndex % 2 === 0 ? 'bg-white' : 'bg-gray-50'"
              >
                <td
                  v-for="(cell, cellIndex) in excelHeaders"
                  :key="cellIndex"
                  class="border border-gray-300 px-4 py-2 text-sm text-gray-900"
                >
                  {{ row[cellIndex] || '' }}
                </td>
              </tr>
            </tbody>
          </table>
          
          <div v-if="excelPreviewData.length === 0" class="text-center py-8 text-gray-500">
            No data found in Excel file
          </div>

          <!-- Description Text Box -->
          <div class="mt-6">
            <label for="excel-description" class="block text-sm font-medium text-gray-700 mb-2">
              Deskripsi File (Opsional)
            </label>
            <textarea
              id="excel-description"
              v-model="excelDescription"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 resize-none overflow-auto"
              placeholder="Tambahkan deskripsi atau catatan untuk file Excel ini..."
            ></textarea>
          </div>
        </div>
        
        <!-- Modal Footer -->
        <div class="p-6 flex justify-end space-x-3 border-t border-gray-200">
          <woot-button data-testid="excel-confirm" @click.prevent="confirmExcelUpload">
            Tambahkan ke Antrian
          </woot-button>
          <woot-button 
            class="button clear" 
            @click.prevent="closeExcelPreview"
          >
            Batal
          </woot-button>
        </div>
      </woot-modal>
    </div>
    <div class="w-[200px]">
      <div class="sticky top-0 flex flex-col gap-2 px-2">
        <div class="flex flex-col gap-0">
          <span>Files</span>
          <span class="text-xl font-bold">{{ files.length }}</span>
        </div>
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
  </div>
</template>

<style lang="css">
.note-editing-area {
  background: white;
}
</style>
