# Chatwoot

# Development process

- All app code goes into root folder
- Do not touch `infra` folder with any changes
- In order to build app for deployment modify `Dockerfile` and `sidekiq.Dockerfile` according to needs to get changes
- Push your feature branch
- Create MR
- Follow automated pipelines for docker build, publish, terraform plan
- If there are no errors and code good to go to production merge it and follow pipelines again