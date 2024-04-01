<template>
    <div class="spinner"></div>
</template>

<style scoped>
.spinner {
  width: 56px;
  height: 56px;
  display: grid;
  border: 4.5px solid #0000;
  border-radius: 50%;
  border-color: #dbdcef #0000;
  animation: spinner-e04l1k 1s infinite linear;
}

.spinner::before,
.spinner::after {
  /* content: ""; */
  grid-area: 0;
  /* margin: 2.2px; */
  border: inherit;
  border-radius: 50%;
}

.spinner::before {
  border-color: #474bff #0000;
  animation: inherit;
  animation-duration: 2.5s;
  /* animation-direction: reverse; */
}

/* .spinner::after {
  margin: 8.9px;
} */

@keyframes spinner-e04l1k {
  100% {
    transform: rotate(1turn);
  }
}
</style>
