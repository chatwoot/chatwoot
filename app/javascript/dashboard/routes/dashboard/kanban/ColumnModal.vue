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
      localSelectedLabels: []
    }
  },

  watch: {
    editedColumn: {
      handler(newVal) {
        if (this.isEditing && newVal) {
          this.localColumnTitle = newVal.title
          this.localSelectedLabels = [...newVal.labels]
        }
      },
      immediate: true
    },
    show: {
      handler(newVal) {
        console.log("show mudou para ", newVal)
        if (!newVal) {
          this.resetForm()
        }
      }
    }
  },

  methods: {
    closeModal() {
      this.$emit('close')
      this.resetForm()
    },

    addColumn() {
      if (this.localColumnTitle.trim()) {
        const columnData = {
          title: this.localColumnTitle,
          labels: [...this.localSelectedLabels]
        }
        
        this.$emit(this.isEditing ? 'update' : 'add', columnData)
        this.closeModal()
      }
    },

    resetForm() {
      this.localColumnTitle = ''
      this.localSelectedLabels = []
    }
  }
}
</script>

<template>
  <div v-if="show" class="modal-overlay">
    <div class="modal">
      <h3 v-text="this.isEditing ? 'Editar Coluna' : 'Nova Coluna'"></h3>
      <input 
        v-model="localColumnTitle"
        type="text"
        placeholder="Nome da coluna"
        @keyup.enter="addColumn"
      >
      <label for="labels">Etiquetas: (para escolher mais de uma, mantenha ctrl pressionado ao escolher)</label>
      <select 
        name="labels" 
        id="column-labels" 
        v-model="localSelectedLabels" 
        multiple
        class="labels-select"
      >
        <option v-for="label in mockLabels" :key="label.value" :value="label.value">
          {{ label.text }}
        </option>
      </select>
      <div class="modal-actions">
        <button @click="closeModal" class="cancel-btn">Cancelar</button>
        <button @click="addColumn" class="confirm-btn" v-text="this.isEditing ? 'Alterar' : 'Adicionar'"></button>
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
  min-width: 300px;
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
</style>
