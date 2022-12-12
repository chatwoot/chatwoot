<template>
  <div class="specimens specimens--text">
    <h2>Text classification</h2>
    <div class="specimen">
      <h3>Color</h3>
      <FormulateInput
        label="Pick a color?"
        type="color"
        help="Choose your favorite."
        validation="required|between:0,10"
      />
    </div>
    <div class="specimen">
      <h3>Date</h3>
      <FormulateInput
        label="Select a day."
        type="date"
        help="Choose your birthday."
      />
    </div>
    <div class="specimen">
      <h3>Datetime-local</h3>
      <FormulateInput
        label="Select a day and time."
        type="datetime-local"
        help="When is the meeting?"
      />
    </div>
    <div class="specimen">
      <h3>Email</h3>
      <FormulateInput
        label="What is your email?"
        type="email"
        placeholder="placeholder@example.com"
        help="What is your email address?"
      />
    </div>
    <div class="specimen">
      <h3>Month</h3>
      <FormulateInput
        label="Favorite month"
        type="month"
        help="When is Christmas?"
      />
    </div>
    <div class="specimen">
      <h3>Number</h3>
      <FormulateInput
        label="How old are you?"
        type="number"
        placeholder="25"
        help="Select your age"
      />
    </div>
    <div class="specimen">
      <h3>Password</h3>
      <FormulateInput
        label="Enter a password."
        type="password"
        help="Choose something long and tricky."
      />
    </div>
    <div class="specimen">
      <h3>Search</h3>
      <FormulateInput
        label="But I still haven't found."
        type="search"
        placeholder="What im looking for..."
        help="I have climbed the highest mountains."
      />
    </div>
    <div class="specimen">
      <h3>Tel</h3>
      <FormulateInput
        label="Oh you like Mike & Ikes?"
        type="tel"
        placeholder="Can I have you number..."
        help="Can I have it?"
      />
    </div>
    <div class="specimen">
      <h3>Time</h3>
      <FormulateInput
        label="What time is dinner?"
        type="time"
        placeholder="Pick a time"
        help="When will you eat your food?"
      />
    </div>
    <div class="specimen">
      <h3>Text</h3>
      <FormulateInput
        label="Username"
        type="text"
        placeholder="Username"
        help="Select a username"
      />
    </div>
    <div class="specimen">
      <h3>Url</h3>
      <FormulateInput
        label="Personal website"
        type="url"
        placeholder="https://"
        help="What is the url for your website?"
      />
    </div>
    <div class="specimen">
      <h3>Week</h3>
      <FormulateInput
        label="I don’t know who would use this field."
        type="week"
        placeholder="Pick a week"
        help="What week is it?"
      />
    </div>
  </div>
</template>
