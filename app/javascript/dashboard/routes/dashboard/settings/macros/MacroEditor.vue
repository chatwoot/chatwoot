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
import ChatwootExtraAPI from 'dashboard/api/chatwootExtra';

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
  // Ensure inboxes are loaded first
  await store.dispatch('inboxes/get');
  await store.dispatch('macros/getSingleMacro', macroId.value);

  const singleMacro = store.getters['macros/getMacro'](macroId.value);
  const formattedMacro = formatMacro(singleMacro);

  // Load source channels from Vuex cache
  const sourceChannelIds = getters['macros/getMacroSourceChannels'].value(
    macroId.value
  );
  const inboxes = getters['inboxes/getInboxes'].value;

  formattedMacro.sourceChannels = sourceChannelIds.map(channelId => {
    const inbox = inboxes.find(i => i.channel_id === channelId);
    return {
      id: channelId,
      name: inbox?.name || `Channel ${channelId}`,
    };
  });

  macro.value = formattedMacro;
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
    const sourceChannels = serializedMacro.sourceChannels || [];
    delete serializedMacro.sourceChannels;
    serializedMacro.actions = actionQueryGenerator(serializedMacro.actions);

    const result = await store.dispatch(action, serializedMacro);
    const currentUser = getters.getCurrentUser.value;
    const createdMacroId = result?.id || macroId.value;
    const sourceChannelIds = sourceChannels.map(channel => channel.id);

    // ALWAYS sync with chatwoot-extra (even with empty sources)
    try {
      let extraResponse;
      if (mode.value === 'EDIT') {
        // Use update endpoint which handles create-or-update
        extraResponse = await ChatwootExtraAPI.updateMacroSources({
          chatwootUserId: currentUser.id,
          chatwootMacrosId: createdMacroId,
          sourceChannelIds,
        });
      } else {
        // Create new macro in extra
        extraResponse = await ChatwootExtraAPI.createMacro({
          chatwootUserId: currentUser.id,
          chatwootMacrosId: createdMacroId,
          sourceChannelIds:
            sourceChannelIds.length > 0 ? sourceChannelIds : undefined,
        });
      }

      // Update Vuex cache with sources
      store.commit('macros/UPDATE_MACRO_SOURCES', {
        macroId: createdMacroId,
        sourceChannelIds,
      });

      // Update Vuex cache with UUID from response
      if (extraResponse?.data?.id) {
        store.commit('macros/UPDATE_MACRO_EXTRA_UUID', {
          macroId: createdMacroId,
          uuid: extraResponse.data.id,
        });
      }
    } catch (extraError) {
      // Ignore extra sync error
    }

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
