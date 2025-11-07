<template>
  <div class="settings--content">
    <h2 class="text-lg font-semibold mb-4">Konfigurasi Penomoran Otomatis</h2>
    <div class="card p-4 space-y-4">
      
      <div>
        <label>Format Penomoran <span class="text-red-500">*</span></label>
        <div class="flex gap-2">
          <input v-model="form.format" type="text" class="input flex-1"/>
          <select v-model="codeOption" class="input w-80" @change="addCode">
            <option value="" disabled selected hidden>Tambah Kode Penomoran</option>

            <option value="[NUMBER]">Nomor Urut (1 - 10000)</option>
            <option value="[MONTH]">Bulan (01 - 12)</option>
            <option value="[MONTH_ROMAN]">Bulan Romawi (I - XII)</option>
            <option value="[MONTH_SHORT]">Bulan (JAN - DES)</option>
            <option value="[MONTH_LONG]">Bulan (JANUARI - DESEMBER)</option>
            <option value="[YEAR_SHORT]">Tahun (contoh: 25)</option>
            <option value="[YEAR]">Tahun (contoh: 2025)</option>
          </select>
        </div>
        <p class="text-md text-gray-400 mt-1">Contoh Output: {{ liveSampleOutput }}</p>
      </div>

      <div class="flex gap-4">
        <div class="flex-1">
          <label>Nomor Saat Ini <span class="text-red-500">*</span></label>
          <input v-model.number="form.currentNumber" type="number" class="input w-full" min="1" />
        </div>

        <div class="flex-1">
          <label>Jumlah Digit Nomor Urut</label>
          <input 
            v-model.number="form.number_digits" 
            type="number" 
            class="input w-full" 
            min="3"
          />
        </div>

        <div class="flex-1">
          <label>Kode Toko (Opsional)</label>
          <input 
            v-model="form.prefix" 
            type="text" 
            class="input w-full" 
            placeholder="Contoh: PB/ atau INV-"
          />
        </div>
      </div>

      <div>
        <label>Reset Nomor Setiap</label>
        <div class="space-y-1">
          <label><input type="radio" value="never" v-model="form.resetEvery" /> Tidak pernah reset</label><br />
          <label><input type="radio" value="month" v-model="form.resetEvery" /> Setiap bulan</label><br />
          <label><input type="radio" value="year" v-model="form.resetEvery" /> Setiap tahun</label>
        </div>
      </div>

      <div class="flex justify-end mt-4">
        <button class="button primary" @click="onSave" :disabled="loading">
          <span v-if="!loading">Simpan</span>
          <span v-else>Menunggu...</span>
        </button>
      </div>
      <div v-if="showSuccessModal" class="success-modal-overlay" @click.self="closeSuccessModal">
          <div class="success-modal-content">
            
            <div class="modal-icon-wrapper">
              <svg class="modal-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path>
              </svg>
            </div>

            <h2 class="modal-title">Sukses!</h2>
            <p class="modal-message">Data format penomoran berhasil disimpan.</p>

            <button class="button primary" @click="closeSuccessModal">
              Tutup
            </button>

        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import aiAgents from '../../../../../api/aiAgents';

export default {
  name: 'AutoNumbering',
  props: {
    data: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      form: {
        prefix: '',
        format: '[NUMBER]/[MONTH]/[YEAR]',
        currentNumber: 1,
        resetEvery: 'never',
        number_digits: 3,
      },
      codeOption: '',
      showSuccessModal: false,
      loading: false,
    };
  },
  computed: {
    liveSampleOutput() {
      if (!this.form.format) return '...';

      const roman = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
      const shortMonths = ['JAN','FEB','MAR','APR','MEI','JUN','JUL','AGU','SEP','OKT','NOV','DES'];
      const longMonths = ['JANUARI','FEBRUARI','MARET','APRIL','MEI','JUNI','JULI','AGUSTUS','SEPTEMBER','OKTOBER','NOVEMBER','DESEMBER'];

      const now = new Date();
      const year = now.getFullYear();                
      const yearShort = String(year).slice(-2);      
      const monthIndex = now.getMonth();             
      const monthNum = String(monthIndex + 1).padStart(2, '0');

      let padding = this.form.number_digits || 3;
      if (padding < 3) {
        padding = 3;
      }
      const number = String(this.form.currentNumber || 0).padStart(padding, '0');

      const processedFormat = this.form.format
        .replace(/\[NUMBER\]/g, number)
        .replace(/\[YEAR\]/g, year)
        .replace(/\[YEAR_SHORT\]/g, yearShort)
        .replace(/\[MONTH\]/g, monthNum)
        .replace(/\[MONTH_ROMAN\]/g, roman[monthIndex])
        .replace(/\[MONTH_SHORT\]/g, shortMonths[monthIndex])
        .replace(/\[MONTH_LONG\]/g, longMonths[monthIndex]);

      return (this.form.prefix || '') + processedFormat;
    },
  },
  watch: {
    data: {
      handler(newData) {
        // Cek jika 'number_format_config' ada di dalam flowData
        if (newData && 
            newData.display_flow_data && 
            newData.display_flow_data.agents_config && 
            newData.display_flow_data.agents_config[0] &&
            newData.display_flow_data.agents_config[0].configurations && 
            newData.display_flow_data.agents_config[0].configurations.number_format
        ) {
          // Gabungkan data dari flowData dengan data default
          this.form = { 
            ...this.form, 
            ...newData.display_flow_data.agents_config[0].configurations.number_format 
          };
        }
      },
      immediate: true,
      deep: true,
    }
  },

  methods: {
    addCode() {
      const token = this.codeOption;
      if (!token) return;
      this.form.format = this.form.format + token;
      this.codeOption = '';
    },

    async onSave() {
      if (this.loading) return;

      try {
        this.loading = true;
        const flowData = JSON.parse(JSON.stringify(this.data.display_flow_data));

        // Pastikan path-nya ada
        if (flowData.agents_config && flowData.agents_config[0]) {
          if (!flowData.agents_config[0].configurations) {
            flowData.agents_config[0].configurations = {};
          }
          // Suntikkan 'form' kita ke lokasi yang benar
          flowData.agents_config[0].configurations.number_format = this.form;
        } else {
          throw new Error("Format data tidak ditemukan.");
        }

        const payload = {
          flow_data: flowData,
        };

        await aiAgents.updateAgent(this.data.id, payload);

        this.showSuccessModal = true;

      } catch (error) {
        console.error("Gagal menyimpan:", error);
      } finally {
        this.loading = false;
      }
    },
    
    closeSuccessModal() {
      this.showSuccessModal = false;
    },
  },
};
</script>

<style scoped>
.success-modal-overlay {
  position: fixed; 
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5); 
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 999; 
}

.success-modal-content {
  background-color: white;
  padding: 24px;
  border-radius: 8px;
  text-align: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  max-width: 400px; /* Lebar modal */
  width: 90%;
}

.modal-icon-wrapper {
  width: 72px;
  height: 72px;
  background-color: #A7F3D0; 
  border-radius: 50%; 
  margin: 0 auto 20px auto; 
  display: flex;
  justify-content: center;
  align-items: center;
}

.modal-icon {
  width: 36px;
  height: 36px;
  color: #065F46; 
}

.modal-title {
  font-size: 24px; 
  font-weight: 600; 
  margin-bottom: 8px;
  color: black;
}

.modal-message {
  font-size: 16px; 
  color: black; 
  margin-bottom: 24px;
}
</style>