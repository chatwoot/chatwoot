import subprocess
import sys

def run_cmd(description, cmd):
    print(f"\033[1;34m🔧 {description}...\033[0m")
    try:
        subprocess.run(cmd, check=True, shell=True)
    except subprocess.CalledProcessError as e:
        print(f"\033[1;31m❌ Error: {e}\033[0m")
        sys.exit(1)

def main():
    run_cmd("Build Containers", 
        "docker compose -f docker-compose.local.production.yaml build")

    #run_cmd("Execute outstanding Migrations", 
        #"docker compose -f docker-compose.local.production.yaml run --rm rails bundle exec rails db:migrate")

    run_cmd("Preparing Chatwoot DB", 
        "docker compose -f docker-compose.local.production.yaml run --rm rails bundle exec rails db:chatwoot_prepare")

    #run_cmd("Seeding Database", 
        #"docker compose -f docker-compose.local.production.yaml run --rm rails bundle exec rails db:seed")

    run_cmd("Starting containers", 
        "docker compose -f docker-compose.local.production.yaml up -d")

    print("\033[1;32m✅ All done!\033[0m")

if __name__ == "__main__":
    main()

