<template>
  <div class="column content-box">
    <p v-if="!uiFlags.isFetching && !macro" class="no-items-error-message">
      {{ $t('MACROS.LIST.404') }}
    </p>
    <woot-loading-state
      v-if="uiFlags.isFetching"
      :message="$t('MACROS.LOADING')"
    />
    <macro-form v-if="macro" :macro-data.sync="macro" @submit="saveMacro" />
  </div>
</template>

<script>
import MacroForm from './MacroForm';
import { MACRO_ACTION_TYPES } from './constants';
import { mapGetters } from 'vuex';
import { emptyMacro } from './macroHelper';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import alertMixin from 'shared/mixins/alertMixin';
import macrosMixin from 'dashboard/mixins/macrosMixin';

export default {
  components: {
    MacroForm,
  },
  mixins: [alertMixin, macrosMixin],
  provide() {
    return {
      macroActionTypes: this.macroActionTypes,
    };
  },
  data() {
    return {
      macro: {},
      mode: 'CREATE',
      macroActionTypes: MACRO_ACTION_TYPES,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'macros/getUIFlags',
      labels: 'labels/getLabels',
      teams: 'teams/getTeams',
    }),
    macroId() {
      return this.$route.params.macroId;
    },
  },
  watch: {
    $route: {
      handler() {
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
    fetchMacro() {
      this.mode = 'EDIT';
      this.$store.dispatch('agents/get');
      this.$store.dispatch('teams/get');
      this.$store.dispatch('labels/get');
      this.manifestMacro();
    },
    async manifestMacro() {
      const isMacroAvailable = this.$store.getters['macros/getMacro'](
        this.macroId
      );
      if (isMacroAvailable) this.macro = this.formatMacro(isMacroAvailable);
      else {
        await this.$store.dispatch('macros/getSingleMacro', this.macroId);
        const singleMacro = this.$store.getters['macros/getMacro'](
          this.macroId
        );
        this.macro = this.formatMacro(singleMacro);
      }
    },
    formatMacro(macro) {
      const formattedActions = macro.actions.map(action => {
        let actionParams = [];
        if (action.action_params.length) {
          const inputType = this.macroActionTypes.find(
            item => item.key === action.action_name
          ).inputType;
          if (inputType === 'multi_select') {
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
      this.macro = emptyMacro;
    },
    async saveMacro(macro) {
      try {
        const action = this.mode === 'EDIT' ? 'macros/update' : 'macros/create';
        const successMessage =
          this.mode === 'EDIT'
            ? this.$t('MACROS.EDIT.API.SUCCESS_MESSAGE')
            : this.$t('MACROS.ADD.API.SUCCESS_MESSAGE');
        let serializeMacro = JSON.parse(JSON.stringify(macro));
        serializeMacro.actions = actionQueryGenerator(serializeMacro.actions);
        await this.$store.dispatch(action, serializeMacro);
        this.showAlert(this.$t(successMessage));
        this.$router.push({ name: 'macros_wrapper' });
      } catch (error) {
        this.showAlert(this.$t('MACROS.ERROR'));
      }
    },
  },
};
</script>

<style scoped>
.content-box {
  padding: 0;
  height: 100vh;
}
</style>
