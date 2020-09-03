---
path: "/docs/deployment/cdn/cloudfront"
title: "Configuring Cloudfront with Chatwoot"
---

This document helps you to configure Cloudfront as the asset host for Chatwoot. If you have a high traffic website, we would recommend setting up a CDN for Chatwoot.

### Configure a Cloudfront distribution

**Step 1**: Create a Cloudfront distribution.

![create-distribution](./images/cloudfront/create-distribution.png)

**Step 2**: Select "Web" as delivery method for your content.

![web-delivery-method](./images/cloudfront/web-delivery-method.png)

**Step 3**: Configure the Origin Settings as the following.

![origin-settings](./images/cloudfront/origin-settings.png)

- Provide your Chatwoot Installation URL under Origin Domain Name.
- Select "Origin Protocol Policy" as Match Viewer.

**Step 4**: Configure Cache behaviour.

![cache-behaviour](./images/cloudfront/cache-behaviour.png)

- Configure **Allowed HTTP methods** to use *GET, HEAD, OPTIONS*.
- Configure **Cache and origin request settings** to use *Use legacy cache settings*.
- Select **Whitelist** for *Cache Based on Selected Request Headers*.
- Add the following headers to the **Whitelist Headers**.
![extra-headers](./images/cloudfront/extra-headers.png)
  - **Access-Control-Request-Headers**
  - **Access-Control-Request-Method**
  - **Origin**

**Step 5**: Click on **Create Distribution**. You will be able to see the distribution as shown below. Use the **Domain name** listed in the details as the **ASSET_CDN_HOST** in Chatwoot.

![cdn-distribution-settings](./images/cloudfront/cdn-distribution-settings.png)

### Add ASSET_CDN_HOST in Chatwoot

Your Cloudfront URL will be of the format `<distribution>.cloudfront.net`.

Set

```bash
ASSET_CDN_HOST=<distribution>.cloudfront.net
```

in the environment variables.
