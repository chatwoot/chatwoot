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
      sourceItemIndex: null
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
    }
  }
}
</script>

<template>
  <div class="kanban-root">
    <header class="kanban-header">
      <button class="kanban-button">Nova coluna</button>
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
</style>
