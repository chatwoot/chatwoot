<script setup>
import { ref } from 'vue';
import TextArea from './TextArea.vue';

const shortText = ref('');
const limitedText = ref('');
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story title="Components/TextArea" :layout="{ type: 'grid', width: '400px' }">
    <Variant title="Default">
      <TextArea
        v-model="shortText"
        label="Comment"
        placeholder="Enter your comment"
      />
    </Variant>

    <Variant title="Without Label">
      <TextArea v-model="shortText" placeholder="Enter your comment" />
    </Variant>

    <Variant title="With Character Count">
      <TextArea
        v-model="limitedText"
        label="Limited Comment"
        placeholder="Enter your comment (max 100 characters)"
        :max-length="100"
        show-character-count
      />
    </Variant>

    <Variant title="Without Character Count">
      <TextArea
        v-model="shortText"
        label="Quick Note"
        placeholder="Enter a quick note"
        :show-character-count="false"
      />
    </Variant>

    <Variant title="Disabled">
      <TextArea
        v-model="shortText"
        label="Disabled TextArea"
        placeholder="You can't type here"
        disabled
      />
    </Variant>

    <Variant title="Custom Style">
      <TextArea
        v-model="shortText"
        label="Styled TextArea"
        placeholder="Enter text here"
        custom-text-area-class="bg-yellow-100 border-yellow-300"
      />
    </Variant>
  </Story>
</template>
