<script setup>
defineProps({
  show: Boolean,
  reply: {
    type: Object,
    default: () => ({ id: 0, name: '', content: '' }),
  }
});

const emit = defineEmits(['close', 'submit']);
</script>

<template>
  <div v-if="show" class="modal-overlay">
    <div class="modal-content">
      <button class="modal-close" @click="$emit('close')">✕</button>
      <h2 class="modal-title">
        {{ reply.id ? 'Ubah Balasan Cepat' : 'Buat Balasan Cepat Baru' }}
      </h2>

      <!-- TODO: Add localization -->
      <label class="modal-label">Nama</label> 
      <!-- TODO: Add localization -->
      <input class="modal-input" placeholder="Masukkan nama" v-model="reply.name" />

      <!-- TODO: Add localization -->
      <label class="modal-label">Konten</label>
      <!-- TODO: Add localization -->
      <textarea
        class="modal-input"
        rows="4"
        placeholder="Masukkan balasan cepat"
        v-model="reply.content"
      ></textarea>

      <div class="modal-actions">
        <button @click="$emit('close')" class="button clear">Batalkan</button>
        <button class="button nice gap-2" @click="$emit('submit', reply)">
          {{ reply.id ? 'Ubah Balasan Cepat' : 'Tambah Balasan Cepat' }}
        </button>
      </div>
    </div>
  </div>
</template>


<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 9999;
  display: flex;
  justify-content: center;
  align-items: center;
}

.modal-content {
  background: white;
  border-radius: 8px;
  padding: 24px;
  width: 600px;
  position: relative;
  max-width: 95%;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
}

.modal-close {
  position: absolute;
  top: 16px;
  right: 16px;
  background: none;
  border: none;
  font-size: 18px;
  color: #999;
  cursor: pointer;
}
.modal-close:hover {
  color: #333;
}

.modal-title {
  font-size: 20px;
  font-weight: 600;
  margin-bottom: 16px;
}

.modal-label {
  display: block;
  font-weight: 600;
  margin-bottom: 8px;
}

.modal-input {
  width: 100%;
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
  margin-bottom: 16px;
  font-size: 14px;
}

.attachment-box {
  border: 2px dashed #ccc;
  padding: 24px;
  text-align: center;
  color: #666;
  font-size: 14px;
  border-radius: 6px;
  margin-bottom: 24px;
}
.upload-icon {
  font-size: 24px;
  margin-bottom: 8px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-cancel {
  background: transparent;
  border: 1px solid #e53935;
  color: #e53935;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
}
.btn-cancel:hover {
  background: #fcebea;
}

.btn-create {
  background: #3f51b5;
  color: white;
  padding: 8px 24px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.btn-create:hover {
  background: #303f9f;
}
</style>
