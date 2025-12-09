<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { frontendURL } from 'dashboard/helper/URLHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
  funnelId: {
    type: Number,
    required: true,
  },
  columnId: {
    type: String,
    required: true,
  },
  index: {
    type: Number,
    default: 0,
  },
});
const emit = defineEmits(['remove']);
const { t } = useI18n();
const store = useStore();

const router = useRouter();
const route = useRoute();
const isDragging = ref(false);

const contactName = computed(() => props.contact?.name || '');
const contactThumbnail = computed(() => props.contact?.thumbnail || '');
const contactStatus = computed(() => props.contact?.availability_status);

// Getters para labels, teams e conversas
const getContactLabels = useMapGetter('contactLabels/getContactLabels');
const allLabels = useMapGetter('labels/getLabels');
const teams = useMapGetter('teams/getTeams');
const getContactConversations = useMapGetter(
  'contactConversations/getContactConversation'
);

// Labels do contato
const contactLabelTitles = computed(() => {
  // Primeiro tentar buscar do objeto contact diretamente
  if (props.contact.labels && Array.isArray(props.contact.labels)) {
    return props.contact.labels.map(l => {
      if (typeof l === 'string') return l;
      if (typeof l === 'object' && l !== null) {
        return l.title || l.name || l;
      }
      return String(l);
    });
  }

  // Se não encontrou, buscar do store
  const labels = getContactLabels.value(props.contact?.id);
  return labels && Array.isArray(labels) ? labels : [];
});

// Labels completos com informações de cor
const contactLabels = computed(() => {
  const titles = contactLabelTitles.value;
  if (!titles || titles.length === 0) return [];

  return allLabels.value
    .filter(label => titles.includes(label.title))
    .slice(0, 3); // Limitar a 3 labels para não sobrecarregar o card
});

// Team do contato - buscar através das conversas
const contactTeam = computed(() => {
  if (!teams.value || !props.contact?.id) return null;

  // Primeiro tentar buscar do objeto contact diretamente (caso venha da API)
  if (props.contact.team_id) {
    return teams.value.find(team => team.id === props.contact.team_id);
  }

  // Se não encontrou, buscar através das conversas do contato
  const conversations = getContactConversations.value(props.contact.id);
  if (
    conversations &&
    Array.isArray(conversations) &&
    conversations.length > 0
  ) {
    // Buscar a primeira conversa que tenha team
    // O team pode estar em meta.team (objeto completo) ou team_id (apenas ID)
    const conversationWithTeam = conversations.find(conv => {
      return conv.meta?.team || conv.team_id || conv.team?.id;
    });

    if (conversationWithTeam) {
      // Tentar obter o team de diferentes formas
      let teamId = null;

      // Se tem meta.team com id
      if (conversationWithTeam.meta?.team?.id) {
        teamId = conversationWithTeam.meta.team.id;
      }
      // Se tem team_id diretamente
      else if (conversationWithTeam.team_id) {
        teamId = conversationWithTeam.team_id;
      }
      // Se tem team.id diretamente
      else if (conversationWithTeam.team?.id) {
        teamId = conversationWithTeam.team.id;
      }

      if (teamId) {
        return teams.value.find(team => team.id === teamId);
      }
    }
  }

  return null;
});

// Carregar labels e conversas quando o componente for montado
onMounted(() => {
  if (props.contact?.id) {
    store.dispatch('contactLabels/get', props.contact.id).catch(() => {
      // Ignorar erros silenciosamente
    });
    // Carregar conversas para obter o time
    store.dispatch('contactConversations/get', props.contact.id).catch(() => {
      // Ignorar erros silenciosamente
    });
  }
});

const handleCardClick = () => {
  // Não navegar se estiver arrastando
  if (isDragging.value) return;
  const path = frontendURL(
    `accounts/${route.params.accountId}/contacts/${props.contact.id}`
  );
  router.push({ path });
};

const handleDragStart = e => {
  isDragging.value = true;
  e.dataTransfer.effectAllowed = 'move';

  const dragData = {
    contactId: props.contact.id,
    sourceColumnId: props.columnId,
    sourceFunnelId: props.funnelId,
    sourceIndex: props.index,
  };

  e.dataTransfer.setData('application/json', JSON.stringify(dragData));
  e.dataTransfer.setData('text/plain', props.contact.id.toString());
};

const handleDragEnd = () => {
  isDragging.value = false;
};

const showCardMenu = ref(false);

const handleCardOptions = e => {
  e.stopPropagation();
  showCardMenu.value = !showCardMenu.value;
};

const handleRemoveFromFunnel = async () => {
  showCardMenu.value = false;
  try {
    await emit('remove', props.contact.id);
  } catch {
    // Error is handled by the parent component
  }
};

const handleViewContact = () => {
  showCardMenu.value = false;
  handleCardClick();
};

const handleClickOutside = e => {
  if (!e.target.closest('.card-menu-container')) {
    showCardMenu.value = false;
  }
};

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});

const formatDate = date => {
  try {
    if (!date) return '';
    const d = new Date(date * 1000);
    if (Number.isNaN(d.getTime())) return '';
    return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;
  } catch {
    return '';
  }
};

const lastActivity = computed(() => {
  try {
    return formatDate(props.contact?.last_activity_at);
  } catch {
    return '';
  }
});
</script>

<template>
  <div
    class="kanban-card flex flex-col gap-2 p-3 bg-n-background border border-n-weak rounded-lg hover:border-n-strong hover:shadow-sm transition-all cursor-grab active:cursor-grabbing"
    :class="{ 'opacity-50 scale-95': isDragging }"
    draggable="true"
    @dragstart="handleDragStart"
    @dragend="handleDragEnd"
    @click="handleCardClick"
  >
    <div class="flex items-start justify-between gap-2">
      <div class="flex items-center gap-2 flex-1 min-w-0">
        <div class="flex items-center justify-center p-1 text-n-slate-9">
          <Icon icon="i-lucide-grip-vertical" class="size-4" />
        </div>
        <Avatar
          :name="contactName"
          :src="contactThumbnail"
          :size="32"
          :status="contactStatus"
          rounded-full
        />
        <div class="flex flex-col min-w-0 flex-1">
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ contactName }}
          </span>
        </div>
      </div>
      <span class="text-xs text-n-slate-9 flex-shrink-0">
        {{ lastActivity }}
      </span>
    </div>
    <!-- Team e Labels -->
    <div
      v-if="contactTeam || contactLabels.length > 0"
      class="flex flex-col gap-1.5"
    >
      <!-- Team - Primeira fileira -->
      <div v-if="contactTeam" class="flex items-center gap-1">
        <div
          class="flex items-center gap-1 px-2 py-0.5 text-xs font-medium bg-n-slate-3 text-n-slate-11 rounded-md"
        >
          <Icon icon="i-lucide-users" class="size-3" />
          <span class="truncate">{{ contactTeam.name }}</span>
        </div>
      </div>
      <!-- Labels - Segunda fileira -->
      <div
        v-if="contactLabels.length > 0"
        class="flex flex-wrap items-center gap-1.5"
      >
        <div
          v-for="label in contactLabels"
          :key="label.id"
          class="flex items-center px-1.5 py-0.5 overflow-hidden rounded-md bg-n-alpha-2"
        >
          <div
            class="w-1.5 h-1.5 rounded-sm flex-shrink-0"
            :style="{ backgroundColor: label.color }"
          />
          <span
            class="text-xs text-n-slate-12 ltr:ml-1 rtl:mr-1 truncate max-w-[80px]"
          >
            {{ label.title }}
          </span>
        </div>
        <div
          v-if="contactLabelTitles.length > 3"
          class="flex items-center px-1.5 py-0.5 text-xs text-n-slate-10"
        >
          +{{ contactLabelTitles.length - 3 }}
        </div>
      </div>
    </div>
    <div class="flex items-center justify-end">
      <div class="relative card-menu-container">
        <button
          class="p-0.5 text-n-slate-9 rounded hover:bg-n-slate-3 hover:text-n-slate-12 transition-colors cursor-pointer"
          :title="t('KANBAN.CARD_OPTIONS')"
          @click.stop="handleCardOptions"
          @mousedown.stop
        >
          <Icon icon="i-lucide-more-horizontal" class="size-4" />
        </button>
        <div
          v-if="showCardMenu"
          class="absolute right-0 top-full mt-1 w-48 bg-n-background rounded-lg shadow-lg border border-n-strong z-50 overflow-hidden"
          @click.stop
        >
          <button
            class="w-full px-4 py-2 text-left text-sm text-white bg-n-slate-9 hover:bg-n-slate-10 transition-colors"
            @click="handleViewContact"
          >
            <Icon icon="i-lucide-eye" class="size-4 inline mr-2" />
            {{ t('KANBAN.VIEW_CONTACT') }}
          </button>
          <button
            class="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 transition-colors"
            @click="handleRemoveFromFunnel"
          >
            <Icon icon="i-lucide-x" class="size-4 inline mr-2" />
            {{ t('KANBAN.REMOVE_FROM_FUNNEL') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
