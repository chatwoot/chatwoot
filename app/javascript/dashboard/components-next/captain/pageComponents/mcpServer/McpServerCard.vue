<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  server: {
    type: Object,
    required: true,
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();
const [showActionsDropdown, toggleDropdown] = useToggle();

const statusConfig = computed(() => {
  const configs = {
    connected: {
      label: t('CAPTAIN_SETTINGS.MCP_SERVERS.STATUS.CONNECTED'),
      color: 'bg-n-teal-9',
      textColor: 'text-n-teal-11',
      bgColor: 'bg-n-teal-3',
    },
    connecting: {
      label: t('CAPTAIN_SETTINGS.MCP_SERVERS.STATUS.CONNECTING'),
      color: 'bg-n-amber-9',
      textColor: 'text-n-amber-11',
      bgColor: 'bg-n-amber-3',
    },
    disconnected: {
      label: t('CAPTAIN_SETTINGS.MCP_SERVERS.STATUS.DISCONNECTED'),
      color: 'bg-n-slate-8',
      textColor: 'text-n-slate-11',
      bgColor: 'bg-n-slate-3',
    },
    error: {
      label: t('CAPTAIN_SETTINGS.MCP_SERVERS.STATUS.ERROR'),
      color: 'bg-n-ruby-9',
      textColor: 'text-n-ruby-11',
      bgColor: 'bg-n-ruby-3',
    },
  };
  return configs[props.server.status] || configs.disconnected;
});

const menuItems = computed(() => {
  const items = [];

  if (props.server.status === 'connected') {
    items.push({
      label: t('CAPTAIN_SETTINGS.MCP_SERVERS.OPTIONS.REFRESH'),
      value: 'refresh',
      action: 'refresh',
      icon: 'i-lucide-refresh-cw',
    });
    items.push({
      label: t('CAPTAIN_SETTINGS.MCP_SERVERS.OPTIONS.DISCONNECT'),
      value: 'disconnect',
      action: 'disconnect',
      icon: 'i-lucide-unplug',
    });
  } else {
    items.push({
      label: t('CAPTAIN_SETTINGS.MCP_SERVERS.OPTIONS.CONNECT'),
      value: 'connect',
      action: 'connect',
      icon: 'i-lucide-plug',
    });
  }

  items.push({
    label: t('CAPTAIN_SETTINGS.MCP_SERVERS.OPTIONS.EDIT'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil-line',
  });

  items.push({
    label: t('CAPTAIN_SETTINGS.MCP_SERVERS.OPTIONS.DELETE'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  });

  return items;
});

const toolsCount = computed(() => props.server.cached_tools?.length || 0);

const timestamp = computed(() => {
  if (props.server.last_connected_at) {
    return t('CAPTAIN_SETTINGS.MCP_SERVERS.LAST_CONNECTED', {
      time: dynamicTime(props.server.last_connected_at),
    });
  }
  return dynamicTime(props.server.updated_at || props.server.created_at);
});

const authTypeLabel = computed(() => {
  if (props.server.auth_type === 'none') return null;
  return t(
    `CAPTAIN_SETTINGS.MCP_SERVERS.AUTH_TYPES.${props.server.auth_type.toUpperCase()}`
  );
});

const handleAction = ({ action }) => {
  toggleDropdown(false);
  emit('action', { action, id: props.server.id });
};

const handleQuickConnect = () => {
  emit('action', {
    action: props.server.status === 'connected' ? 'disconnect' : 'connect',
    id: props.server.id,
  });
};
</script>

<template>
  <CardLayout class="relative group">
    <div class="flex items-start justify-between w-full gap-4">
      <div class="flex items-start gap-3 flex-1 min-w-0">
        <!-- Status indicator -->
        <div
          class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors"
          :class="statusConfig.bgColor"
        >
          <i
            class="text-xl"
            :class="[
              server.status === 'connected'
                ? 'i-lucide-plug-2'
                : 'i-lucide-plug',
              statusConfig.textColor,
            ]"
          />
        </div>

        <div class="flex flex-col gap-1 min-w-0 flex-1">
          <div class="flex items-center gap-2">
            <span class="text-base text-n-slate-12 font-medium truncate">
              {{ server.name }}
            </span>
            <span
              class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
              :class="[statusConfig.bgColor, statusConfig.textColor]"
            >
              <span
                class="w-1.5 h-1.5 rounded-full"
                :class="statusConfig.color"
              />
              {{ statusConfig.label }}
            </span>
          </div>

          <p
            v-if="server.description"
            class="text-sm text-n-slate-11 line-clamp-1"
          >
            {{ server.description }}
          </p>

          <div class="flex items-center gap-3 mt-1">
            <span
              class="text-xs text-n-slate-10 truncate max-w-xs"
              :title="server.url"
            >
              {{ server.url }}
            </span>

            <span
              v-if="authTypeLabel"
              class="text-xs text-n-slate-10 inline-flex items-center gap-1"
            >
              <i class="i-lucide-lock text-xs" />
              {{ authTypeLabel }}
            </span>

            <span
              v-if="toolsCount > 0"
              class="text-xs text-n-slate-10 inline-flex items-center gap-1"
            >
              <i class="i-lucide-wrench text-xs" />
              {{
                t('CAPTAIN_SETTINGS.MCP_SERVERS.TOOLS_COUNT', {
                  count: toolsCount,
                })
              }}
            </span>
          </div>
        </div>
      </div>

      <div class="flex items-center gap-2 shrink-0">
        <span class="text-xs text-n-slate-10 hidden sm:block">
          {{ timestamp }}
        </span>

        <Policy :permissions="['administrator']">
          <Button
            v-if="server.status !== 'connecting'"
            :icon="
              server.status === 'connected'
                ? 'i-lucide-unplug'
                : 'i-lucide-plug'
            "
            :color="server.status === 'connected' ? 'slate' : 'blue'"
            size="xs"
            :is-loading="isUpdating"
            class="opacity-0 group-hover:opacity-100 transition-opacity"
            @click="handleQuickConnect"
          />
        </Policy>

        <Policy
          v-on-clickaway="() => toggleDropdown(false)"
          :permissions="['administrator']"
          class="relative flex items-center"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            color="slate"
            size="xs"
            class="rounded-md hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="menuItems"
            class="mt-1 ltr:right-0 rtl:right-0 top-full"
            @action="handleAction($event)"
          />
        </Policy>
      </div>
    </div>

    <!-- Error message -->
    <div
      v-if="server.status === 'error' && server.last_error"
      class="mt-3 p-3 rounded-lg bg-n-ruby-2 border border-n-ruby-6"
    >
      <div class="flex items-start gap-2">
        <i
          class="i-lucide-alert-circle text-n-ruby-11 text-base mt-0.5 shrink-0"
        />
        <p
          class="text-sm text-n-ruby-11 line-clamp-2"
          :title="server.last_error"
        >
          {{ server.last_error }}
        </p>
      </div>
    </div>

    <!-- Tools preview -->
    <div
      v-if="server.status === 'connected' && server.cached_tools?.length"
      class="mt-3 pt-3 border-t border-n-slate-6"
    >
      <div class="flex items-center gap-2 mb-2">
        <i class="i-lucide-wrench text-sm text-n-slate-11" />
        <span
          class="text-xs font-medium text-n-slate-11 uppercase tracking-wide"
        >
          {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.AVAILABLE_TOOLS') }}
        </span>
      </div>
      <div class="flex flex-wrap gap-1.5">
        <span
          v-for="tool in server.cached_tools.slice(0, 8)"
          :key="tool.name"
          class="inline-flex items-center px-2 py-1 rounded-md bg-n-slate-3 text-xs text-n-slate-11"
          :title="tool.description"
        >
          {{ tool.name }}
        </span>
        <span
          v-if="server.cached_tools.length > 8"
          class="inline-flex items-center px-2 py-1 rounded-md bg-n-slate-3 text-xs text-n-slate-10"
        >
          {{
            t('CAPTAIN_SETTINGS.MCP_SERVERS.TOOLS_MORE', {
              count: server.cached_tools.length - 8,
            })
          }}
        </span>
      </div>
    </div>
  </CardLayout>
</template>
