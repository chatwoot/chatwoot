# -*- coding: utf-8 -*-
require_relative '_lib'
require 'base64'

describe RestClient do

  it "a simple request" do
    body = 'abc'
    stub_request(:get, "www.example.com").to_return(:body => body, :status => 200)
    response = RestClient.get "www.example.com"
    expect(response.code).to eq 200
    expect(response.body).to eq body
  end

  it "a 404" do
    body = "Ho hai ! I'm not here !"
    stub_request(:get, "www.example.com").to_return(:body => body, :status => 404)
    begin
      RestClient.get "www.example.com"
      raise
    rescue RestClient::ResourceNotFound => e
      expect(e.http_code).to eq 404
      expect(e.response.code).to eq 404
      expect(e.response.body).to eq body
      expect(e.http_body).to eq body
    end
  end

  describe 'charset parsing' do
    it 'handles utf-8' do
      body = "λ".force_encoding('ASCII-8BIT')
      stub_request(:get, "www.example.com").to_return(
        :body => body, :status => 200, :headers => {
          'Content-Type' => 'text/plain; charset=UTF-8'
      })
      response = RestClient.get "www.example.com"
      expect(response.encoding).to eq Encoding::UTF_8
      expect(response.valid_encoding?).to eq true
    end

    it 'handles windows-1252' do
      body = "\xff".force_encoding('ASCII-8BIT')
      stub_request(:get, "www.example.com").to_return(
        :body => body, :status => 200, :headers => {
          'Content-Type' => 'text/plain; charset=windows-1252'
      })
      response = RestClient.get "www.example.com"
      expect(response.encoding).to eq Encoding::WINDOWS_1252
      expect(response.encode('utf-8')).to eq "ÿ"
      expect(response.valid_encoding?).to eq true
    end

    it 'handles binary' do
      body = "\xfe".force_encoding('ASCII-8BIT')
      stub_request(:get, "www.example.com").to_return(
        :body => body, :status => 200, :headers => {
          'Content-Type' => 'application/octet-stream; charset=binary'
      })
      response = RestClient.get "www.example.com"
      expect(response.encoding).to eq Encoding::BINARY
      expect {
        response.encode('utf-8')
      }.to raise_error(Encoding::UndefinedConversionError)
      expect(response.valid_encoding?).to eq true
    end

    it 'handles euc-jp' do
      body = "\xA4\xA2\xA4\xA4\xA4\xA6\xA4\xA8\xA4\xAA".
        force_encoding(Encoding::BINARY)
      body_utf8 = 'あいうえお'
      expect(body_utf8.encoding).to eq Encoding::UTF_8

      stub_request(:get, 'www.example.com').to_return(
        :body => body, :status => 200, :headers => {
          'Content-Type' => 'text/plain; charset=EUC-JP'
      })
      response = RestClient.get 'www.example.com'
      expect(response.encoding).to eq Encoding::EUC_JP
      expect(response.valid_encoding?).to eq true
      expect(response.length).to eq 5
      expect(response.encode('utf-8')).to eq body_utf8
    end

    it 'defaults to the default encoding' do
      stub_request(:get, 'www.example.com').to_return(
        body: 'abc', status: 200, headers: {
          'Content-Type' => 'text/plain'
        })

      response = RestClient.get 'www.example.com'
      # expect(response.encoding).to eq Encoding.default_external
      expect(response.encoding).to eq Encoding::UTF_8
    end

    it 'handles invalid encoding' do
      stub_request(:get, 'www.example.com').to_return(
        body: 'abc', status: 200, headers: {
          'Content-Type' => 'text; charset=plain'
        })

      response = RestClient.get 'www.example.com'
      # expect(response.encoding).to eq Encoding.default_external
      expect(response.encoding).to eq Encoding::UTF_8
    end

    it 'leaves images as binary' do
      gif = Base64.strict_decode64('R0lGODlhAQABAAAAADs=')

      stub_request(:get, 'www.example.com').to_return(
        body: gif, status: 200, headers: {
          'Content-Type' => 'image/gif'
        })

      response = RestClient.get 'www.example.com'
      expect(response.encoding).to eq Encoding::BINARY
    end
  end
end
