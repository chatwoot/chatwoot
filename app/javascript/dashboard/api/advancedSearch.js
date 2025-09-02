/* global axios */
import ApiClient from './ApiClient';

class AdvancedSearchAPI extends ApiClient {
  constructor() {
    super('advanced_search', { accountScoped: true });
  }

  // Main search endpoint - searches across all types
  search(params) {
    return axios.get(this.url, { params });
  }

  // Type-specific search endpoints
  conversations(params) {
    return axios.get(`${this.url}/conversations`, { params });
  }

  messages(params) {
    return axios.get(`${this.url}/messages`, { params });
  }

  contacts(params) {
    return axios.get(`${this.url}/contacts`, { params });
  }

  // Get search suggestions
  suggestions(params) {
    return axios.get(`${this.url}/suggestions`, { params });
  }

  // Get available filters for the account
  getFilters() {
    return axios.get(`${this.url}/filters`);
  }

  // Saved searches
  getSavedSearches() {
    return axios.get(`${this.url}/saved_searches`);
  }

  createSavedSearch(searchData) {
    return axios.post(`${this.url}/saved_searches`, {
      saved_search: searchData
    });
  }

  updateSavedSearch(searchId, searchData) {
    return axios.put(`${this.url}/saved_searches/${searchId}`, {
      saved_search: searchData
    });
  }

  deleteSavedSearch(searchId) {
    return axios.delete(`${this.url}/saved_searches/${searchId}`);
  }

  incrementSearchUsage(searchId) {
    return axios.post(`${this.url}/saved_searches/${searchId}/increment_usage`);
  }

  // Performance and analytics
  getSearchAnalytics(timeframe = '7d') {
    return axios.get(`${this.url}/analytics`, {
      params: { timeframe }
    });
  }

  getSlowQueries(limit = 50) {
    return axios.get(`${this.url}/slow_queries`, {
      params: { limit }
    });
  }

  // Utility methods for building search parameters
  static buildParams(searchParams) {
    const params = {};

    // Basic search
    if (searchParams.query) {
      params.q = searchParams.query;
    }

    // Pagination
    if (searchParams.page) {
      params.page = searchParams.page;
    }
    if (searchParams.per_page) {
      params.per_page = searchParams.per_page;
    }

    // Array filters - convert arrays to comma-separated strings
    const arrayFilters = [
      'channel_types', 'inbox_ids', 'agent_ids', 'team_ids', 'tags', 'labels',
      'status', 'priority', 'message_types', 'sender_types', 'sentiment', 'sla_status'
    ];

    arrayFilters.forEach(filter => {
      if (searchParams[filter] && Array.isArray(searchParams[filter]) && searchParams[filter].length > 0) {
        params[filter] = searchParams[filter].join(',');
      }
    });

    // Date filters
    if (searchParams.date_from) {
      params.date_from = this.formatDate(searchParams.date_from);
    }
    if (searchParams.date_to) {
      params.date_to = this.formatDate(searchParams.date_to);
    }

    // Boolean filters
    const booleanFilters = [
      'has_attachments', 'unread_only', 'assigned_only', 'unassigned_only'
    ];

    booleanFilters.forEach(filter => {
      if (searchParams[filter] === true) {
        params[filter] = 'true';
      }
    });

    // Custom attributes (JSON string)
    if (searchParams.custom_attributes) {
      params.custom_attributes = searchParams.custom_attributes;
    }

    return params;
  }

  static formatDate(date) {
    if (typeof date === 'string') return date;
    if (date instanceof Date) {
      return date.toISOString().split('T')[0]; // YYYY-MM-DD format
    }
    return date;
  }

  // Advanced search with automatic parameter building
  advancedSearch(searchType, searchParams) {
    const params = AdvancedSearchAPI.buildParams(searchParams);

    switch (searchType) {
      case 'conversations':
        return this.conversations(params);
      case 'messages':
        return this.messages(params);
      case 'contacts':
        return this.contacts(params);
      default:
        return this.search(params);
    }
  }

  // Search with performance tracking
  async performanceSearch(searchType, searchParams) {
    const startTime = performance.now();
    
    try {
      const result = await this.advancedSearch(searchType, searchParams);
      const endTime = performance.now();
      const duration = endTime - startTime;

      // Log performance metrics
      console.info(`Search completed in ${duration.toFixed(2)}ms`, {
        searchType,
        queryLength: searchParams.query?.length || 0,
        filtersCount: this.countActiveFilters(searchParams),
        resultsCount: result.data.meta?.total_results || 0
      });

      // Warn about slow searches
      if (duration > 300) {
        console.warn(`Slow search detected: ${duration.toFixed(2)}ms`, searchParams);
      }

      return result;
    } catch (error) {
      const endTime = performance.now();
      const duration = endTime - startTime;
      
      console.error(`Search failed after ${duration.toFixed(2)}ms`, error);
      throw error;
    }
  }

  static countActiveFilters(searchParams) {
    let count = 0;

    // Array filters
    const arrayFilters = [
      'channel_types', 'inbox_ids', 'agent_ids', 'team_ids', 'tags', 'labels',
      'status', 'priority', 'message_types', 'sender_types', 'sentiment', 'sla_status'
    ];

    arrayFilters.forEach(filter => {
      if (searchParams[filter] && Array.isArray(searchParams[filter]) && searchParams[filter].length > 0) {
        count++;
      }
    });

    // Date filters
    if (searchParams.date_from) count++;
    if (searchParams.date_to) count++;

    // Boolean filters
    const booleanFilters = [
      'has_attachments', 'unread_only', 'assigned_only', 'unassigned_only'
    ];

    booleanFilters.forEach(filter => {
      if (searchParams[filter] === true) {
        count++;
      }
    });

    // Custom attributes
    if (searchParams.custom_attributes) count++;

    return count;
  }

  // Batch search for multiple queries
  async batchSearch(searches) {
    const promises = searches.map(({ type, params }) => 
      this.advancedSearch(type, params)
    );

    try {
      const results = await Promise.allSettled(promises);
      return results.map((result, index) => ({
        ...searches[index],
        success: result.status === 'fulfilled',
        data: result.status === 'fulfilled' ? result.value.data : null,
        error: result.status === 'rejected' ? result.reason : null
      }));
    } catch (error) {
      console.error('Batch search failed:', error);
      throw error;
    }
  }

  // Search with caching
  async cachedSearch(searchType, searchParams, cacheKey = null) {
    if (!cacheKey) {
      cacheKey = this.generateCacheKey(searchType, searchParams);
    }

    // Check cache first (if localStorage is available)
    if (typeof Storage !== 'undefined') {
      const cached = localStorage.getItem(cacheKey);
      if (cached) {
        const { data, timestamp } = JSON.parse(cached);
        const cacheAge = Date.now() - timestamp;
        
        // Cache valid for 5 minutes
        if (cacheAge < 5 * 60 * 1000) {
          console.info('Returning cached search result', { cacheKey, cacheAge });
          return { data };
        }
      }
    }

    // Perform fresh search
    try {
      const result = await this.advancedSearch(searchType, searchParams);
      
      // Cache the result
      if (typeof Storage !== 'undefined') {
        const cacheData = {
          data: result.data,
          timestamp: Date.now()
        };
        localStorage.setItem(cacheKey, JSON.stringify(cacheData));
        
        // Clean up old cache entries
        this.cleanupCache();
      }

      return result;
    } catch (error) {
      // Return cached data if available, even if stale
      if (typeof Storage !== 'undefined') {
        const cached = localStorage.getItem(cacheKey);
        if (cached) {
          console.warn('Search failed, returning stale cache', error);
          return { data: JSON.parse(cached).data };
        }
      }
      throw error;
    }
  }

  generateCacheKey(searchType, searchParams) {
    const keyData = {
      type: searchType,
      query: searchParams.query,
      filters: Object.keys(searchParams)
        .filter(key => key !== 'page' && key !== 'per_page')
        .sort()
        .reduce((obj, key) => {
          obj[key] = searchParams[key];
          return obj;
        }, {})
    };

    return `advanced_search_${btoa(JSON.stringify(keyData)).replace(/[+/=]/g, '_')}`;
  }

  cleanupCache() {
    if (typeof Storage === 'undefined') return;

    const keys = Object.keys(localStorage);
    const searchKeys = keys.filter(key => key.startsWith('advanced_search_'));
    
    // Remove old cache entries (older than 1 hour)
    searchKeys.forEach(key => {
      try {
        const cached = localStorage.getItem(key);
        if (cached) {
          const { timestamp } = JSON.parse(cached);
          const age = Date.now() - timestamp;
          
          if (age > 60 * 60 * 1000) { // 1 hour
            localStorage.removeItem(key);
          }
        }
      } catch (error) {
        localStorage.removeItem(key); // Remove corrupted cache entries
      }
    });
  }
}

export default new AdvancedSearchAPI();