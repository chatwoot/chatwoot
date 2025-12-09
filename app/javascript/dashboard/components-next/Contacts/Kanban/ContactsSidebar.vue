<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter, useRoute } from 'vue-router';
import { frontendURL } from 'dashboard/helper/URLHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  searchQuery: {
    type: String,
    default: '',
  },
  funnelId: {
    type: Number,
    default: null,
  },
  appliedFilters: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['addContact']);

const store = useStore();
const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const contacts = useMapGetter('contacts/getContactsList');
const uiFlags = useMapGetter('contacts/getUIFlags');
const getFunnelContacts = useMapGetter('funnels/getFunnelContacts');
const getContactLabels = useMapGetter('contactLabels/getContactLabels');

// Helper para obter valor do contato
const getContactValue = (contact, attributeKey) => {
  if (attributeKey === 'name') {
    return contact.name || '';
  }
  if (attributeKey === 'labels') {
    // Primeiro tentar buscar do objeto contact diretamente (caso venha da API)
    if (contact.labels && Array.isArray(contact.labels)) {
      const labels = contact.labels.map(l => {
        if (typeof l === 'string') return l;
        if (typeof l === 'object' && l !== null) {
          return l.title || l.name || l;
        }
        return String(l);
      });
      if (labels.length > 0) return labels;
    }

    // Se não encontrou no objeto, buscar do store contactLabels
    const labels = getContactLabels.value(contact.id);

    // Se encontrou no store, retornar (é um array de strings)
    if (labels && Array.isArray(labels) && labels.length > 0) {
      return labels;
    }

    // Se não encontrou em nenhum lugar, retornar array vazio
    return [];
  }
  if (attributeKey === 'team_id') {
    // Para times, verificar se o contato tem team_id diretamente
    // Se não tiver, retornar null (não filtra por time se não houver informação)
    // Nota: Contatos não têm team_id diretamente, apenas conversas têm
    // Para filtrar por time, seria necessário buscar contatos via API com filtro
    return contact.team_id || null;
  }
  if (attributeKey === 'created_at') {
    // created_at vem como timestamp (número)
    return contact.created_at;
  }
  return null;
};

// Helper para verificar se um filtro individual corresponde
const matchesFilter = (contact, filter) => {
  const { attributeKey, filterOperator, values } = filter;
  const contactValue = getContactValue(contact, attributeKey);
  const filterValue = values;

  // Se não há valor no filtro e o operador requer valor, não filtra (retorna true para não excluir)
  if (
    filterValue === null ||
    filterValue === undefined ||
    filterValue === '' ||
    (Array.isArray(filterValue) && filterValue.length === 0)
  ) {
    if (!['is_present', 'is_not_present'].includes(filterOperator)) {
      return true; // Se não há valor para filtrar, não filtra (retorna true para não excluir o contato)
    }
  }

  // Se o valor do contato é null/undefined e o operador requer valor
  if (
    (contactValue === null ||
      contactValue === undefined ||
      contactValue === '') &&
    !['is_present', 'is_not_present'].includes(filterOperator)
  ) {
    // Para operadores que requerem valor, se o contato não tem valor, não corresponde
    return false;
  }

  switch (filterOperator) {
    case 'equal_to': {
      if (attributeKey === 'labels') {
        // Para labels, verifica se algum label do filtro está nos labels do contato
        const contactLabels = Array.isArray(contactValue) ? contactValue : [];
        if (Array.isArray(filterValue) && filterValue.length > 0) {
          // Se filterValue é um objeto com id/name, extrair o valor
          const filterLabels = filterValue.map(fv => {
            if (typeof fv === 'object' && fv !== null) {
              return fv.id || fv.name || fv;
            }
            return fv;
          });
          return filterLabels.some(fv =>
            contactLabels.some(
              cl => String(cl).toLowerCase() === String(fv).toLowerCase()
            )
          );
        }
        // Se filterValue é um objeto único
        if (filterValue && typeof filterValue === 'object') {
          const filterVal = filterValue.id || filterValue.name || filterValue;
          return contactLabels.some(
            cl => String(cl).toLowerCase() === String(filterVal).toLowerCase()
          );
        }
        return contactLabels.some(
          cv => String(cv).toLowerCase() === String(filterValue).toLowerCase()
        );
      }
      if (attributeKey === 'team_id') {
        // Contatos não têm team_id diretamente - times são associados a conversas, não a contatos
        // O filtro de times deve ser feito apenas via API, não localmente
        // Se chegamos aqui, significa que o filtro não foi aplicado via API
        // Retornar true para não excluir nenhum contato localmente (deixa a API filtrar)
        return true;
      }
      if (Array.isArray(filterValue)) {
        return filterValue.some(v => {
          const val = typeof v === 'object' ? v.id || v.name || v : v;
          return (
            String(contactValue).toLowerCase() === String(val).toLowerCase()
          );
        });
      }
      const filterVal =
        typeof filterValue === 'object'
          ? filterValue.id || filterValue.name || filterValue
          : filterValue;
      return (
        String(contactValue).toLowerCase() === String(filterVal).toLowerCase()
      );
    }

    case 'not_equal_to':
      if (attributeKey === 'labels') {
        if (Array.isArray(filterValue)) {
          const contactLabels = Array.isArray(contactValue) ? contactValue : [];
          return !filterValue.some(fv =>
            contactLabels.some(
              cl => String(cl).toLowerCase() === String(fv).toLowerCase()
            )
          );
        }
        return (
          !Array.isArray(contactValue) ||
          !contactValue.some(
            cv => String(cv).toLowerCase() === String(filterValue).toLowerCase()
          )
        );
      }
      if (Array.isArray(filterValue)) {
        return !filterValue.some(
          v => String(contactValue).toLowerCase() === String(v).toLowerCase()
        );
      }
      return (
        String(contactValue).toLowerCase() !== String(filterValue).toLowerCase()
      );

    case 'contains':
      return String(contactValue)
        .toLowerCase()
        .includes(String(filterValue).toLowerCase());

    case 'does_not_contain':
      return !String(contactValue)
        .toLowerCase()
        .includes(String(filterValue).toLowerCase());

    case 'is_present':
      return (
        contactValue !== null &&
        contactValue !== undefined &&
        contactValue !== '' &&
        (!Array.isArray(contactValue) || contactValue.length > 0)
      );

    case 'is_not_present':
      return (
        contactValue === null ||
        contactValue === undefined ||
        contactValue === '' ||
        (Array.isArray(contactValue) && contactValue.length === 0)
      );

    case 'is_greater_than': {
      if (attributeKey === 'created_at') {
        // created_at vem como timestamp (número)
        const contactTimestamp = Number(contactValue);
        const filterTimestamp =
          typeof filterValue === 'string'
            ? new Date(filterValue).getTime() / 1000
            : Number(filterValue);
        return contactTimestamp > filterTimestamp;
      }
      return Number(contactValue) > Number(filterValue);
    }

    case 'is_less_than': {
      if (attributeKey === 'created_at') {
        // created_at vem como timestamp (número)
        const contactTimestamp = Number(contactValue);
        const filterTimestamp =
          typeof filterValue === 'string'
            ? new Date(filterValue).getTime() / 1000
            : Number(filterValue);
        return contactTimestamp < filterTimestamp;
      }
      return Number(contactValue) < Number(filterValue);
    }

    case 'days_before': {
      if (attributeKey === 'created_at') {
        // created_at vem como timestamp (número em segundos)
        const today = Math.floor(Date.now() / 1000);
        const daysInSeconds = Number(filterValue) * 24 * 60 * 60;
        const targetTimestamp = today - daysInSeconds;
        const contactTimestamp = Number(contactValue);
        return contactTimestamp < targetTimestamp;
      }
      return false;
    }

    case 'starts_with':
      return String(contactValue)
        .toLowerCase()
        .startsWith(String(filterValue).toLowerCase());

    default:
      return true;
  }
};

// Helper para aplicar filtros respeitando operadores AND/OR
const applyContactFilters = (contact, filters) => {
  if (!filters || filters.length === 0) {
    return true;
  }

  // Filtrar apenas filtros que têm valores válidos
  const validFilters = filters.filter(f => {
    const hasValue =
      f.values !== null &&
      f.values !== undefined &&
      f.values !== '' &&
      (!Array.isArray(f.values) || f.values.length > 0);
    return (
      hasValue || ['is_present', 'is_not_present'].includes(f.filterOperator)
    );
  });

  if (validFilters.length === 0) {
    return true;
  }

  // Se só tem um filtro válido, aplica diretamente
  if (validFilters.length === 1) {
    return matchesFilter(contact, validFilters[0]);
  }

  // Para múltiplos filtros, aplica lógica AND/OR
  let result = matchesFilter(contact, validFilters[0]);

  for (let i = 1; i < validFilters.length; i += 1) {
    const filter = validFilters[i];
    const filterResult = matchesFilter(contact, filter);
    const queryOperator = validFilters[i - 1].queryOperator || 'and';

    if (queryOperator === 'or') {
      result = result || filterResult;
    } else {
      result = result && filterResult;
    }
  }

  return result;
};

// Watch para garantir que labels sejam carregados quando há filtros de labels
const labelsLoading = ref(false);
watch(
  () => [props.appliedFilters, contacts.value],
  async ([filters, contactsList]) => {
    if (!filters || !contactsList || labelsLoading.value) return;

    // Verificar se há filtro de labels
    const hasLabelFilter = filters.some(
      f =>
        f.attributeKey === 'labels' &&
        f.values &&
        (Array.isArray(f.values) ? f.values.length > 0 : f.values !== '')
    );

    if (hasLabelFilter && contactsList && contactsList.length > 0) {
      labelsLoading.value = true;
      const contactIds = contactsList.map(c => c.id).filter(Boolean);
      if (contactIds.length > 0) {
        // Buscar labels para todos os contatos em paralelo
        await Promise.all(
          contactIds.map(contactId => {
            return store.dispatch('contactLabels/get', contactId).catch(() => {
              // Ignorar erros silenciosamente
            });
          })
        );
      }
      labelsLoading.value = false;
    }
  },
  { immediate: true, deep: true }
);

const filteredContacts = computed(() => {
  if (!contacts.value || !Array.isArray(contacts.value)) {
    return [];
  }

  const query = props.searchQuery?.toLowerCase() || '';
  const funnelContactsList = props.funnelId
    ? getFunnelContacts.value(props.funnelId) || []
    : [];
  const funnelContactIds = funnelContactsList.map(fc => fc.contact_id);

  const filtered = contacts.value.filter(contact => {
    // Filtrar por busca
    if (query) {
      const matchesSearch =
        (contact.name && contact.name.toLowerCase().includes(query)) ||
        (contact.email && contact.email.toLowerCase().includes(query)) ||
        (contact.phone_number &&
          contact.phone_number.toLowerCase().includes(query));
      if (!matchesSearch) return false;
    }

    // Aplicar filtros avançados apenas se houver filtros válidos
    // IMPORTANTE: Não aplicar filtro de team_id localmente - contatos não têm team_id
    if (props.appliedFilters && props.appliedFilters.length > 0) {
      // Separar filtros que podem ser aplicados localmente dos que precisam de API
      const localFilters = props.appliedFilters.filter(
        f => f.attributeKey !== 'team_id'
      );
      const hasTeamFilter = props.appliedFilters.some(
        f => f.attributeKey === 'team_id'
      );

      // Se há filtro de team, não aplicar filtros locais (a API já filtrou)
      // Se não há filtro de team, aplicar filtros locais normalmente
      if (hasTeamFilter) {
        // Se há filtro de team, a API já filtrou os contatos no store
        // A lista de contatos em contacts.value já está filtrada pela API
        // Aplicar outros filtros locais se houver (como labels)
        if (localFilters.length > 0) {
          const hasValidLocalFilters = localFilters.some(f => {
            const hasValue =
              f.values !== null &&
              f.values !== undefined &&
              f.values !== '' &&
              (!Array.isArray(f.values) || f.values.length > 0);
            return (
              hasValue ||
              ['is_present', 'is_not_present'].includes(f.filterOperator)
            );
          });

          if (hasValidLocalFilters) {
            const matchesFilters = applyContactFilters(contact, localFilters);
            if (!matchesFilters) {
              return false;
            }
          }
        }
        // Se chegou aqui e há filtro de team, o contato já passou pelo filtro da API
        // e pelos filtros locais (se houver)
        // MAS ainda precisa verificar se não está no funil
      } else {
        // Sem filtro de team - aplicar todos os filtros localmente
        const hasValidFilters = props.appliedFilters.some(f => {
          const hasValue =
            f.values !== null &&
            f.values !== undefined &&
            f.values !== '' &&
            (!Array.isArray(f.values) || f.values.length > 0);
          return (
            hasValue ||
            ['is_present', 'is_not_present'].includes(f.filterOperator)
          );
        });

        if (hasValidFilters) {
          const matchesFilters = applyContactFilters(
            contact,
            props.appliedFilters
          );
          if (!matchesFilters) {
            return false;
          }
        }
      }
    }

    // Mostrar apenas contatos que não estão no funil
    // IMPORTANTE: Esta verificação deve sempre ser feita, mesmo quando há filtro de times
    return !funnelContactIds.includes(contact.id);
  });

  return filtered;
});

const handleContactClick = contact => {
  router.push(
    frontendURL(`accounts/${route.params.accountId}/contacts/${contact.id}`)
  );
};

const handleAddToFunnel = (contact, event) => {
  event.stopPropagation();
  if (props.funnelId) {
    emit('addContact', { contactId: contact.id, funnelId: props.funnelId });
  }
};

const handleDragStart = (e, contact) => {
  e.dataTransfer.effectAllowed = 'move';

  const dragData = {
    contactId: contact.id,
    fromSidebar: true,
  };

  e.dataTransfer.setData('application/json', JSON.stringify(dragData));
  e.dataTransfer.setData('text/plain', contact.id.toString());
};

const handleContactDrag = (e, contact) => {
  e.stopPropagation();
  handleDragStart(e, contact);
};

const handleDrop = async e => {
  e.preventDefault();

  let dragData = null;
  try {
    const jsonData = e.dataTransfer.getData('application/json');
    if (jsonData) {
      dragData = JSON.parse(jsonData);
    } else {
      return;
    }
  } catch (error) {
    // Se não conseguir parsear, não faz nada
    return;
  }

  const { contactId, fromSidebar, sourceFunnelId } = dragData;

  // Só trata drops vindos do Kanban, não da própria sidebar
  if (!contactId || fromSidebar) return;

  try {
    if (props.funnelId && sourceFunnelId === props.funnelId) {
      await store.dispatch('funnels/removeContact', {
        funnelId: props.funnelId,
        contactId,
      });
    }
    // Assim que remover do funil, o contato volta a aparecer na lista
  } catch (error) {
    // Silencia erro aqui; o usuário ainda pode remover pelo menu do card
    // e não queremos quebrar o drag-and-drop
  }
};
</script>

<template>
  <div
    class="flex flex-col h-full bg-n-slate-1 border-r border-n-strong"
    @dragover.prevent
    @drop="handleDrop"
  >
    <div class="flex items-center px-4 h-[5rem] border-b border-n-strong">
      <div class="flex flex-col justify-center">
        <h3 class="text-sm font-semibold text-n-slate-12 leading-tight">
          {{ t('KANBAN.CONTACTS_SIDEBAR.TITLE') }}
        </h3>
        <p class="text-xs text-n-slate-10 mt-0.5 leading-tight">
          {{ t('KANBAN.CONTACTS_SIDEBAR.SUBTITLE') }}
        </p>
      </div>
    </div>
    <div class="flex-1 overflow-y-auto">
      <div
        v-if="uiFlags.isFetching"
        class="flex items-center justify-center py-8"
      >
        <Icon
          icon="i-lucide-loader-2"
          class="size-5 animate-spin text-n-slate-10"
        />
      </div>
      <div
        v-else-if="filteredContacts.length === 0"
        class="flex flex-col items-center justify-center py-8 px-4 text-center"
      >
        <Icon icon="i-lucide-users" class="size-8 text-n-slate-10 mb-2" />
        <p class="text-sm text-n-slate-11">
          {{ t('KANBAN.CONTACTS_SIDEBAR.NO_CONTACTS') }}
        </p>
      </div>
      <div v-else class="divide-y divide-n-strong">
        <div
          v-for="contact in filteredContacts"
          :key="contact.id"
          class="flex items-center gap-2 px-4 py-3 hover:bg-n-slate-2 cursor-move transition-colors group"
          draggable="true"
          @dragstart="handleContactDrag($event, contact)"
          @click="handleContactClick(contact)"
        >
          <Avatar
            :name="contact.name"
            :src="contact.thumbnail"
            :size="32"
            :status="contact.availability_status"
            rounded-full
          />
          <div class="flex-1 min-w-0 mr-1">
            <h4 class="text-sm font-medium truncate text-n-slate-12">
              {{ contact.name || t('KANBAN.CONTACTS_SIDEBAR.UNNAMED') }}
            </h4>
            <p v-if="contact.email" class="text-xs text-n-slate-10 truncate">
              {{ contact.email }}
            </p>
          </div>
          <button
            v-if="funnelId"
            class="opacity-0 group-hover:opacity-100 p-1.5 rounded hover:bg-n-slate-3 transition-opacity cursor-pointer"
            :title="t('KANBAN.CONTACTS_SIDEBAR.ADD_TO_FUNNEL')"
            @click.stop="handleAddToFunnel(contact, $event)"
          >
            <Icon icon="i-lucide-plus" class="size-4 text-n-slate-11" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
