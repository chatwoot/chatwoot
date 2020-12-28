---
path: "/docs/deployment/deploy-chatwoot-with-heroku"
title: "Heroku Chatwoot Production deployment guide"
---

### Deploying on Heroku
Deploy chatwoot on Heroku through the following steps

1. Click on the [one click deploy button](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master) and deploy your app.
2. Go to the Resources tab in the Heroku app dashboard and ensure the worker dynos is turned on.
3. Head over to settings tabs in Heroku app dashboard and click reveal config vars.
4. Configure the environment variables for [mailer](https://www.chatwoot.com/docs/environment-variables#configure-emails) and [storage](https://www.chatwoot.com/docs/configuring-cloud-storage) as per the [documentation](https://www.chatwoot.com/docs/environment-variables).
5. Head over to `yourapp.herokuapp.com` and enjoy using Chatwoot.


### Updating the deployment on Heroku

Whenever a new version is out for chatwoot, you update your Heroku deployment through following steps.

1. In the deploy tab, choose `Github` as the deployment option.
2. Connect chatwoot repo to the app.
3. Head over to the manual deploy option, choose `master` branch and hit deploy.

### Known Limitations

1. If you are on a free tier and you don’t access the application for a while Heroku will put your dynos to sleep. You can fix this by upgrading the dynos to paid tier.

2. Heroku has an "ephemeral" hard disk. The files uploaded to Chatwoot would not persist after the application is restarted. By default, Chatwoot uses local disk as the upload destination. To overcome this problem, you will have to [configure a cloud storage](https://www.chatwoot.com/docs/configuring-cloud-storage). 
