<template>
  <div class="specimens specimens--group">
    <h2>Group classification</h2>
    <div class="specimen">
      <h3>Non-repeatable group</h3>
      <FormulateInput
        type="group"
      >
        <FormulateInput
          label="City"
          type="text"
          name="city"
        />
        <FormulateInput
          label="State"
          type="select"
          :options="{NE: 'Nebraska', MO: 'Missouri', VA: 'Virginia'}"
          placeholder="Select a state"
        />
      </FormulateInput>
    </div>
    <div class="specimen">
      <h3>Simple repeatable group</h3>
      <FormulateInput
        type="group"
        name="foobar"
        :repeatable="true"
      >
        <div class="wrap">
          <FormulateInput
            type="text"
            name="name"
          />
        </div>
      </FormulateInput>
    </div>
    <div class="specimen">
      <h3>Repeatable group</h3>
      <FormulateInput
        name="users"
        label="Invite some new users"
        type="group"
        placeholder="users"
        help="Fields can be grouped"
        :repeatable="true"
        minimum="3"
        :value="[{ name: 'Justin' }, { name: 'Bob' }]"
        add-label="Add new user"
        remove-label="Remove user"
      >
        <FormulateInput
          label="First and last name"
          name="name"
          type="text"
          placeholder="User’s name"
          validation="required"
        />
        <FormulateInput
          name="email"
          label="Email address"
          type="email"
          placeholder="User’s email"
          validation="required|email"
        />
      </FormulateInput>
    </div>
  </div>
</template>
