<script>
import ColumnModal from './ColumnModal.vue'
import { toRaw } from 'vue'

export default {
  components: {
    ColumnModal
  },
  name: 'Kanban',
  
  props: {
    /**
     * Columns data. Use v-model:columns to get updates when items move.
     */
    columns: {
      type: Array,
      required: false
    }
  },

  emits: ['update:columns', 'moved', 'columnDeleted'],

  mounted() {
    this.fetchLabels()
    this.fetchColumns()
  },

  data() {
    return {
      localColumns: [],
      draggedItem: null,
      sourceColumnIndex: null,
      sourceItemIndex: null,
      showColumnModal: false,
      labels: [],
      isEditing: false,
      editedColumn: {}
    }
  },

  watch: {
    columns: {
      handler(next) {
        if (!next) return
        this.localColumns = next.map(c => ({ ...c, items: [...c.items] }))
      },
      deep: true
    }
  },

  methods: {
    onDragStart(event, columnIndex, itemIndex) {
      this.draggedItem = this.localColumns[columnIndex].items[itemIndex]
      this.sourceColumnIndex = columnIndex
      this.sourceItemIndex = itemIndex
      const target = event.target
      target?.classList.add('dragging')
      // for Firefox compatibility
      event.dataTransfer?.setData('text/plain', '')
    },

    onDragEnd(event) {
      const target = event.target
      target?.classList.remove('dragging')
    },

    onDrop(_event, targetColumnIndex) {
      if (this.draggedItem && this.sourceColumnIndex !== null && this.sourceItemIndex !== null) {
        // Remove from source
        const [removed] = this.localColumns[this.sourceColumnIndex].items.splice(this.sourceItemIndex, 1)
        // Add to target
        this.localColumns[targetColumnIndex].items.push(removed)

        // Mirror to v-model
        this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
        this.$emit('moved', { 
          item: removed, 
          fromColumn: this.sourceColumnIndex, 
          toColumn: targetColumnIndex 
        })
        // Update localStorage
        localStorage.setItem('localColumns',JSON.stringify(this.localColumns))
        // Reset state
        this.draggedItem = null
        this.sourceColumnIndex = null
        this.sourceItemIndex = null
      }
    },

    openColumnModal() {
      this.showColumnModal = true
      this.isEditing = false
      this.editedColumn = null
    },

    closeColumnModal() {
      this.showColumnModal = false
    },

    deleteColumn(columnIndex) {
      this.localColumns.splice(columnIndex, 1)
      this.$emit('update:columns', [JSON.parse(JSON.stringify(this.localColumns))])
      this.$emit('columnDeleted', columnIndex)
    },

    editColumn(columnIndex) {
      const editedColumn = this.localColumns[columnIndex]
      this.isEditing =  true
      this.editedColumn = editedColumn
      this.showColumnModal =  true
    },

    addNewColumn(columnData) {
      const newCol = {
        title: columnData.title,
        items: [
          {content: 'Fulano'},
          {content: 'Sicrano'}
        ],
        labels: columnData.labels
      }
      this.localColumns.push(newCol)
      this.closeColumnModal()
      this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
      localStorage.setItem('localColumns', JSON.stringify(this.localColumns))
    },

    updateColumn(columnData) {
      if (this.editedColumn) {
        const index = this.localColumns.findIndex(col => col === this.editedColumn)
        if (index !== -1) {
          this.localColumns[index] = {
            ...this.localColumns[index],
            ...columnData
          }
          this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
          localStorage.setItem('localColumns',  JSON.stringify(this.localColumns))
        }
      }
      this.closeColumnModal()
    },

    async fetchLabels() {
      // Simulando delay de API
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      // Simulando resposta da API
      const apiLabels = [
        {text: 'Etapa 1', value: 'etapa_1'}, 
        {text: 'Etapa 2', value: 'etapa_2'}, 
        {text: 'Etapa 3', value: 'etapa_3'},
        {text: 'Urgente', value: 'urgente'},
        {text: 'Pode Esperar', value: 'esperar'}
      ]
      
      this.labels = apiLabels

    },

    async fetchColumns() {
      await new Promise(resolve => setTimeout(resolve, 1000))
      // Verificar se tem localColumns no localStorage e setar o this.localColumns
      const storedCols = localStorage.getItem('localColumns')
      if (storedCols) {
        const storedColsObject = JSON.parse(storedCols)
        this.localColumns = storedColsObject
      } else {
        this.localColumns = []
      }
    },

    exportKanban() {
      const plainData = toRaw(this.localColumns)
      const jsonData = JSON.stringify(plainData, null, 2)
      const blob = new Blob([jsonData], {type: 'application/json'})

      const tempUrl = window.URL.createObjectURL(blob)
      const linkElement = document.createElement('a')
      linkElement.href = tempUrl
      linkElement.download = 'kanban.json'
      document.body.appendChild(linkElement)
      linkElement.click()

      document.body.removeChild(linkElement)
      window.URL.revokeObjectURL(tempUrl)
    },

    importKanban() {
      const fileInput = document.createElement('input')
      fileInput.type = 'file'
      fileInput.accept = '.json'

      fileInput.onchange = (e) => {
        const file = e.target.files[0]
        if (!file) return

        const reader = new FileReader()
        reader.onload = (e) => {
          try {
            const importedData = JSON.parse(e.target.result)
            this.localColumns = importedData
            this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
          } catch (error) {
            console.error('Erro ao importar arquivo: ', error)
            alert('Erro ao importar arquivo')
          }
        }
        reader.readAsText(file)
      }

      document.body.appendChild(fileInput)
      fileInput.click()
      setTimeout(() => {
        document.body.removeChild(fileInput)
      }, 100)
    }
  }
}
</script>

<template>
  <div class="kanban-root">
    <header class="kanban-header">
      <button class="kanban-button" @click="openColumnModal">Nova coluna</button>
      <button class="kanban-button" @click="importKanban">Importar Kanban</button>
      <button class="kanban-button" @click="exportKanban">Exportar Kanban</button>
    </header>
    <div class="kanban-board">
      <div v-if="localColumns.length === 0" class="empty-state">
        <h2>Nenhuma coluna criada</h2>
        <p>Clique em "Nova coluna" para começar seu quadro Kanban</p>
      </div>
      <div
        v-else
        v-for="(column, columnIndex) in localColumns"
        :key="column.id ?? columnIndex"
        class="column"
        @dragover.prevent
        @drop="onDrop($event, columnIndex)"
      >
        <div class="column-header">
          <h2>{{ column.title }}</h2>
          <button class="delete-column-btn" @click="deleteColumn(columnIndex)">
            Deletar
          </button>
          <button class="delete-column-btn" @click="editColumn(columnIndex)">
            Editar
          </button>
        </div>
        
        <div
          v-for="(item, itemIndex) in column.items"
          :key="item.id ?? itemIndex"
          class="card"
          draggable="true"
          @dragstart="onDragStart($event, columnIndex, itemIndex)"
          @dragend="onDragEnd"
        >
          <slot name="card" :item="item" :column="column">{{ item.content }}</slot>
        </div>
      </div>
    </div>

    <ColumnModal
      :isEditing="isEditing"
      :editedColumn="editedColumn"
      :show="showColumnModal"
      :mock-labels="labels"
      @close="closeColumnModal"
      @add="addNewColumn"
      @update="updateColumn"
    />
  </div>
</template>

<style scoped>
.kanban-root {
  font-family: Arial, sans-serif;
  padding: 20px;
  background-color: #292525;
  height: 100vh;
  width: 100vw;
  box-sizing: border-box;
}

.kanban-board {
  display: flex;
  gap: 20px;
  width: 100%;
  height: 100%;
  margin: 0 auto;
}

.column {
  background-color: #464343;
  border-radius: 8px;
  padding: 12px;
  width: 300px;
  height: calc(100vh - 40px); /* 40px to account for the root padding */
  overflow-y: auto;
}

.column-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10%;
  padding-bottom: 10px;
  border-bottom: 2px solid #ccc;
}

.column-header h2 {
  margin: 0;
  font-size: 18px;
}

.delete-column-btn {
  background: none;
  border: none;
  color: #fff;
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.2s ease;
}

.delete-column-btn:hover {
  background-color: rgba(255, 255, 255, 0.1);
  color: #ff4444;
}

.card {
  color: #464343;
  background-color: #fff;
  border-radius: 6px;
  padding: 10px;
  margin-bottom: 10px;
  cursor: move;
  box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
  user-select: none;
}

.card:hover {
  box-shadow: 0 3px 6px rgba(0,0,0,0.16), 0 3px 6px rgba(0,0,0,0.23);
}

.dragging { opacity: 0.5; }

.empty-state {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  color: #fff;
  text-align: center;
}

.empty-state h2 {
  font-size: 24px;
  margin-bottom: 16px;
}

.empty-state p {
  font-size: 16px;
  color: #ccc;
}

.kanban-header {
  background-color: #464343;
  padding: 15px;
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  width: 100%;
  position: sticky;
  top: 0;
  z-index: 100;
  margin-bottom: 1.5%;
}

.kanban-button {
  padding: 8px 16px;
  background-color: #fff;
  border: none;
  border-radius: 4px;
  color: #464343;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.2s ease;
}

.kanban-button:hover {
  background-color: #e0e0e0;
  transform: translateY(-1px);
}

</style>
