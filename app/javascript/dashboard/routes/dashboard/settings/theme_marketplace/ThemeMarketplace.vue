<script>
import { mapGetters, mapActions } from 'vuex';
import { useAlert } from 'dashboard/composables';
import PageHeader from '../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'ThemeMarketplace',
  components: { PageHeader, NextButton },
  data() {
    return {
      search: '',
      installing: {},
      featured: [
        {
          id: 'minimal',
          name: 'Minimal',
          description: 'Clean, distraction-free chat interface',
          author: 'Whisker',
          version: '1.0.0',
          downloads: 1240,
          rating: 4.8,
          preview: 'linear-gradient(135deg, #f8fafc, #e2e8f0)',
        },
        {
          id: 'dark-ocean',
          name: 'Dark Ocean',
          description: 'Deep blue dark theme with teal accents',
          author: 'Community',
          version: '1.0.0',
          downloads: 890,
          rating: 4.6,
          preview: 'linear-gradient(135deg, #0f172a, #1e293b)',
        },
        {
          id: 'neon-pulse',
          name: 'Neon Pulse',
          description: 'Vibrant neon accents on dark background',
          author: 'Community',
          version: '1.0.0',
          downloads: 560,
          rating: 4.5,
          preview: 'linear-gradient(135deg, #1a1a2e, #16213e)',
        },
        {
          id: 'whisker-default',
          name: 'Whisker Default',
          description: 'The official Whisker teal + blue theme',
          author: 'Whisker',
          version: '1.0.0',
          downloads: 2100,
          rating: 4.9,
          preview: 'linear-gradient(135deg, #1fe0b5, #1ba5ff)',
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      installedThemes: 'whiskerThemes/getInstalled',
      activeTheme: 'whiskerThemes/getActive',
    }),
    filtered() {
      if (!this.search) return this.featured;
      return this.featured.filter(t =>
        t.name.toLowerCase().includes(this.search.toLowerCase()) ||
        t.description.toLowerCase().includes(this.search.toLowerCase())
      );
    },
  },
  methods: {
    ...mapActions('whiskerThemes', ['installTheme', 'setActiveTheme']),
    isInstalled(id) {
      return this.installedThemes.some(t => t.id === id);
    },
    async handleInstall(theme) {
      this.installing[theme.id] = true;
      try {
        await this.installTheme(theme);
        useAlert(`Installed ${theme.name}`);
      } catch (err) {
        useAlert(err.message || 'Install failed');
      } finally {
        this.installing[theme.id] = false;
      }
    },
    async handleActivate(theme) {
      try {
        await this.setActiveTheme(theme.id);
        useAlert(`Activated ${theme.name}`);
      } catch (err) {
        useAlert(err.message || 'Activation failed');
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full overflow-auto">
    <PageHeader
      header-title="Theme Marketplace"
      header-content="Browse and install widget themes to customize your chat experience."
    />
    <div class="flex-1 px-6 py-4">
      <div class="mb-4">
        <input
          v-model="search"
          type="text"
          placeholder="Search themes..."
          class="w-full max-w-md px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
        />
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="theme in filtered"
          :key="theme.id"
          class="border rounded-xl border-n-slate-6 overflow-hidden hover:border-n-brand transition-colors"
        >
          <div class="h-24" :style="{ background: theme.preview }" />
          <div class="p-4">
            <div class="flex items-center justify-between mb-1">
              <h3 class="font-medium text-n-slate-12">{{ theme.name }}</h3>
              <span class="text-xs text-n-slate-10">v{{ theme.version }}</span>
            </div>
            <p class="text-xs text-n-slate-11 mb-3">{{ theme.description }}</p>
            <div class="flex items-center justify-between text-xs text-n-slate-10 mb-3">
              <span>by {{ theme.author }}</span>
              <span>{{ theme.downloads.toLocaleString() }} downloads</span>
              <span>★ {{ theme.rating }}</span>
            </div>
            <div class="flex gap-2">
              <NextButton
                v-if="!isInstalled(theme.id)"
                solid
                blue
                small
                :label="installing[theme.id] ? 'Installing...' : 'Install'"
                :disabled="installing[theme.id]"
                @click="handleInstall(theme)"
              />
              <template v-else>
                <NextButton
                  v-if="activeTheme?.id !== theme.id"
                  solid
                  small
                  label="Activate"
                  @click="handleActivate(theme)"
                />
                <span v-else class="text-xs text-n-brand font-medium px-2 py-1">Active</span>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
