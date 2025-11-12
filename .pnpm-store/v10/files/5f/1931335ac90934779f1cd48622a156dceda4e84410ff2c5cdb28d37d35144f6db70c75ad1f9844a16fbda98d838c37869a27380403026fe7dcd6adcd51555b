# countries-and-timezones
![](https://img.shields.io/github/actions/workflow/status/manuelmhtr/countries-and-timezones/tests.yml?branch=master)
![](https://img.shields.io/npm/dm/countries-and-timezones)
![](https://img.shields.io/badge/license-MIT-blue?style=flat)

> Minimalistic library to work with countries and timezones data. Updated with the [IANA timezones database](https://www.iana.org/time-zones).

## Usage

### NodeJS

Install with npm or yarn:

```bash
npm install --save countries-and-timezones
```

### Browser

Add the following script to your project (only ~9kb):

```html
<!-- Latest version -->
<script src="https://cdn.jsdelivr.net/gh/manuelmhtr/countries-and-timezones@latest/dist/index.min.js" type="text/javascript"></script>

<!-- Or specify a version -->
<script src="https://cdn.jsdelivr.net/gh/manuelmhtr/countries-and-timezones@v3.6.0/dist/index.min.js" type="text/javascript"></script>

<!-- This will export a variable named "ct": -->
<script type="text/javascript">
  var data = ct.getCountry('MX');
  console.log(data);
</script>
```


## API

### `.getCountry(id, options = {})`

Returns a country referenced by its `id`.

Accepts a parameter with [`options`](#options).

**Example**

```javascript
const ct = require('countries-and-timezones');

const country = ct.getCountry('DE');
console.log(country);

/*
Prints:

{
  id: 'DE',
  name: 'Germany',
  timezones: [ 'Europe/Berlin', 'Europe/Zurich' ]
}

*/
```

### `.getTimezone(name)`

Returns a timezone referenced by its `name`.

**Example**

```javascript
const ct = require('countries-and-timezones');

const timezone = ct.getTimezone('America/Los_Angeles');
console.log(timezone);

/*
Prints:

{
  name: 'America/Los_Angeles',
  countries: [ 'US' ],
  utcOffset: -480,
  utcOffsetStr: '-08:00',
  dstOffset: -420,
  dstOffsetStr: '-07:00',
  aliasOf: null
}

*/
```

### `.getAllCountries(options = {})`

Returns an object with the data of all countries.

Accepts a parameter with [`options`](#options).

**Example**

```javascript
const ct = require('countries-and-timezones');

const countries = ct.getAllCountries();
console.log(countries);

/*
Prints:

{
  AD: {
    id: 'AD',
    name: 'Andorra',
    timezones: [ 'Europe/Andorra' ]
  },
  AE: {
    id: 'AE',
    name: 'United Arab Emirates',
    timezones: [ 'Asia/Dubai' ]
  },
  AF: {
    id: 'AF',
    name: 'Afghanistan',
    timezones: [ 'Asia/Kabul' ]
  },
  AG: {
    id: 'AG',
    name: 'Antigua and Barbuda',
    timezones: [ 'America/Puerto_Rico' ]
  },
  ...
}

*/
```

### `.getAllTimezones(options = {})`

Returns an object with the data of all timezones.

Accepts a parameter with [`options`](#options).

**Example**

```javascript
const ct = require('countries-and-timezones');

const timezones = ct.getAllTimezones();
console.log(timezones);

/*
Prints:

{
  "Africa/Abidjan": {
    "name": "Africa/Abidjan",
    "countries": [
      "CI", "BF", "GH",
      "GM", "GN", "ML",
      "MR", "SH", "SL",
      "SN", "TG"
    ],
    "utcOffset": 0,
    "utcOffsetStr": "+00:00",
    "dstOffset": 0,
    "dstOffsetStr": "+00:00",
    "aliasOf": null
  },
  "Africa/Algiers": {
    "name": "Africa/Algiers",
    "countries": [
      "DZ"
    ],
    "utcOffset": 60,
    "utcOffsetStr": "+01:00",
    "dstOffset": 60,
    "dstOffsetStr": "+01:00",
    "aliasOf": null
  },
  "Africa/Bissau": {
    "name": "Africa/Bissau",
    "countries": [
      "GW"
    ],
    "utcOffset": 0,
    "utcOffsetStr": "+00:00",
    "dstOffset": 0,
    "dstOffsetStr": "+00:00",
    "aliasOf": null
  },
  ...
}

*/
```

### `.getTimezonesForCountry(id, options = {})`

Returns an array with all the timezones of a country given its `id`.

Accepts a parameter with [`options`](#options).

**Example**

```javascript
const ct = require('countries-and-timezones');

const timezones = ct.getTimezonesForCountry('MX');
console.log(timezones);

/*
Prints:

[
  {
    "name": "America/Bahia_Banderas",
    "countries": [ "MX" ],
    "utcOffset": -360,
    "utcOffsetStr": "-06:00",
    "dstOffset": -300,
    "dstOffsetStr": "-05:00",
    "aliasOf": null
  },
  {
    "name": "America/Cancun",
    "countries": [ "MX" ],
    "utcOffset": -300,
    "utcOffsetStr": "-05:00",
    "dstOffset": -300,
    "dstOffsetStr": "-05:00",
    "aliasOf": null
  },
  {
    "name": "America/Chihuahua",
    "countries": [ "MX" ],
    "utcOffset": -420,
    "utcOffsetStr": "-07:00",
    "dstOffset": -360,
    "dstOffsetStr": "-06:00",
    "aliasOf": null
  },
  ...
}

*/
```

### `.getCountriesForTimezone(name, options = {})`

Returns a list of the countries that uses a timezone given its `name`. When a timezone has multiple countries **the first element is more relevant** due to its geographical location.

Accepts a parameter with [`options`](#options).

**Example**

```javascript
const ct = require('countries-and-timezones');

const timezone = ct.getCountriesForTimezone('Europe/Zurich');
console.log(timezone);

/*
Prints:

[
  {
    "id": "CH",
    "name": "Switzerland",
    "timezones": [
      "Europe/Zurich"
    ]
  },
  {
    "id": "DE",
    "name": "Germany",
    "timezones": [
      "Europe/Berlin",
      "Europe/Zurich"
    ]
  },
  {
    "id": "LI",
    "name": "Liechtenstein",
    "timezones": [
      "Europe/Zurich"
    ]
  }
]

*/

```

### `.getCountryForTimezone(name, options = {})`

Returns a the most relevant country (due to its geographical location) that uses a timezone given its `name`.

Accepts a parameter with [`options`](#options).

**Example**

```javascript
const ct = require('countries-and-timezones');

const timezone = ct.getCountryForTimezone('Europe/Zurich');
console.log(timezone);

/*
Prints:

{
  "id": "CH",
  "name": "Switzerland",
  "timezones": [
    "Europe/Zurich"
  ]
}

*/

```

### `options`

Available options for functions are:

| Parameter | Type | Description |
| --------- | ---- | ----------- |
|`deprecated`|Boolean|Indicates if the result should include deprecated timezones or not. By default no deprecated timezones are included.|


## Data models

### Country

A country is defined by the following parameters:

| Parameter | Type | Description |
| --------- | ---- | ----------- |
|`id`|String|The country [ISO 3166-1 code](https://es.wikipedia.org/wiki/ISO_3166-1).|
|`name`|String|Preferred name of the country.|
|`timezones`|Array[String]|The list of timezones used in the country.|

```javascript
{
  id: 'MX',
  name: 'Mexico',
  timezones: [
    'America/Bahia_Banderas',
    'America/Cancun',
    'America/Chihuahua',
    'America/Hermosillo',
    'America/Matamoros',
    'America/Mazatlan',
    'America/Merida',
    'America/Mexico_City',
    'America/Monterrey',
    'America/Ojinaga',
    'America/Tijuana'
  ]
}
```

### Timezone

A timezone is defined by the following parameters:

| Parameter | Type | Description |
| --------- | ---- | ----------- |
|`name`|String|The name of the timezone, from [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).|
|`countries`|[String]|A list of [ISO 3166-1 codes](https://es.wikipedia.org/wiki/ISO_3166-1) of the countries where it's used. `Etc/*`, `GMT` and `UTC` timezones don't have associated countries.|
|`utcOffset`|Number|The difference in **minutes** between the timezone and [UTC](https://en.wikipedia.org/wiki/Coordinated_Universal_Time).|
|`utcOffsetStr`|String|The difference in hours and minutes between the timezone and [UTC](https://en.wikipedia.org/wiki/Coordinated_Universal_Time), expressed as string with format: `±[hh]:[mm]`.|
|`dstOffset`|Number|The difference in **minutes** between the timezone and [UTC](https://en.wikipedia.org/wiki/Coordinated_Universal_Time) during daylight saving time ([DST](https://en.wikipedia.org/wiki/Daylight_saving_time)). When `utcOffset` and `dstOffset` are the same, means that the timezone does not observe a daylight saving time.|
|`dstOffsetStr`|String|The difference in hours and minutes between the timezone and [UTC](https://en.wikipedia.org/wiki/Coordinated_Universal_Time) during daylight saving time ([DST](https://en.wikipedia.org/wiki/Daylight_saving_time), expressed as string with format: `±[hh]:[mm]`.|
|`aliasOf`|String|The `name` of a primary timezone in case this is an alias. `null` means this is a primary timezone.|
|`deprecated`|Boolean|`true` when the timezone has been deprecated, otherwise this property is not returned.|

```javascript
{
  name: 'Asia/Tel_Aviv',
  countries: [ 'IL' ],
  utcOffset: 120,
  utcOffsetStr: '+02:00',
  dstOffset: 180,
  dstOffsetStr: '+03:00',
  aliasOf: 'Asia/Jerusalem',
  deprecated: true
}
```


## Related projects

* [countries-db](https://www.npmjs.com/package/countries-db): Minimalistic lib with countries data.
* [location-by-ip](https://www.npmjs.com/package/location-by-ip): Get the location of any IP address.


## Support

Consider [sponsoring this project](https://github.com/sponsors/manuelmhtr).

## Working on something more complex?

Meet [Spott](https://spott.dev):
- **Search any city, country or administrative division** in the world. By full strings or autocompletion.
- Find a place by an IP address.
- Access to more than 240,000 geographical places. In more than 20 languages.

[![Spott API for cities, countries and administrative divisions](https://spott-assets.s3.amazonaws.com/marketing/banner-720px.png)](https://spott.dev)


## License

MIT
