<template>
  <div class="settings--content">
    <h2 class="text-lg font-semibold mb-4">Konfigurasi Penomoran Otomatis</h2>

    <div class="card p-4 space-y-4">
      <!-- Format Penomoran -->
      <div>
        <label class="label">Format Penomoran <span class="text-red-500">*</span></label>
        <div class="flex gap-2">
          <input
            ref="formatInput"
            v-model="form.format"
            type="text"
            class="input flex-1"
            placeholder="Contoh: INV/[NUMBER]"
          />
          <select v-model="form.codeOption" class="input w-60" @change="addCode">
            <option disabled value="">Tambah Kode Penomoran</option>
            <option>[NUMBER]</option>
            <option>[YEAR]</option>
            <option>[MONTH]</option>
          </select>
        </div>
        <p class="text-sm text-gray-400 mt-1">
          Contoh Output: {{ sampleOutput }}
        </p>
      </div>

      <!-- Nomor Saat Ini -->
      <div>
        <label class="label">Nomor Saat Ini <span class="text-red-500">*</span></label>
        <input
          v-model="form.currentNumber"
          type="number"
          class="input w-full"
          placeholder="Contoh: 53"
        />
      </div>

      <!-- Reset Nomor -->
      <div>
        <label class="label">Reset Nomor Setiap</label>
        <div class="space-y-1">
          <label><input type="radio" value="never" v-model="form.resetEvery" /> Tidak pernah reset</label><br />
          <label><input type="radio" value="month" v-model="form.resetEvery" /> Setiap bulan</label><br />
          <label><input type="radio" value="year" v-model="form.resetEvery" /> Setiap tahun</label>
        </div>
      </div>

      <!-- Tombol Aksi -->
      <div class="flex justify-end mt-4">
        <button class="button secondary mr-2" @click="resetForm">Batal</button>
        <button class="button primary" @click="saveConfig">Simpan</button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AutoNumbering',
  data() {
    return {
      form: {
        format: 'INV/',
        currentNumber: 1,
        resetEvery: 'never',
        codeOption: '',
      },
    };
  },
  computed: {
    sampleOutput() {
      const year = new Date().getFullYear();
      const month = String(new Date().getMonth() + 1).padStart(2, '0');
      const number = String(this.form.currentNumber).padStart(5, '0');
      return this.form.format
        .replace('[YEAR]', year)
        .replace('[MONTH]', month)
        .replace('[NUMBER]', number);
    },
  },
  methods: {
    addCode() {
      const token = this.form.codeOption;
      if (!token) return;

      const input = this.$refs.formatInput;
      if (!input) return;

      const start = input.selectionStart || this.form.format.length;
      const end = input.selectionEnd || this.form.format.length;

      // Sisipkan token di posisi kursor
      const before = this.form.format.substring(0, start);
      const after = this.form.format.substring(end);
      this.form.format = before + token + after;

      // Reset dropdown
      this.form.codeOption = '';

      // Fokus kembali ke input dan set posisi kursor setelah token
      this.$nextTick(() => {
        input.focus();
        const newPos = start + token.length;
        input.setSelectionRange(newPos, newPos);
      });
    },
    saveConfig() {
      // Simulasi penyimpanan (dummy)
      console.log('Konfigurasi disimpan:', this.form);
      alert('Konfigurasi penomoran disimpan (dummy).');
    },
    resetForm() {
      this.form = {
        format: 'INV/',
        currentNumber: 1,
        resetEvery: 'never',
        codeOption: '',
      };
    },
  },
};
</script>