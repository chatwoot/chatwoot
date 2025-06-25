<script>
import { provide } from 'vue';
import MacroNodes from './MacroNodes.vue';
import MacroProperties from './MacroProperties.vue';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { validateActions } from 'dashboard/helper/validations';

export default {
  components: {
    MacroNodes,
    MacroProperties,
  },
  props: {
    macroData: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['submit'],
  setup() {
    const v$ = useVuelidate();
    provide('v$', v$);

    return { v$ };
  },
  data() {
    return {
      macro: this.macroData,
      errors: {},
    };
  },
  computed: {
    files() {
      if (this.macro && this.macro.files) return this.macro.files;
      return [];
    },
  },
  watch: {
    $route: {
      handler() {
        this.resetValidation();
      },
      immediate: true,
    },
    macroData: {
      handler() {
        this.macro = this.macroData;
      },
      immediate: true,
    },
  },
  validations: {
    macro: {
      name: {
        required,
      },
      visibility: {
        required,
      },
    },
  },
  methods: {
    removeObjectProperty(obj, keyToRemove) {
      return Object.fromEntries(
        Object.entries(obj).filter(([key]) => key !== keyToRemove)
      );
    },
    updateName(value) {
      this.macro.name = value;
    },
    updateVisibility(value) {
      this.macro.visibility = value;
    },
    appendNode() {
      this.macro.actions.push({
        action_name: 'assign_team',
        action_params: [],
      });
    },
    deleteNode(index) {
      // remove that index specifically
      // so that the next item does not get marked invalid
      this.errors = this.removeObjectProperty(this.errors, `action_${index}`);
      this.macro.actions.splice(index, 1);
    },
    submit() {
      this.errors = validateActions(this.macro.actions);
      if (Object.keys(this.errors).length !== 0) return;

      this.v$.$touch();
      if (this.v$.$invalid) return;

      this.$emit('submit', this.macro);
    },
    resetNode(index) {
      // remove that index specifically
      // so that the next item does not get marked invalid
      this.errors = this.removeObjectProperty(this.errors, `action_${index}`);
      this.macro.actions[index].action_params = [];
    },
    resetValidation() {
      this.errors = {};
      this.v$?.$reset?.();
    },
  },
};
</script>

<template>
  <div class="flex flex-col w-full h-auto md:flex-row md:h-full">
    <div
      class="flex-1 w-full h-full max-h-full px-12 py-4 overflow-y-auto md:w-auto macro-gradient-radial dark:macro-dark-gradient-radial macro-gradient-radial-size"
    >
      <MacroNodes
        v-model="macro.actions"
        :files="files"
        :errors="errors"
        @add-new-node="appendNode"
        @delete-node="deleteNode"
        @reset-action="resetNode"
      />
    </div>
    <div class="w-full md:w-1/3 pb-4">
      <MacroProperties
        :macro-name="macro.name"
        :macro-visibility="macro.visibility"
        @update:name="updateName"
        @update:visibility="updateVisibility"
        @submit="submit"
      />
    </div>
  </div>
</template>

<style scoped>
@tailwind components;

@layer components {
  .macro-gradient-radial {
    background-image: radial-gradient(#ebf0f5 1.2px, transparent 0);
  }

  .macro-dark-gradient-radial {
    background-image: radial-gradient(#293f51 1.2px, transparent 0);
  }

  .macro-gradient-radial-size {
    background-size: 1rem 1rem;
  }
}
</style>
