<template>
  <div class="flex flex-1 overflow-auto">
    <pre-chat-form :options="preChatFormOptions" />
  </div>
</template>
<script>
import PreChatForm from '../components/PreChat/Form';
import configMixin from '../mixins/configMixin';

export default {
  components: {
    PreChatForm,
  },
  mixins: [configMixin],
};
</script>
