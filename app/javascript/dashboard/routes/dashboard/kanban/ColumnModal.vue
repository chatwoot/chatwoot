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

    resetForm() {
      this.localColumnTitle = ''
      this.localSelectedLabels = []
      this.label_to_add = ''
    },


  }
}
</script>

<template>
  <div v-if="show" class="modal-overlay">
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
        <option v-for="label in mockLabels" :key="label.title" :value="label">
          {{ label.description || label.title }}
        </option>
      </select>
      <label for="label_to_add">{{ $t('COLUMN_MODAL.LABEL_TO_ADD') }}</label>
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
        <button @click="closeModal" class="cancel-btn">{{$t('COLUMN_MODAL.CANCEL_BUTTON')}}</button>
        <button @click="addColumn" class="confirm-btn" v-text="this.isEditing ? $t('COLUMN_MODAL.CONFIRM_UPDATE') : $t('COLUMN_MODAL.CONFIRM_ADD')"></button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal {
  background-color: #464343;
  padding: 20px;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
  margin: 20px;
}

@media (max-width: 768px) {
  .modal {
    width: 95%;
    padding: 15px;
    margin: 10px;
  }
}

.modal h3 {
  color: #fff;
  margin-top: 0;
  margin-bottom: 15px;
}

.modal input {
  width: 100%;
  padding: 8px;
  margin-bottom: 15px;
  border: none;
  border-radius: 4px;
  box-sizing: border-box;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  flex-wrap: wrap;
}

@media (max-width: 768px) {
  .modal-actions {
    justify-content: center;
  }
  
  .cancel-btn, .confirm-btn {
    width: 100%;
    margin: 5px 0;
  }
}

.cancel-btn, .confirm-btn {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
}

.cancel-btn {
  background-color: transparent;
  color: #fff;
}

.confirm-btn {
  background-color: #fff;
  color: #464343;
}

.cancel-btn:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.confirm-btn:hover {
  background-color: #e0e0e0;
}

.labels-select {
  width: 100%;
  height: 30%;
  padding: 8px;
  margin-bottom: 15px;
  border: none;
  border-radius: 4px;
  background-color: rgb(46, 42, 42);
  min-height: 100px;
}

.labels-select option {
  padding: 8px;
  margin: 2px 0;
}

.labels-select option:checked {
  background-color: #464343;
  color: white;
}

.single-select {
  width: 100%;
  padding: 8px;
  margin: 8px 0 15px;
  border: none;
  border-radius: 4px;
  background-color: rgb(46, 42, 42);
  color: white;
  display: block;
}

.single-select option {
  padding: 8px;
}

label {
  display: block;
  color: #fff;
  margin: 10px 0 5px;
}
</style>
