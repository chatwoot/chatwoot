<script setup>
import { computed, ref, onMounted, onUnmounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import KanbanCard from './KanbanCard.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  funnelId: {
    type: Number,
    required: true,
  },
  column: {
    type: Object,
    required: true,
  },
  columnIndex: {
    type: Number,
    required: true,
  },
  searchQuery: {
    type: String,
    default: '',
  },
  appliedFilters: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits([
  'contactMoved',
  'columnDragStart',
  'addContactFromSidebar',
]);

const store = useStore();
const { t } = useI18n();

const getContactsByColumn = useMapGetter('funnels/getContactsByColumn');
const getContactLabels = useMapGetter('contactLabels/getContactLabels');
const contactsFromAPI = useMapGetter('contacts/getContactsList');
const isDraggingOver = ref(false);

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
          const fv = filterValue.id || filterValue.name || filterValue;
          return contactLabels.some(
            cl => String(cl).toLowerCase() === String(fv).toLowerCase()
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

    case 'not_equal_to': {
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
    }

    case 'contains': {
      return String(contactValue)
        .toLowerCase()
        .includes(String(filterValue).toLowerCase());
    }

    case 'does_not_contain': {
      return !String(contactValue)
        .toLowerCase()
        .includes(String(filterValue).toLowerCase());
    }

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
  () => [props.appliedFilters, props.funnelId, props.column?.id],
  async ([filters, funnelId, columnId]) => {
    if (!filters || !funnelId || !columnId || labelsLoading.value) return;

    // Verificar se há filtro de labels
    const hasLabelFilter = filters.some(
      f =>
        f.attributeKey === 'labels' &&
        f.values &&
        (Array.isArray(f.values) ? f.values.length > 0 : f.values !== '')
    );

    if (hasLabelFilter) {
      const columnContacts = getContactsByColumn.value(funnelId, columnId);
      if (
        columnContacts &&
        Array.isArray(columnContacts) &&
        columnContacts.length > 0
      ) {
        labelsLoading.value = true;
        const contactIds = columnContacts
          .map(fc => fc?.contact?.id)
          .filter(Boolean);
        if (contactIds.length > 0) {
          // Buscar labels para todos os contatos em paralelo
          await Promise.all(
            contactIds.map(contactId => {
              return store
                .dispatch('contactLabels/get', contactId)
                .catch(() => {
                  // Ignorar erros silenciosamente
                });
            })
          );
        }
        labelsLoading.value = false;
      }
    }
  },
  { immediate: true, deep: true }
);

const contacts = computed(() => {
  try {
    if (!props.funnelId || !props.column?.id) {
      return [];
    }

    const columnContacts = getContactsByColumn.value(
      props.funnelId,
      props.column.id
    );
    if (!Array.isArray(columnContacts)) {
      return [];
    }

    let filtered = columnContacts;

    // Aplicar busca por texto
    if (props.searchQuery) {
      const query = props.searchQuery.toLowerCase();
      filtered = filtered.filter(fc => {
        if (!fc) return false;
        const contact = fc.contact;
        if (!contact) return false;
        return (
          (contact.name && contact.name.toLowerCase().includes(query)) ||
          (contact.email && contact.email.toLowerCase().includes(query)) ||
          (contact.phone_number &&
            contact.phone_number.toLowerCase().includes(query))
        );
      });
    }

    // Aplicar filtros avançados
    // IMPORTANTE: Não aplicar filtro de team_id localmente - contatos não têm team_id
    if (props.appliedFilters && props.appliedFilters.length > 0) {
      // Separar filtros que podem ser aplicados localmente dos que precisam de API
      const localFilters = props.appliedFilters.filter(
        f => f.attributeKey !== 'team_id'
      );
      const hasTeamFilter = props.appliedFilters.some(
        f => f.attributeKey === 'team_id'
      );

      // Se há filtro de team, precisamos verificar se o contato está na lista filtrada pela API
      // pois contatos não têm team_id diretamente
      if (hasTeamFilter) {
        // Obter lista de contatos filtrados pela API (que passaram no filtro de times)
        const filteredContactsFromAPI = contactsFromAPI.value || [];
        const filteredContactIds = new Set(
          filteredContactsFromAPI.map(c => c.id)
        );

        // Filtrar apenas contatos que estão na lista retornada pela API
        filtered = filtered.filter(fc => {
          if (!fc || !fc.contact) {
            return false;
          }
          return filteredContactIds.has(fc.contact.id);
        });

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
            filtered = filtered.filter(fc => {
              if (!fc || !fc.contact) {
                return false;
              }
              return applyContactFilters(fc.contact, localFilters);
            });
          }
        }
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
          filtered = filtered.filter(fc => {
            if (!fc || !fc.contact) {
              return false;
            }
            return applyContactFilters(fc.contact, props.appliedFilters);
          });
        }
      }
    }

    return filtered;
  } catch {
    return [];
  }
});

const totalValue = computed(() => {
  return 'R$ 0,00';
});

const handleMoveContact = async (contactId, newColumnId, position) => {
  try {
    await store.dispatch('funnels/moveContact', {
      funnelId: props.funnelId,
      contactId,
      columnId: newColumnId,
      position,
    });
    emit('contactMoved');
  } catch {
    useAlert(t('KANBAN.MOVE_CONTACT.ERROR'));
  }
};

const isContactDragEvent = e => {
  try {
    const jsonData = e.dataTransfer.getData('application/json');
    if (jsonData) {
      const data = JSON.parse(jsonData);
      return Boolean(data && data.contactId);
    }

    // Fallback para drag vindo da sidebar
    const fromSidebar = e.dataTransfer.getData('fromSidebar') === 'true';
    const contactId = parseInt(
      e.dataTransfer.getData('contactId') ||
        e.dataTransfer.getData('text/plain'),
      10
    );

    return fromSidebar && Boolean(contactId);
  } catch {
    return false;
  }
};

const handleDragOver = e => {
  // Só tratamos o dragover aqui quando for drag de contato.
  // Para drag de coluna, deixamos o evento propagar para o wrapper pai,
  // que é responsável por reordenar as colunas.
  if (!isContactDragEvent(e)) {
    isDraggingOver.value = false;
    return;
  }

  e.stopPropagation();
  e.dataTransfer.dropEffect = 'move';
  isDraggingOver.value = true;
};

const handleDragLeave = () => {
  isDraggingOver.value = false;
};

const handleDrop = async e => {
  // Se não for um drag de contato, não tratamos aqui para permitir
  // que o wrapper da coluna lide com reordenação de colunas.
  if (!isContactDragEvent(e)) {
    isDraggingOver.value = false;
    return;
  }

  e.stopPropagation();
  isDraggingOver.value = false;

  let dragData;
  try {
    const jsonData = e.dataTransfer.getData('application/json');
    if (jsonData) {
      dragData = JSON.parse(jsonData);
    } else {
      // Fallback para dados antigos (sidebar)
      const contactId = parseInt(
        e.dataTransfer.getData('contactId') ||
          e.dataTransfer.getData('text/plain'),
        10
      );
      const fromSidebar = e.dataTransfer.getData('fromSidebar') === 'true';
      if (fromSidebar && contactId) {
        emit('addContactFromSidebar', { contactId, columnId: props.column.id });
        return;
      }
      return;
    }
  } catch {
    return;
  }

  const { contactId, sourceColumnId, sourceFunnelId } = dragData;

  if (!contactId) return;

  // Se o contato já está nesta coluna, não faz nada
  if (sourceColumnId === props.column.id && sourceFunnelId === props.funnelId) {
    return;
  }

  // Calcula a posição baseada na posição do drop
  const dropY = e.clientY;
  const cards = e.currentTarget.querySelectorAll('.kanban-card');
  let position = contacts.value.length;

  for (let i = 0; i < cards.length; i += 1) {
    const cardRect = cards[i].getBoundingClientRect();
    if (dropY < cardRect.top + cardRect.height / 2) {
      position = i;
      break;
    }
  }

  await handleMoveContact(contactId, props.column.id, position);
};

const showColumnMenu = ref(false);
const isEditingColumn = ref(false);
const editedColumnName = ref('');

const handleColumnOptions = e => {
  e.stopPropagation();
  showColumnMenu.value = !showColumnMenu.value;
};

const handleEditColumn = () => {
  showColumnMenu.value = false;
  editedColumnName.value = props.column.name;
  isEditingColumn.value = true;
};

const handleSaveColumnName = async () => {
  if (!editedColumnName.value.trim()) {
    editedColumnName.value = props.column.name;
    isEditingColumn.value = false;
    return;
  }

  try {
    // Obter o funil atual
    const funnels = store.getters['funnels/getFunnels'];
    const funnel = funnels.find(f => f.id === props.funnelId);

    if (!funnel) {
      throw new Error('Funnel not found');
    }

    // Atualizar o nome da coluna no array de colunas
    const updatedColumns = funnel.columns.map(col => {
      if (col.id === props.column.id) {
        return { ...col, name: editedColumnName.value.trim() };
      }
      return col;
    });

    // Atualizar o funil
    await store.dispatch('funnels/update', {
      id: props.funnelId,
      columns: updatedColumns,
    });

    isEditingColumn.value = false;
    useAlert(t('KANBAN.UPDATE_COLUMN.SUCCESS'));
  } catch {
    useAlert(t('KANBAN.UPDATE_COLUMN.ERROR'));
    editedColumnName.value = props.column.name;
    isEditingColumn.value = false;
  }
};

const handleCancelEdit = () => {
  editedColumnName.value = props.column.name;
  isEditingColumn.value = false;
};

const handleDeleteColumn = () => {
  showColumnMenu.value = false;
  // TODO: Implementar exclusão de coluna
};

const handleRemoveContact = async contactId => {
  try {
    await store.dispatch('funnels/removeContact', {
      funnelId: props.funnelId,
      contactId,
    });
    useAlert(t('KANBAN.REMOVE_CONTACT.SUCCESS'));
    emit('contactMoved');
  } catch {
    useAlert(t('KANBAN.REMOVE_CONTACT.ERROR'));
  }
};

const handleClickOutside = e => {
  if (!e.target.closest('.column-menu-container')) {
    showColumnMenu.value = false;
  }
};

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});
</script>

<template>
  <div
    class="flex flex-col w-80 bg-n-slate-2 rounded-lg transition-all"
    :class="{ 'ring-2 ring-n-teal-9 ring-opacity-50': isDraggingOver }"
    @dragover.prevent="handleDragOver"
    @dragleave="handleDragLeave"
    @drop.prevent="handleDrop"
  >
    <div
      class="flex items-center justify-between px-4 py-3 bg-n-teal-9 rounded-t-lg cursor-move"
      draggable="true"
      @dragstart.stop="emit('columnDragStart', $event, columnIndex)"
    >
      <div class="flex items-center gap-2 flex-1 min-w-0">
        <h3
          v-if="!isEditingColumn"
          class="text-sm font-semibold text-white truncate"
        >
          {{ column.name }}
        </h3>
        <div v-else class="flex items-center gap-2 flex-1">
          <input
            v-model="editedColumnName"
            type="text"
            class="flex-1 px-2 py-1 text-sm font-semibold text-n-slate-12 bg-white rounded border border-n-strong focus:outline-none focus:ring-2 focus:ring-n-teal-9"
            autofocus
            @keyup.enter="handleSaveColumnName"
            @keyup.esc="handleCancelEdit"
            @blur="handleSaveColumnName"
          />
        </div>
      </div>
      <div class="relative column-menu-container flex-shrink-0">
        <button
          class="p-0.5 text-white rounded hover:bg-n-teal-10 transition-colors"
          :title="t('KANBAN.COLUMN_OPTIONS')"
          @click.stop="handleColumnOptions"
          @mousedown.stop
        >
          <Icon icon="i-lucide-more-horizontal" class="size-4" />
        </button>
        <div
          v-if="showColumnMenu"
          class="absolute right-0 top-full mt-1 w-48 bg-n-background rounded-lg shadow-lg border border-n-strong z-50 overflow-hidden"
          @click.stop
        >
          <button
            class="w-full px-4 py-2 text-left text-sm text-n-slate-10 hover:bg-n-slate-3 transition-colors"
            @click="handleEditColumn"
          >
            <Icon icon="i-lucide-edit" class="size-4 inline mr-2" />
            {{ t('KANBAN.EDIT_COLUMN') }}
          </button>
          <button
            class="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 transition-colors"
            @click="handleDeleteColumn"
          >
            <Icon icon="i-lucide-trash" class="size-4 inline mr-2" />
            {{ t('KANBAN.DELETE_COLUMN') }}
          </button>
        </div>
      </div>
    </div>
    <div class="px-4 py-2 text-sm text-n-slate-11">
      {{ totalValue }}
    </div>
    <div
      class="flex-1 px-2 pb-4 overflow-y-auto space-y-2 min-h-[100px]"
      :class="{ 'bg-n-teal-2 bg-opacity-30': isDraggingOver }"
    >
      <KanbanCard
        v-for="(funnelContact, index) in contacts"
        :key="funnelContact.contact_id"
        :contact="funnelContact.contact"
        :funnel-id="funnelId"
        :column-id="column.id"
        :index="index"
        @remove="handleRemoveContact"
      />
      <div
        v-if="contacts.length === 0 && !isDraggingOver"
        class="flex items-center justify-center py-8 text-sm text-n-slate-10"
      >
        {{ t('KANBAN.NO_CONTACTS') }}
      </div>
      <div
        v-if="isDraggingOver && contacts.length === 0"
        class="flex items-center justify-center py-8 text-sm text-n-teal-11 border-2 border-dashed border-n-teal-9 rounded-lg"
      >
        {{ t('KANBAN.DROP_HERE') }}
      </div>
    </div>
  </div>
</template>
