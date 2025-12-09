<script setup>
import { computed, watch, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import ContactAPI from 'dashboard/api/contacts';

import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';

const props = defineProps({
  contactId: {
    type: [String, Number],
    default: null,
  },
});

const store = useStore();
const route = useRoute();

const teams = useMapGetter('teams/getTeams');

const teamsList = computed(() => {
  return [{ id: 0, name: 'Nenhum' }, ...teams.value];
});

// Busca o time atual do contato através das conversas
const currentTeam = ref(null);
const isLoadingTeam = ref(false);

const fetchContactTeam = async contactId => {
  if (!contactId) {
    currentTeam.value = null;
    return;
  }

  isLoadingTeam.value = true;
  try {
    const conversationsResponse = await ContactAPI.getConversations(contactId);
    const conversations = conversationsResponse?.data?.payload || [];

    // Busca o time da primeira conversa que tiver um time atribuído
    const conversationWithTeam = conversations.find(conv => conv.meta?.team);
    if (conversationWithTeam) {
      currentTeam.value = conversationWithTeam.meta.team;
    } else {
      currentTeam.value = null;
    }
  } catch {
    currentTeam.value = null;
  } finally {
    isLoadingTeam.value = false;
  }
};

const handleTeamChange = async selectedTeam => {
  try {
    // Se selecionou o mesmo time ou "Nenhum" quando já estava sem time, não faz nada
    if (selectedTeam.id === 0 && !currentTeam.value) {
      return;
    }
    if (currentTeam.value && selectedTeam.id === currentTeam.value.id) {
      return;
    }

    const newTeamId = selectedTeam.id === 0 ? null : selectedTeam.id;
    const newTeam = selectedTeam.id === 0 ? null : selectedTeam;

    // Busca todas as conversas do contato
    try {
      const conversationsResponse = await ContactAPI.getConversations(
        props.contactId
      );
      const conversations = conversationsResponse?.data?.payload || [];

      // Atualiza o time de cada conversa
      await Promise.all(
        conversations.map(conversation =>
          store
            .dispatch('assignTeam', {
              conversationId: conversation.id,
              teamId: newTeamId || 0,
              skipSync: true, // Evita sincronização redundante, pois já estamos sincronizando todas aqui
            })
            .catch(() => {
              // Continua com as próximas conversas mesmo se uma falhar
            })
        )
      );

      // Atualiza o time local
      currentTeam.value = newTeam;
    } catch {
      // Não bloqueia a atualização se a sincronização falhar
    }
  } catch {
    // Erro silencioso - a UI já mostra feedback através do store
  }
};

watch(
  () => props.contactId,
  (newVal, oldVal) => {
    if (newVal !== oldVal) {
      fetchContactTeam(newVal);
    }
  }
);

const currentContactId = computed(
  () => props.contactId || route.params.contactId
);

onMounted(() => {
  const contactIdToFetch = currentContactId.value;
  if (contactIdToFetch) {
    fetchContactTeam(contactIdToFetch);
  }
});
</script>

<template>
  <div class="flex flex-col gap-2">
    <div class="text-sm font-medium text-n-slate-12">
      {{ $t('CONVERSATION_SIDEBAR.TEAM_LABEL') }}
    </div>
    <MultiselectDropdown
      v-if="!isLoadingTeam"
      :options="teamsList"
      :selected-item="currentTeam"
      :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.TEAM')"
      :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
      :no-search-result="$t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.TEAM')"
      :input-placeholder="
        $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.TEAM')
      "
      @select="handleTeamChange"
    />
    <div v-else class="text-sm text-n-slate-11">
      {{ $t('GENERAL.LOADING') }}
    </div>
  </div>
</template>
