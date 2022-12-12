<template>
  <div class="collapse" :class="{ open: open }">
    <div class="toggle" @click="open = !open">{{ title }} <span class="icon">▼</span></div>
    <div class="content" v-if="open"><slot/></div>
  </div>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      required: true,
    },
  },

  data () {
    return {
      open: false,
    }
  },
}
</script>

<style lang="scss" scoped>
.toggle {
  padding: 12px;
  text-align: center;
  cursor: pointer;
  user-select: none;
  color: #666;

  .icon {
    display: inline-block;
    transition: transform .3s ease-in-out;
    transform-origin: center 10px;
  }

  &:hover {
    color: black;
    background: #f8f8f8;
  }
}

.open {
  .toggle {
    .icon {
      transform: rotate(180deg);
    }
  }
}
</style>
