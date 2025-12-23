require 'geocoder/results/base'

module Geocoder::Result
  class Twogis < Base
    def coordinates
      ['lat', 'lon'].map{ |i| @data['point'][i] } if @data['point']
    end

    def address(_format = :full)
      @data['full_address_name'] || ''
    end

    def city
      return '' unless @data['adm_div']
      @data['adm_div'].select{|u| u["type"] == "city"}.first.try(:[], 'name') || ''
    end

    def region
      return '' unless @data['adm_div']
      @data['adm_div'].select{|u| u["type"] == "region"}.first.try(:[], 'name') || ''
    end

    def country
      return '' unless @data['adm_div']
      @data['adm_div'].select{|u| u["type"] == "country"}.first.try(:[], 'name') || ''
    end

    def district
      return '' unless @data['adm_div']
      @data['adm_div'].select{|u| u["type"] == "district"}.first.try(:[], 'name') || ''
    end

    def district_area
      return '' unless @data['adm_div']
      @data['adm_div'].select{|u| u["type"] == "district_area"}.first.try(:[], 'name') || ''
    end

    def street_address
      @data['address_name'] || ''
    end

    def street
      return '' unless @data['address_name']
      @data['address_name'].split(', ').first
    end

    def street_number
      return '' unless @data['address_name']
      @data['address_name'].split(', ')[1] || ''
    end

    def type
      @data['type'] || ''
    end

    def purpose_name
      @data['purpose_name'] || ''
    end

    def building_name
      @data['building_name'] || ''
    end

    def subtype
      @data['subtype'] || ''
    end

    def subtype_specification
      @data['subtype_specification'] || ''
    end

    def name
      @data['name'] || ''
    end
  end
end
