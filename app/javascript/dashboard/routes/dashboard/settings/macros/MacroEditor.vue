<template>
  <div class="flex flex-col flex-1 h-full overflow-auto">
    <woot-loading-state
      v-if="uiFlags.isFetchingItem"
      :message="$t('MACROS.EDITOR.LOADING')"
    />
    <macro-form
      v-if="macro && !uiFlags.isFetchingItem"
      :macro-data.sync="macro"
      @submit="saveMacro"
    />
  </div>
</template>

<script>
import MacroForm from './MacroForm.vue';
import { MACRO_ACTION_TYPES } from './constants';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import macrosMixin from 'dashboard/mixins/macrosMixin';

export default {
  components: {
    MacroForm,
  },
  mixins: [macrosMixin],
  provide() {
    return {
      macroActionTypes: this.macroActionTypes,
    };
  },
  data() {
    return {
      macro: null,
      mode: 'CREATE',
      macroActionTypes: MACRO_ACTION_TYPES,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'macros/getUIFlags',
      labels: 'labels/getLabels',
      agents: 'agents/getAgents',
      teams: 'teams/getTeams',
    }),
    macroId() {
      return this.$route.params.macroId;
    },
  },
  watch: {
    $route: {
      handler() {
        this.fetchDropdownData();
        if (this.$route.params.macroId) {
          this.fetchMacro();
        } else {
          this.initNewMacro();
        }
      },
      immediate: true,
    },
  },
  methods: {
    fetchDropdownData() {
      this.$store.dispatch('agents/get');
      this.$store.dispatch('teams/get');
      this.$store.dispatch('labels/get');
    },
    fetchMacro() {
      this.mode = 'EDIT';
      this.manifestMacro();
    },
    async manifestMacro() {
      await this.$store.dispatch('macros/getSingleMacro', this.macroId);
      const singleMacro = this.$store.getters['macros/getMacro'](this.macroId);
      this.macro = this.formatMacro(singleMacro);
    },
    formatMacro(macro) {
      const formattedActions = macro.actions.map(action => {
        let actionParams = [];
        if (action.action_params.length) {
          const inputType = this.macroActionTypes.find(
            item => item.key === action.action_name
          ).inputType;
          if (inputType === 'multi_select' || inputType === 'search_select') {
            actionParams = [
              ...this.getDropdownValues(action.action_name, this.$store),
            ].filter(item => [...action.action_params].includes(item.id));
          } else if (inputType === 'team_message') {
            actionParams = {
              team_ids: [
                ...this.getDropdownValues(action.action_name, this.$store),
              ].filter(item =>
                [...action.action_params[0].team_ids].includes(item.id)
              ),
              message: action.action_params[0].message,
            };
          } else actionParams = [...action.action_params];
        }
        return {
          ...action,
          action_params: actionParams,
        };
      });
      return {
        ...macro,
        actions: formattedActions,
      };
    },
    initNewMacro() {
      this.mode = 'CREATE';
      this.macro = {
        name: '',
        actions: [
          {
            action_name: 'assign_team',
            action_params: [],
          },
        ],
        visibility: 'global',
      };
    },
    async saveMacro(macro) {
      try {
        const action = this.mode === 'EDIT' ? 'macros/update' : 'macros/create';
        let successMessage =
          this.mode === 'EDIT'
            ? this.$t('MACROS.EDIT.API.SUCCESS_MESSAGE')
            : this.$t('MACROS.ADD.API.SUCCESS_MESSAGE');
        let serializedMacro = JSON.parse(JSON.stringify(macro));
        serializedMacro.actions = actionQueryGenerator(serializedMacro.actions);
        await this.$store.dispatch(action, serializedMacro);
        useAlert(successMessage);
        this.$router.push({ name: 'macros_wrapper' });
      } catch (error) {
        useAlert(this.$t('MACROS.ERROR'));
      }
    },
  },
};
</script>
