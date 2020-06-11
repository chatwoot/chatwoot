---
path: "/docs/deployment/deploy-chatwoot-with-heroku"
title: "Heroku Chatwoot Production deployment guide"
---

## Deploying on Heroku
Deploy chatwoot on heroku through the following steps 

1. Click on the [one click deploy button](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master) and deploy your app 
2. Go to resources tab in heroku app dashboard and ensure the worker dynos is turned on
3. Head over to settings tabs in heroku app dashboard and click reveal config vars
4. Configure the environment variables for [mailer](https://www.chatwoot.com/docs/environment-variables#configure-emails) and [storage](https://www.chatwoot.com/docs/configuring-cloud-storage) as per the [documentation](https://www.chatwoot.com/docs/environment-variables)
5. Head over to `yourapp.herokuapp.com` and Enjoy using chatwoot.


## Updating the deployment on Heroku

Whenever a new version is out for chatwoot, you update your heroku deployment through following steps

1. In deploy tab, choose `github` as the deployment option
2. Connect chatwoot repo to the app 
3. Head over to the mannual deploy option, choose `master` branch and hit deploy
