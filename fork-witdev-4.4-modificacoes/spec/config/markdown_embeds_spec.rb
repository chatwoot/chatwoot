require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Markdown Embeds Configuration' do
  # rubocop:enable RSpec/DescribeClass
  let(:config) { YAML.load_file(Rails.root.join('config/markdown_embeds.yml')) }

  describe 'YAML structure' do
    it 'loads valid YAML' do
      expect(config).to be_a(Hash)
      expect(config).not_to be_empty
    end

    it 'has required keys for each embed type' do
      config.each do |embed_type, embed_config|
        expect(embed_config).to have_key('regex'), "#{embed_type} missing regex"
        expect(embed_config).to have_key('template'), "#{embed_type} missing template"
        expect(embed_config['regex']).to be_a(String), "#{embed_type} regex should be string"
        expect(embed_config['template']).to be_a(String), "#{embed_type} template should be string"
      end
    end

    it 'contains expected embed types' do
      expected_types = %w[youtube loom vimeo mp4 arcade wistia bunny codepen github_gist]
      expect(config.keys).to match_array(expected_types)
    end
  end

  describe 'regex patterns and named capture groups' do
    let(:test_cases) do
      {
        'youtube' => [
          { url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', expected: { 'video_id' => 'dQw4w9WgXcQ' } },
          { url: 'https://youtu.be/dQw4w9WgXcQ', expected: { 'video_id' => 'dQw4w9WgXcQ' } },
          { url: 'https://youtube.com/watch?v=abc123XYZ', expected: { 'video_id' => 'abc123XYZ' } }
        ],
        'loom' => [
          { url: 'https://www.loom.com/share/abc123def456', expected: { 'video_id' => 'abc123def456' } },
          { url: 'https://loom.com/share/xyz789', expected: { 'video_id' => 'xyz789' } }
        ],
        'vimeo' => [
          { url: 'https://vimeo.com/123456789', expected: { 'video_id' => '123456789' } },
          { url: 'https://www.vimeo.com/987654321', expected: { 'video_id' => '987654321' } }
        ],
        'mp4' => [
          { url: 'https://example.com/video.mp4', expected: { 'link_url' => 'https://example.com/video.mp4' } },
          { url: 'https://www.test.com/path/to/movie.mp4', expected: { 'link_url' => 'https://www.test.com/path/to/movie.mp4' } }
        ],
        'arcade' => [
          { url: 'https://app.arcade.software/share/arcade123', expected: { 'video_id' => 'arcade123' } },
          { url: 'https://www.app.arcade.software/share/demo456', expected: { 'video_id' => 'demo456' } }
        ],
        'wistia' => [
          { url: 'https://chatwoot.wistia.com/medias/kjwjeq6f9i', expected: { 'video_id' => 'kjwjeq6f9i' } },
          { url: 'https://www.company.wistia.com/medias/abc123def', expected: { 'video_id' => 'abc123def' } }
        ],
        'bunny' => [
          { url: 'https://iframe.mediadelivery.net/play/431789/1f105841-cad9-46fe-a70e-b7623c60797c',
            expected: { 'library_id' => '431789', 'video_id' => '1f105841-cad9-46fe-a70e-b7623c60797c' } },
          { url: 'https://iframe.mediadelivery.net/play/12345/abcdef-ghijkl', expected: { 'library_id' => '12345', 'video_id' => 'abcdef-ghijkl' } }
        ],
        'codepen' => [
          { url: 'https://codepen.io/username/pen/abcdef', expected: { 'user' => 'username', 'pen_id' => 'abcdef' } },
          { url: 'https://www.codepen.io/testuser/pen/xyz123', expected: { 'user' => 'testuser', 'pen_id' => 'xyz123' } }
        ],
        'github_gist' => [
          { url: 'https://gist.github.com/username/1234567890abcdef1234567890abcdef',
            expected: { 'username' => 'username', 'gist_id' => '1234567890abcdef1234567890abcdef' } },
          { url: 'https://gist.github.com/testuser/fedcba0987654321fedcba0987654321', expected: { 'username' => 'testuser', 'gist_id' => 'fedcba0987654321fedcba0987654321' } }
        ]
      }
    end

    it 'correctly captures named groups for all embed types' do
      test_cases.each do |embed_type, cases|
        regex = Regexp.new(config[embed_type]['regex'])

        cases.each do |test_case|
          match = regex.match(test_case[:url])
          expect(match).not_to be_nil, "#{embed_type} regex failed to match URL: #{test_case[:url]}"
          expect(match.named_captures).to eq(test_case[:expected]),
                                          "#{embed_type} captured groups don't match expected for URL: #{test_case[:url]}"
        end
      end
    end

    it 'validates that template variables match capture group names' do
      config.each do |embed_type, embed_config|
        regex = Regexp.new(embed_config['regex'])
        template = embed_config['template']

        # Extract template variables like %{video_id}
        template_vars = template.scan(/%\{(\w+)\}/).flatten.uniq

        # Get named capture groups from regex
        capture_names = regex.names

        expect(capture_names).to match_array(template_vars),
                                 "#{embed_type}: Template variables #{template_vars} don't match capture groups #{capture_names}"
      end
    end
  end
end
