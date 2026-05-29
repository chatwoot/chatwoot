<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ConfirmButton from 'dashboard/components-next/button/ConfirmButton.vue';

defineProps({
  tokens: {
    // [{ scope: 'full' | 'read_only', value: String }]
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['copy', 'reset']);

const { t } = useI18n();

const tk = key => t(`PROFILE_SETTINGS.FORM.ACCESS_TOKEN.${key}`);

const SCOPE_META = {
  full: {
    label: () => tk('SCOPES.FULL_LABEL'),
    icon: 'i-lucide-shield-check',
    badgeClass: 'bg-n-teal-3 text-n-teal-11',
  },
  read_only: {
    label: () => tk('SCOPES.READ_ONLY_LABEL'),
    icon: 'i-lucide-eye',
    badgeClass: 'bg-n-alpha-2 text-n-slate-11 outline outline-1 outline-n-weak',
  },
};

// track reveal state per scope
const revealedScopes = ref([]);
const isRevealed = scope => revealedScopes.value.includes(scope);
const toggleReveal = scope => {
  revealedScopes.value = isRevealed(scope)
    ? revealedScopes.value.filter(s => s !== scope)
    : [...revealedScopes.value, scope];
};

const maskToken = value =>
  `${value.slice(0, 4)}${'•'.repeat(20)}${value.slice(-4)}`;
</script>

<template>
  <div class="overflow-hidden rounded-xl outline outline-1 outline-n-weak">
    <div
      v-if="!tokens.length"
      class="flex flex-col items-center justify-center gap-1 px-4 py-12 text-center"
    >
      <span
        class="grid mb-2 rounded-lg size-10 place-items-center bg-n-alpha-1 text-n-slate-11"
      >
        <span class="i-lucide-key-round size-5" />
      </span>
      <p class="text-sm font-medium text-n-slate-12">
        {{ tk('EMPTY.TITLE') }}
      </p>
      <p class="max-w-xs text-sm text-n-slate-11">
        {{ tk('EMPTY.DESCRIPTION') }}
      </p>
    </div>
    <table v-else class="min-w-full text-sm border-collapse">
      <thead>
        <tr class="bg-n-alpha-1 text-n-slate-11">
          <th
            class="px-4 py-2.5 font-medium text-start text-xs uppercase tracking-wide"
          >
            {{ tk('TABLE.TOKEN') }}
          </th>
          <th
            class="px-4 py-2.5 font-medium text-start text-xs uppercase tracking-wide"
          >
            {{ tk('TABLE.PERMISSION') }}
          </th>
          <th class="px-4 py-2.5 w-40" />
        </tr>
      </thead>
      <tbody class="divide-y divide-n-weak">
        <tr
          v-for="token in tokens"
          :key="token.scope"
          class="border-t border-n-weak"
        >
          <td class="px-4 py-3">
            <div class="flex items-center gap-1.5 min-w-0">
              <code
                class="inline-block min-w-56 px-2 py-1 font-mono text-xs rounded-md bg-n-alpha-1 text-n-slate-12 outline outline-1 outline-n-weak truncate align-middle"
              >
                {{
                  isRevealed(token.scope) ? token.value : maskToken(token.value)
                }}
              </code>
              <NextButton
                :icon="
                  isRevealed(token.scope) ? 'i-lucide-eye-off' : 'i-lucide-eye'
                "
                size="xs"
                slate
                ghost
                class="shrink-0"
                @click="toggleReveal(token.scope)"
              />
              <NextButton
                icon="i-lucide-copy"
                size="xs"
                slate
                ghost
                class="shrink-0"
                @click="emit('copy', token.value)"
              />
            </div>
          </td>
          <td class="px-4 py-3">
            <span
              class="inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full"
              :class="SCOPE_META[token.scope].badgeClass"
            >
              <span :class="SCOPE_META[token.scope].icon" class="size-3" />
              {{ SCOPE_META[token.scope].label() }}
            </span>
          </td>
          <td class="px-4 py-3 text-end">
            <ConfirmButton
              :label="tk('RESET')"
              :confirm-label="tk('CONFIRM_RESET')"
              color="slate"
              confirm-color="ruby"
              variant="outline"
              size="xs"
              icon="i-lucide-key-round"
              @click="emit('reset', token.scope)"
            />
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
