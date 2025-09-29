<script>
import ColumnModal from './ColumnModal.vue'
import ConversationApi from '../../../api/inbox/conversation';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { toRaw } from 'vue'
import { conversationUrl, frontendURL } from '../../../helper/URLHelper';


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

  async mounted() {
    this.fetchLabels()
    this.fetchColumns()
  },

  setup() {
      const {
      savedLabels,
      activeLabels,
      accountLabels,
      addLabelToConversation,
      removeLabelFromConversation,
      } = useConversationLabels();
      
      return {
        savedLabels,
        activeLabels,
        accountLabels,
        addLabelToConversation,
        removeLabelFromConversation
      }
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
      editedColumn: {},
      dragColumnsMode: false,
    }
  },

  watch: {
    columns: {
      handler(next) {
        if (!next) return
        this.localColumns = next.map(c => ({ ...c, items: [...c.items] }))
      },
      deep: true
    },

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

    onColumnDragStart(event, columnIndex) {
      this.sourceColumnIndex = columnIndex
      event.target.classList.add('column-dragging')
      // for Firefox compatibility
      event.dataTransfer?.setData('text/plain', '')
    },

    onColumnDragEnd(event) {
      event.target.classList.remove('column-dragging')
      this.sourceColumnIndex = null
    },

    onColumnDrop(event, targetColumnIndex) {
      if (this.sourceColumnIndex !== null && this.sourceColumnIndex !== targetColumnIndex) {
        const [movedColumn] = this.localColumns.splice(this.sourceColumnIndex, 1)
        this.localColumns.splice(targetColumnIndex, 0, movedColumn)
        
        this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
        localStorage.setItem('localColumns', JSON.stringify(this.localColumns))
      }
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

    handleCardClick(item) {
      const conversationPath = conversationUrl({
        accountId: this.$route.params.accountId,
        id: item.id
      })
      const fullPath = frontendURL(conversationPath)
      this.$router.push(fullPath)
    },

    openColumnModal() {
      this.showColumnModal = true
      this.isEditing = false
      this.editedColumn = null
    },

    closeColumnModal(columnData) {
      console.log("pegou evento de close modal no pai")
      console.log(columnData)
      const usedLabels = columnData.labels
      // Encontra e remove do array de labels as labels que ja foram usadas
      this.labels = this.labels.filter(label => 
        !usedLabels.some(usedLabel => 
          label.title === usedLabel.title
        )
      )
      this.showColumnModal = false
      this.editedColumn = columnData
    },

    deleteColumn(columnIndex) {
      // Pegar as labels da coluna que será deletada
      const deletedColumn = this.localColumns[columnIndex]
      const deletedLabels = deletedColumn.labels

      // Adicionar as labels de volta ao array de labels disponíveis
      this.labels = [...this.labels, ...deletedLabels]

      // Remover a coluna
      this.localColumns.splice(columnIndex, 1)
      
      // Emitir eventos e atualizar localStorage
      this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
      this.$emit('columnDeleted', columnIndex)
      localStorage.setItem('localColumns', JSON.stringify(this.localColumns))
    },

    editColumn(columnIndex) {
      const columnToEdit = this.localColumns[columnIndex];
      this.isEditing = true;
      // Adiciona as labels da coluna de volta ao pool temporariamente
      const columnLabels = columnToEdit.labels || []
      this.labels = [...this.labels, ...columnLabels]
      this.editedColumn = {
        ...columnToEdit,
        originalIndex: columnIndex
      };
      this.showColumnModal = true;
    },

    async addNewColumn(columnData) {
      // Extrai apenas os títulos das labels
      const labelTitles = columnData.labels.map(label => label.title)
      const filters = [
        {
          "attribute_key": "labels",
          "attribute_model": "standard", 
          "filter_operator": "equal_to",
          "values": labelTitles,
          "custom_attribute_type": ""
        }
      ]
      const payload = {
          queryData: {
            payload: filters
          }
      };
      const {data} = await ConversationApi.filter(payload)
      const filteredConversations = data.payload
      console.log("O que vem em conversations => ", filteredConversations)
      const newCol = {
        title: columnData.title,
        items: filteredConversations.map(conv => ({
          id: conv.id,
          content: conv.meta.sender.name,
        })),
        labels: columnData.labels,
        label_to_add: columnData.label_to_add
      }
      const usedLabels = columnData.labels
      // Encontra e remove do array de labels as labels que ja foram usadas
      this.labels = this.labels.filter(label => 
        !usedLabels.some(usedLabel => 
          label.title === usedLabel.title
        )
      )
      this.localColumns.push(newCol)
      this.closeColumnModal(newCol)
      this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
      localStorage.setItem('localColumns', JSON.stringify(this.localColumns))
    },

    async updateColumn(columnData) {
      if (!this.editedColumn) return;
      
      const originalIndex = this.editedColumn.originalIndex;

      // Remove todas as labels do pool temporariamente
      const allLabels = [...this.labels];
      
      // Filtra as labels, mantendo apenas as que não foram selecionadas
      this.labels = allLabels.filter(label => 
        !columnData.labels.some(newLabel => label.title === newLabel.title)
      );
          
      // Filtrar conversas baseado nas novas labels
      const labelTitles = columnData.labels.map(label => label.title);
      const filters = [{
        attribute_key: "labels",
        attribute_model: "standard",
        filter_operator: "equal_to", 
        values: labelTitles,
        custom_attribute_type: ""
      }];

      const {data} = await ConversationApi.filter({
        queryData: { payload: filters }
      });

      // Atualizar coluna mantendo posição original
      const updatedColumn = {
        ...this.localColumns[originalIndex],
        title: columnData.title,
        labels: columnData.labels,
        label_to_add: columnData.label_to_add,
        items: data.payload.map(conv => ({
          id: conv.id,
          content: conv.meta.sender.name
        }))
      };

      // Atualizar coluna na posição original
      this.localColumns.splice(originalIndex, 1, updatedColumn);

      // Atualizar storage e emitir eventos
      this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)));
      localStorage.setItem('localColumns', JSON.stringify(this.localColumns));
      
      this.closeColumnModal(updatedColumn);
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
      
      this.labels = this.accountLabels

    },

    async fetchColumns() {
      await new Promise(resolve => setTimeout(resolve, 1000))
      // Verificar se tem localColumns no localStorage e setar o this.localColumns
      const storedCols = localStorage.getItem('localColumns')
      if (storedCols) {
        const storedColsObject = JSON.parse(storedCols)
        this.localColumns = storedColsObject
        // Para cada coluna, percorrer e remover os labels
        for (const col of this.localColumns) {
          // Encontra e remove do array de labels as labels que ja foram usadas
          this.labels = this.labels.filter(label => 
            !col.labels.some(usedLabel => 
              label.title === usedLabel.title
            )
          )
        }
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
    },

  }
}
</script>

<template>
  <div class="kanban-root">
    <header class="kanban-header">
      <div class="kanban-header-left">
        <button 
          class="kanban-button toggle-button" 
          :class="{ active: dragColumnsMode }"
          @click="dragColumnsMode = !dragColumnsMode"
        >
          {{ dragColumnsMode ? 'Modo Arrasto Ativo' : 'Modo Arrasto' }}
        </button>
      </div>
      <div class="kanban-header-right">
        <button class="kanban-button" @click="openColumnModal">Nova coluna</button>
        <button class="kanban-button" @click="importKanban">Importar Kanban</button>
        <button class="kanban-button" @click="exportKanban">Exportar Kanban</button>
      </div>
    </header>
      
          <h3 class="debug-title">Debug Info</h3>
          <div class="debug-item">
            <strong>Labels:</strong> 
            {{ labels }}
          </div>
  
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
        :draggable="dragColumnsMode"
        @dragstart="dragColumnsMode && onColumnDragStart($event, columnIndex)"
        @dragend="dragColumnsMode && onColumnDragEnd"
        @dragover.prevent
        @drop="dragColumnsMode ? onColumnDrop($event, columnIndex) : onDrop($event, columnIndex)"
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
          @click="handleCardClick(item)"
        >
          <slot name="card" :item="item" :column="column">{{ item.content }} / {{ item.id }}</slot>
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
  justify-content: space-between;
  width: 100%;
  position: sticky;
  top: 0;
  z-index: 100;
  margin-bottom: 1.5%;
}

.kanban-header-left,
.kanban-header-right {
  display: flex;
  gap: 10px;
}

.toggle-button {
  background-color: #666;
  color: white;
}

.toggle-button.active {
  background-color: #4CAF50;
}

.column-dragging {
  opacity: 0.5;
  cursor: move;
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

.debug-section {
  background: #464343;
  padding: 15px;
  margin: 10px 0;
  border-radius: 8px;
  max-height: 400px;
  overflow-y: auto;
}

.debug-title {
  color: #fff;
  margin: 0 0 15px 0;
  padding-bottom: 10px;
  border-bottom: 2px solid #666;
}

.debug-item {
  color: white;
  margin: 10px 0;
  padding: 5px;
  border-bottom: 1px solid #666;
}

.debug-item strong {
  color: #4CAF50;
  margin-right: 10px;
  display: block;
  margin-bottom: 8px;
}

.conversation-item {
  padding: 8px;
  margin: 8px 0;
  background: rgba(0,0,0,0.2);
  border-radius: 4px;
}

.conversation-index {
  color: #4CAF50;
  font-weight: bold;
  margin-right: 8px;
}

.conversation-data {
  margin: 8px 0 0 0;
  white-space: pre-wrap;
  font-family: monospace;
  font-size: 12px;
  background: rgba(0,0,0,0.3);
  padding: 8px;
  border-radius: 4px;
  overflow-x: auto;
}

</style>
