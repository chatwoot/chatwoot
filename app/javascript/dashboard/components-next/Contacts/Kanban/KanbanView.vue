<script setup>
import { onMounted, onUnmounted, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';

import KanbanColumn from './KanbanColumn.vue';
import CreateFunnelDialog from './CreateFunnelDialog.vue';
import CreateColumnDialog from './CreateColumnDialog.vue';
import ContactsSidebar from './ContactsSidebar.vue';
import KanbanFilter from './KanbanFilter.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const store = useStore();
const { t } = useI18n();

const funnels = useMapGetter('funnels/getFunnels');
const uiFlags = useMapGetter('funnels/getUIFlags');
const defaultFunnel = useMapGetter('funnels/getDefaultFunnel');
const teams = useMapGetter('teams/getTeams');

const selectedFunnelId = ref(null);
const showCreateDialog = ref(false);
const showCreateColumnDialog = ref(false);
const showCreateDropdown = ref(false);
const showFilterDialog = ref(false);
const searchQuery = ref('');
const error = ref(null);
const sidebarWidth = ref(290);
const draggedColumnIndex = ref(null);
const columnsOrder = ref([]);
const appliedFilters = ref([]);

// Sidebar resize functionality
const MIN_SIDEBAR_WIDTH = 200;
const MAX_SIDEBAR_WIDTH = 500;
const isResizingSidebar = ref(false);
const resizeStartX = ref(0);
const resizeStartWidth = ref(290);

const handleSidebarResize = event => {
  if (!isResizingSidebar.value) return;

  const deltaX = event.clientX - resizeStartX.value;
  const newWidth = resizeStartWidth.value + deltaX;

  const clampedWidth = Math.max(
    MIN_SIDEBAR_WIDTH,
    Math.min(MAX_SIDEBAR_WIDTH, newWidth)
  );
  sidebarWidth.value = clampedWidth;
};

const stopSidebarResize = () => {
  isResizingSidebar.value = false;
  document.removeEventListener('mousemove', handleSidebarResize);
  document.removeEventListener('mouseup', stopSidebarResize);
  document.body.style.cursor = '';
  document.body.style.userSelect = '';
};

const startSidebarResize = event => {
  isResizingSidebar.value = true;
  resizeStartX.value = event.clientX;
  resizeStartWidth.value = sidebarWidth.value;

  document.addEventListener('mousemove', handleSidebarResize);
  document.addEventListener('mouseup', stopSidebarResize);
  document.body.style.cursor = 'col-resize';
  document.body.style.userSelect = 'none';

  event.preventDefault();
};

const currentFunnel = computed(() => {
  if (!funnels.value || funnels.value.length === 0) return null;
  if (selectedFunnelId.value) {
    return funnels.value.find(f => f.id === selectedFunnelId.value);
  }
  return defaultFunnel.value || funnels.value[0] || null;
});

const sortedColumns = computed(() => {
  const funnel = currentFunnel.value;
  if (!funnel || !Array.isArray(funnel.columns)) return [];

  if (!columnsOrder.value.length) {
    return funnel.columns;
  }

  const byId = funnel.columns.reduce((acc, col) => {
    acc[col.id] = col;
    return acc;
  }, {});

  return columnsOrder.value.map(id => byId[id]).filter(Boolean);
});

const isFetching = computed(() => uiFlags.value.isFetching);
const isCreating = computed(() => uiFlags.value.isCreating);
const isUpdating = computed(() => uiFlags.value.isUpdating);

async function reloadFunnels() {
  try {
    error.value = null;
    await store.dispatch('funnels/get');
    await store.dispatch('teams/get');

    // Aguardar um tick para garantir que os getters foram atualizados
    await new Promise(resolve => {
      setTimeout(resolve, 100);
    });

    const funnel =
      defaultFunnel.value || (funnels.value && funnels.value[0]) || null;
    if (funnel) {
      selectedFunnelId.value = funnel.id;
      columnsOrder.value = (funnel.columns || []).map(col => col.id);
      await store.dispatch('funnels/getContacts', {
        funnelId: funnel.id,
      });
    }
  } catch (err) {
    error.value =
      err?.message || err?.toString() || t('KANBAN.ERROR.LOAD_FUNNELS');
  }
}

const handleCreateFunnel = () => {
  showCreateDialog.value = true;
  showCreateDropdown.value = false;
};

const handleCreateColumn = () => {
  if (!currentFunnel.value) {
    useAlert(t('KANBAN.CREATE_COLUMN.NO_FUNNEL_SELECTED'));
    showCreateDropdown.value = false;
    return;
  }
  showCreateColumnDialog.value = true;
  showCreateDropdown.value = false;
};

const handleColumnCreated = async ({ name }) => {
  const funnel = currentFunnel.value;
  if (!funnel) return;

  try {
    // Criar ID único para a nova coluna
    const newColumnId = `col_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Obter a posição máxima atual e adicionar 1
    const maxPosition =
      funnel.columns && funnel.columns.length > 0
        ? Math.max(...funnel.columns.map(col => col.position || 0))
        : -1;

    // Criar nova coluna
    const newColumn = {
      id: newColumnId,
      name: name.trim(),
      position: maxPosition + 1,
    };

    // Adicionar a nova coluna ao array de colunas
    const updatedColumns = [...(funnel.columns || []), newColumn];

    // Atualizar o funil via API
    await store.dispatch('funnels/update', {
      id: funnel.id,
      columns: updatedColumns,
    });

    // Atualizar a ordem das colunas localmente
    columnsOrder.value = updatedColumns.map(col => col.id);

    // Recarregar os funis para garantir sincronização
    await reloadFunnels();

    showCreateColumnDialog.value = false;
    useAlert(t('KANBAN.CREATE_COLUMN.SUCCESS'));
  } catch {
    useAlert(t('KANBAN.CREATE_COLUMN_ERROR'));
  }
};

const createMenuItems = computed(() => [
  {
    action: 'create_funnel',
    value: 'create_funnel',
    label: t('KANBAN.CREATE_NEW_FUNNEL'),
    icon: 'i-lucide-plus',
  },
  {
    action: 'create_column',
    value: 'create_column',
    label: t('KANBAN.CREATE_NEW_COLUMN'),
    icon: 'i-lucide-layout-grid',
  },
]);

const handleCreateAction = ({ action }) => {
  if (action === 'create_funnel') {
    handleCreateFunnel();
  } else if (action === 'create_column') {
    handleCreateColumn();
  }
};

const loadContacts = async () => {
  try {
    await store.dispatch('contacts/get', { page: 1 });
  } catch {
    // Error is handled by the store
  }
};

const handleFunnelSelect = async () => {
  const funnel = currentFunnel.value;
  if (!funnel) return;
  try {
    selectedFunnelId.value = funnel.id;
    columnsOrder.value = (funnel.columns || []).map(col => col.id);
    await store.dispatch('funnels/getContacts', { funnelId: funnel.id });
  } catch {
    // Erro silencioso - a UI já mostra feedback através do store
  }
};

const handleAddContact = async ({ contactId, funnelId }) => {
  try {
    const funnel = currentFunnel.value;
    if (!funnel || !funnel.columns || funnel.columns.length === 0) {
      useAlert(t('KANBAN.ADD_CONTACT.NO_COLUMNS'));
      return;
    }

    // Adiciona o contato na primeira coluna
    const firstColumnId = funnel.columns[0].id;
    await store.dispatch('funnels/addContact', {
      funnelId,
      contactId,
      columnId: firstColumnId,
    });
    useAlert(t('KANBAN.ADD_CONTACT.SUCCESS'));
    // UI já é atualizada localmente pela mutation UPDATE_FUNNEL_CONTACT
  } catch {
    useAlert(t('KANBAN.ADD_CONTACT.ERROR'));
  }
};

const handleFilter = () => {
  showFilterDialog.value = !showFilterDialog.value;
};

const handleApplyFilter = async filters => {
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

  // Se há filtros válidos, sempre buscar contatos via API com filtros
  if (validFilters.length > 0) {
    try {
      // Converter filtros para o formato esperado pelo filterQueryGenerator
      const filtersForQuery = validFilters.map(f => {
        let processedValues = f.values;

        // Para team_id, extrair o ID do objeto se for um objeto
        if (f.attributeKey === 'team_id') {
          if (
            typeof f.values === 'object' &&
            f.values !== null &&
            !Array.isArray(f.values)
          ) {
            // Se é um objeto único, extrair o ID
            processedValues = [f.values.id || f.values];
          } else if (Array.isArray(f.values)) {
            // Se é array, extrair IDs dos objetos
            processedValues = f.values.map(v =>
              typeof v === 'object' && v !== null ? v.id || v : v
            );
          } else {
            // Se é um valor simples, colocar em array
            processedValues = [f.values];
          }
        }

        return {
          attribute_key: f.attributeKey,
          filter_operator: f.filterOperator,
          values: processedValues,
          query_operator: f.queryOperator || 'and',
        };
      });

      const queryPayload = filterQueryGenerator(filtersForQuery);

      await store.dispatch('contacts/filter', {
        page: 1,
        queryPayload,
      });
    } catch {
      useAlert(t('KANBAN.FILTER.ERROR'));
    }
  } else {
    // Se não há filtros válidos, recarregar contatos sem filtro
    await loadContacts();
  }

  appliedFilters.value = filters;
  showFilterDialog.value = false;
};

const handleClearFilters = async () => {
  store.dispatch('contacts/clearContactFilters');
  appliedFilters.value = [];
  showFilterDialog.value = false;
  // Recarregar contatos sem filtro
  await loadContacts();
};

// Limpar filtros quando o diálogo é fechado sem aplicar
watch(
  () => showFilterDialog.value,
  newValue => {
    if (!newValue && appliedFilters.value.length > 0) {
      // Verificar se os filtros ainda são válidos
      const hasValidFilters = appliedFilters.value.some(f => {
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

      if (!hasValidFilters) {
        appliedFilters.value = [];
        store.dispatch('contacts/clearContactFilters');
      }
    }
  }
);

const handleFunnelCreated = async funnel => {
  try {
    selectedFunnelId.value = funnel.id;
    await store.dispatch('funnels/getContacts', { funnelId: funnel.id });
    showCreateDialog.value = false;
  } catch (err) {
    error.value = err.message || t('KANBAN.ERROR.LOAD_CONTACTS');
    showCreateDialog.value = false;
  }
};

const handleContactMoved = async () => {
  // Recarrega os contatos após mover
  if (currentFunnel.value) {
    await store.dispatch('funnels/getContacts', {
      funnelId: currentFunnel.value.id,
    });
  }
};

const handleAddContactFromSidebar = async ({ contactId, columnId }) => {
  try {
    const funnel = currentFunnel.value;
    if (!funnel) return;

    await store.dispatch('funnels/addContact', {
      funnelId: funnel.id,
      contactId,
      columnId,
    });
    useAlert(t('KANBAN.ADD_CONTACT.SUCCESS'));
    // UI já é atualizada localmente pela mutation UPDATE_FUNNEL_CONTACT
  } catch {
    useAlert(t('KANBAN.ADD_CONTACT.ERROR'));
  }
};

const handleColumnDragStart = (e, index) => {
  draggedColumnIndex.value = index;
  e.dataTransfer.effectAllowed = 'move';
};

const handleColumnDragOver = e => {
  e.preventDefault();
  e.dataTransfer.dropEffect = 'move';
};

const handleColumnDrop = (e, dropIndex) => {
  e.preventDefault();

  const fromIndex = draggedColumnIndex.value;
  draggedColumnIndex.value = null;

  if (fromIndex === null || fromIndex === dropIndex || !currentFunnel.value) {
    return;
  }

  // Usamos apenas o array de IDs `columnsOrder` para reordenar,
  // garantindo que o índice vindo do v-for corresponda à ordem atual exibida.
  const currentOrder =
    columnsOrder.value && columnsOrder.value.length
      ? [...columnsOrder.value]
      : (currentFunnel.value.columns || []).map(col => col.id);

  if (!currentOrder.length) return;

  const [movedId] = currentOrder.splice(fromIndex, 1);
  currentOrder.splice(dropIndex, 0, movedId);

  columnsOrder.value = currentOrder;
};

// Fechar dropdown ao clicar fora
const handleClickOutside = event => {
  if (showCreateDropdown.value) {
    const target = event.target;
    const button = target.closest(
      '.create-dropdown-button, .create-dropdown-button *'
    );
    const dropdown = target.closest(
      '[class*="dropdown-menu"], [class*="DropdownMenu"]'
    );

    if (!button && !dropdown) {
      showCreateDropdown.value = false;
    }
  }
};

onMounted(() => {
  try {
    loadContacts();
    reloadFunnels();
    document.addEventListener('click', handleClickOutside);
  } catch (err) {
    error.value = t('KANBAN.ERROR.FATAL');
  }
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});
</script>

<template>
  <div class="flex h-full bg-n-background">
    <!-- Sidebar de Contatos -->
    <div
      class="relative flex-shrink-0 border-r border-n-strong"
      :style="{ width: `${sidebarWidth}px` }"
    >
      <ContactsSidebar
        :search-query="searchQuery"
        :funnel-id="currentFunnel?.id"
        :applied-filters="appliedFilters"
        @add-contact="handleAddContact"
      />
      <!-- Resize handle -->
      <div
        class="absolute top-0 bottom-0 right-0 w-1 cursor-col-resize hover:bg-n-strong/50 transition-colors z-50 group"
        @mousedown="startSidebarResize"
      >
        <div class="absolute inset-y-0 -right-1 w-3" />
      </div>
    </div>

    <!-- Área Principal do Kanban -->
    <div class="flex flex-col flex-1 min-w-0">
      <div
        v-if="error"
        class="p-4 m-4 bg-red-100 border border-red-400 rounded text-red-700"
      >
        <p class="font-semibold">{{ t('KANBAN.ERROR.TITLE') }}</p>
        <p class="text-sm mt-1">{{ error }}</p>
        <button
          class="mt-2 px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
          @click="reloadFunnels"
        >
          {{ t('KANBAN.ERROR.RETRY') }}
        </button>
      </div>
      <template v-else>
        <div
          class="flex items-center justify-between px-6 h-[5rem] border-b border-n-strong gap-4"
        >
          <div class="flex items-center gap-4 flex-shrink-0">
            <div
              v-if="funnels && funnels.length > 0"
              class="relative w-[140px] flex-shrink-0 h-10"
            >
              <select
                v-model="selectedFunnelId"
                class="funnel-select w-full h-full px-3 pr-8 text-sm border rounded-lg bg-n-background border-n-weak text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-weak"
                @change="handleFunnelSelect"
              >
                <option
                  v-for="funnel in funnels"
                  :key="funnel.id"
                  :value="funnel.id"
                >
                  {{ funnel.name }}
                </option>
              </select>
              <Icon
                icon="i-lucide-chevron-down"
                class="absolute right-2 top-1/2 -translate-y-1/2 size-4 text-n-slate-10 pointer-events-none"
              />
            </div>
            <div class="relative flex items-center group">
              <Button
                icon="i-lucide-plus"
                variant="solid"
                color="teal"
                size="sm"
                :label="t('KANBAN.CREATE_FUNNEL')"
                class="flex-shrink-0 whitespace-nowrap create-dropdown-button"
                @click.stop="showCreateDropdown = !showCreateDropdown"
              />
              <DropdownMenu
                v-if="showCreateDropdown"
                :menu-items="createMenuItems"
                class="mt-1 ltr:left-0 rtl:right-0 top-full z-50"
                @action="handleCreateAction"
              />
            </div>
          </div>
          <div class="flex items-center gap-2 flex-shrink-0">
            <div class="relative w-[240px] h-10">
              <input
                v-model="searchQuery"
                type="text"
                :placeholder="t('KANBAN.SEARCH_PLACEHOLDER')"
                class="w-full h-full px-4 pr-10 text-sm border border-n-weak rounded-lg bg-n-background text-n-slate-12 focus:outline-none focus:border-n-strong focus:ring-1 focus:ring-n-weak"
              />
              <Icon
                icon="i-lucide-search"
                class="absolute right-3 top-1/2 -translate-y-1/2 size-4 text-n-slate-10 pointer-events-none"
              />
            </div>
            <div class="relative flex-shrink-0">
              <Button
                id="toggleKanbanFilterButton"
                icon="i-lucide-filter"
                variant="ghost"
                color="slate"
                size="sm"
                :label="t('KANBAN.FILTER')"
                class="whitespace-nowrap"
                :class="{ 'bg-n-slate-3': showFilterDialog }"
                @click="handleFilter"
              />
              <div
                v-if="showFilterDialog"
                id="kanbanFilterTeleportTarget"
                class="absolute z-50 mt-2 ltr:right-0 rtl:left-0"
              />
              <TeleportWithDirection
                v-if="showFilterDialog"
                to="#kanbanFilterTeleportTarget"
              >
                <KanbanFilter
                  v-model="appliedFilters"
                  @apply-filter="handleApplyFilter"
                  @clear-filters="handleClearFilters"
                  @close="showFilterDialog = false"
                />
              </TeleportWithDirection>
            </div>
          </div>
        </div>

        <div v-if="isFetching" class="flex items-center justify-center flex-1">
          <Spinner />
        </div>

        <template v-else>
          <div
            v-if="
              currentFunnel &&
              currentFunnel.columns &&
              Array.isArray(currentFunnel.columns)
            "
            class="flex-1 overflow-x-auto"
          >
            <div class="flex gap-4 px-6 py-4 min-w-max">
              <div
                v-for="(column, columnIndex) in sortedColumns"
                :key="column.id || column"
                class="kanban-column-wrapper"
                @dragover.prevent="handleColumnDragOver($event, columnIndex)"
                @drop.prevent="handleColumnDrop($event, columnIndex)"
              >
                <KanbanColumn
                  :funnel-id="currentFunnel.id"
                  :column="column"
                  :column-index="columnIndex"
                  :search-query="searchQuery"
                  :applied-filters="appliedFilters"
                  @contact-moved="handleContactMoved"
                  @add-contact-from-sidebar="handleAddContactFromSidebar"
                  @column-drag-start="handleColumnDragStart"
                />
              </div>
            </div>
          </div>

          <div
            v-else
            class="flex flex-col items-center justify-center flex-1 gap-4 text-n-slate-11"
          >
            <Icon icon="i-lucide-layout-kanban" class="size-12" />
            <p>{{ t('KANBAN.NO_FUNNELS') }}</p>
            <Button
              :label="t('KANBAN.CREATE_FIRST_FUNNEL')"
              variant="solid"
              color="teal"
              @click="handleCreateFunnel"
            />
          </div>
        </template>
      </template>

      <CreateFunnelDialog
        v-model:show="showCreateDialog"
        :teams="teams"
        :is-loading="isCreating"
        @create="handleFunnelCreated"
      />
      <CreateColumnDialog
        v-model:show="showCreateColumnDialog"
        :is-loading="isUpdating"
        @create="handleColumnCreated"
      />
    </div>
  </div>
</template>

<style scoped>
.funnel-select {
  appearance: none !important;
  -webkit-appearance: none !important;
  -moz-appearance: none !important;
  background-image: none !important;
}

.funnel-select::-ms-expand {
  display: none !important;
}
</style>
