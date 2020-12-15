---
path: "/docs/self-hosted/enable-ip-logging"
title: "Chatwoot Production deployment guide"
---

Chatwoot allows you to identify the location of the user by geocoding the IP address. For IP Address geocoding, we support MaxmindDB services. This lookup provides methods for geocoding IP addresses without making a call to a remote API everytime. To setup your self-hosted instance with the geocoding, follow the steps below.

**Step 1:** Create an account at [MaxmindDB](https://www.maxmind.com) and create an API key.

**Step 2:** Add the following environment variables.

```bash
IP_LOOKUP_SERVICE=geoip2
IP_LOOKUP_API_KEY=your-api-key
```

With this step, Chatwoot would automatically download the [MaxmindDB downloadable databases](https://dev.maxmind.com/geoip/geoip2/downloadable/) and cache it locally.

**Step 3:** Enable IP Lookup on your account.

Login to Rails console

```
RAILS_ENV=production bundle exec rails console
```

```rb
account_id = 1 // Please fill your account id instead of 1
account = Account.find(account_id)
account.enable_features('ip_lookup')
account.save!
```
