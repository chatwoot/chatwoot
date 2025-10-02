<script>
import ColumnModal from './ColumnModal.vue'
import ConversationApi from '../../../api/inbox/conversation';
import { toRaw } from 'vue'
import { conversationUrl, frontendURL } from '../../../helper/URLHelper';
import Spinner from '../../../../shared/components/Spinner.vue'

export default {
  components: {
    ColumnModal,
    Spinner
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
    await this.$store.dispatch('labels/get')
    const labelsFromStore = this.$store.getters['labels/getLabels']
    this.labels = [...labelsFromStore]
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
      editedColumn: {},
      dragColumnsMode: false,
      isLoading: false,
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
    async handleItemDrop(item, labelToRemove, labelToAdd) {
      // Get current item labels
      const itemLabels = [...item.labels]
      // If labelToRemove is part of item labels, remove it
      const labelToRemoveIndex = itemLabels.findIndex(label => label === labelToRemove.title)
      if (labelToRemoveIndex > -1) {
        itemLabels.splice(labelToRemove, 1)
      }
      // If labelToAdd is not part of item labels, add it
      const labelToAddIndex = itemLabels.findIndex(label => label === labelToAdd.title)
      if (labelToAddIndex < 0) {
        itemLabels.push(labelToAdd.title)
      }
      // Call API and add labels to conversations
      try {
        await this.$store.dispatch('conversationLabels/update', {
          conversationId: item.id,
          labels: itemLabels
        })
      } catch (error) {
        console.error("Erro ao atualizar labels: ", error)
      }
    },

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
        // Check if the item isn't already in this column using its ID
        const targetColumnItems = [...this.localColumns[targetColumnIndex].items]
        if (targetColumnItems.some(item => item.id === removed.id)) {
          // Return the item to its original column
          this.localColumns[this.sourceColumnIndex].items.splice(this.sourceItemIndex, 0, removed)
          return
        }
        // Switch labels
        this.handleItemDrop(removed, this.localColumns[this.sourceColumnIndex].label_to_add, this.localColumns[targetColumnIndex].label_to_add)
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
      const usedLabels = columnData.labels
      this.labels = this.labels.filter(label => 
        !usedLabels.some(usedLabel => 
          label.title === usedLabel.title
        )
      )
      this.showColumnModal = false
      this.editedColumn = columnData
    },

    deleteColumn(columnIndex) {
      const deletedColumn = this.localColumns[columnIndex]
      const deletedLabels = deletedColumn.labels

      this.labels = [...this.labels, ...deletedLabels]

      this.localColumns.splice(columnIndex, 1)

      this.editedColumn = null
      this.isEditing = false
      
      this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
      this.$emit('columnDeleted', columnIndex)
      localStorage.setItem('localColumns', JSON.stringify(this.localColumns))
    },

    editColumn(columnIndex) {
      const columnToEdit = this.localColumns[columnIndex];
      this.isEditing = true;
      // Add the labels back in the labels pool
      const columnLabels = columnToEdit.labels || []
      this.labels = [...this.labels, ...columnLabels]
      this.editedColumn = {
        ...columnToEdit,
        originalIndex: columnIndex
      };
      this.showColumnModal = true;
    },

    async addNewColumn(columnData) {
      this.isLoading = true
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
      const newCol = {
        title: columnData.title,
        items: filteredConversations.map(conv => ({
          id: conv.id,
          content: conv.meta.sender.name,
          labels: conv.labels
        })),
        labels: columnData.labels,
        label_to_add: columnData.label_to_add
      }
      const usedLabels = columnData.labels
      // Find and remove from the labels array the labels that are being used
      this.labels = this.labels.filter(label => 
        !usedLabels.some(usedLabel => 
          label.title === usedLabel.title
        )
      )
      this.localColumns.push(newCol)
      this.closeColumnModal(newCol)
      this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)))
      localStorage.setItem('localColumns', JSON.stringify(this.localColumns))
      this.isLoading = false
    },

    async updateColumn(columnData) {
      if (!this.editedColumn) return;
      this.isLoading = true
      const originalIndex = this.editedColumn.originalIndex;

      const allLabels = [...this.labels];
      
      // Get the labels that were not selected yet
      this.labels = allLabels.filter(label => 
        !columnData.labels.some(newLabel => label.title === newLabel.title)
      );
          
      // Filter conversations using its labels
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

      const updatedColumn = {
        ...this.localColumns[originalIndex],
        title: columnData.title,
        labels: columnData.labels,
        label_to_add: columnData.label_to_add,
        items: data.payload.map(conv => ({
          id: conv.id,
          content: conv.meta.sender.name,
          labels: conv.labels
        }))
      };

      // Update column in its original index
      this.localColumns.splice(originalIndex, 1, updatedColumn);

      // Update localStorage and emit events
      this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)));
      localStorage.setItem('localColumns', JSON.stringify(this.localColumns));
      this.isLoading = false
      this.closeColumnModal(updatedColumn);
    },

    fetchColumns() {
      this.isLoading = true
      // Check if there are localColumns in localStorage and set this.localColumns
      const storedCols = localStorage.getItem('localColumns')
      if (storedCols) {
        const storedColsObject = JSON.parse(storedCols)
        this.localColumns = storedColsObject
        // For each column, iterate and remove labels
        for (const col of this.localColumns) {
          // Find and remove from labels array the labels that are already used
          this.labels = this.labels.filter(label => 
            !col.labels.some(usedLabel => 
              label.title === usedLabel.title
            )
          )
        }
        this.isLoading = false
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
          {{ dragColumnsMode ? $t('KANBAN.HEADER.DRAG_MODE.ACTIVE') : $t('KANBAN.HEADER.DRAG_MODE.INACTIVE') }}
        </button>
      </div>
      <div class="kanban-header-right">
        <button class="kanban-button" @click="openColumnModal">{{ $t('KANBAN.HEADER.BUTTONS.NEW_COLUMN') }}</button>
        <button class="kanban-button" @click="importKanban">{{ $t('KANBAN.HEADER.BUTTONS.IMPORT') }}</button>
        <button class="kanban-button" @click="exportKanban">{{ $t('KANBAN.HEADER.BUTTONS.EXPORT') }}</button>
      </div>
    </header>

    <div class="kanban-board" v-if="!isLoading">
      <div v-if="localColumns.length === 0" class="empty-state">
        <h2>{{ $t('KANBAN.EMPTY_STATE.TITLE') }}</h2>
        <p>{{ $t('KANBAN.EMPTY_STATE.DESCRIPTION') }}</p>
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
          <button 
            class="delete-column-btn" 
            @click="deleteColumn(columnIndex)"
          >
            {{ $t('KANBAN.COLUMN.ACTIONS.DELETE') }}
          </button>
          <button 
            class="delete-column-btn" 
            @click="editColumn(columnIndex)"
          >
            {{ $t('KANBAN.COLUMN.ACTIONS.EDIT') }}
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
          <slot name="card" :item="item" :column="column">{{ item.content }}</slot>
        </div>
      </div>
    </div>
    <div v-else class="spinner-container">
      <Spinner></Spinner>
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
  @apply p-2.5 bg-n-background h-screen w-screen box-border overflow-x-auto;
}

@media (max-width: 768px) {
  .kanban-root {
    padding: 5px;
  }
}

.kanban-board {
  @apply flex gap-5 h-[calc(100vh-100px)] mx-auto overflow-x-auto pb-5;
}

@media (max-width: 768px) {
  .kanban-board {
    padding-bottom: 10px;
    gap: 10px;
  }
}

.column {
  @apply bg-n-slate-5 rounded-lg p-3 w-[300px] min-w-[300px] h-full overflow-y-auto;
}

.delete-column-btn {
  @apply bg-transparent border-none text-n-slate-11 cursor-pointer p-1 flex items-center justify-center rounded transition-all duration-200 hover:bg-n-slate-4
}

.delete-column-btn:hover {
  color: red;
}

@media (max-width: 768px) {
  .column {
    width: 280px;
    min-width: 280px;
    padding: 8px;
  }
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
  @apply bg-n-slate-5 p-4 flex gap-2.5 justify-between w-full sticky top-0 z-50 mb-[1.5%] flex-wrap;
}

@media (max-width: 768px) {
  .kanban-header {
    padding: 10px;
    gap: 5px;
  }
  
  .kanban-header-left,
  .kanban-header-right {
    width: 100%;
    justify-content: center;
  }
  
  .kanban-button {
    width: calc(50% - 5px);
    font-size: 14px;
    padding: 6px 12px;
  }
}

.kanban-header-left,
.kanban-header-right {
  display: flex;
  gap: 10px;
}

.toggle-button {
  @apply bg-n-slate-4 text-n-slate-11;
}

.toggle-button.active {
  @apply bg-n-brand text-n-slate-1;
}

.column-dragging {
  opacity: 0.5;
  cursor: move;
}

.kanban-button {
  @apply py-2 px-4 bg-n-slate-1 border-none rounded text-n-slate-12 cursor-pointer font-bold transition-all duration-200;
}

.kanban-button:hover {
  @apply bg-n-slate-3 -translate-y-[1px];
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

.spinner-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: calc(100vh - 100px);
  width: 100%;
}

</style>
