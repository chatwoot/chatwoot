<template>
  <div class="specimens specimens--text">
    <h2>Select classification</h2>
    <div class="specimen">
      <h3>Select</h3>
      <FormulateInput
        label="What planet is the hottest?"
        type="select"
        :options="{mercury: 'Mercury', venus: 'Venus', earth: 'Earth', mars: 'Mars'}"
        help="Average temperature on the surface of the planet."
      />
      <FormulateInput
        label="Who makes the best rockets?"
        type="select"
        :options="['SpaceX', 'United Launch Alliance', 'Avio', 'Aerojet Rocketdyne', 'Russians']"
        help="Select your favorite"
      />
    </div>
    <div class="specimen">
      <h3>Select with placeholder</h3>
      <FormulateInput
        label="What planet is the hottest?"
        type="select"
        placeholder="Select a planet"
        :options="{mercury: 'Mercury', venus: 'Venus', earth: 'Earth', mars: 'Mars'}"
        help="Average temperature on the surface of the planet."
      />
    </div>
    <div class="specimen">
      <h3>Select with multiple attribute</h3>
      <FormulateInput
        label="When visiting a hot planet what are your favorite icecream flavors?"
        type="select"
        multiple
        size="3"
        :options="{vanilla: 'Vanilla', chocolate: 'Chocolate', cherry: 'Cherry', lemon: 'Lemon'}"
        help="You can choose more than one selection by holding command (mac) or option (windows)."
      />
    </div>
  </div>
</template>
