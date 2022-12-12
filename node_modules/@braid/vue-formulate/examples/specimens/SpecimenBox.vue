<template>
  <div class="specimens specimens--text">
    <h2>Box classification</h2>
    <div class="specimen">
      <h3>Single Checkbox</h3>
      <FormulateInput
        type="checkbox"
        label="Are you attractive?"
        help="In your own opinion at least."
      />
    </div>
    <div class="specimen">
      <h3>Multi checkbox</h3>
      <FormulateInput
        type="checkbox"
        label="Which recent U.S. president is your favorite?"
        :options="{trump: 'Trump', obama: 'Obama', bush: 'Bush', clinton: 'Clinton'}"
        help="Your selection will be transmitted directly to the NSA."
      />
    </div>
    <div class="specimen">
      <h3>Radio</h3>
      <FormulateInput
        type="radio"
        label="What heavily body would you like to visit?"
        :options="{moon: 'Moon', mars: 'Mars', venus: 'Venus', mercury: 'Mercury', sun: 'Sun'}"
      />
    </div>
  </div>
</template>
