<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Policy from 'dashboard/components/policy.vue';
import { fingerprintLabel } from './mcpTools';

const props = defineProps({
  server: { type: Object, required: true },
  isUpdating: { type: Boolean, default: false },
});

const emit = defineEmits(['action', 'toggle']);

const { t } = useI18n();
const [showActionsDropdown, toggleDropdown] = useToggle();

const STATUS_CLASSES = {
  active: 'bg-n-teal-3 text-n-teal-11',
  needs_sign_in: 'bg-n-amber-3 text-n-amber-11',
  error: 'bg-n-ruby-3 text-n-ruby-11',
};

const enabledState = computed({
  get: () => props.server.enabled,
  set: enabled => emit('toggle', { id: props.server.id, enabled }),
});

const statusLabel = computed(() =>
  t(`CAPTAIN.MCP_SERVERS.STATUS.${props.server.status.toUpperCase()}`)
);

const authLabel = computed(() =>
  t(`CAPTAIN.MCP_SERVERS.AUTH_TYPES.${props.server.auth_type.toUpperCase()}`)
);

const menuItems = computed(() => [
  {
    label: t('CAPTAIN.MCP_SERVERS.ACTIONS.MANAGE_TOOLS'),
    value: 'manage',
    action: 'manage',
    icon: 'i-lucide-wrench',
  },
  ...(props.server.auth_type === 'oauth'
    ? [
        {
          label: t('CAPTAIN.MCP_SERVERS.ACTIONS.SIGN_IN'),
          value: 'sign_in',
          action: 'sign_in',
          icon: 'i-lucide-log-in',
        },
      ]
    : []),
  {
    label: t('CAPTAIN.MCP_SERVERS.ACTIONS.DELETE'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const handleAction = ({ action }) => {
  toggleDropdown(false);
  emit('action', { action, server: props.server });
};
</script>

<template>
  <CardLayout class="relative">
    <div class="flex justify-between w-full gap-2">
      <div class="flex flex-col min-w-0 gap-0.5">
        <span class="text-base font-medium text-n-slate-12 truncate">
          {{ server.name }}
        </span>
        <span class="text-xs font-mono text-n-slate-11 truncate">
          {{ server.url }}
        </span>
      </div>
      <div class="flex items-center gap-2 shrink-0">
        <span
          v-if="server.tools_changed_at"
          class="text-xs font-medium px-2 py-0.5 rounded-full bg-n-amber-3 text-n-amber-11"
        >
          {{ t('CAPTAIN.MCP_SERVERS.NEEDS_REVIEW') }}
        </span>
        <span
          v-tooltip.top="server.last_error || ''"
          class="text-xs font-medium px-2 py-0.5 rounded-full"
          :class="STATUS_CLASSES[server.status]"
        >
          {{ statusLabel }}
        </span>
        <Policy
          as="span"
          :permissions="['administrator']"
          class="inline-flex items-center"
        >
          <Switch
            v-model="enabledState"
            :disabled="isUpdating"
            :aria-label="
              t('CAPTAIN.MCP_SERVERS.STATUS.TOGGLE', { name: server.name })
            "
          />
        </Policy>
        <Policy
          v-on-clickaway="() => toggleDropdown(false)"
          :permissions="['administrator']"
          class="relative flex items-center group"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            color="slate"
            size="xs"
            class="rounded-md group-hover:bg-n-alpha-2"
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

    <div class="flex items-center gap-3 text-sm text-n-slate-11">
      <span class="inline-flex items-center gap-1">
        <i class="i-lucide-lock text-base" />
        {{ authLabel }}
      </span>
      <span class="inline-flex items-center gap-1">
        <i class="i-lucide-wrench text-base" />
        {{ t('CAPTAIN.MCP_SERVERS.TOOL_COUNT', { n: server.tools.length }) }}
      </span>
    </div>

    <ul
      v-if="server.tools.length"
      class="flex flex-col gap-1.5 m-0 list-none w-full"
    >
      <li
        v-for="tool in server.tools"
        :key="tool.name"
        class="flex items-center justify-between gap-3 text-sm"
      >
        <code class="text-n-slate-12 truncate">{{ tool.name }}</code>
        <span class="flex items-center gap-3 shrink-0 text-xs text-n-slate-11">
          <span>
            {{
              tool.requires_email_verification
                ? t('CAPTAIN.MCP_SERVERS.WHO.VERIFIED')
                : t('CAPTAIN.MCP_SERVERS.WHO.ANYONE')
            }}
          </span>
          <span class="font-mono">{{
            fingerprintLabel(tool.approved_digest)
          }}</span>
        </span>
      </li>
    </ul>
    <p v-else class="text-sm text-n-slate-11 mb-0">
      {{ t('CAPTAIN.MCP_SERVERS.NO_TOOLS') }}
    </p>
  </CardLayout>
</template>
