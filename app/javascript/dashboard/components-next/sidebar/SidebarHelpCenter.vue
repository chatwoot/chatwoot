<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { getAllContextHelp } from 'dashboard/helper/contextHelpContent';

const route = useRoute();
const { t } = useI18n();

const isOpen = ref(false);
const searchTerm = ref('');

const currentHelpKey = computed(() => {
  const routeName = route.name;

  if (!routeName) return null;

  if (routeName.includes('contact')) return 'contacts';
  if (routeName.includes('conversation') || routeName.includes('inbox')) {
    return 'conversations';
  }
  if (routeName.includes('report')) return 'reports';
  if (routeName.includes('campaign')) return 'campaigns';
  if (routeName.includes('company')) return 'companies';
  if (routeName.includes('portal') || routeName.includes('helpcenter')) {
    return 'help_center';
  }
  if (routeName.includes('captain')) return 'captain';
  if (routeName.includes('setting') || routeName.includes('automation')) {
    return 'settings';
  }

  return 'dashboard';
});

const allHelpItems = computed(() => getAllContextHelp());

const filteredHelpItems = computed(() => {
  const query = searchTerm.value.trim().toLowerCase();

  if (!query) return allHelpItems.value;

  return allHelpItems.value.filter(item => {
    return (
      item.title.toLowerCase().includes(query) ||
      item.body.toLowerCase().includes(query)
    );
  });
});
</script>

<template>
  <div class="w-full px-2 pb-1">
    <button
      type="button"
      class="w-full h-8 rounded-lg border border-n-weak text-n-slate-11 bg-n-alpha-black2 hover:border-n-brand hover:text-n-brand transition-colors flex items-center gap-2 px-2"
      @click="isOpen = true"
    >
      <span class="i-lucide-life-buoy size-4" />
      <span class="truncate text-xs font-medium">{{
        t('SIDEBAR.HELP_HUB.OPEN')
      }}</span>
    </button>

    <div
      v-if="isOpen"
      class="fixed inset-0 z-50 bg-n-alpha-black5 flex justify-end"
      @click.self="isOpen = false"
    >
      <section
        class="w-full max-w-md h-full bg-n-solid-1 border-l border-n-weak p-4 overflow-y-auto"
      >
        <div class="flex items-center justify-between gap-2 mb-3">
          <h2 class="text-base font-semibold text-n-slate-12">
            {{ t('SIDEBAR.HELP_HUB.TITLE') }}
          </h2>
          <button
            type="button"
            class="size-8 rounded-lg border border-n-weak text-n-slate-11 hover:text-n-brand hover:border-n-brand transition-colors"
            :title="t('SIDEBAR.HELP_HUB.CLOSE')"
            @click="isOpen = false"
          >
            <span class="i-lucide-x size-4 mx-auto" />
          </button>
        </div>

        <p class="text-xs text-n-slate-10 mb-3">
          {{ t('SIDEBAR.HELP_HUB.DESCRIPTION') }}
        </p>

        <input
          v-model="searchTerm"
          type="text"
          class="w-full h-9 rounded-lg border border-n-weak bg-n-alpha-black2 px-3 text-sm text-n-slate-12 placeholder:text-n-slate-10 mb-3"
          :placeholder="t('SIDEBAR.HELP_HUB.SEARCH_PLACEHOLDER')"
        />

        <div
          v-if="currentHelpKey"
          class="rounded-lg border border-n-brand/30 bg-n-brand/5 p-3 mb-3"
        >
          <p class="text-xs text-n-brand font-medium mb-1">
            {{ t('SIDEBAR.HELP_HUB.CURRENT_CONTEXT') }}
          </p>
          <p class="text-sm text-n-slate-12 font-medium mb-1">
            {{ allHelpItems.find(item => item.key === currentHelpKey)?.title }}
          </p>
          <p class="text-xs text-n-slate-11 whitespace-pre-line">
            {{ allHelpItems.find(item => item.key === currentHelpKey)?.body }}
          </p>
        </div>

        <div class="grid gap-2">
          <article
            v-for="item in filteredHelpItems"
            :key="item.key"
            class="rounded-lg border border-n-weak p-3 bg-n-alpha-black2"
          >
            <h3 class="text-sm font-medium text-n-slate-12 mb-1">
              {{ item.title }}
            </h3>
            <p class="text-xs text-n-slate-11 whitespace-pre-line">
              {{ item.body }}
            </p>
          </article>
        </div>
      </section>
    </div>
  </div>
</template>
