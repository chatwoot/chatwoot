![ChatUI progess](https://chatwoot.com/images/dashboard-screen.png)

## Build Setup

``` bash
# install JS dependencies
yarn install

# install ruby dependencies
bundle

# copy database config
cp shared/config/database.yml config/database.yml

# copy frontend env file
cp .env.sample .env

# run db migrations
bundle exec rake db:migrate

# fireup the server
foreman start
```
