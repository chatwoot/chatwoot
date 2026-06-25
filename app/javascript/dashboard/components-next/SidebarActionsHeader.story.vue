<script setup>
import SidebarActionsHeader from './SidebarActionsHeader.vue';
</script>

<template>
  <Story
    title="Components/SidebarActionsHeader"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <!-- Default State -->
    <Variant title="Default State">
      <SidebarActionsHeader title="Default State" />
    </Variant>

    <!-- With New Conversation Button -->
    <Variant title="With New Conversation Button">
      <!-- eslint-disable-next-line vue/prefer-true-attribute-shorthand -->
      <SidebarActionsHeader
        title="With New Conversation Button"
        :buttons="[
          {
            key: 'new_conversation',
            icon: 'i-lucide-plus',
          },
        ]"
      />
    </Variant>
  </Story>
</template>
