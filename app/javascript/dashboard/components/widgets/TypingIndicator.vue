<template>
  <div class="typing-indicator">
    <label>AI is typing</label>
    <div class="typing">
      <span class="circle scaling" />
      <span class="circle scaling" />
      <span class="circle scaling" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.typing-indicator {
  color: #282d3e;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  width: fit-content;

  .typing {
    display: block;
    width: 36px;
    height: 16px;
    border-radius: 20px;
    margin: 0 4px 0 8px;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .circle {
    display: block;
    height: 6px;
    width: 6px;
    border-radius: 50%;
    background-color: #000;
    margin: 3px;

    &.scaling {
      animation: typing 1000ms ease-in-out infinite;
      animation-delay: 3600ms;
    }

    &.bouncing {
      animation: bounce 1000ms ease-in-out infinite;
      animation-delay: 3600ms;
    }
    .circle:nth-child(1) {
      animation-delay: 0ms;
    }

    .circle:nth-child(2) {
      animation-delay: 333ms;
    }

    .circle:nth-child(3) {
      animation-delay: 666ms;
    }
  }
}

@keyframes typing {
  0% {
    transform: scale(1);
  }
  33% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.4);
  }
  100% {
    transform: scale(1);
  }
}
</style>
