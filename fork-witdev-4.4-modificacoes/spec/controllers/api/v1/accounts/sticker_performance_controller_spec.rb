# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Accounts::StickerPerformanceController, type: :controller do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:metrics_service) { instance_double(StickerPerformanceMetricsService) }

  before do
    allow(StickerPerformanceMetricsService).to receive(:instance).and_return(metrics_service)
  end

  describe 'GET #index' do
    context 'when user is administrator' do
      before { sign_in administrator }

      it 'returns performance report' do
        report_data = {
          date: Date.current.strftime('%Y-%m-%d'),
          usage_stats: { 'giphy' => 10 },
          cache_stats: { 'giphy_search' => { hit_rate: 85.0 } },
          api_performance: { 'giphy_api' => { success_rate: 95.0 } }
        }

        expect(metrics_service).to receive(:get_performance_report)
          .with(date: Date.current, account_id: account.id)
          .and_return(report_data)

        get :index, params: { account_id: account.id }

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['performance_report']).to eq(report_data.as_json)
      end

      it 'accepts date parameter' do
        test_date = Date.current - 1.day
        
        expect(metrics_service).to receive(:get_performance_report)
          .with(date: test_date, account_id: account.id)
          .and_return({})

        get :index, params: { account_id: account.id, date: test_date.strftime('%Y-%m-%d') }

        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not authorized' do
      before { sign_in agent }

      it 'returns unauthorized' do
        get :index, params: { account_id: account.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #usage_stats' do
    before { sign_in administrator }

    it 'returns usage statistics for single date' do
      usage_data = { 'giphy' => 5, 'custom' => 3 }
      
      expect(metrics_service).to receive(:get_usage_stats)
        .with(date: Date.current, account_id: account.id)
        .and_return(usage_data)

      get :usage_stats, params: { account_id: account.id }

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['usage_stats']).to eq(usage_data.as_json)
    end

    it 'returns usage statistics for date range' do
      start_date = Date.current - 2.days
      end_date = Date.current
      
      expect(metrics_service).to receive(:get_usage_stats).exactly(3).times
        .and_return({ 'giphy' => 1 })

      get :usage_stats, params: { 
        account_id: account.id,
        start_date: start_date.strftime('%Y-%m-%d'),
        end_date: end_date.strftime('%Y-%m-%d')
      }

      expect(response).to have_http_status(:success)
      response_data = JSON.parse(response.body)
      expect(response_data['usage_stats']).to be_a(Hash)
      expect(response_data['date_range']).to have(3).items
    end
  end

  describe 'GET #cache_performance' do
    before { sign_in administrator }

    it 'returns cache performance statistics' do
      cache_data = {
        'giphy_search' => { hits: 80, misses: 20, total: 100, hit_rate: 80.0 },
        'whatsapp_media' => { hits: 90, misses: 10, total: 100, hit_rate: 90.0 }
      }
      
      expect(metrics_service).to receive(:get_cache_stats)
        .with(date: Date.current)
        .and_return(cache_data)

      get :cache_performance, params: { account_id: account.id }

      expect(response).to have_http_status(:success)
      response_data = JSON.parse(response.body)
      
      expect(response_data['cache_stats']).to eq(cache_data.as_json)
      expect(response_data['summary']['overall_hit_rate']).to eq(85.0)
      expect(response_data['summary']['best_performing_cache']).to eq('whatsapp_media')
      expect(response_data['summary']['worst_performing_cache']).to eq('giphy_search')
    end
  end

  describe 'GET #api_performance' do
    before { sign_in administrator }

    it 'returns API performance statistics' do
      api_data = {
        'giphy_api' => { 
          success_count: 95, 
          failure_count: 5, 
          total_requests: 100, 
          success_rate: 95.0,
          avg_response_time: 150.0
        },
        'whatsapp_api' => { 
          success_count: 98, 
          failure_count: 2, 
          total_requests: 100, 
          success_rate: 98.0,
          avg_response_time: 200.0
        }
      }
      
      expect(metrics_service).to receive(:get_api_performance_stats)
        .with(date: Date.current)
        .and_return(api_data)

      get :api_performance, params: { account_id: account.id }

      expect(response).to have_http_status(:success)
      response_data = JSON.parse(response.body)
      
      expect(response_data['api_performance']).to eq(api_data.as_json)
      expect(response_data['summary']['overall_success_rate']).to eq(96.5)
      expect(response_data['summary']['fastest_api']).to eq('giphy_api')
      expect(response_data['summary']['slowest_api']).to eq('whatsapp_api')
    end
  end

  describe 'POST #benchmark_image_processing' do
    context 'when user is administrator' do
      before { sign_in administrator }

      it 'runs image processing benchmark' do
        benchmark_result = {
          iterations: 3,
          successful: 3,
          failed: 0,
          avg_processing_time: 150.0
        }

        expect(StickerImageOptimizerService).to receive(:benchmark_processing)
          .and_return(benchmark_result)

        post :benchmark_image_processing, params: { account_id: account.id, iterations: 3 }

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        
        expect(response_data['benchmark_result']).to eq(benchmark_result.as_json)
        expect(response_data['test_conditions']['iterations']).to eq(3)
      end
    end

    context 'when user is not administrator' do
      before { sign_in agent }

      it 'returns unauthorized' do
        post :benchmark_image_processing, params: { account_id: account.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #system_health' do
    context 'when user is administrator' do
      before { sign_in administrator }

      it 'returns system health status' do
        allow(Redis.current).to receive(:ping).and_return('PONG')
        allow(MiniMagick::Tool::Identify).to receive(:new).and_return(double(version: '7.0.0'))
        allow(Redis.current).to receive(:info).and_return({
          'used_memory' => '1000000',
          'used_memory_human' => '1MB'
        })

        get :system_health, params: { account_id: account.id }

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        
        expect(response_data['system_health']['redis_status']).to eq('healthy')
        expect(response_data['system_health']['image_processing_status']).to eq('healthy')
        expect(response_data['overall_status']).to eq('healthy')
      end
    end

    context 'when user is not administrator' do
      before { sign_in agent }

      it 'returns unauthorized' do
        get :system_health, params: { account_id: account.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'private methods' do
    let(:controller) { described_class.new }

    describe '#parse_date_param' do
      it 'parses valid date string' do
        allow(controller).to receive(:params).and_return({ date: '2024-01-15' })
        
        result = controller.send(:parse_date_param)
        expect(result).to eq(Date.new(2024, 1, 15))
      end

      it 'returns current date for invalid date' do
        allow(controller).to receive(:params).and_return({ date: 'invalid' })
        
        result = controller.send(:parse_date_param)
        expect(result).to eq(Date.current)
      end

      it 'returns current date when no date provided' do
        allow(controller).to receive(:params).and_return({})
        
        result = controller.send(:parse_date_param)
        expect(result).to eq(Date.current)
      end
    end

    describe '#calculate_overall_hit_rate' do
      it 'calculates correct hit rate' do
        cache_stats = {
          'cache1' => { hits: 80, total: 100 },
          'cache2' => { hits: 60, total: 100 }
        }
        
        result = controller.send(:calculate_overall_hit_rate, cache_stats)
        expect(result).to eq(70.0)
      end

      it 'returns 0 for empty stats' do
        result = controller.send(:calculate_overall_hit_rate, {})
        expect(result).to eq(0)
      end
    end
  end
end