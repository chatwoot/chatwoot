<template>
  <div class="macros__nodes">
    <macros-pill :label="$t('MACROS.EDITOR.START_FLOW')" class="macro__node" />
    <draggable
      :list="actionData"
      animation="200"
      ghost-class="ghost"
      tag="div"
      class="macros__nodes-draggable"
      handle=".macros__node-drag-handle"
    >
      <div v-for="(action, i) in actionData" :key="i" class="macro__node">
        <macro-node
          v-model="actionData[i]"
          class="macros__node-action"
          type="add"
          :index="i"
          :single-node="actionData.length === 1"
          @resetAction="$emit('resetAction', i)"
          @deleteNode="$emit('deleteNode', i)"
        />
      </div>
    </draggable>
    <macro-action-button
      icon="add-circle"
      class="macro__node"
      :tooltip="$t('MACROS.EDITOR.ADD_BTN_TOOLTIP')"
      type="add"
      @click="$emit('addNewNode')"
    />
    <macros-pill :label="$t('MACROS.EDITOR.END_FLOW')" class="macro__node" />
  </div>
</template>

<script>
import MacrosPill from './Pill.vue';
import Draggable from 'vuedraggable';
import MacroNode from './MacroNode.vue';
import MacroActionButton from './ActionButton.vue';

export default {
  components: {
    Draggable,
    MacrosPill,
    MacroNode,
    MacroActionButton,
  },
  props: {
    value: {
      type: Array,
      default: () => [],
    },
  },
  computed: {
    actionData: {
      get() {
        return this.value;
      },
      set(value) {
        this.$emit('input', value);
      },
    },
  },
};
</script>

<style scoped lang="scss">
.macros__nodes {
  max-width: 800px;
}

.macro__node:not(:last-child) {
  position: relative;
  padding-bottom: var(--space-three);
}

.macro__node:not(:last-child):not(.sortable-chosen):after,
.macros__nodes-draggable:after {
  content: '';
  position: absolute;
  height: var(--space-three);
  width: var(--space-smaller);
  margin-left: var(--space-medium);
  background-image: url("data:image/svg+xml,%3Csvg width='4' height='30' viewBox='0 0 4 30' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cline x1='1.50098' y1='0.579529' x2='1.50098' y2='30.5795' stroke='%2393afc8' stroke-width='2' stroke-dasharray='5 5'/%3E%3C/svg%3E%0A");
}

.macros__nodes-draggable {
  position: relative;
  padding-bottom: var(--space-three);
}

.macros__node-action-container {
  position: relative;
  .drag-handle {
    position: absolute;
    left: var(--space-minus-medium);
    top: var(--space-smaller);
    cursor: move;
    color: var(--s-400);
  }
}
</style>
