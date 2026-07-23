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
    canManagePublicMacros: {
      type: Boolean,
      default: true,
    },
    readOnly: {
      type: Boolean,
      default: false,
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
    folderOptions() {
      const macros = this.$store?.getters?.['macros/getMacros'] || [];
      return [
        ...new Set(
          macros.map(macro => (macro.folder || '').trim()).filter(Boolean)
        ),
      ].sort((a, b) => a.localeCompare(b));
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
    updateFolder(value) {
      this.macro.folder = value;
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
      const actionName = this.macro.actions[index]?.action_name;
      const isCustomAttribute = [
        'update_contact_custom_attribute',
        'update_conversation_custom_attribute',
      ].includes(actionName);
      this.macro.actions[index].action_params = isCustomAttribute
        ? { attribute_key: '', value: '' }
        : [];
      this.macro.actions[index].delivery = {
        delay_seconds: 0,
        mark_read_and_typing: false,
      };
    },
    resetValidation() {
      this.errors = {};
      this.v$?.$reset?.();
    },
  },
};
</script>

<template>
  <div class="flex flex-col w-full h-auto lg:flex-row lg:h-full">
    <div
      class="flex-1 w-full h-full max-h-full ltr:pl-12 ltr:pr-6 rtl:pl-6 rtl:pr-12 py-4 overflow-y-auto lg:w-auto macro-gradient-radial dark:macro-dark-gradient-radial macro-gradient-radial-size"
    >
      <div :inert="readOnly" :class="{ 'opacity-75': readOnly }">
        <MacroNodes
          v-model="macro.actions"
          :files="files"
          :errors="errors"
          @add-new-node="appendNode"
          @delete-node="deleteNode"
          @reset-action="resetNode"
        />
      </div>
    </div>
    <div class="w-full lg:w-1/3 pb-4">
      <MacroProperties
        :macro-name="macro.name"
        :macro-visibility="macro.visibility"
        :macro-folder="macro.folder || ''"
        :folder-options="folderOptions"
        :can-manage-public-macros="canManagePublicMacros"
        :read-only="readOnly"
        @update:name="updateName"
        @update:visibility="updateVisibility"
        @update:folder="updateFolder"
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
