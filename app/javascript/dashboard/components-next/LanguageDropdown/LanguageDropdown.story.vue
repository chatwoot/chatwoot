<script setup>
import { ref } from 'vue';
import LanguageDropdown from './LanguageDropdown.vue';

const selectedLanguage = ref('en');
</script>

<template>
  <Story
    title="Components/LanguageDropdown"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant title="Default">
      <div class="flex flex-col gap-4 p-4 h-[300px]">
        <LanguageDropdown
          v-model="selectedLanguage"
          placeholder="Select language"
        />
        <div class="text-sm">Selected language: {{ selectedLanguage }}</div>
      </div>
    </Variant>

    <Variant title="With Search">
      <div class="flex flex-col gap-4 p-4 h-[300px]">
        <LanguageDropdown
          v-model="selectedLanguage"
          placeholder="All languages"
          show-search
          search-placeholder="Search languages..."
        />
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="flex flex-col gap-4 p-4 h-[300px]">
        <LanguageDropdown
          v-model="selectedLanguage"
          placeholder="Select language"
          disabled
        />
      </div>
    </Variant>

    <Variant title="Small Size">
      <div class="flex flex-col gap-4 p-4 h-[300px]">
        <LanguageDropdown
          v-model="selectedLanguage"
          placeholder="Select language"
          size="sm"
        />
      </div>
    </Variant>
  </Story>
</template>
