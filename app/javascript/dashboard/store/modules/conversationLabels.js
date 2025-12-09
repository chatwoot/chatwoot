import * as types from '../mutation-types';
import ConversationAPI from '../../api/conversations';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isError: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getConversationLabels: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  get: async ({ commit }, conversationId) => {
    commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await ConversationAPI.getLabels(conversationId);
      commit(types.default.SET_CONVERSATION_LABELS, {
        id: conversationId,
        data: response.data.payload,
      });
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
  /**
   * Atualiza as labels da conversa e sincroniza com as labels do contato.
   *
   * - Continua funcionando normalmente para atualizar apenas a conversa.
   * - Após sucesso, tenta encontrar o contato relacionado à conversa
   *   e dispara `contactLabels/update` para manter o perfil em sincronia.
   * - A sincronização de contato é "best effort": se algo falhar, não
   *   quebra a atualização principal da conversa.
   */
  update: async (
    { commit, dispatch, rootGetters },
    { conversationId, labels }
  ) => {
    commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
      isUpdating: true,
    });
    try {
      const response = await ConversationAPI.updateLabels(
        conversationId,
        labels
      );

      commit(types.default.SET_CONVERSATION_LABELS, {
        id: conversationId,
        data: response.data.payload,
      });

      // Mantém o comportamento atual de UI da conversa
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: false,
      });

      // --- Sincronizar labels da conversa com o contato relacionado ---
      // Busca o contactId da conversa para sincronizar as labels
      try {
        let contactId = null;

        // Tentativa 1: Buscar do store de conversas primeiro (mais rápido)
        try {
          const getConversationById =
            rootGetters['conversations/getConversationById'];
          if (typeof getConversationById === 'function') {
            const conversation = getConversationById(conversationId);
            if (conversation?.meta?.sender?.id) {
              contactId = conversation.meta.sender.id;
            }
          }
        } catch {
          // Error is handled silently
        }

        // Tentativa 2: Se não encontrou no store, buscar diretamente da API
        if (!contactId) {
          try {
            const conversationResponse =
              await ConversationAPI.show(conversationId);
            const conversationData = conversationResponse?.data;

            // Tenta diferentes formatos de resposta
            if (conversationData?.payload?.meta?.sender?.id) {
              contactId = conversationData.payload.meta.sender.id;
            } else if (conversationData?.payload?.sender?.id) {
              contactId = conversationData.payload.sender.id;
            } else if (conversationData?.meta?.sender?.id) {
              contactId = conversationData.meta.sender.id;
            } else if (conversationData?.sender?.id) {
              contactId = conversationData.sender.id;
            }
          } catch {
            // Error is handled silently
          }
        }

        // Tentativa 3: Verificar resposta da API de updateLabels (caso tenha)
        if (!contactId && response?.data?.conversation?.meta?.sender?.id) {
          contactId = response.data.conversation.meta.sender.id;
        }

        if (contactId) {
          try {
            await dispatch(
              'contactLabels/update',
              {
                contactId,
                labels,
              },
              { root: true }
            );
          } catch {
            // Error is handled silently
          }
        }
      } catch {
        // Ignora erros de sincronização de contato para não quebrar o fluxo principal
      }
    } catch (error) {
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: true,
      });
    }
  },
  setBulkConversationLabels({ commit }, conversations) {
    commit(types.default.SET_BULK_CONVERSATION_LABELS, conversations);
  },
  setConversationLabel({ commit, dispatch }, { id, data }) {
    commit(types.default.SET_CONVERSATION_LABELS, { id, data });

    // Sincroniza com o contato quando as labels são atualizadas via ActionCable
    // Chama syncContactLabels diretamente (sem namespace, pois já estamos no módulo)
    dispatch('syncContactLabels', {
      conversationId: id,
      labels: data || [],
    });
  },
  /**
   * Sincroniza as labels de uma conversa com o contato relacionado
   * Pode ser chamada quando as labels são atualizadas via ActionCable ou outros métodos
   */
  syncContactLabels: async (
    { dispatch, rootGetters },
    { conversationId, labels }
  ) => {
    try {
      let contactId = null;

      // Tentativa 1: Buscar do store de conversas
      try {
        const getConversationById =
          rootGetters['conversations/getConversationById'];
        if (typeof getConversationById === 'function') {
          const conversation = getConversationById(conversationId);
          if (conversation?.meta?.sender?.id) {
            contactId = conversation.meta.sender.id;
          }
        }
      } catch {
        // Error is handled silently
      }

      // Tentativa 2: Buscar da API se não encontrou no store
      if (!contactId) {
        try {
          const conversationResponse =
            await ConversationAPI.show(conversationId);
          const conversationData = conversationResponse?.data;

          if (conversationData?.payload?.meta?.sender?.id) {
            contactId = conversationData.payload.meta.sender.id;
          } else if (conversationData?.payload?.sender?.id) {
            contactId = conversationData.payload.sender.id;
          } else if (conversationData?.meta?.sender?.id) {
            contactId = conversationData.meta.sender.id;
          } else if (conversationData?.sender?.id) {
            contactId = conversationData.sender.id;
          }
        } catch {
          // Error is handled silently
        }
      }

      if (contactId) {
        await dispatch(
          'contactLabels/update',
          {
            contactId,
            labels,
          },
          { root: true }
        );
      }
    } catch {
      // Error is handled silently
    }
  },
};

export const mutations = {
  [types.default.SET_CONVERSATION_LABELS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_CONVERSATION_LABELS]: ($state, { id, data }) => {
    $state.records = { ...$state.records, [id]: data };

    // Se as labels mudaram e não estamos em processo de atualização,
    // pode ser uma atualização via ActionCable - vamos sincronizar
    // Nota: Não podemos fazer dispatch aqui, mas podemos sinalizar que precisa sincronizar
    // A sincronização será feita pela action update ou syncContactLabels
  },
  [types.default.SET_BULK_CONVERSATION_LABELS]: ($state, conversations) => {
    const updatedRecords = { ...$state.records };
    conversations.forEach(conversation => {
      updatedRecords[conversation.id] = conversation.labels;
    });

    $state.records = updatedRecords;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
