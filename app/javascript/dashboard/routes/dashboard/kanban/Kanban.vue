<script>
export default {
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

  data() {
    return {
      localColumns: this.columns?.map(c => ({ ...c, items: [...c.items] })) ?? [
        { title: 'To Do', items: [{ content: 'Task 1' }, { content: 'Task 2' }, { content: 'Task 3' }] },
        { title: 'In Progress', items: [{ content: 'Task 4' }, { content: 'Task 5' }] },
        { title: 'Done', items: [{ content: 'Task 6' }] }
      ],
      draggedItem: null,
      sourceColumnIndex: null,
      sourceItemIndex: null,
      showColumnModal: false,
      newColumnTitle: ''
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

    deleteColumn(columnIndex) {
      this.localColumns.splice(columnIndex, 1)
      this.$emit('update:columns', structuredClone(this.localColumns))
      this.$emit('columnDeleted', columnIndex)
    },

    onDrop(_event, targetColumnIndex) {
      if (this.draggedItem && this.sourceColumnIndex !== null && this.sourceItemIndex !== null) {
        // Remove from source
        const [removed] = this.localColumns[this.sourceColumnIndex].items.splice(this.sourceItemIndex, 1)
        // Add to target
        this.localColumns[targetColumnIndex].items.push(removed)

        // Mirror to v-model
        this.$emit('update:columns', structuredClone(this.localColumns))
        this.$emit('moved', { 
          item: removed, 
          fromColumn: this.sourceColumnIndex, 
          toColumn: targetColumnIndex 
        })

        // Reset state
        this.draggedItem = null
        this.sourceColumnIndex = null
        this.sourceItemIndex = null
      }
    },

    openColumnModal() {
      this.showColumnModal = true
      this.newColumnTitle = ''
    },

    closeColumnModal() {
      this.showColumnModal = false
    },

    addNewColumn() {
      if (this.newColumnTitle.trim()) {
        this.localColumns.push({
          title: this.newColumnTitle,
          items: []
        })
        this.closeColumnModal()
        this.newColumnTitle = ''
        this.$emit('update:columns', structuredClone(this.localColumns))
      }
      
    }
  }
}
</script>

<template>
  <div class="kanban-root">
    <header class="kanban-header">
      <button class="kanban-button" @click="openColumnModal">Nova coluna</button>
      <button class="kanban-button">Importar Kanban</button>
      <button class="kanban-button">Exportar Kanban</button>
    </header>
    <div class="kanban-board">
      <div
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

    <!-- Modal para nova coluna -->
    <div v-if="showColumnModal" class="modal-overlay">
      <div class="modal">
        <h3>Nova Coluna</h3>
        <input 
          v-model="newColumnTitle"
          type="text"
          placeholder="Nome da coluna"
          @keyup.enter="addNewColumn"
        >
        <div class="modal-actions">
          <button @click="closeColumnModal" class="cancel-btn">Cancelar</button>
          <button @click="addNewColumn" class="confirm-btn">Adicionar</button>
        </div>
      </div>
    </div>
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
</style>
