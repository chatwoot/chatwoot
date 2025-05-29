cp .env.example .env
sed -i -e '/REDIS_URL/ s/=.*/=redis:\/\/localhost:6379/' .env
sed -i -e '/POSTGRES_HOST/ s/=.*/=localhost/' .env
sed -i -e '/SMTP_ADDRESS/ s/=.*/=localhost/' .env
sed -i -e "/FRONTEND_URL/ s/=.*/=https:\/\/$CODESPACE_NAME-3000.app.github.dev/" .env

# codespaces make the ports public
gh codespace ports visibility 3000:public 3036:public 8025:public -c $CODESPACE_NAME
