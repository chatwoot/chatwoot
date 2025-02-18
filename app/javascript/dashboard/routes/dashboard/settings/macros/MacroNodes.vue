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
    errors: {
      type: Object,
      default: () => ({}),
    },
    modelValue: {
      type: Array,
      default: () => [],
    },
    files: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['update:modelValue', 'resetAction', 'deleteNode', 'addNewNode'],
  computed: {
    actionData: {
      get() {
        return this.modelValue;
      },
      set(value) {
        this.$emit('update:modelValue', value);
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
    <Draggable
      :list="actionData"
      animation="200"
      item-key="id"
      ghost-class="ghost"
      tag="div"
      class="macros__nodes-draggable"
      handle=".macros__node-drag-handle"
    >
      <template #item="{ index: i }">
        <div :key="i" class="macro__node">
          <MacroNode
            v-model="actionData[i]"
            class="macros__node-action"
            type="add"
            :index="i"
            :error-key="errors[`action_${i}`]"
            :file-name="
              fileName(
                actionData[i].action_params[0],
                actionData[i].action_name,
                files
              )
            "
            :single-node="actionData.length === 1"
            @reset-action="$emit('resetAction', i)"
            @delete-node="$emit('deleteNode', i)"
          />
        </div>
      </template>
    </Draggable>
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
