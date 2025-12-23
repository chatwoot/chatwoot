# frozen_string_literal: true

RSpec.describe HTTP::Redirector do
  def simple_response(status, body = "", headers = {})
    HTTP::Response.new(
      :status  => status,
      :version => "1.1",
      :headers => headers,
      :body    => body,
      :request => HTTP::Request.new(:verb => :get, :uri => "http://example.com")
    )
  end

  def redirect_response(status, location, set_cookie = {})
    res = simple_response status, "", "Location" => location
    set_cookie.each do |name, value|
      res.headers.add("Set-Cookie", "#{name}=#{value}; path=/; httponly; secure; SameSite=none; Secure")
    end
    res
  end

  describe "#strict" do
    subject { redirector.strict }

    context "by default" do
      let(:redirector) { described_class.new }
      it { is_expected.to be true }
    end
  end

  describe "#max_hops" do
    subject { redirector.max_hops }

    context "by default" do
      let(:redirector) { described_class.new }
      it { is_expected.to eq 5 }
    end
  end

  describe "#perform" do
    let(:options)    { {} }
    let(:redirector) { described_class.new options }

    it "fails with TooManyRedirectsError if max hops reached" do
      req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
      res = proc { |prev_req| redirect_response(301, "#{prev_req.uri}/1") }

      expect { redirector.perform(req, res.call(req), &res) }.
        to raise_error HTTP::Redirector::TooManyRedirectsError
    end

    it "fails with EndlessRedirectError if endless loop detected" do
      req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
      res = redirect_response(301, req.uri)

      expect { redirector.perform(req, res) { res } }.
        to raise_error HTTP::Redirector::EndlessRedirectError
    end

    it "fails with StateError if there were no Location header" do
      req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
      res = simple_response(301)

      expect { |b| redirector.perform(req, res, &b) }.
        to raise_error HTTP::StateError
    end

    it "returns first non-redirect response" do
      req  = HTTP::Request.new :verb => :head, :uri => "http://example.com"
      hops = [
        redirect_response(301, "http://example.com/1"),
        redirect_response(301, "http://example.com/2"),
        redirect_response(301, "http://example.com/3"),
        simple_response(200, "foo"),
        redirect_response(301, "http://example.com/4"),
        simple_response(200, "bar")
      ]

      res = redirector.perform(req, hops.shift) { hops.shift }
      expect(res.to_s).to eq "foo"
    end

    it "concatenates multiple Location headers" do
      req     = HTTP::Request.new :verb => :head, :uri => "http://example.com"
      headers = HTTP::Headers.new

      %w[http://example.com /123].each { |loc| headers.add("Location", loc) }

      res = redirector.perform(req, simple_response(301, "", headers)) do |redirect|
        simple_response(200, redirect.uri.to_s)
      end

      expect(res.to_s).to eq "http://example.com/123"
    end

    it "returns cookies in response" do
      req  = HTTP::Request.new :verb => :head, :uri => "http://example.com"
      hops = [
        redirect_response(301, "http://example.com/1", {"foo" => "42"}),
        redirect_response(301, "http://example.com/2", {"bar" => "53", "deleted" => "foo"}),
        redirect_response(301, "http://example.com/3", {"baz" => "64", "deleted" => ""}),
        redirect_response(301, "http://example.com/4", {"baz" => "65"}),
        simple_response(200, "bar")
      ]

      request_cookies = [
        {"foo" => "42"},
        {"foo" => "42", "bar" => "53", "deleted" => "foo"},
        {"foo" => "42", "bar" => "53", "baz" => "64"},
        {"foo" => "42", "bar" => "53", "baz" => "65"}
      ]

      res = redirector.perform(req, hops.shift) do |request|
        req_cookie = HTTP::Cookie.cookie_value_to_hash(request.headers["Cookie"] || "")
        expect(req_cookie).to eq request_cookies.shift
        hops.shift
      end
      expect(res.to_s).to eq "bar"
      cookies = res.cookies.cookies.to_h { |c| [c.name, c.value] }
      expect(cookies["foo"]).to eq "42"
      expect(cookies["bar"]).to eq "53"
      expect(cookies["baz"]).to eq "65"
      expect(cookies["deleted"]).to eq nil
    end

    it "returns original cookies in response" do
      req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
      req.headers.set("Cookie", "foo=42; deleted=baz")
      hops = [
        redirect_response(301, "http://example.com/1", {"bar" => "64", "deleted" => ""}),
        simple_response(200, "bar")
      ]

      request_cookies = [
        {"foo" => "42", "bar" => "64"},
        {"foo" => "42", "bar" => "64"}
      ]

      res = redirector.perform(req, hops.shift) do |request|
        req_cookie = HTTP::Cookie.cookie_value_to_hash(request.headers["Cookie"] || "")
        expect(req_cookie).to eq request_cookies.shift
        hops.shift
      end
      expect(res.to_s).to eq "bar"
      cookies = res.cookies.cookies.to_h { |c| [c.name, c.value] }
      expect(cookies["foo"]).to eq "42"
      expect(cookies["bar"]).to eq "64"
      expect(cookies["deleted"]).to eq nil
    end

    context "with on_redirect callback" do
      let(:options) do
        {
          :on_redirect => proc do |response, location|
            @redirect_response = response
            @redirect_location = location
          end
        }
      end

      it "calls on_redirect" do
        req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
        hops = [
          redirect_response(301, "http://example.com/1"),
          redirect_response(301, "http://example.com/2"),
          simple_response(200, "foo")
        ]

        redirector.perform(req, hops.shift) do |prev_req, _|
          expect(@redirect_location.uri.to_s).to eq prev_req.uri.to_s
          expect(@redirect_response.code).to eq 301
          hops.shift
        end
      end
    end

    context "following 300 redirect" do
      context "with strict mode" do
        let(:options) { {:strict => true} }

        it "it follows with original verb if it's safe" do
          req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
          res = redirect_response 300, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :head
            simple_response 200
          end
        end

        it "raises StateError if original request was PUT" do
          req = HTTP::Request.new :verb => :put, :uri => "http://example.com"
          res = redirect_response 300, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end

        it "raises StateError if original request was POST" do
          req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
          res = redirect_response 300, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end

        it "raises StateError if original request was DELETE" do
          req = HTTP::Request.new :verb => :delete, :uri => "http://example.com"
          res = redirect_response 300, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end
      end

      context "with non-strict mode" do
        let(:options) { {:strict => false} }

        it "it follows with original verb if it's safe" do
          req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
          res = redirect_response 300, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :head
            simple_response 200
          end
        end

        it "it follows with GET if original request was PUT" do
          req = HTTP::Request.new :verb => :put, :uri => "http://example.com"
          res = redirect_response 300, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end

        it "it follows with GET if original request was POST" do
          req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
          res = redirect_response 300, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end

        it "it follows with GET if original request was DELETE" do
          req = HTTP::Request.new :verb => :delete, :uri => "http://example.com"
          res = redirect_response 300, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end
      end
    end

    context "following 301 redirect" do
      context "with strict mode" do
        let(:options) { {:strict => true} }

        it "it follows with original verb if it's safe" do
          req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
          res = redirect_response 301, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :head
            simple_response 200
          end
        end

        it "raises StateError if original request was PUT" do
          req = HTTP::Request.new :verb => :put, :uri => "http://example.com"
          res = redirect_response 301, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end

        it "raises StateError if original request was POST" do
          req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
          res = redirect_response 301, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end

        it "raises StateError if original request was DELETE" do
          req = HTTP::Request.new :verb => :delete, :uri => "http://example.com"
          res = redirect_response 301, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end
      end

      context "with non-strict mode" do
        let(:options) { {:strict => false} }

        it "it follows with original verb if it's safe" do
          req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
          res = redirect_response 301, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :head
            simple_response 200
          end
        end

        it "it follows with GET if original request was PUT" do
          req = HTTP::Request.new :verb => :put, :uri => "http://example.com"
          res = redirect_response 301, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end

        it "it follows with GET if original request was POST" do
          req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
          res = redirect_response 301, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end

        it "it follows with GET if original request was DELETE" do
          req = HTTP::Request.new :verb => :delete, :uri => "http://example.com"
          res = redirect_response 301, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end
      end
    end

    context "following 302 redirect" do
      context "with strict mode" do
        let(:options) { {:strict => true} }

        it "it follows with original verb if it's safe" do
          req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
          res = redirect_response 302, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :head
            simple_response 200
          end
        end

        it "raises StateError if original request was PUT" do
          req = HTTP::Request.new :verb => :put, :uri => "http://example.com"
          res = redirect_response 302, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end

        it "raises StateError if original request was POST" do
          req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
          res = redirect_response 302, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end

        it "raises StateError if original request was DELETE" do
          req = HTTP::Request.new :verb => :delete, :uri => "http://example.com"
          res = redirect_response 302, "http://example.com/1"

          expect { redirector.perform(req, res) { simple_response 200 } }.
            to raise_error HTTP::StateError
        end
      end

      context "with non-strict mode" do
        let(:options) { {:strict => false} }

        it "it follows with original verb if it's safe" do
          req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
          res = redirect_response 302, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :head
            simple_response 200
          end
        end

        it "it follows with GET if original request was PUT" do
          req = HTTP::Request.new :verb => :put, :uri => "http://example.com"
          res = redirect_response 302, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end

        it "it follows with GET if original request was POST" do
          req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
          res = redirect_response 302, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end

        it "it follows with GET if original request was DELETE" do
          req = HTTP::Request.new :verb => :delete, :uri => "http://example.com"
          res = redirect_response 302, "http://example.com/1"

          redirector.perform(req, res) do |prev_req, _|
            expect(prev_req.verb).to be :get
            simple_response 200
          end
        end
      end
    end

    context "following 303 redirect" do
      it "follows with HEAD if original request was HEAD" do
        req = HTTP::Request.new :verb => :head, :uri => "http://example.com"
        res = redirect_response 303, "http://example.com/1"

        redirector.perform(req, res) do |prev_req, _|
          expect(prev_req.verb).to be :head
          simple_response 200
        end
      end

      it "follows with GET if original request was GET" do
        req = HTTP::Request.new :verb => :get, :uri => "http://example.com"
        res = redirect_response 303, "http://example.com/1"

        redirector.perform(req, res) do |prev_req, _|
          expect(prev_req.verb).to be :get
          simple_response 200
        end
      end

      it "follows with GET if original request was neither GET nor HEAD" do
        req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
        res = redirect_response 303, "http://example.com/1"

        redirector.perform(req, res) do |prev_req, _|
          expect(prev_req.verb).to be :get
          simple_response 200
        end
      end
    end

    context "following 307 redirect" do
      it "follows with original request's verb" do
        req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
        res = redirect_response 307, "http://example.com/1"

        redirector.perform(req, res) do |prev_req, _|
          expect(prev_req.verb).to be :post
          simple_response 200
        end
      end
    end

    context "following 308 redirect" do
      it "follows with original request's verb" do
        req = HTTP::Request.new :verb => :post, :uri => "http://example.com"
        res = redirect_response 308, "http://example.com/1"

        redirector.perform(req, res) do |prev_req, _|
          expect(prev_req.verb).to be :post
          simple_response 200
        end
      end
    end

    describe "changing verbs during redirects" do
      let(:options) { {:strict => false} }
      let(:post_body) { HTTP::Request::Body.new("i might be way longer in real life") }
      let(:cookie) { "dont=eat my cookies" }

      def a_dangerous_request(verb)
        HTTP::Request.new(
          :verb => verb, :uri => "http://example.com",
          :body => post_body, :headers => {
            "Content-Type" => "meme",
            "Cookie"       => cookie
          }
        )
      end

      def empty_body
        HTTP::Request::Body.new(nil)
      end

      it "follows without body/content type if it has to change verb" do
        req = a_dangerous_request(:post)
        res = redirect_response 302, "http://example.com/1"

        redirector.perform(req, res) do |prev_req, _|
          expect(prev_req.body).to eq(empty_body)
          expect(prev_req.headers["Cookie"]).to eq(cookie)
          expect(prev_req.headers["Content-Type"]).to eq(nil)
          simple_response 200
        end
      end

      it "leaves body/content-type intact if it does not have to change verb" do
        req = a_dangerous_request(:post)
        res = redirect_response 307, "http://example.com/1"

        redirector.perform(req, res) do |prev_req, _|
          expect(prev_req.body).to eq(post_body)
          expect(prev_req.headers["Cookie"]).to eq(cookie)
          expect(prev_req.headers["Content-Type"]).to eq("meme")
          simple_response 200
        end
      end
    end
  end
end
