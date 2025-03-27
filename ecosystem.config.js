module.exports = {
    apps: [
      {
        name: "chatwoot-backend",
        script: "make",
        args: "server",
        env: {
        //   NODE_ENV: "development",
        },
      },
      {
        name: "chatwoot-worker",
        script: "bundle exec sidekiq -C config/sidekiq.yml",
        args: "",
        env: {
        //   NODE_ENV: "development",
        },
      },
      {
        name: "chatwoot-vite",
        script: "bin/vite dev",
        args: "",
        env: {
        //   NODE_ENV: "development",
        },
      },
    ],
  };
  