<script setup>
import { useI18n } from 'vue-i18n';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const { t } = useI18n();

const CHATWOOT_URL = 'https://www.chatwoot.com';
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <BaseSettingsHeader :title="t('ABOUT_PAGE.TITLE')" :description="t('ABOUT_PAGE.SUBTITLE')" />

    <!-- Nexus description -->
    <section class="flex flex-col gap-3 p-6 rounded-xl bg-n-surface-2 border border-n-weak">
      <h2 class="text-heading-2 text-n-slate-12">
        {{ t('ABOUT_PAGE.TITLE') }}
      </h2>
      <p class="text-body-main text-n-slate-11 max-w-2xl">
        {{ t('ABOUT_PAGE.DESCRIPTION') }}
      </p>
    </section>

    <!-- Credits -->
    <section class="flex flex-col gap-3 p-6 rounded-xl bg-n-surface-2 border border-n-weak">
      <h2 class="text-heading-2 text-n-slate-12">
        {{ t('ABOUT_PAGE.CREDITS_TITLE') }}
      </h2>
      <p class="text-body-main text-n-slate-11 max-w-2xl">
        {{ t('ABOUT_PAGE.CREDITS_BODY') }}
      </p>
      <div class="flex items-center gap-3 mt-1">
        <a
          :href="CHATWOOT_URL"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center gap-1.5 text-sm font-medium text-n-blue-11 hover:underline"
        >
          {{ t('ABOUT_PAGE.CHATWOOT_LINK_LABEL') }}
          <span class="i-lucide-external-link size-3.5 flex-shrink-0" />
        </a>
      </div>
      <p class="text-body-small text-n-slate-10 mt-1">
        {{ t('ABOUT_PAGE.LICENSE_LABEL') }}
      </p>
    </section>

    <!-- Ecosystem -->
    <section class="flex flex-col gap-4 p-6 rounded-xl bg-n-surface-2 border border-n-weak">
      <h2 class="text-heading-2 text-n-slate-12">
        {{ t('ABOUT_PAGE.ECOSYSTEM_TITLE') }}
      </h2>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div class="flex flex-col gap-1 p-4 rounded-lg bg-n-surface-3 border border-n-weak">
          <span class="text-label-strong text-n-slate-12">{{ t('ABOUT_PAGE.HUB_LABEL') }}</span>
          <span class="text-body-small text-n-slate-10">{{ t('ABOUT_PAGE.HUB_DESC') }}</span>
        </div>
        <div class="flex flex-col gap-1 p-4 rounded-lg bg-n-surface-3 border border-n-weak">
          <span class="text-label-strong text-n-slate-12">{{ t('ABOUT_PAGE.AMPLEX_LABEL') }}</span>
          <span class="text-body-small text-n-slate-10">{{ t('ABOUT_PAGE.AMPLEX_DESC') }}</span>
        </div>
        <div class="flex flex-col gap-1 p-4 rounded-lg bg-n-surface-3 border border-n-weak">
          <span class="text-label-strong text-n-slate-12">{{ t('ABOUT_PAGE.ENTITY_LABEL') }}</span>
          <span class="text-body-small text-n-slate-10">{{ t('ABOUT_PAGE.ENTITY_DESC') }}</span>
        </div>
      </div>
    </section>
  </div>
</template>
