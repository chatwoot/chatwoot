<script setup>
import { ref, computed, watch, provide } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import MacroForm from './MacroForm.vue';
import { MACRO_ACTION_TYPES } from './constants';
import { useAlert } from 'dashboard/composables';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import { useMacros } from 'dashboard/composables/useMacros';

const store = useStore();
const getters = useStoreGetters();

const route = useRoute();
const router = useRouter();

const { t } = useI18n();

const { getMacroDropdownValues } = useMacros();

const macro = ref(null);
const mode = ref('CREATE');

const macroActionTypes = computed(() => {
  return MACRO_ACTION_TYPES.map(type => ({
    ...type,
    label: t(`MACROS.ACTIONS.${type.label}`),
  }));
});

provide('macroActionTypes', macroActionTypes);

const uiFlags = computed(() => getters['macros/getUIFlags'].value);
const macroId = computed(() => route.params.macroId);

const fetchDropdownData = () => {
  store.dispatch('agents/get');
  store.dispatch('teams/get');
  store.dispatch('labels/get');
};

const formatMacro = macroData => {
  const formattedActions = macroData.actions.map(action => {
    let actionParams = [];
    if (action.action_params.length) {
      const inputType = macroActionTypes.value.find(
        item => item.key === action.action_name
      ).inputType;
      if (inputType === 'multi_select' || inputType === 'search_select') {
        actionParams = getMacroDropdownValues(action.action_name).filter(item =>
          [...action.action_params].includes(item.id)
        );
      } else if (inputType === 'team_message') {
        actionParams = {
          team_ids: getMacroDropdownValues(action.action_name).filter(item =>
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
    ...macroData,
    actions: formattedActions,
  };
};

const manifestMacro = async () => {
  await store.dispatch('macros/getSingleMacro', macroId.value);
  const singleMacro = store.getters['macros/getMacro'](macroId.value);
  macro.value = formatMacro(singleMacro);
};

const fetchMacro = () => {
  mode.value = 'EDIT';
  manifestMacro();
};

const initNewMacro = () => {
  mode.value = 'CREATE';
  macro.value = {
    name: '',
    actions: [
      {
        action_name: 'assign_team',
        action_params: [],
      },
    ],
    visibility: 'global',
  };
};

watch(
  () => route,
  () => {
    fetchDropdownData();
    if (route.params.macroId) {
      fetchMacro();
    } else {
      initNewMacro();
    }
  },
  { immediate: true, deep: true }
);

const saveMacro = async macroData => {
  try {
    const action = mode.value === 'EDIT' ? 'macros/update' : 'macros/create';
    const successMessage =
      mode.value === 'EDIT'
        ? t('MACROS.EDIT.API.SUCCESS_MESSAGE')
        : t('MACROS.ADD.API.SUCCESS_MESSAGE');
    let serializedMacro = JSON.parse(JSON.stringify(macroData));
    serializedMacro.actions = actionQueryGenerator(serializedMacro.actions);
    await store.dispatch(action, serializedMacro);
    useAlert(successMessage);
    router.push({ name: 'macros_wrapper' });
  } catch (error) {
    useAlert(t('MACROS.ERROR'));
  }
};
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-auto">
    <woot-loading-state
      v-if="uiFlags.isFetchingItem"
      :message="t('MACROS.EDITOR.LOADING')"
    />
    <MacroForm
      v-if="macro && !uiFlags.isFetchingItem"
      :macro-data="macro"
      @update:macro-data="macro = $event"
      @submit="saveMacro"
    />
  </div>
</template>
