require 'rspec'

describe "installing digest-crc" do
  ROOT_DIR   = File.expand_path('../../..',__FILE__)
  DOCKER_DIR = File.expand_path('../docker', __FILE__)

  IMAGES = %w[
    test-digest-crc-base
    test-digest-crc-with-gcc
    test-digest-crc-with-gcc-and-make
  ]

  before(:all) do
    puts ">>> Building digest-crc gem ..."
    Dir.chdir(ROOT_DIR) do
      system 'gem', 'build',
             '-o', File.join(DOCKER_DIR,'digest-crc.gem'),
             'digest-crc.gemspec'
    end

    IMAGES.each do |image|
      suffix = image.sub('test-digest-crc-','')

      puts ">>> Building #{image} docker image ..."
      Dir.chdir(DOCKER_DIR) do
        system "docker build -t #{image} --file Dockerfile.#{suffix} ."
      end
    end
  end

  context "when installing into a slim environment" do
    let(:image) { 'test-digest-crc-base' }

    it "should successfully install digest-crc" do
      expect(system("docker run #{image}")).to be(true)
    end
  end

  context "when gcc is installed" do
    let(:image) { 'test-digest-crc-with-gcc' }

    it "should successfully install digest-crc" do
      expect(system("docker run #{image}")).to be(true)
    end
  end

  context "when gcc and make are installed" do
    let(:image) { 'test-digest-crc-with-gcc-and-make' }

    it "should successfully install digest-crc" do
      expect(system("docker run #{image}")).to be(true)
    end
  end

  after(:all) do
    puts ">>> Removing test-digest-crc docker images ..."
    system "docker image rm -f #{IMAGES.reverse.join(' ')}"
  end
end
