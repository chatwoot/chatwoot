<template>
  <div class="column content-box">
    <campaign />
  </div>
</template>

<script>
import Campaign from './Campaign.vue';

export default {
  components: {
    Campaign,
  },
  data() {
    return { selectedAgents: [] };
  },
  computed: {},
  methods: {},
};
</script>
