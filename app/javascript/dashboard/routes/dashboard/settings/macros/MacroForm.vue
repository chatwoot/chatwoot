<template>
  <div class="flex flex-col md:flex-row h-auto md:h-full w-full">
    <div
      class="flex-1 w-full md:w-auto macro-gradient-radial dark:macro-dark-gradient-radial macro-gradient-radial-size h-full max-h-full py-4 px-12 overflow-y-auto"
    >
      <macro-nodes
        v-model="macro.actions"
        :files="files"
        @addNewNode="appendNode"
        @deleteNode="deleteNode"
        @resetAction="resetNode"
      />
    </div>
    <div class="w-full md:w-1/3">
      <macro-properties
        :macro-name="macro.name"
        :macro-visibility="macro.visibility"
        @update:name="updateName"
        @update:visibility="updateVisibility"
        @submit="submit"
      />
    </div>
  </div>
</template>

<script>
import MacroNodes from './MacroNodes.vue';
import MacroProperties from './MacroProperties.vue';
import { required, requiredIf } from 'vuelidate/lib/validators';

export default {
  components: {
    MacroNodes,
    MacroProperties,
  },
  provide() {
    return {
      $v: this.$v,
    };
  },
  props: {
    macroData: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      macro: this.macroData,
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
      actions: {
        required,
        $each: {
          action_params: {
            required: requiredIf(prop => {
              if (prop.action_name === 'send_email_to_team') return true;
              return !(
                prop.action_name === 'mute_conversation' ||
                prop.action_name === 'snooze_conversation' ||
                prop.action_name === 'resolve_conversation' ||
                prop.action_name === 'remove_assigned_team'
              );
            }),
          },
        },
      },
    },
  },
  methods: {
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
      this.macro.actions.splice(index, 1);
    },
    submit() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      this.$emit('submit', this.macro);
    },
    resetNode(index) {
      this.$v.macro.actions.$each[index].$reset();
      this.macro.actions[index].action_params = [];
    },
    resetValidation() {
      this.$v.$reset();
    },
  },
};
</script>

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
