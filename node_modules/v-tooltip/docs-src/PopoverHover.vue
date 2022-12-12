<template>
  <v-popover
    trigger="hover"
    offset="16"
    :auto-hide="false"
  >
    <button class="tooltip-target b1 popover-btn">Target</button>

    <template slot="popover">
      Hello
    </template>
  </v-popover>
</template>
