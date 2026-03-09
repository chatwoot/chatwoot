#!/usr/bin/env pwsh
# Docker Test Runner for Chatwit
# Usage: ./test-docker.ps1 [test-type] [specific-test]
# Examples:
#   ./test-docker.ps1                    # Run all tests
#   ./test-docker.ps1 rspec              # Run RSpec tests only
#   ./test-docker.ps1 rspec spec/models  # Run specific RSpec tests
#   ./test-docker.ps1 jest               # Run Jest tests only

param(
    [string]$TestType = "all",
    [string]$SpecificTest = ""
)

Write-Host "🐳 Starting Docker test environment..." -ForegroundColor Blue

# Build test image
Write-Host "Building test image..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml build test

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build test image" -ForegroundColor Red
    exit 1
}

# Start dependencies
Write-Host "Starting test dependencies..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml up -d postgres_test redis_test

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Setup test database
Write-Host "Setting up test database..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml run --rm test bundle exec rails db:create db:schema:load

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to setup test database" -ForegroundColor Red
    docker-compose -f docker-compose.test.yml down
    exit 1
}

# Run tests based on type
switch ($TestType.ToLower()) {
    "rspec" {
        Write-Host "🧪 Running RSpec tests..." -ForegroundColor Green
        if ($SpecificTest) {
            docker-compose -f docker-compose.test.yml run --rm test bundle exec rspec $SpecificTest
        } else {
            docker-compose -f docker-compose.test.yml run --rm test bundle exec rspec
        }
    }
    "jest" {
        Write-Host "🧪 Running Jest tests..." -ForegroundColor Green
        if ($SpecificTest) {
            docker-compose -f docker-compose.test.yml run --rm test pnpm test $SpecificTest
        } else {
            docker-compose -f docker-compose.test.yml run --rm test pnpm test
        }
    }
    "socialwise" {
        Write-Host "🧪 Running Socialwise tests..." -ForegroundColor Green
        docker-compose -f docker-compose.test.yml run --rm test bundle exec rspec spec/integration/socialwise_webhook_integration_spec.rb spec/lib/tasks/setup_socialwise_spec.rb spec/lib/integrations/dialogflow/processor_service_spec.rb spec/listeners/webhook_listener_spec.rb
    }
    "all" {
        Write-Host "🧪 Running all tests..." -ForegroundColor Green
        
        # Run RSpec tests
        Write-Host "Running RSpec tests..." -ForegroundColor Cyan
        docker-compose -f docker-compose.test.yml run --rm test bundle exec rspec
        $rspecResult = $LASTEXITCODE
        
        # Run Jest tests
        Write-Host "Running Jest tests..." -ForegroundColor Cyan
        docker-compose -f docker-compose.test.yml run --rm test pnpm test
        $jestResult = $LASTEXITCODE
        
        if ($rspecResult -ne 0 -or $jestResult -ne 0) {
            Write-Host "❌ Some tests failed" -ForegroundColor Red
            $exitCode = 1
        } else {
            Write-Host "✅ All tests passed!" -ForegroundColor Green
            $exitCode = 0
        }
    }
    default {
        Write-Host "❌ Unknown test type: $TestType" -ForegroundColor Red
        Write-Host "Available types: all, rspec, jest, socialwise" -ForegroundColor Yellow
        $exitCode = 1
    }
}

# Cleanup
Write-Host "Cleaning up..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down

if ($exitCode) {
    exit $exitCode
} else {
    Write-Host "🎉 Tests completed successfully!" -ForegroundColor Green
}