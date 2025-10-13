<script setup>
import PortalSwitcher from './PortalSwitcher.vue';

const portals = [
  {
    id: 1,
    name: 'AlooChat Help Center',
    articles: 67,
    domain: 'AlooChat.help',
    slug: 'help-center',
  },
  {
    id: 2,
    name: 'AlooChat Handbook',
    articles: 42,
    domain: 'AlooChat.help',
    slug: 'handbook',
  },
  {
    id: 3,
    name: 'Developer Documentation',
    articles: 89,
    domain: 'dev.aloochat.ai',
    slug: 'docs',
  },
];
</script>

<template>
  <Story
    title="Components/HelpCenter/PortalSwitcher"
    :layout="{ type: 'grid', width: '510px' }"
  >
    <Variant title="Portal Switcher">
      <div class="h-[500px] p-4 bg-n-slate-2 dark:bg-n-background">
        <PortalSwitcher
          :portals="portals"
          header="Choose a Portal"
          description="Select from available help center portals"
        />
      </div>
    </Variant>
  </Story>
</template>
