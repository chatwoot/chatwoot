<script>
export default {
  emits: ['open'],

  methods: {
    onClick() {
      this.$emit('open');
    },
  },
};
</script>

<template>
  <div class="relative">
    <woot-button
      icon="wand"
      color-scheme="secondary"
      variant="smooth"
      size="small"
      class-names="cta-btn cta-btn-light dark:cta-btn-dark hover:cta-btn-light-hover dark:hover:cta-btn-dark-hover"
      @click="onClick"
    >
      {{ $t('INTEGRATION_SETTINGS.OPEN_AI.AI_ASSIST') }}
    </woot-button>

    <div
      class="radar-ping-animation absolute top-0 right-0 -mt-1 -mr-1 rounded-full w-3 h-3 bg-woot-500 dark:bg-woot-500"
    />
    <div
      class="absolute top-0 right-0 -mt-1 -mr-1 rounded-full w-3 h-3 bg-woot-500 dark:bg-woot-500 opacity-50"
    />
  </div>
</template>

<style scoped>
@tailwind components;
@layer components {
  /* Gradient animation */
  @keyframes gradient {
    0% {
      background-position: 0% 50%;
    }
    50% {
      background-position: 100% 50%;
    }
    100% {
      background-position: 0% 50%;
    }
  }
  .cta-btn {
    animation: gradient 5s ease infinite;
    border: 0;
  }

  .cta-btn-light {
    background: linear-gradient(
        255.98deg,
        rgba(161, 87, 246, 0.2) 15.83%,
        rgba(71, 145, 247, 0.2) 81.39%
      ),
      linear-gradient(0deg, #f2f5f8, #f2f5f8);
  }

  .cta-btn-dark {
    background: linear-gradient(
        255.98deg,
        rgba(161, 87, 246, 0.2) 15.83%,
        rgba(71, 145, 247, 0.2) 81.39%
      ),
      linear-gradient(0deg, #313538, #313538);
  }

  .cta-btn-light-hover {
    background: linear-gradient(
        255.98deg,
        rgba(161, 87, 246, 0.2) 15.83%,
        rgba(71, 145, 247, 0.2) 81.39%
      ),
      linear-gradient(0deg, #e3e5e7, #e3e5e7);
  }

  .cta-btn-dark-hover {
    background: linear-gradient(
        255.98deg,
        rgba(161, 87, 246, 0.2) 15.83%,
        rgba(71, 145, 247, 0.2) 81.39%
      ),
      linear-gradient(0deg, #202425, #202425);
  }

  /* Radar ping animation */
  @keyframes ping {
    75%,
    100% {
      transform: scale(2);
      opacity: 0;
    }
  }
  .radar-ping-animation {
    animation: ping 1s ease infinite;
  }
}
</style>
