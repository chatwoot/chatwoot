<script setup>
import { h, ref, computed, onMounted } from 'vue';
import { provideSidebarContext, useSidebarResize } from './provider';
import { useAccount } from 'dashboard/composables/useAccount';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useSidebarKeyboardShortcuts } from './useSidebarKeyboardShortcuts';
import { vOnClickOutside } from '@vueuse/components';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useWindowSize, useEventListener } from '@vueuse/core';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

import Button from 'dashboard/components-next/button/Button.vue';
import SidebarGroup from './SidebarGroup.vue';
import SidebarProfileMenu from './SidebarProfileMenu.vue';
import SidebarChangelogCard from './SidebarChangelogCard.vue';
import SidebarChangelogButton from './SidebarChangelogButton.vue';
import SidebarAccountSwitcher from './SidebarAccountSwitcher.vue';
import SidebarNotificationBell from './SidebarNotificationBell.vue';
import Logo from 'next/icon/Logo.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import { useAgentMetricsStore } from 'dashboard/store/synapseos/useAgentMetrics';

const props = defineProps({
  isMobileSidebarOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'closeKeyShortcutModal',
  'openKeyShortcutModal',
  'showCreateAccountModal',
  'closeMobileSidebar',
]);

const { accountScopedRoute, isOnChatwootCloud } = useAccount();
const store = useStore();
const searchShortcut = useKbd([`$mod`, 'k']);
const { t } = useI18n();

// CUSTOMIZAÇÃO_SYNAPSEOS: itens técnicos do menu de Settings (Inboxes,
// Agent Bots, Custom Attributes, Integrations) ficam VISÍVEIS só pra
// administradores. Agents não veem — esses são setup técnico de operação.
const { isAdmin } = useAdmin();

// CUSTOMIZAÇÃO_SYNAPSEOS: atalho admin pro painel agentic (a "plataforma"),
// reaproveitando o login do Chatwoot — passa o access_token do usuário no
// fragmento (#cwsso=), que o painel troca por uma sessão (SSO). Só admin.
const currentUser = useMapGetter('getCurrentUser');
const SYNAPSEOS_PANEL_URL = 'https://painel.dexidigital.com.br';
const openPlatform = () => {
  const token = currentUser.value?.access_token;
  const url = token
    ? `${SYNAPSEOS_PANEL_URL}/#cwsso=${encodeURIComponent(token)}`
    : SYNAPSEOS_PANEL_URL;
  window.open(url, '_blank', 'noopener,noreferrer');
};

const isACustomBrandedInstance = useMapGetter(
  'globalConfig/isACustomBrandedInstance'
);
const isRTL = useMapGetter('accounts/isRTL');

const { width: windowWidth } = useWindowSize();
const isMobile = computed(() => windowWidth.value < 768);

const accountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const hasAdvancedAssignment = computed(() => {
  return isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.ADVANCED_ASSIGNMENT
  );
});

const toggleShortcutModalFn = show => {
  if (show) {
    emit('openKeyShortcutModal');
  } else {
    emit('closeKeyShortcutModal');
  }
};

useSidebarKeyboardShortcuts(toggleShortcutModalFn);

const expandedItem = ref(null);

const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

const {
  sidebarWidth,
  isCollapsed,
  setSidebarWidth,
  saveWidth,
  snapToCollapsed,
  snapToExpanded,
  COLLAPSED_THRESHOLD,
} = useSidebarResize();

// On mobile, sidebar is always expanded (flyout mode)
const isEffectivelyCollapsed = computed(
  () => !isMobile.value && isCollapsed.value
);

// Resize handle logic
const isResizing = ref(false);
const startX = ref(0);
const startWidth = ref(0);

provideSidebarContext({
  expandedItem,
  setExpandedItem,
  isCollapsed: isEffectivelyCollapsed,
  sidebarWidth,
  isResizing,
});

// Get clientX from mouse or touch event
const getClientX = event =>
  event.touches ? event.touches[0].clientX : event.clientX;

const onResizeStart = event => {
  isResizing.value = true;
  startX.value = getClientX(event);
  startWidth.value = sidebarWidth.value;
  Object.assign(document.body.style, {
    cursor: 'col-resize',
    userSelect: 'none',
  });
  // Prevent default to avoid scrolling on touch
  event.preventDefault();
};

const onResizeMove = event => {
  if (!isResizing.value) return;

  const delta = isRTL.value
    ? startX.value - getClientX(event)
    : getClientX(event) - startX.value;
  setSidebarWidth(startWidth.value + delta);
};

const onResizeEnd = () => {
  if (!isResizing.value) return;

  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });

  // Snap to collapsed state if below threshold
  if (sidebarWidth.value < COLLAPSED_THRESHOLD) {
    snapToCollapsed();
  } else {
    saveWidth();
  }
};

const onResizeHandleDoubleClick = () => {
  if (isCollapsed.value) snapToExpanded();
  else snapToCollapsed();
};

// Support both mouse and touch events
useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);

// CUSTOMIZAÇÃO_SYNAPSEOS: getters/dispatches de labels, teams, customViews
// e sortedInboxes foram removidos do sidebar — os submenus que os consumiam
// (Conversas > Folders/Teams/Channels/Labels, Contatos > Segments/Tagged)
// não existem mais. Notification count segue porque Caixa de Entrada usa.
// CUSTOMIZAÇÃO_SYNAPSEOS: lista de squad ativo (AgentBots cadastrados) define
// se o item "Esquadrão / Métricas" aparece no nav.
const agentMetricsStore = useAgentMetricsStore();
const hasSynapseosAgents = computed(() => agentMetricsStore.hasActiveAgents);

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('notifications/unReadCount');
  store.dispatch('attributes/get');
  if (accountId.value) {
    agentMetricsStore.fetchActiveAgents({ accountId: accountId.value });
  }
});

const closeMobileSidebar = () => {
  if (!props.isMobileSidebarOpen) return;
  emit('closeMobileSidebar');
};

const onComposeOpen = toggleFn => {
  toggleFn();
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, true);
};

const onComposeClose = () => {
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
};

// CUSTOMIZAÇÃO_SYNAPSEOS: reports de Label, Inbox e Team foram removidos do
// nav (escopo reduzido pra Agent + Conversation overview apenas). As rotas
// continuam registradas caso haja links diretos.
const newReportRoutes = () => [
  {
    name: 'Reports Agent',
    label: t('SIDEBAR.REPORTS_AGENT'),
    to: accountScopedRoute('agent_reports_index'),
    activeOn: ['agent_reports_show'],
  },
];

const reportRoutes = computed(() => newReportRoutes());

const menuItems = computed(() => {
  return [
    // CUSTOMIZAÇÃO_SYNAPSEOS: Caixa de Entrada passa a apontar direto pra
    // lista de todas as conversas (antes era a tela de notificações pessoais
    // inbox_view). Consolida 'Conversas > Todas as conversas' aqui; o item
    // 'Conversas' foi removido da sidebar. A rota inbox_view continua
    // existindo via rotas caso algum link externo aponte pra ela.
    {
      name: 'Inbox',
      label: t('SIDEBAR.INBOX'),
      icon: 'i-lucide-inbox',
      to: accountScopedRoute('home'),
      activeOn: [
        'home',
        'inbox_conversation',
        'conversation_through_mentions',
        'conversation_through_participating',
        'conversation_through_unattended',
        'conversations_through_folders',
        'conversations_through_team',
        'conversation_through_inbox',
        'conversations_through_label',
      ],
      // CUSTOMIZAÇÃO_SYNAPSEOS: badge de não-lidos removido (cliente não usa o
      // contador; o "1" fixo incomodava). Sem getterKeys.count = sem badge.
    },
    // CUSTOMIZAÇÃO_SYNAPSEOS: Synapse OS — itens top-level da sidebar
    {
      name: 'SynapseOS Dashboard',
      label: t('SIDEBAR.SYNAPSEOS_DASHBOARD'),
      icon: 'i-lucide-layout-dashboard',
      to: accountScopedRoute('synapseos_dashboard'),
      activeOn: ['synapseos_dashboard'],
    },
    {
      name: 'SynapseOS Live Agents',
      label: t('SIDEBAR.SYNAPSEOS_LIVE_AGENTS'),
      icon: 'i-lucide-users',
      to: accountScopedRoute('synapseos_live_agents'),
      activeOn: ['synapseos_live_agents'],
    },
    // CUSTOMIZAÇÃO_SYNAPSEOS: Esquadrão / Métricas só aparece quando há
    // pelo menos um AgentBot cadastrado (squadron_role ou nome legado).
    // Sem agentes a página é puro empty state — esconde do nav até cadastrar.
    ...(hasSynapseosAgents.value
      ? [
          {
            name: 'SynapseOS Agent Metrics',
            label: t('SIDEBAR.SYNAPSEOS_AGENT_METRICS'),
            icon: 'i-lucide-bot',
            to: accountScopedRoute('synapseos_agent_metrics'),
            activeOn: ['synapseos_agent_metrics'],
          },
        ]
      : []),
    // CUSTOMIZAÇÃO_SYNAPSEOS: Tempo Real removido do nav — redundante com
    // Live Agents (mesmas métricas, mesma semântica de monitoramento ao vivo).
    // A rota `synapseos_live_dashboard` continua existindo no routes.js caso
    // algum link direto ainda seja referenciado.
    {
      name: 'SynapseOS Pipeline',
      label: t('SIDEBAR.SYNAPSEOS_PIPELINE'),
      icon: 'i-lucide-git-branch',
      to: accountScopedRoute('synapseos_pipeline'),
      activeOn: ['synapseos_pipeline'],
    },
    // CUSTOMIZAÇÃO_SYNAPSEOS: item 'Conversas' removido. Todas as sub-rotas
    // (Mentions, Participating, Unattended, Folders, Teams, Channels, Labels)
    // continuam registradas e acessíveis por URL direta / filtros dentro da
    // nova Caixa de Entrada, mas não aparecem como atalhos no nav.
    // CUSTOMIZAÇÃO_SYNAPSEOS: Captain (IA do Chatwoot) removido do nav —
    // o Synapse OS usa seu próprio esquadrão de agentes (AgentBot +
    // squadron_role). Rotas /captain_assistants/* permanecem caso algum
    // link externo referencie.
    // CUSTOMIZAÇÃO_SYNAPSEOS: Contatos + Companies removidos do nav.
    // Contatos continuam acessíveis via painel lateral da conversa e
    // rotas /contacts /companies por URL direta.
    // CUSTOMIZAÇÃO_SYNAPSEOS: Relatórios — mantém apenas visão geral
    // (Conversation) e performance por agente. CSAT, SLA, Robôs, Time,
    // Caixa de Entrada e Etiquetas foram removidos do nav (escopo enxuto
    // pro uso atual; rotas /reports/* permanecem via URL direta).
    {
      name: 'Reports',
      label: t('SIDEBAR.REPORTS'),
      icon: 'i-lucide-chart-spline',
      children: [
        {
          name: 'Report Conversation',
          label: t('SIDEBAR.REPORTS_CONVERSATION'),
          to: accountScopedRoute('conversation_reports'),
        },
        ...reportRoutes.value,
      ],
    },
    // CUSTOMIZAÇÃO_SYNAPSEOS: Campaigns e Help Center (Portals) escondidos da sidebar.
    // As rotas permanecem registradas para não quebrar automações/integrações existentes.
    {
      name: 'Settings',
      label: t('SIDEBAR.SETTINGS'),
      icon: 'i-lucide-bolt',
      children: [
        {
          name: 'Settings Account Settings',
          label: t('SIDEBAR.ACCOUNT_SETTINGS'),
          icon: 'i-lucide-briefcase',
          to: accountScopedRoute('general_settings_index'),
        },
        // {
        //   name: 'Settings Captain',
        //   label: t('SIDEBAR.CAPTAIN_AI'),
        //   icon: 'i-woot-captain',
        //   to: accountScopedRoute('captain_settings_index'),
        // },
        {
          name: 'Settings Agents',
          label: t('SIDEBAR.AGENTS'),
          icon: 'i-lucide-square-user',
          to: accountScopedRoute('agent_list'),
        },
        {
          name: 'Settings Teams',
          label: t('SIDEBAR.TEAMS'),
          icon: 'i-lucide-users',
          activeOn: [
            'settings_teams_list',
            'settings_teams_new',
            'settings_teams_finish',
            'settings_teams_add_agents',
            'settings_teams_show',
            'settings_teams_edit',
            'settings_teams_edit_members',
            'settings_teams_edit_finish',
          ],
          to: accountScopedRoute('settings_teams_list'),
        },
        ...(hasAdvancedAssignment.value
          ? [
              {
                name: 'Settings Agent Assignment',
                label: t('SIDEBAR.AGENT_ASSIGNMENT'),
                icon: 'i-lucide-user-cog',
                activeOn: [
                  'assignment_policy_index',
                  'agent_assignment_policy_index',
                  'agent_assignment_policy_create',
                  'agent_assignment_policy_edit',
                  'agent_capacity_policy_index',
                  'agent_capacity_policy_create',
                  'agent_capacity_policy_edit',
                ],
                to: accountScopedRoute('assignment_policy_index'),
              },
            ]
          : []),
        // CUSTOMIZAÇÃO_SYNAPSEOS: 4 itens técnicos visíveis SÓ pra administrators.
        // Agents/operadores comuns têm UI enxuta (labels, automation, macros,
        // canned responses). Admins têm tudo + setup técnico.
        ...(isAdmin.value
          ? [
              {
                name: 'Settings Inboxes',
                label: t('SIDEBAR.INBOXES'),
                icon: 'i-lucide-inbox',
                activeOn: [
                  'settings_inbox_list',
                  'settings_inbox_show',
                  'settings_inbox_new',
                  'settings_inbox_finish',
                  'settings_inboxes_page_channel',
                  'settings_inboxes_add_agents',
                ],
                to: accountScopedRoute('settings_inbox_list'),
              },
            ]
          : []),
        {
          name: 'Settings Labels',
          label: t('SIDEBAR.LABELS'),
          icon: 'i-lucide-tags',
          to: accountScopedRoute('labels_list'),
        },
        ...(isAdmin.value
          ? [
              {
                name: 'Settings Custom Attributes',
                label: t('SIDEBAR.CUSTOM_ATTRIBUTES'),
                icon: 'i-lucide-code',
                to: accountScopedRoute('attributes_list'),
              },
            ]
          : []),
        {
          name: 'Settings Automation',
          label: t('SIDEBAR.AUTOMATION'),
          icon: 'i-lucide-repeat',
          to: accountScopedRoute('automation_list'),
        },
        ...(isAdmin.value
          ? [
              {
                name: 'Settings Agent Bots',
                label: t('SIDEBAR.AGENT_BOTS'),
                icon: 'i-lucide-bot',
                to: accountScopedRoute('agent_bots'),
              },
            ]
          : []),
        {
          name: 'Settings Macros',
          label: t('SIDEBAR.MACROS'),
          icon: 'i-lucide-toy-brick',
          to: accountScopedRoute('macros_wrapper'),
        },
        {
          name: 'Settings Canned Responses',
          label: t('SIDEBAR.CANNED_RESPONSES'),
          icon: 'i-lucide-message-square-quote',
          to: accountScopedRoute('canned_list'),
        },
        ...(isAdmin.value
          ? [
              {
                name: 'Settings Integrations',
                label: t('SIDEBAR.INTEGRATIONS'),
                icon: 'i-lucide-blocks',
                to: accountScopedRoute('settings_applications'),
              },
              {
                name: 'Settings WhatsApp Connection',
                label: t('SIDEBAR.WHATSAPP_CONNECTION'),
                icon: 'i-lucide-plug-zap',
                to: accountScopedRoute('whatsapp_connection_index'),
              },
              {
                name: 'Settings Monthly Reports',
                label: t('SIDEBAR.MONTHLY_REPORTS'),
                icon: 'i-lucide-file-bar-chart',
                to: accountScopedRoute('monthly_reports_index'),
              },
            ]
          : []),
        {
          name: 'Settings Audit Logs',
          label: t('SIDEBAR.AUDIT_LOGS'),
          icon: 'i-lucide-briefcase',
          to: accountScopedRoute('auditlogs_list'),
        },
        {
          name: 'Settings Custom Roles',
          label: t('SIDEBAR.CUSTOM_ROLES'),
          icon: 'i-lucide-shield-plus',
          to: accountScopedRoute('custom_roles_list'),
        },
        {
          name: 'Settings Sla',
          label: t('SIDEBAR.SLA'),
          icon: 'i-lucide-clock-alert',
          to: accountScopedRoute('sla_list'),
        },
        {
          name: 'Conversation Workflow',
          label: t('SIDEBAR.CONVERSATION_WORKFLOW'),
          icon: 'i-lucide-workflow',
          to: accountScopedRoute('conversation_workflow_index'),
        },
        {
          name: 'Settings Security',
          label: t('SIDEBAR.SECURITY'),
          icon: 'i-lucide-shield',
          to: accountScopedRoute('security_settings_index'),
        },
        {
          name: 'Settings Billing',
          label: t('SIDEBAR.BILLING'),
          icon: 'i-lucide-credit-card',
          to: accountScopedRoute('billing_settings_index'),
        },
      ],
    },
  ];
});
</script>

<template>
  <aside
    v-on-click-outside="[
      closeMobileSidebar,
      { ignore: ['#mobile-sidebar-launcher'] },
    ]"
    class="bg-s-sidebar flex flex-col text-sm pb-px fixed top-0 ltr:left-0 rtl:right-0 h-full z-40 w-[240px] md:w-auto md:relative md:flex-shrink-0 md:ltr:translate-x-0 md:rtl:translate-x-0 ltr:border-r rtl:border-l border-s-brand-800"
    :class="[
      {
        'shadow-lg md:shadow-none': isMobileSidebarOpen,
        'ltr:-translate-x-full rtl:translate-x-full': !isMobileSidebarOpen,
        'transition-transform duration-200 ease-out md:transition-[width]':
          !isResizing,
      },
    ]"
    :style="isMobile ? undefined : { width: `${sidebarWidth}px` }"
  >
    <section
      class="grid"
      :class="
        isEffectivelyCollapsed ? 'mt-3 mb-4 gap-3 px-1' : 'mt-3 mb-4 gap-3 px-3'
      "
    >
      <div
        class="flex gap-2 items-center min-w-0"
        :class="{
          'justify-center': isEffectivelyCollapsed,
        }"
      >
        <template v-if="isEffectivelyCollapsed">
          <SidebarAccountSwitcher
            is-collapsed
            @show-create-account-modal="emit('showCreateAccountModal')"
          />
        </template>
        <template v-else>
          <div class="grid flex-shrink-0 place-content-center size-6">
            <Logo class="size-4" />
          </div>
          <div class="flex-shrink-0 w-px h-3 bg-white/10" />
          <SidebarAccountSwitcher
            class="flex-grow -mx-1 min-w-0"
            @show-create-account-modal="emit('showCreateAccountModal')"
          />
        </template>
      </div>
      <div
        class="flex gap-2"
        :class="isEffectivelyCollapsed ? 'flex-col items-center' : ''"
      >
        <RouterLink
          v-if="!isEffectivelyCollapsed"
          :to="{ name: 'search' }"
          class="flex gap-2 items-center px-3 w-full h-9 rounded-lg border border-white/10 bg-white/[0.06] text-s-on-dark-muted hover:bg-white/10 hover:text-s-on-dark transition-colors"
        >
          <span class="flex-shrink-0 i-lucide-search size-4" />
          <span class="flex-grow text-start text-sm">
            {{ t('COMBOBOX.SEARCH_PLACEHOLDER') }}
          </span>
          <span
            class="tracking-wide pointer-events-none select-none text-[11px] font-mono"
          >
            {{ searchShortcut }}
          </span>
        </RouterLink>
        <RouterLink
          v-else
          :to="{ name: 'search' }"
          class="flex items-center justify-center size-9 rounded-lg border border-white/10 bg-white/[0.06] text-s-on-dark-muted hover:bg-white/10 hover:text-s-on-dark transition-colors"
          :title="t('COMBOBOX.SEARCH_PLACEHOLDER')"
        >
          <span class="i-lucide-search size-4" />
        </RouterLink>
        <SidebarNotificationBell />
        <ComposeConversation align-position="right" @close="onComposeClose">
          <template #trigger="{ toggle, isOpen }">
            <Button
              icon="i-lucide-pen-line"
              color="slate"
              size="sm"
              :class="[
                isEffectivelyCollapsed
                  ? '!size-9 !outline-white/10 !text-s-on-dark-muted !bg-white/[0.06] hover:!bg-white/10 hover:!text-s-on-dark'
                  : '!h-9 !outline-white/10 !text-s-on-dark-muted !bg-white/[0.06] hover:!bg-white/10 hover:!text-s-on-dark',
                { '!bg-white/10 !text-s-on-dark': isOpen },
              ]"
              @click="onComposeOpen(toggle)"
            />
          </template>
        </ComposeConversation>
      </div>
    </section>
    <nav
      class="grid overflow-y-scroll flex-grow gap-1 pb-5 no-scrollbar min-w-0"
      :class="isEffectivelyCollapsed ? 'px-2' : 'px-3'"
    >
      <ul
        class="flex flex-col gap-0.5 m-0 list-none min-w-0"
        :class="{ 'items-center': isEffectivelyCollapsed }"
      >
        <SidebarGroup
          v-for="item in menuItems"
          :key="item.name"
          v-bind="item"
        />
      </ul>
    </nav>
    <section
      class="flex relative flex-col flex-shrink-0 gap-1 justify-between items-center"
    >
      <div
        class="pointer-events-none absolute inset-x-0 -top-[1.938rem] h-8 bg-gradient-to-t from-s-sidebar to-transparent"
      />
      <SidebarChangelogCard
        v-if="
          isOnChatwootCloud &&
          !isACustomBrandedInstance &&
          !isEffectivelyCollapsed
        "
      />
      <SidebarChangelogButton
        v-if="
          isOnChatwootCloud &&
          !isACustomBrandedInstance &&
          isEffectivelyCollapsed
        "
      />
      <button
        v-if="isAdmin"
        type="button"
        :title="t('SIDEBAR.SYNAPSEOS_PLATFORM')"
        class="flex gap-2 items-center px-3 h-9 rounded-lg border border-white/10 bg-white/[0.06] text-s-on-dark-muted hover:bg-white/10 hover:text-s-on-dark transition-colors"
        :class="isEffectivelyCollapsed ? 'justify-center w-9 px-0' : 'w-[calc(100%-1rem)] mx-2'"
        @click="openPlatform"
      >
        <span class="flex-shrink-0 i-lucide-layout-grid size-4" />
        <span v-if="!isEffectivelyCollapsed" class="flex-grow text-start text-sm">
          {{ t('SIDEBAR.SYNAPSEOS_PLATFORM') }}
        </span>
        <span v-if="!isEffectivelyCollapsed" class="flex-shrink-0 i-lucide-external-link size-3.5 opacity-60" />
      </button>
      <div
        class="px-2 py-2 flex-shrink-0 flex w-full z-50 gap-2 items-center border-t border-white/10"
        :class="isEffectivelyCollapsed ? 'justify-center' : 'justify-between'"
      >
        <SidebarProfileMenu
          :is-collapsed="isEffectivelyCollapsed"
          @open-key-shortcut-modal="emit('openKeyShortcutModal')"
        />
      </div>
    </section>
    <!-- Resize Handle (desktop only) -->
    <div
      class="hidden md:block absolute top-0 h-full w-1 cursor-col-resize z-40 ltr:right-0 rtl:left-0 group"
      @mousedown="onResizeStart"
      @touchstart="onResizeStart"
      @dblclick="onResizeHandleDoubleClick"
    >
      <div
        class="absolute top-0 h-full w-px ltr:right-0 rtl:left-0 bg-transparent group-hover:bg-s-accent-500 transition-colors"
        :class="{ 'bg-s-accent-500': isResizing }"
      />
    </div>
  </aside>
</template>
