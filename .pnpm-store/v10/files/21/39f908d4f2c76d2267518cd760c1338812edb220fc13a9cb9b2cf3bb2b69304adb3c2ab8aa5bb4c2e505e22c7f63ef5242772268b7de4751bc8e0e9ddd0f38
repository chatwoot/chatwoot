# Timezone Phone Codes

A lightweight, easy-to-use library for retrieving telephone country codes based on timezone, with full TypeScript support.

## Features

- Get phone country codes by timezone
- Zero dependencies

## Installation

You can install this package using npm, yarn, or pnpm:

```bash
# npm
npm install timezone-phone-codes

# yarn
yarn add timezone-phone-codes

# pnpm
pnpm add timezone-phone-codes
```

## Usage

Here's a basic example of how to use the library:

```typescript
import { getPhoneCodeByTimezone } from 'timezone-phone-codes';

const phoneCode = getPhoneCodeByTimezone('America/New_York');
console.log(phoneCode); // Output: +1

const unknownTimezone = getPhoneCodeByTimezone('Unknown/Timezone');
console.log(unknownTimezone); // Output: null
```

## API

```ts
getPhoneCodeByTimezone(timezone: string): string | null
```

Returns the phone country code for the given timezone. If the timezone is not recognized, it returns `null`.

## Supported Timezones

This library supports a wide range of timezones. Here are a few examples:

- America/New_York: +1
- Europe/London: +44
- Asia/Tokyo: +81
- Australia/Sydney: +61


## Testing

To run the tests:
```bash
pnpm test
```

To run the tests with coverage:
```bash
pnpm coverage
```
