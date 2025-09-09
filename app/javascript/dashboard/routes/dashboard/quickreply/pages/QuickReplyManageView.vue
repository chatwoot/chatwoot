<template>
  <div class="flex flex-col w-full h-full m-0 p-6 sm:py-8 lg:px-16 overflow-auto bg-n-background font-inter">

    <!-- Main content -->
    <div class="content">
      <div class="title-section">
        <h1>Quick Replies</h1>
        <div class="actions">
          <woot-button
            class="rounded-md button nice"
            icon="add-circle"
            @click="addQuickReply"
          >
            Tambah Balasan Cepat
          </woot-button>
          <div class= "flex px-4 pb-1 justify-between items-center flex-row gap-1 pt-2.5 border-b border-transparent">
            <div class="search-container">
            <div class="flex items-center">

            </div>
            <input 
              type="text" 
              placeholder="Cari Balasan Cepat"
              v-model="searchQuery"
              class="search-input"
            />
          </div>
          </div>
        </div>
      </div>

      <!-- Table -->
      <div class="table-container">
        <table class="replies-table">
          <thead>
            <tr>
              <th>Nama Balasan Cepat</th>
              <th>Dibuat pada</th>
              <th>Konten</th>
              <th>Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="reply in filteredReplies" :key="reply.id">
              <td>{{ reply.name }}</td>
              <td>{{ reply.createdAt }}</td>
              <td>{{ reply.content }}</td>
              <td class="actions-cell">
                <button class="edit-button" @click="editReply(reply)">Edit</button>
                <button class="delete-button" @click="confirmDelete(reply)">Delete</button>
              </td>
            </tr>
            <tr v-if="filteredReplies.length === 0">
              <td colspan="4" class="empty-state">Belum ada balasan cepat</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Delete confirmation modal -->
    <div class="modal" v-if="showDeleteModal">
      <div class="modal-content">
        <h3>Confirm Delete</h3>
        <p>Are you sure you want to delete "{{ replyToDelete?.name }}"?</p>
        <div class="modal-actions">
          <button class="cancel-button" @click="showDeleteModal = false">Cancel</button>
          <button class="confirm-delete-button" @click="deleteReply(replyToDelete)" :disabled="isDeleting">
            {{ isDeleting ? 'Deleting...' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>
  </div>
  <QuickReplyModal
  :show="showModal"
  :reply="currentReply"
  @close="showModal = false"
  @submit="handleSubmit"
/>

</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { Plus } from 'lucide-vue-next';
import { useAlert } from 'dashboard/composables';

import QuickReplyModal from './QuickReplyModal.vue'

const store = useStore();

const showModal = ref(false);
const currentReply = ref({ id: 0, name: '', content: '' });
const quickRepliesRaw = ref([]); 

const searchQuery = ref('');
const showDeleteModal = ref(false);
const replyToDelete = ref(null);
const isDeleting = ref(false);

async function handleSubmit(reply) {
  try {
    if (reply.id === 0) {
      // Create new quick reply
      await store.dispatch('quickReplies/create', {
        name: reply.name,
        content: reply.content,
      });
    } else {
      // Update existing quick reply
      await store.dispatch('quickReplies/update', {
        id: reply.id,
        name: reply.name,
        content: reply.content,
      });
    }

    showModal.value = false;
    await fetchQuickReply(); 
  } catch (err) {
    useAlert(err?.response?.data?.message)
  }
}


onMounted(() => {
  fetchQuickReply()
});

async function fetchQuickReply() {
  await store.dispatch('quickReplies/get');
  quickRepliesRaw.value = store.getters['quickReplies/quickReplies']; 
}


// Filtered replies based on search
const filteredReplies = computed(() => {
  const query = searchQuery.value.toLowerCase();
  return quickRepliesRaw.value.filter(reply =>
    reply.name.toLowerCase().includes(query) ||
    reply.content.toLowerCase().includes(query)
  );
});

function addQuickReply() {
  currentReply.value = { id: 0, name: '', content: '' };
  showModal.value = true;
}

function editReply(reply) {
  currentReply.value = { id: reply.id, name: reply.name, content: reply.content };
  showModal.value = true;
}

function confirmDelete(reply) {
  replyToDelete.value = reply;
  showDeleteModal.value = true;
}

async function deleteReply(reply) {
  console.log(reply.id)
  if (!reply) return;

  try {
    isDeleting.value = true;
    await store.dispatch('quickReplies/destroy', {id :reply.id});
    showDeleteModal.value = false;
    await fetchQuickReply(); 
  } catch (err) {
    console.error('Error deleting quick reply:', err);
  } finally {
    isDeleting.value = false;
  }
}
</script>

<style scoped>

.header {
  margin-bottom: 30px;
}

.back-button {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #0070f3;
  background: none;
  border: 1px solid #0070f3;
  border-radius: 6px;
  padding: 8px 16px;
  font-size: 14px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.back-button:hover {
  background-color: rgba(0, 112, 243, 0.05);
}

.title-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

h1 {
  font-size: 24px;
  font-weight: 600;
  margin: 0;
}

.actions {
  display: flex;
  gap: 16px;
  align-items: center;
}

.add-button {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #0070f3;
  color: white;
  border: none;
  border-radius: 6px;
  padding: 10px 16px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
  box-shadow: 0 4px 14px rgba(0, 118, 255, 0.25);
}

.add-button:hover {
  background-color: #0060df;
}

.search-container {
  position: relative;
}

.search-input {
  padding: 10px 16px 10px 40px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 14px;
  width: 250px;
  outline: none;
  transition: border-color 0.2s;
  margin-bottom: 0 !important;
}

.search-input:focus {
  border-color: #0070f3;
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
}

.table-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.replies-table {
  width: 100%;
  border-collapse: collapse;
}

.replies-table th {
  text-align: left;
  padding: 16px;
  background-color: #f8fafc;
  font-weight: 600;
  font-size: 14px;
  color: #64748b;
  border-bottom: 1px solid #e2e8f0;
}

.replies-table td {
  padding: 16px;
  border-bottom: 1px solid #e2e8f0;
  font-size: 14px;
}

.replies-table tr:last-child td {
  border-bottom: none;
}

.actions-cell {
  display: flex;
  gap: 8px;
}

.edit-button {
  padding: 6px 12px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  color: #0070f3;
  font-size: 14px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.edit-button:hover {
  background-color: #f1f5f9;
}

.delete-button {
  padding: 6px 12px;
  background-color: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  color: #ef4444;
  font-size: 14px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.delete-button:hover {
  background-color: #fef2f2;
}

.empty-state {
  text-align: center;
  color: #64748b;
  padding: 32px !important;
}

/* Modal styles */
.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background-color: white;
  border-radius: 8px;
  padding: 24px;
  width: 400px;
  max-width: 90%;
}

.modal-content h3 {
  margin-top: 0;
  font-size: 18px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 24px;
}

.cancel-button {
  padding: 8px 16px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
}

.confirm-delete-button {
  padding: 8px 16px;
  background-color: #ef4444;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
}

.confirm-delete-button:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.icon {
  flex-shrink: 0;
}
</style>