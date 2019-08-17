![ChatUI progess](https://chatwoot.com/images/dashboard-screen.png)

## Build Setup

``` bash
# install JS dependencies
yarn install

# install ruby dependencies
bundle

# copy database config
cp shared/config/database.yml.sample config/database.yml

# run db migrations
bundle exec rake db:migrate

# fireup the server
foreman start
```
