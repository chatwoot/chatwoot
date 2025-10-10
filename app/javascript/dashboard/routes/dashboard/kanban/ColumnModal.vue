<script>
export default {
  name: 'ColumnModal',
  
  props: {
    show: {
      type: Boolean,
      required: true
    },
    mockLabels: {
      type: Array,
      required: true
    },
    isEditing: {
      type: Boolean,
    },
    editedColumn: {
      type: Object,
    }
  },

  data() {
    return {
      localColumnTitle: '',
      localSelectedLabels: [],
      label_to_add: ''
    }
  },

  watch: {
    editedColumn: {
      handler(newVal) {
        if (this.isEditing && newVal) {
          this.localColumnTitle = newVal.title || '';
          this.localSelectedLabels = Array.isArray(newVal.labels) ? 
            [...newVal.labels] : [];
          this.label_to_add = newVal.label_to_add || '';
        }
      },
      immediate: true,
      deep: true
    },
    show: {
      handler(newVal) {
        if (!newVal) {
          this.resetForm()
        }
      }
    },
    localSelectedLabels: {
      handler(newLabels) {
        if (newLabels.length > 0 && !this.label_to_add) {
          this.label_to_add = newLabels[0]
        }
        else if (newLabels === 0) {
          this.label_to_add = '';
        }
      },
      immediate: true
    }
  },

  methods: {
    closeModal() {      
      const columnData = {
          title: this.localColumnTitle,
          labels: this.localSelectedLabels,
          label_to_add: this.label_to_add
      }
      this.$emit('close', columnData)
      this.resetForm()
    },

    addColumn() {
      if (this.localColumnTitle.trim()) {
        const columnData = {
          title: this.localColumnTitle,
          labels: this.localSelectedLabels,
          label_to_add: this.label_to_add
        }
        this.$emit(this.isEditing ? 'update' : 'add', columnData)
        this.closeModal()
      }
    },

    cancel() {
      const columnData = {
        title: '',
        labels: [],
        label_to_add: ''
      }
      this.$emit('close', columnData)
      this.resetForm()
    },

    resetForm() {
      this.localColumnTitle = ''
      this.localSelectedLabels = []
      this.label_to_add = ''
    },


  }
}
</script>

<template>
  <div v-if="show" class="modal-overlay" @click.self="cancel">
    <div class="modal">
      <h3 v-text="this.isEditing ? $t('COLUMN_MODAL.EDIT_COLUMN') : $t('COLUMN_MODAL.ADD_COLUMN')"></h3>
      <input 
        v-model="localColumnTitle"
        type="text"
        :placeholder="$t('COLUMN_MODAL.COLUMN_NAME')"
        @keyup.enter="addColumn"
      >
      <label for="labels">{{$t('COLUMN_MODAL.LABELS')}}</label>
      <select 
        name="labels" 
        id="column-labels" 
        v-model="localSelectedLabels" 
        multiple
        class="labels-select"
      >
        <option v-for="label in mockLabels" :key="label.title" :value="label" :title="label.description || label.title">
          {{  label.title }}
        </option>
      </select>
      <label for="label_to_add">{{ $t('COLUMN_MODAL.LABEL_TO_ADD') }}</label>
      <span>{{ $t('COLUMN_MODAL.LABEL_TO_ADD_EXPLANATION') }}</span>
      <select
      name="label_to_add"
      id="label-to-add"
      v-model="label_to_add"
      class="single-select"
      >
        <option value="">{{$t('COLUMN_MODAL.SELECT_LABEL_TO_ADD_TEXT')}}</option>
        <option
         v-for="labelValue in localSelectedLabels"
         :key="labelValue"
         :value="labelValue"
         >
         {{ labelValue.title }}
        </option>
      </select>
      <div class="modal-actions">
        <button @click="cancel" class="cancel-btn">{{$t('COLUMN_MODAL.CANCEL_BUTTON')}}</button>
        <button @click="addColumn" class="confirm-btn" v-text="this.isEditing ? $t('COLUMN_MODAL.CONFIRM_UPDATE') : $t('COLUMN_MODAL.CONFIRM_ADD')"></button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-overlay {
  @apply fixed top-0 left-0 w-full h-full flex justify-center items-center z-[1000];
}

.modal {
  @apply bg-n-slate-2 p-5 rounded-lg w-[90%] max-w-[500px] m-5;
}

@media (max-width: 768px) {
  .modal {
    @apply w-[95%] p-4 m-2.5;
  }
}

.modal h3 {
  @apply text-n-slate-12 mt-0 mb-4;
}

.modal input {
  @apply w-full p-2 mb-4 border-none rounded bg-n-slate-1 text-n-slate-12;
}

.modal-actions {
  @apply flex justify-end gap-2.5 flex-wrap;
}

@media (max-width: 768px) {
  .modal-actions {
    @apply justify-center;
  }
  
  .cancel-btn, .confirm-btn {
    @apply w-full my-1;
  }
}

.cancel-btn, .confirm-btn {
  @apply py-2 px-4 border-none rounded cursor-pointer font-bold;
}

.cancel-btn {
  @apply bg-transparent text-n-slate-11;
}

.confirm-btn {
  @apply bg-n-slate-1 text-n-slate-12;
}

.cancel-btn:hover {
  @apply bg-n-slate-3;
}

.confirm-btn:hover {
  @apply bg-n-slate-3;
}

.labels-select {
  @apply w-full h-[30%] p-2 mb-4 border-none rounded bg-n-slate-3 min-h-[100px] text-n-slate-12;
}

.labels-select option {
  @apply p-2 my-0.5;
}

.labels-select option:checked {
  @apply bg-n-slate-4 text-n-slate-12;
}

.single-select {
  @apply w-full p-2 my-2 mb-4 border-none rounded bg-n-slate-3 text-n-slate-12 block;
}

.single-select option {
  @apply p-2;
}

label {
  @apply block text-n-slate-11 my-2.5 mt-2;
}
</style>
