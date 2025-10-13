#!/bin/bash
# Roo-Debugger-Fix-v3

# Chatwoot Development Server Management Script
# This script manages the Rails server and Sidekiq with the correct Ruby version

# Set the correct Ruby path
eval "$(rbenv init -)"

# --- Ruby Version Check ---
REQUIRED_RUBY_VERSION="3.3.9"
CURRENT_RUBY_VERSION=$(ruby --version | cut -d' ' -f2)

if [ "$CURRENT_RUBY_VERSION" != "$REQUIRED_RUBY_VERSION" ]; then
    echo -e "\033[0;31m[ERROR] Incorrect Ruby version. Expected ${REQUIRED_RUBY_VERSION}, but found ${CURRENT_RUBY_VERSION}.\033[0m"
    echo -e "\033[1;33mPlease install Ruby 3.3.9 and ensure it is the active version.\033[0m"
    echo -e "\033[1;33mIt is highly recommended to use a Ruby version manager like rbenv or asdf.\033[0m"
    exit 1
fi
# --- End Ruby Version Check ---

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# PID files
RAILS_PID_FILE="tmp/pids/server.pid"
SIDEKIQ_PID_FILE="tmp/pids/sidekiq.pid"
NGROK_PID_FILE="tmp/pids/ngrok.pid"
TAILSCALE_FUNNEL_PID_FILE="tmp/pids/tailscale_funnel.pid"
TAILSCALE_URL_FILE="tmp/pids/tailscale_url.txt"
NGINX_PID_FILE="tmp/pids/nginx.pid"

# Domain configuration
NGROK_PORT=3000
NGROK_SUBDOMAIN=""  # Set this to use a custom subdomain (requires ngrok account)
NGROK_CONFIG_FILE="$HOME/.ngrok2/ngrok.yml"  # Default ngrok config location

# Public access configuration
CUSTOM_DOMAIN="liquid-m3-pro.tail367da4.ts.net"  # Your custom domain
USE_CUSTOM_DOMAIN=false  # Set to false to use Tailscale Funnel or ngrok
USE_TAILSCALE_FUNNEL=true  # Set to true to use Tailscale Funnel, false for ngrok
TAILSCALE_PORT=10750
DEFAULT_TAILSCALE_URL="liquid-m3-pro.tail367da4.ts.net"  # Default Tailscale URL

# Rails configuration files
RAILS_ENV_FILE=".env"
RAILS_CONFIG_FILE="config/environments/development.rb"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a process is running
is_running() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        # Use kill -0 instead of ps -p to avoid permission issues
        if kill -0 "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$pid_file"
            return 1
        fi
    fi
    return 1
}

# Function to cleanup stale processes and PID files
cleanup_stale_processes() {
    print_status "Cleaning up stale processes and PID files..."
    
    # Kill any Rails processes running on port 10750
    local rails_pids=$(lsof -ti :10750 2>/dev/null || true)
    if [ -n "$rails_pids" ]; then
        print_status "Killing stale Rails processes on port 10750: $rails_pids"
        echo "$rails_pids" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
    
    # Kill any Sidekiq processes that might be orphaned
    local sidekiq_pids=$(pgrep -f "sidekiq" 2>/dev/null || true)
    if [ -n "$sidekiq_pids" ]; then
        print_status "Killing stale Sidekiq processes: $sidekiq_pids"
        echo "$sidekiq_pids" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
    
    # Kill any Ruby processes that might be Rails servers or consoles
    local ruby_rails_pids=$(pgrep -f "rails server\|rails console" 2>/dev/null || true)
    if [ -n "$ruby_rails_pids" ]; then
        print_status "Killing stale Rails processes: $ruby_rails_pids"
        echo "$ruby_rails_pids" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
    
    # Kill any ngrok processes that might be orphaned
    local ngrok_pids=$(pgrep -f "ngrok" 2>/dev/null || true)
    if [ -n "$ngrok_pids" ]; then
        print_status "Killing stale ngrok processes: $ngrok_pids"
        echo "$ngrok_pids" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi

    # Kill any tailscale funnel processes that might be orphaned
    local tailscale_pids=$(pgrep -f "tailscale funnel" 2>/dev/null || true)
    if [ -n "$tailscale_pids" ]; then
        print_status "Killing stale Tailscale Funnel processes: $tailscale_pids"
        echo "$tailscale_pids" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
    
    # Remove any stale PID files and temporary files after killing processes
    # But preserve the Tailscale URL file if it exists
    local tailscale_url_backup=""
    if [ -f "$TAILSCALE_URL_FILE" ]; then
        tailscale_url_backup=$(cat "$TAILSCALE_URL_FILE" 2>/dev/null | head -1 | tr -d '\n')
    fi

    rm -rf tmp/pids tmp/cache tmp/*.pid
    mkdir -p tmp/pids tmp/cache

    # Restore the Tailscale URL file if we had one
    if [ -n "$tailscale_url_backup" ]; then
        echo "$tailscale_url_backup" > "$TAILSCALE_URL_FILE"
    fi

    # Also check for Rails-specific PID files that might be elsewhere
    rm -f tmp/server.pid tmp/puma.pid 2>/dev/null || true

    # Clear any spring processes that might be holding onto the server
    if command -v spring >/dev/null 2>&1; then
        spring stop >/dev/null 2>&1 || true
    fi

    # Clear any bundler processes that might interfere
    if command -v bundle >/dev/null 2>&1; then
        bundle exec spring stop >/dev/null 2>&1 || true
    fi
    
    # Wait a moment for processes to fully terminate
    sleep 2
    
    print_success "Cleanup completed"
}

# Function to check if nginx is running
is_nginx_running() {
    if pgrep -f "nginx: master process" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Function to start nginx
start_nginx() {
    if is_nginx_running; then
        print_warning "Nginx is already running"
        return
    fi
    
    print_status "Starting nginx server..."
    
    # Check if nginx is installed
    if ! command -v nginx >/dev/null 2>&1; then
        print_error "Nginx is not installed. Please install nginx first:"
        print_status "Run: brew install nginx"
        return 1
    fi
    
    # Start nginx
    if sudo nginx; then
        print_success "Nginx started successfully"
        print_status "HTTPS proxy available at: https://dev.rhaps.net"
    else
        print_error "Failed to start nginx"
        print_status "Check nginx configuration with: sudo nginx -t"
        return 1
    fi
}

# Function to stop nginx
stop_nginx() {
    if is_nginx_running; then
        print_status "Stopping nginx server..."
        if sudo nginx -s quit; then
            print_success "Nginx stopped successfully"
        else
            print_warning "Nginx may have stopped ungracefully, trying force stop..."
            sudo pkill -f "nginx: master process" 2>/dev/null || true
            print_success "Nginx stopped"
        fi
    else
        print_warning "Nginx is not running"
    fi
}

# Function to reload nginx configuration
reload_nginx() {
    if is_nginx_running; then
        print_status "Reloading nginx configuration..."
        if sudo nginx -s reload; then
            print_success "Nginx configuration reloaded"
        else
            print_error "Failed to reload nginx configuration"
            return 1
        fi
    else
        print_warning "Nginx is not running, starting instead..."
        start_nginx
    fi
}

# Function to start the Rails server
start_rails() {
    if is_running "$RAILS_PID_FILE"; then
        print_warning "Rails server is already running (PID: $(cat $RAILS_PID_FILE))"
        return
    fi

    # Extra check: make sure no Rails process is using the port
    local port_check=$(lsof -ti :10750 2>/dev/null || true)
    if [ -n "$port_check" ]; then
        print_warning "Port 10750 is in use by process $port_check. Killing it..."
        kill -9 "$port_check" 2>/dev/null || true
        sleep 2
    fi

    # Remove any stale Rails PID files before starting
    rm -f tmp/pids/server.pid tmp/server.pid tmp/puma.pid 2>/dev/null || true

    print_status "Starting Rails server with Ruby $(ruby --version | cut -d' ' -f2)..."

    # Create log directory if it doesn't exist
    mkdir -p log

    # Start Rails server with binding for Tailscale Funnel compatibility
    nohup bundle exec rails server -p 10750 --binding=0.0.0.0 --pid="$RAILS_PID_FILE" > log/rails.log 2>&1 &
    RAILS_PID=$!

    # Wait and check for Rails to start with multiple retries
    local attempts=0
    local max_attempts=15
    local port_ready=false

    print_status "Waiting for Rails server to start..."

    while [ $attempts -lt $max_attempts ]; do
        if lsof -i :10750 > /dev/null 2>&1; then
            port_ready=true
            break
        fi

        # Check if the process is still running
        if ! kill -0 "$RAILS_PID" > /dev/null 2>&1; then
            print_error "Rails process terminated unexpectedly"
            break
        fi

        attempts=$((attempts + 1))
        sleep 1
        echo -n "."
    done
    echo ""

    # Final check
    if [ "$port_ready" = true ]; then
        print_success "Rails server started successfully (PID: $RAILS_PID)"
        print_status "Server available at: http://localhost:10750"
    else
        print_error "Failed to start Rails server after ${max_attempts} seconds"
        print_status "Check log/rails.log for details:"
        tail -20 log/rails.log 2>/dev/null || echo "No log file found"
        rm -f "$RAILS_PID_FILE"
    fi
}

# Function to start Sidekiq
start_sidekiq() {
    if is_running "$SIDEKIQ_PID_FILE"; then
        print_warning "Sidekiq is already running (PID: $(cat $SIDEKIQ_PID_FILE))"
        return
    fi
    
    print_status "Starting Sidekiq..."
    
    # Create log directory if it doesn't exist
    mkdir -p log
    
    # Start Sidekiq in background (newer versions don't support -d flag)
    nohup bundle exec sidekiq > log/sidekiq.log 2>&1 &
    SIDEKIQ_PID=$!
    echo $SIDEKIQ_PID > "$SIDEKIQ_PID_FILE"
    
    # Wait a moment for Sidekiq to start
    sleep 2
    
    if is_running "$SIDEKIQ_PID_FILE"; then
        print_success "Sidekiq started successfully (PID: $(cat $SIDEKIQ_PID_FILE))"
    else
        print_error "Failed to start Sidekiq"
    fi
}

# Function to stop the Rails server
stop_rails() {
    local quiet_mode=${1:-false}
    if is_running "$RAILS_PID_FILE"; then
        local pid=$(cat "$RAILS_PID_FILE")
        print_status "Stopping Rails server (PID: $pid)..."
        kill "$pid"
        rm -f "$RAILS_PID_FILE"
        print_success "Rails server stopped"
    elif [ "$quiet_mode" != "true" ]; then
        print_warning "Rails server is not running"
    fi
}

# The functions to update the .env file have been removed.
# This was causing the "server is already running" error.

# Function to start ngrok
start_ngrok() {
    if is_running "$NGROK_PID_FILE"; then
        print_warning "Ngrok is already running (PID: $(cat $NGROK_PID_FILE))"
        return
    fi
    
    # Check if ngrok is installed
    if ! command -v ngrok >/dev/null 2>&1; then
        print_error "Ngrok is not installed. Please install ngrok first:"
        print_status "Visit https://ngrok.com/download or run: brew install ngrok"
        return 1
    fi
    
    print_status "Starting ngrok tunnel for port $NGROK_PORT..."
    
    # Create log directory if it doesn't exist
    mkdir -p log
    
    # Build ngrok command
    local ngrok_cmd="ngrok http $NGROK_PORT"
    if [ -n "$NGROK_SUBDOMAIN" ]; then
        ngrok_cmd="$ngrok_cmd --subdomain=$NGROK_SUBDOMAIN"
    fi
    
    # Start ngrok in background
    nohup $ngrok_cmd > log/ngrok.log 2>&1 &
    NGROK_PID=$!
    echo $NGROK_PID > "$NGROK_PID_FILE"
    
    # Wait for ngrok to start and establish tunnel
    print_status "Waiting for ngrok to establish tunnel..."
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if curl -s http://localhost:4040/api/tunnels >/dev/null 2>&1; then
            local tunnels_json=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$tunnels_json" ]; then
                local ngrok_url=$(echo "$tunnels_json" | grep -o '"public_url":"https://[^"]*"' | grep -o 'https://[^"]*' | head -1)
                if [ -n "$ngrok_url" ]; then
                    print_success "Ngrok started successfully (PID: $NGROK_PID)"
                    print_status "Public URL: $ngrok_url"
                    
                    # Update Rails configuration with ngrok URL
                    # The function to update the .env file has been removed.
                    
                    return 0
                fi
            fi
        fi
        
        attempts=$((attempts + 1))
        sleep 1
    done
    
    print_error "Failed to start ngrok or establish tunnel"
    print_status "Check log/ngrok.log for details:"
    tail -10 log/ngrok.log 2>/dev/null || echo "No log file found"
    rm -f "$NGROK_PID_FILE"
    return 1
}

# Function to stop ngrok
stop_ngrok() {
    local quiet_mode=${1:-false}
    if is_running "$NGROK_PID_FILE"; then
        local pid=$(cat "$NGROK_PID_FILE")
        print_status "Stopping ngrok (PID: $pid)..."
        kill "$pid"
        rm -f "$NGROK_PID_FILE"

        # Remove ngrok configuration from Rails
        # The function to update the .env file has been removed.

        print_success "Ngrok stopped"
    elif [ "$quiet_mode" != "true" ]; then
        print_warning "Ngrok is not running"
    fi
}

# Function to ask user for Tailscale Funnel URL
ask_tailscale_funnel_url() {
    # Check if running in non-interactive mode (no TTY)
    if [ ! -t 0 ]; then
        # Non-interactive - use default immediately
        echo "$DEFAULT_TAILSCALE_URL"
        return 0
    fi

    print_status "Please provide your Tailscale Funnel URL:"
    print_status "Example: your-machine.your-tailnet.ts.net"
    print_status "Press Enter to use default: $DEFAULT_TAILSCALE_URL"

    # Use timeout with read to prevent blocking - if no input in 1 second, use default
    if read -t 1 -p "Enter your Tailscale URL (without https://): " tailscale_url 2>/dev/null; then
        # User provided input
        :
    else
        # No input or timeout - use default
        tailscale_url=""
    fi

    # Use default if nothing entered
    if [ -z "$tailscale_url" ]; then
        tailscale_url="$DEFAULT_TAILSCALE_URL"
    fi

    # Clean the input - remove any whitespace and protocol prefixes
    tailscale_url=$(echo "$tailscale_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's|^https\?://||')

    if [ -n "$tailscale_url" ]; then
        # Only echo the clean URL, no other text
        echo "$tailscale_url"
        return 0
    fi

    return 1
}

# Function to start Tailscale Funnel
start_tailscale_funnel() {
    if is_running "$TAILSCALE_FUNNEL_PID_FILE"; then
        print_warning "Tailscale Funnel is already running (PID: $(cat $TAILSCALE_FUNNEL_PID_FILE))"
        return
    fi

    # Check if Tailscale is installed
    if ! command -v tailscale >/dev/null 2>&1; then
        print_error "Tailscale is not installed. Please install Tailscale first:"
        print_status "Visit https://tailscale.com/download or run: brew install tailscale"
        return 1
    fi

    # Check if Tailscale Funnel is already running with timeout (using perl for macOS compatibility)
    local tailscale_funnel_output=$(perl -e 'alarm 3; exec @ARGV' tailscale funnel status 2>/dev/null || echo "")

    if echo "$tailscale_funnel_output" | grep -q "Funnel on" && echo "$tailscale_funnel_output" | grep -q ":$TAILSCALE_PORT"; then
        print_success "Tailscale Funnel is already active and funneling port $TAILSCALE_PORT"

        # Extract and save the URL
        local funnel_url=$(echo "$tailscale_funnel_output" | grep -E "https://.*\.ts\.net" | head -1 | sed 's/.*https:\/\///' | sed 's/ .*//' | sed 's|/$||')
        if [ -n "$funnel_url" ]; then
            echo "$funnel_url" > "$TAILSCALE_URL_FILE"
            print_status "Public URL: https://$funnel_url"
        fi

        # Create tracking file
        echo "existing_tailscale_funnel" > "$TAILSCALE_FUNNEL_PID_FILE"
        return 0
    fi

    print_status "Starting Tailscale Funnel for port $TAILSCALE_PORT..."

    # Check Tailscale authentication status with timeout (using perl for macOS compatibility)
    local tailscale_status_output=$(perl -e 'alarm 3; exec @ARGV' tailscale status 2>/dev/null || echo "")
    if [ -z "$tailscale_status_output" ]; then
        print_error "Tailscale is not authenticated. Run 'tailscale up' first"
        return 1
    fi

    if echo "$tailscale_status_output" | grep -q "Logged out"; then
        print_error "Tailscale is logged out. Run 'tailscale up' to log in"
        return 1
    fi

    # Check if Funnel is enabled for this tailnet
    if echo "$tailscale_funnel_output" | grep -q "funnel not enabled"; then
        print_error "Funnel is not enabled for this tailnet"
        print_status "Enable it in Tailscale admin console: https://login.tailscale.com/admin/settings/features"
        return 1
    fi

    print_status "Note: Please run 'tailscale funnel $TAILSCALE_PORT' in your own terminal"
    print_status "This script cannot execute privileged Tailscale commands directly"

    # Create log directory if it doesn't exist
    mkdir -p log

    # Create a placeholder process to track Tailscale Funnel
    print_status "Waiting for you to start Tailscale Funnel in another terminal..."
    echo "manual_tailscale_funnel" > "$TAILSCALE_FUNNEL_PID_FILE"

    # Use timeout with read to prevent blocking - skip prompt in non-interactive mode
    if [ -t 0 ]; then
        print_status "Once you start 'tailscale funnel $TAILSCALE_PORT', press Enter to continue (auto-continuing in 1 second)..."
        read -t 1 -r 2>/dev/null || true
    fi

    # Ask user for their Tailscale URL or use default
    local funnel_url
    if [ -f "$TAILSCALE_URL_FILE" ]; then
        # Use existing saved URL
        funnel_url=$(cat "$TAILSCALE_URL_FILE" 2>/dev/null | head -1 | tr -d '\n')
        print_success "Using saved Tailscale Funnel URL: $funnel_url"
    else
        # Ask for URL or use default
        if funnel_url=$(ask_tailscale_funnel_url); then
            # Save the URL to a file for status checking
            echo "$funnel_url" > "$TAILSCALE_URL_FILE"
            print_success "Tailscale Funnel URL saved: $funnel_url"
        else
            print_error "No Tailscale Funnel URL provided"
            rm -f "$TAILSCALE_FUNNEL_PID_FILE"
            return 1
        fi
    fi

    print_status "Public URL: https://$funnel_url"
    return 0
}

# Function to stop Tailscale Funnel
stop_tailscale_funnel() {
    local quiet_mode=${1:-false}
    if is_running "$TAILSCALE_FUNNEL_PID_FILE"; then
        print_status "Tailscale Funnel is running manually"
        print_status "Please stop it yourself with: Ctrl+C in the terminal where you ran 'tailscale funnel'"
        rm -f "$TAILSCALE_FUNNEL_PID_FILE"
        rm -f "$TAILSCALE_URL_FILE"
        print_success "Tailscale Funnel tracking stopped"
    elif [ "$quiet_mode" != "true" ]; then
        print_warning "Tailscale Funnel is not being tracked by this script"
    fi
}

# Function to check Tailscale Funnel status
check_tailscale_funnel_status() {
    local funnel_status=""
    local funnel_url=""
    local detailed_status=""

    # Read the URL from the saved file first (only first line, clean)
    if [ -f "$TAILSCALE_URL_FILE" ]; then
        funnel_url=$(cat "$TAILSCALE_URL_FILE" 2>/dev/null | head -1 | tr -d '\n')
    fi

    # Check if Tailscale is installed and accessible
    if ! command -v tailscale >/dev/null 2>&1; then
        funnel_status="${RED}TAILSCALE NOT INSTALLED${NC}"
        echo "$funnel_status|$funnel_url|Tailscale command not found"
        return
    fi

    # SKIP LIVE CHECKS - tailscale commands can block Claude
    # Instead, rely on saved state and tracking files
    if is_running "$TAILSCALE_FUNNEL_PID_FILE"; then
        if [ -n "$funnel_url" ]; then
            funnel_status="${GREEN}TRACKED AS RUNNING${NC}"
            detailed_status="Tracked by script (use 'tailscale funnel status' manually to verify)"
        else
            funnel_status="${YELLOW}SCRIPT TRACKING ACTIVE${NC}"
            detailed_status="Tracked but no URL saved"
        fi
    elif [ -n "$funnel_url" ]; then
        funnel_status="${YELLOW}CONFIGURED${NC}"
        detailed_status="URL saved: $funnel_url (use 'tailscale funnel status' to check if active)"
    else
        funnel_status="${YELLOW}STATUS UNKNOWN${NC}"
        detailed_status="Run './dev-server.sh tailscale-status' in your terminal to check"
    fi

    echo "$funnel_status|$funnel_url|$detailed_status"
}

# Function to stop Sidekiq
stop_sidekiq() {
    local quiet_mode=${1:-false}
    if is_running "$SIDEKIQ_PID_FILE"; then
        local pid=$(cat "$SIDEKIQ_PID_FILE")
        print_status "Stopping Sidekiq (PID: $pid)..."
        kill "$pid"
        rm -f "$SIDEKIQ_PID_FILE"
        print_success "Sidekiq stopped"
    elif [ "$quiet_mode" != "true" ]; then
        print_warning "Sidekiq is not running"
    fi
}

# Function to check ngrok status
check_ngrok_status() {
    local ngrok_status=""
    local ngrok_url=""

    # Try to connect to ngrok's local API with 2 second timeout
    if curl -s --max-time 2 http://localhost:4040/api/tunnels >/dev/null 2>&1; then
        local tunnels_json=$(curl -s --max-time 2 http://localhost:4040/api/tunnels 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$tunnels_json" ]; then
            # Find HTTPS tunnel pointing to port 3000
            ngrok_url=$(echo "$tunnels_json" | grep -o '"public_url":"https://[^"]*"' | grep -o 'https://[^"]*' | head -1)
            if [ -n "$ngrok_url" ]; then
                ngrok_status="${GREEN}RUNNING${NC}"
            else
                ngrok_status="${YELLOW}RUNNING (no HTTPS tunnel to port 3000)${NC}"
            fi
        else
            ngrok_status="${RED}API ERROR${NC}"
        fi
    else
        ngrok_status="${RED}NOT RUNNING${NC}"
    fi

    echo "$ngrok_status|$ngrok_url"
}

# Function to show detailed Tailscale status
show_tailscale_status() {
    echo -e "\n${BLUE}=== Tailscale Status Check ===${NC}"

    # Check if Tailscale is installed
    if ! command -v tailscale >/dev/null 2>&1; then
        echo -e "${RED}✗ Tailscale not installed${NC}"
        echo -e "Install with: ${YELLOW}brew install tailscale${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ Tailscale installed${NC}"

    # Check Tailscale status with timeout (using perl for macOS compatibility)
    local tailscale_status_output=$(perl -e 'alarm 3; exec @ARGV' tailscale status 2>/dev/null || echo "")
    if [ -z "$tailscale_status_output" ]; then
        echo -e "${RED}✗ Tailscale not authenticated${NC}"
        echo -e "Run: ${YELLOW}tailscale up${NC}"
        return 1
    fi

    if echo "$tailscale_status_output" | grep -q "Logged out"; then
        echo -e "${RED}✗ Tailscale logged out${NC}"
        echo -e "Run: ${YELLOW}tailscale up${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ Tailscale authenticated and logged in${NC}"

    # Show machine name and tailnet
    local machine_name=$(echo "$tailscale_status_output" | head -1 | awk '{print $1}')
    local tailnet=$(echo "$tailscale_status_output" | grep -o "[^[:space:]]*\.ts\.net" | head -1)

    if [ -n "$machine_name" ]; then
        echo -e "Machine: ${BLUE}$machine_name${NC}"
    fi
    if [ -n "$tailnet" ]; then
        echo -e "Tailnet: ${BLUE}$tailnet${NC}"
    fi

    # Check Funnel capability and status with timeout (using perl for macOS compatibility)
    local tailscale_funnel_output=$(perl -e 'alarm 3; exec @ARGV' tailscale funnel status 2>/dev/null || echo "")

    if echo "$tailscale_funnel_output" | grep -q "funnel not enabled"; then
        echo -e "${RED}✗ Funnel not enabled for this tailnet${NC}"
        echo -e "Enable in Tailscale admin console: ${YELLOW}https://login.tailscale.com/admin/settings/features${NC}"
        return 1
    fi

    if echo "$tailscale_funnel_output" | grep -q "no funnel configured"; then
        echo -e "${YELLOW}⚠ Funnel enabled but not configured${NC}"
        echo -e "Start with: ${YELLOW}tailscale funnel $TAILSCALE_PORT${NC}"
        return 0
    fi

    if echo "$tailscale_funnel_output" | grep -q "Funnel on"; then
        echo -e "${GREEN}✓ Funnel is active${NC}"

        # Show active funnels
        echo -e "\n${BLUE}Active Funnels:${NC}"
        echo "$tailscale_funnel_output" | grep -E "(https://.*\.ts\.net|:[0-9]+)" | while read -r line; do
            if [[ "$line" =~ https://.*\.ts\.net ]]; then
                local url=$(echo "$line" | grep -oE 'https://[^[:space:]]*\.ts\.net[^[:space:]]*')
                echo -e "  ${GREEN}$url${NC}"
            elif [[ "$line" =~ :[0-9]+ ]]; then
                echo -e "  ${BLUE}$line${NC}"
            fi
        done

        # Check if our specific port is being funneled
        if echo "$tailscale_funnel_output" | grep -q ":$TAILSCALE_PORT"; then
            echo -e "\n${GREEN}✓ Port $TAILSCALE_PORT is being funneled${NC}"
        else
            echo -e "\n${YELLOW}⚠ Port $TAILSCALE_PORT is not being funneled${NC}"
            echo -e "Run: ${YELLOW}tailscale funnel $TAILSCALE_PORT${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Funnel status unclear${NC}"
        echo -e "Try: ${YELLOW}tailscale funnel $TAILSCALE_PORT${NC}"
    fi

    echo ""
}
show_status() {
    echo -e "\n${BLUE}=== Chatwoot Development Server Status ===${NC}"
    echo -e "Ruby Version: ${GREEN}$(ruby --version)${NC}"
    echo -e "Bundler Version: ${GREEN}$(bundle --version)${NC}"
    echo ""
    
    if is_running "$RAILS_PID_FILE"; then
        echo -e "Rails Server: ${GREEN}RUNNING${NC} (PID: $(cat $RAILS_PID_FILE))"
        echo -e "Local URL: ${BLUE}http://localhost:10750${NC}"
    else
        echo -e "Rails Server: ${RED}STOPPED${NC}"
    fi
    
    if is_running "$SIDEKIQ_PID_FILE"; then
        echo -e "Sidekiq: ${GREEN}RUNNING${NC} (PID: $(cat $SIDEKIQ_PID_FILE))"
    else
        echo -e "Sidekiq: ${RED}STOPPED${NC}"
    fi
    
    # Nginx status output disabled
    # if is_nginx_running; then
    #     echo -e "Nginx: ${GREEN}RUNNING${NC}"
    #     echo -e "HTTPS URL: ${BLUE}https://$CUSTOM_DOMAIN${NC}"
    # else
    #     echo -e "Nginx: ${RED}STOPPED${NC}"
    # fi
    
    # Ngrok status output disabled
    # Check ngrok status
    local ngrok_info=$(check_ngrok_status)
    local ngrok_status=$(echo "$ngrok_info" | cut -d'|' -f1)
    local ngrok_url=$(echo "$ngrok_info" | cut -d'|' -f2)

    # if is_running "$NGROK_PID_FILE"; then
    #     echo -e "Ngrok: ${GREEN}RUNNING${NC} (PID: $(cat $NGROK_PID_FILE))"
    # else
    #     echo -e "Ngrok: $ngrok_status"
    # fi

    # Check Tailscale Funnel status
    local tailscale_info=$(check_tailscale_funnel_status)
    local tailscale_status=$(echo "$tailscale_info" | cut -d'|' -f1)
    local tailscale_url=$(echo "$tailscale_info" | cut -d'|' -f2)
    local tailscale_details=$(echo "$tailscale_info" | cut -d'|' -f3)

    # Display Tailscale Funnel status with URL and details if available
    if echo "$tailscale_status" | grep -q "RUNNING"; then
        if [ -n "$tailscale_url" ]; then
            echo -e "Tailscale Funnel: $tailscale_status (URL: $tailscale_url)"
        else
            echo -e "Tailscale Funnel: $tailscale_status"
        fi
        if [ -n "$tailscale_details" ]; then
            echo -e "  └─ $tailscale_details"
        fi
    else
        echo -e "Tailscale Funnel: $tailscale_status"
        if [ -n "$tailscale_details" ]; then
            echo -e "  └─ $tailscale_details"
        fi
    fi

    # Determine which public URL to show based on what's actually running
    if echo "$tailscale_status" | grep -q "RUNNING" && [ -n "$tailscale_url" ]; then
        echo -e "HTTPS URL: ${BLUE}https://$tailscale_url${NC}"
        echo -e "${YELLOW}Note: Apple Messages for Business attachments will use Tailscale Funnel URLs${NC}"
    elif [ "$USE_CUSTOM_DOMAIN" = true ] && is_nginx_running; then
        echo -e "HTTPS URL: ${BLUE}https://$CUSTOM_DOMAIN${NC}"
        echo -e "${YELLOW}Note: Apple Messages for Business attachments will use custom domain URLs${NC}"
        echo -e "${YELLOW}Ensure port forwarding is configured: External port 3000 -> Internal IP:3000${NC}"
    elif [ -n "$ngrok_url" ]; then
        echo -e "Public URL: ${BLUE}$ngrok_url${NC}"
        echo -e "${YELLOW}Note: Apple Messages for Business attachments will use ngrok URLs${NC}"
    else
        echo -e "${YELLOW}Note: Apple Messages for Business attachments will use localhost URLs${NC}"
    fi
    echo ""
}

# Function to restart services
restart_services() {
    print_status "Restarting development services..."
    stop_rails true
    stop_sidekiq true
    if [ "$USE_CUSTOM_DOMAIN" = true ]; then
        stop_nginx
    elif [ "$USE_TAILSCALE_FUNNEL" = true ]; then
        stop_tailscale_funnel true
    else
        stop_ngrok true
    fi
    sleep 2
    if [ "$USE_CUSTOM_DOMAIN" = true ]; then
        start_nginx
    elif [ "$USE_TAILSCALE_FUNNEL" = true ]; then
        start_tailscale_funnel
    else
        start_ngrok
    fi
    start_rails
    start_sidekiq
    show_status
}

# Function to start all services with custom domain, Tailscale Funnel, or ngrok coordination
start_all_services() {
    if [ "$USE_CUSTOM_DOMAIN" = true ]; then
        print_status "Starting Chatwoot development server with custom domain ($CUSTOM_DOMAIN)..."
        cleanup_stale_processes

        print_status "Using custom domain: https://$CUSTOM_DOMAIN"
        print_status "Ensure your Freebox port forwarding is configured:"
        print_status "  External port 3000 -> Internal IP ($(ipconfig getifaddr en0 || echo '192.168.1.x')):3000"

        start_nginx
        start_rails
        start_sidekiq
        show_status
    elif [ "$USE_TAILSCALE_FUNNEL" = true ]; then
        print_status "Starting Chatwoot development server with Tailscale Funnel..."
        cleanup_stale_processes

        # Start Tailscale Funnel first so Rails can detect it
        start_tailscale_funnel
        if [ $? -eq 0 ]; then
            print_status "Tailscale Funnel established, starting Rails server..."
            sleep 2  # Give Tailscale Funnel a moment to fully establish
        else
            print_warning "Tailscale Funnel failed to start, continuing with localhost only..."
        fi

        start_rails
        start_sidekiq
        show_status
    else
        print_status "Starting Chatwoot development server with ngrok..."
        cleanup_stale_processes

        # Start ngrok first so Rails can detect it
        start_ngrok
        if [ $? -eq 0 ]; then
            print_status "Ngrok tunnel established, starting Rails server..."
            sleep 2  # Give ngrok a moment to fully establish
        else
            print_warning "Ngrok failed to start, continuing with localhost only..."
        fi

        start_rails
        start_sidekiq
        show_status
    fi
}

# Function to stop all services
stop_all_services() {
    print_status "Stopping Chatwoot development server..."
    stop_rails
    stop_sidekiq
    if [ "$USE_CUSTOM_DOMAIN" = true ]; then
        stop_nginx
    elif [ "$USE_TAILSCALE_FUNNEL" = true ]; then
        stop_tailscale_funnel
    else
        stop_ngrok
    fi
    show_status
}

# Function to show help
show_help() {
    echo -e "\n${BLUE}Chatwoot Development Server Management${NC}"
    echo -e "Usage: $0 {start|start-public|stop|restart|status|nginx-start|nginx-stop|nginx-reload|ngrok-start|ngrok-stop|tailscale-start|tailscale-stop|tailscale-status|help}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  start            - Start Rails server and Sidekiq (localhost only)"
    echo -e "  start-public     - Start all services with public access (custom domain, Tailscale Funnel, or ngrok)"
    echo -e "  stop             - Stop all services"
    echo -e "  restart          - Restart all services with public access"
    echo -e "  status           - Show current status of all services"
    echo -e "  nginx-start      - Start nginx server only (when USE_CUSTOM_DOMAIN=true)"
    echo -e "  nginx-stop       - Stop nginx server only"
    echo -e "  nginx-reload     - Reload nginx configuration"
    echo -e "  ngrok-start      - Start ngrok tunnel only"
    echo -e "  ngrok-stop       - Stop ngrok tunnel only"
    echo -e "  tailscale-start  - Start Tailscale Funnel only"
    echo -e "  tailscale-stop   - Stop Tailscale Funnel only"
    echo -e "  tailscale-status - Check detailed Tailscale and Funnel status"
    echo -e "  help             - Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    if [ "$USE_CUSTOM_DOMAIN" = true ]; then
        echo -e "  $0 start-public    # Start with custom domain: https://$CUSTOM_DOMAIN"
        echo -e "  $0 nginx-start     # Start nginx HTTPS proxy only"
        echo -e "  $0 nginx-reload    # Reload nginx configuration"
    elif [ "$USE_TAILSCALE_FUNNEL" = true ]; then
        echo -e "  $0 start-public      # Start with Tailscale Funnel"
        echo -e "  $0 tailscale-start   # Start Tailscale Funnel only"
        echo -e "  $0 tailscale-status  # Check Tailscale authentication and Funnel status"
    else
        echo -e "  $0 start-public    # Start with ngrok tunnel"
        echo -e "  $0 ngrok-start     # Start ngrok tunnel only"
    fi
    echo -e "  $0 start         # Start with localhost only"
    echo -e "  $0 stop          # Stop all services"
    echo -e "  $0 status        # Check if services are running"
    echo -e "  $0 tailscale-status # Detailed Tailscale diagnostics"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    if [ "$USE_CUSTOM_DOMAIN" = true ]; then
        echo -e "  Current mode: Custom Domain ($CUSTOM_DOMAIN)"
        echo -e "  Ensure Freebox port forwarding: External 3000 -> Internal $(ipconfig getifaddr en0 || echo 'YOUR_MAC_IP'):3000"
        echo -e "  Nginx config: /opt/homebrew/etc/nginx/servers/dev.rhaps.net.conf"
    elif [ "$USE_TAILSCALE_FUNNEL" = true ]; then
        echo -e "  Current mode: Tailscale Funnel"
        echo -e "  Ensure Tailscale is logged in and Funnel is enabled for your tailnet"
        echo -e "  Edit USE_TAILSCALE_FUNNEL=false to use ngrok instead"
    else
        echo -e "  Current mode: Ngrok"
        echo -e "  Edit NGROK_SUBDOMAIN for custom ngrok subdomain (requires account)"
        echo -e "  Edit USE_TAILSCALE_FUNNEL=true to use Tailscale Funnel instead"
    fi
    echo -e "  Edit USE_CUSTOM_DOMAIN, USE_TAILSCALE_FUNNEL variables in this script"
    echo ""
}

# Main script logic
case "$1" in
    start)
        print_status "Starting Chatwoot development server (localhost only)..."
        cleanup_stale_processes
        start_rails
        start_sidekiq
        show_status
        ;;
    start-public|start-with-ngrok)
        start_all_services
        ;;
    stop)
        stop_all_services
        ;;
    restart)
        cleanup_stale_processes
        restart_services
        ;;
    status)
        show_status
        ;;
    nginx-start)
        if [ "$USE_CUSTOM_DOMAIN" = true ]; then
            start_nginx
        else
            print_warning "Ngrok mode is enabled. Use 'ngrok-start' instead."
            print_status "To use nginx, set USE_CUSTOM_DOMAIN=true in this script."
        fi
        ;;
    nginx-stop)
        stop_nginx
        ;;
    nginx-reload)
        reload_nginx
        ;;
    ngrok-start)
        if [ "$USE_CUSTOM_DOMAIN" = true ]; then
            print_warning "Custom domain mode is enabled. Use 'nginx-start' instead."
            print_status "To use ngrok, set USE_CUSTOM_DOMAIN=false in this script."
        else
            start_ngrok
        fi
        ;;
    ngrok-stop)
        stop_ngrok
        ;;
    tailscale-start)
        start_tailscale_funnel
        ;;
    tailscale-stop)
        stop_tailscale_funnel
        ;;
    tailscale-status)
        show_tailscale_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Invalid command: $1"
        show_help
        exit 1
        ;;
esac