<template>
  <div class="macros__nodes">
    <div class="macro__node">
      <div>
        <woot-label
          :title="$t('MACROS.EDITOR.START_FLOW')"
          color-scheme="primary"
        />
      </div>
    </div>
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
          :file-name="
            fileName(
              actionData[i].action_params[0],
              actionData[i].action_name,
              files
            )
          "
          :single-node="actionData.length === 1"
          @resetAction="$emit('resetAction', i)"
          @deleteNode="$emit('deleteNode', i)"
        />
      </div>
    </draggable>
    <div class="macro__node">
      <div>
        <woot-button
          :title="$t('MACROS.EDITOR.ADD_BTN_TOOLTIP')"
          class="macros__action-button"
          color-scheme="success"
          variant="smooth"
          icon="add-circle"
          @click="$emit('addNewNode')"
        >
          {{ $t('MACROS.EDITOR.ADD_BTN_TOOLTIP') }}
        </woot-button>
      </div>
    </div>
    <div class="macro__node">
      <div>
        <woot-label
          :title="$t('MACROS.EDITOR.END_FLOW')"
          color-scheme="primary"
        />
      </div>
    </div>
  </div>
</template>

<script>
import Draggable from 'vuedraggable';
import MacroNode from './MacroNode.vue';
import { getFileName } from './macroHelper';
export default {
  components: {
    Draggable,
    MacroNode,
  },
  props: {
    value: {
      type: Array,
      default: () => [],
    },
    files: {
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
  methods: {
    fileName() {
      return getFileName(...arguments);
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
  padding-bottom: var(--space-large);
}

.macro__node:not(:last-child):not(.sortable-chosen):after,
.macros__nodes-draggable:after {
  content: '';
  position: absolute;
  height: var(--space-large);
  width: var(--space-smaller);
  margin-left: var(--space-medium);

  border-left: 1px dashed var(--s-500);
}

.macros__nodes-draggable {
  position: relative;
  padding-bottom: var(--space-large);
}

.macros__action-button {
  box-shadow: var(--shadow);
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
