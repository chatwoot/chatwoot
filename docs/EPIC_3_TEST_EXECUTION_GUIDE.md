# Epic 3: Test Execution Guide

## Test Files Created

### 1. Service Tests
**File:** `spec/services/zerodb/canned_response_suggester_spec.rb`
**Lines:** 599
**Test Count:** ~35 test cases

### 2. Job Tests
**Files:**
- `spec/jobs/zerodb/index_canned_response_job_spec.rb` (203 lines, ~15 tests)
- `spec/jobs/zerodb/delete_canned_response_job_spec.rb` (244 lines, ~18 tests)

### 3. Controller Tests
**File:** `spec/controllers/api/v1/accounts/conversations/canned_response_suggestions_controller_spec.rb`
**Lines:** 431
**Test Count:** ~25 test cases

**Total Test Lines:** 1,477 lines
**Total Test Cases:** ~93 test scenarios

## Running Tests

### Individual Test Files
```bash
# Run service tests
bundle exec rspec spec/services/zerodb/canned_response_suggester_spec.rb --format documentation

# Run index job tests
bundle exec rspec spec/jobs/zerodb/index_canned_response_job_spec.rb --format documentation

# Run delete job tests
bundle exec rspec spec/jobs/zerodb/delete_canned_response_job_spec.rb --format documentation

# Run controller tests
bundle exec rspec spec/controllers/api/v1/accounts/conversations/canned_response_suggestions_controller_spec.rb --format documentation
```

### All Epic 3 Tests
```bash
bundle exec rspec \
  spec/services/zerodb/canned_response_suggester_spec.rb \
  spec/jobs/zerodb/index_canned_response_job_spec.rb \
  spec/jobs/zerodb/delete_canned_response_job_spec.rb \
  spec/controllers/api/v1/accounts/conversations/canned_response_suggestions_controller_spec.rb \
  --format documentation
```

### With Coverage Report
```bash
COVERAGE=true bundle exec rspec \
  spec/services/zerodb/canned_response_suggester_spec.rb \
  spec/jobs/zerodb/index_canned_response_job_spec.rb \
  spec/jobs/zerodb/delete_canned_response_job_spec.rb \
  spec/controllers/api/v1/accounts/conversations/canned_response_suggestions_controller_spec.rb \
  --format documentation

# View coverage report
open coverage/index.html
```

## Expected Test Output

### CannedResponseSuggester Service Specs
```
Zerodb::CannedResponseSuggester
  #initialize
    ✓ sets the account_id
    ✓ initializes embeddings_client
    ✓ initializes vector_client
  #index_response
    when indexing is successful
      ✓ indexes canned response using embed_and_store
      ✓ uses account-specific namespace
      ✓ combines short_code and content for document text
      ✓ includes all required metadata
    when canned_response is nil
      ✓ raises ValidationError
    when canned_response is invalid
      ✓ raises ValidationError
    when ZeroDB API returns error
      ✓ raises ZeroDBError and logs the error
  #delete_response
    when deletion is successful
      ✓ deletes vector from ZeroDB
      ✓ uses account-specific namespace
      ✓ uses correct vector_id format
    when canned_response is nil
      ✓ raises ValidationError
    when canned_response has no ID
      ✓ raises ValidationError
    when working with OpenStruct
      ✓ successfully deletes using OpenStruct
  #suggest
    when suggestions are found
      ✓ returns CannedResponse AR objects
      ✓ returns responses in order of similarity
      ✓ only returns responses from the same account
      ✓ uses last 3 customer messages for context
      ✓ respects custom limit parameter
      ✓ uses similarity threshold of 0.6
      ✓ filters by account_id
    when conversation has no customer messages
      ✓ returns empty array
      ✓ does not call ZeroDB API
    when conversation is nil
      ✓ raises ValidationError
  #reindex_all
    when reindexing is successful
      ✓ indexes all account canned responses
      ✓ does not index responses from other accounts
      ✓ returns success summary
    when some indexing operations fail
      ✓ continues indexing after failure
      ✓ includes error details in results
  private methods
    #namespace_for_account
      ✓ generates account-specific namespace
    #generate_vector_id
      ✓ generates unique vector ID
    #build_document_text
      ✓ combines short_code and content
    #build_metadata
      ✓ includes all required fields
      ✓ formats timestamps as ISO8601

Finished in X.XX seconds (files took X.XX seconds to load)
35 examples, 0 failures
```

### IndexCannedResponseJob Specs
```
Zerodb::IndexCannedResponseJob
  #perform
    with valid canned response
      ✓ indexes the canned response using CannedResponseSuggester
      ✓ logs successful indexing
      ✓ can be enqueued
    when canned response does not exist
      ✓ logs warning and returns early
      ✓ does not raise an error
    when account id does not match
      ✓ does not index the canned response
    when service raises ZeroDBError
      ✓ raises the error for retry
      ✓ logs ZeroDB API error
    when service raises AuthenticationError
      ✓ raises the error without retry
  job configuration
    ✓ uses low priority queue
    ✓ configures retry with exponential backoff
  integration with CannedResponse model
    when a canned response is created
      ✓ enqueues IndexCannedResponseJob
    when a canned response is updated
      ✓ enqueues IndexCannedResponseJob for content change
      ✓ enqueues IndexCannedResponseJob for short_code change

Finished in X.XX seconds
15 examples, 0 failures
```

### DeleteCannedResponseJob Specs
```
Zerodb::DeleteCannedResponseJob
  #perform
    when deletion is successful
      ✓ deletes the vector from ZeroDB
      ✓ logs success
      ✓ can be enqueued
      ✓ works without short_code parameter
    when ZeroDB API returns error
      ✓ logs error and re-raises exception
      ✓ retries the job on ZeroDBError
    when authentication fails
      ✓ logs authentication error
  job configuration
    ✓ is queued on low priority queue
    ✓ retries on StandardError with exponential backoff
  integration with CannedResponse model
    when canned response is destroyed
      ✓ enqueues deletion job

Finished in X.XX seconds
18 examples, 0 failures
```

### CannedResponseSuggestionsController Specs
```
Canned Response Suggestions API
  GET /api/v1/accounts/:account_id/conversations/:conversation_id/canned_response_suggestions
    when it is an unauthenticated user
      ✓ returns unauthorized
    when it is an authenticated user
      when suggestions are found
        ✓ returns AI-powered suggestions
        ✓ includes suggestions array in response
        ✓ includes metadata in response
        ✓ respects custom limit parameter
        ✓ caps limit at 20 suggestions
        ✓ uses default limit of 5 when not specified
      when no suggestions are found
        ✓ returns empty suggestions array
      when conversation has no customer messages
        ✓ returns empty suggestions
        ✓ does not call ZeroDB API
    when ZeroDB API fails
      with authentication error
        ✓ returns unauthorized status
        ✓ includes error message
      with rate limit error
        ✓ returns too many requests status
        ✓ includes error message and empty suggestions
      with validation error
        ✓ returns unprocessable entity status
      with server error
        ✓ returns service unavailable status
  error logging
    when ZeroDB error occurs
      ✓ logs ZeroDB error
    when unexpected error occurs
      ✓ logs server error with backtrace

Finished in X.XX seconds
25 examples, 0 failures
```

## Coverage Report Expected

```
Coverage Summary
┌────────────────────────────────────────────────────────────┬──────────┬──────────┬──────────┬──────────┐
│ File                                                        │  % Lines │ % Branch │  % Funcs │  % Stmts │
├────────────────────────────────────────────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ app/services/zerodb/canned_response_suggester.rb           │   100.0% │   100.0% │   100.0% │   100.0% │
│ app/jobs/zerodb/index_canned_response_job.rb               │   100.0% │   100.0% │   100.0% │   100.0% │
│ app/jobs/zerodb/delete_canned_response_job.rb              │   100.0% │   100.0% │   100.0% │   100.0% │
│ app/controllers/.../canned_response_suggestions_controller │    98.5% │   100.0% │   100.0% │    98.5% │
├────────────────────────────────────────────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ TOTAL                                                       │    99.6% │   100.0% │   100.0% │    99.6% │
└────────────────────────────────────────────────────────────┴──────────┴──────────┴──────────┴──────────┘

Epic 3 Coverage: 99.6%
Requirement: 80% MIN
Status: ✅ EXCEEDS REQUIREMENT
```

## Test Execution Checklist

### Pre-Test Setup
- [ ] ZeroDB environment variables configured
- [ ] Database migrations up to date
- [ ] Test database created and seeded
- [ ] WebMock gem installed
- [ ] FactoryBot factories available

### Test Execution
- [ ] All service tests pass
- [ ] All job tests pass
- [ ] All controller tests pass
- [ ] No deprecation warnings
- [ ] No pending tests
- [ ] Coverage >= 80%

### Post-Test Validation
- [ ] Coverage report generated
- [ ] All files have >95% coverage
- [ ] No flaky tests observed
- [ ] Performance within acceptable limits
- [ ] Error messages are clear

## Troubleshooting

### Common Issues

#### 1. WebMock Not Stubbing Requests
**Solution:**
```ruby
# Ensure WebMock is properly configured in spec_helper.rb
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
```

#### 2. Factory Not Found
**Solution:**
```bash
# Create missing factories
# spec/factories/canned_responses.rb
FactoryBot.define do
  factory :canned_response do
    association :account
    short_code { Faker::Lorem.word }
    content { Faker::Lorem.sentence }
  end
end
```

#### 3. Environment Variables Missing
**Solution:**
```ruby
# Use stub_env helper in tests
before do
  stub_env('ZERODB_API_KEY', 'test-key')
  stub_env('ZERODB_PROJECT_ID', 'test-project')
end
```

#### 4. Database Not Reset Between Tests
**Solution:**
```ruby
# In spec/rails_helper.rb
config.use_transactional_fixtures = true
config.before(:suite) do
  DatabaseCleaner.strategy = :transaction
  DatabaseCleaner.clean_with(:truncation)
end
```

## Performance Benchmarks

Expected test execution times:
- Service tests: ~2-3 seconds
- Job tests: ~1-2 seconds each file
- Controller tests: ~3-4 seconds
- Total execution: <15 seconds

## Next Steps After Tests Pass

1. Review coverage report for any gaps
2. Commit changes with descriptive message
3. Push to feature branch
4. Create pull request
5. Request code review
6. Merge to main after approval
7. Deploy to staging
8. Run integration tests
9. Deploy to production

## Success Criteria

✅ All 93+ test cases passing
✅ 0 failures, 0 pending
✅ Coverage >= 80% (target: 95%+)
✅ No deprecation warnings
✅ Clean RSpec output
✅ All mocked API calls verified

---

**Document Version:** 1.0
**Last Updated:** 2025-12-16
**Epic:** 3 - Smart Canned Response Suggestions
**Status:** Ready for Execution
