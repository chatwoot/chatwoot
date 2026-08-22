<script setup>
import { ref, computed, watch, provide } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import MacroForm from './MacroForm.vue';
import { MACRO_ACTION_TYPES } from './constants';
import { useAlert } from 'dashboard/composables';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import { getActionIcon } from 'dashboard/helper/automationHelper';
import { useMacros } from 'dashboard/composables/useMacros';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useStatusLabel } from 'dashboard/composables/useStatusLabel';

const store = useStore();
const getters = useStoreGetters();

const route = useRoute();
const router = useRouter();

const { t } = useI18n();
const { getResolveConversationPhrase } = useStatusLabel();

const { getMacroDropdownValues } = useMacros();
const { isAdmin } = useAdmin();

const macro = ref(null);
const mode = ref('CREATE');

const macroActionTypes = computed(() => {
  return MACRO_ACTION_TYPES.map(type => ({
    ...type,
    label:
      type.label === 'RESOLVE_CONVERSATION'
        ? getResolveConversationPhrase()
        : t(`MACROS.ACTIONS.${type.label}`),
    icon: getActionIcon(type.key),
  }));
});

provide('macroActionTypes', macroActionTypes);

const uiFlags = computed(() => getters['macros/getUIFlags'].value);
const macroId = computed(() => route.params.macroId);
const isPublicMacroReadOnly = computed(
  () => macro.value?.visibility === 'global' && !isAdmin.value
);

const fetchDropdownData = () =>
  Promise.all([
    store.dispatch('agents/get'),
    store.dispatch('teams/get'),
    store.dispatch('labels/get'),
    store.dispatch('attributes/get'),
  ]);

const formatMacro = macroData => {
  const formattedActions = macroData.actions.map(action => {
    let actionParams = [];
    const hasParams = Array.isArray(action.action_params)
      ? action.action_params.length > 0
      : action.action_params &&
        typeof action.action_params === 'object' &&
        Object.keys(action.action_params).length > 0;

    if (hasParams) {
      const inputType = macroActionTypes.value.find(
        item => item.key === action.action_name
      )?.inputType;
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
      } else if (inputType === 'custom_attribute') {
        const data = Array.isArray(action.action_params)
          ? action.action_params[0] || {}
          : action.action_params || {};
        actionParams = {
          attribute_key: data.attribute_key || '',
          value: data.value ?? '',
        };
      } else {
        actionParams = Array.isArray(action.action_params)
          ? [...action.action_params]
          : [action.action_params];
      }
    } else if (
      [
        'update_contact_custom_attribute',
        'update_conversation_custom_attribute',
      ].includes(action.action_name)
    ) {
      actionParams = { attribute_key: '', value: '' };
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
  await Promise.all([
    fetchDropdownData(),
    store.dispatch('macros/getSingleMacro', macroId.value),
  ]);
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
    folder: '',
    actions: [
      {
        action_name: 'assign_team',
        action_params: [],
      },
    ],
    visibility: isAdmin.value ? 'global' : 'personal',
  };
};

watch(
  () => route,
  () => {
    if (route.params.macroId) {
      fetchMacro();
    } else {
      fetchDropdownData();
      initNewMacro();
    }
  },
  { immediate: true, deep: true }
);

const saveMacro = async macroData => {
  if (isPublicMacroReadOnly.value) return;

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
  <div class="flex flex-col gap-6 mb-8 max-w-7xl mx-auto h-full w-full !px-6">
    <woot-loading-state
      v-if="uiFlags.isFetchingItem"
      :message="t('MACROS.EDITOR.LOADING')"
    />
    <MacroForm
      v-if="macro && !uiFlags.isFetchingItem"
      :macro-data="macro"
      :can-manage-public-macros="isAdmin"
      :read-only="isPublicMacroReadOnly"
      @update:macro-data="macro = $event"
      @submit="saveMacro"
    />
  </div>
</template>
