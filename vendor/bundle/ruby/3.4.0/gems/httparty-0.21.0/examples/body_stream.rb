# To upload file to a server use :body_stream

HTTParty.put(
  'http://localhost:3000/train',
  body_stream: File.open('sample_configs/config_train_server_md.yml', 'r')
)


# Actually, it works with any IO object

HTTParty.put(
  'http://localhost:3000/train',
  body_stream: StringIO.new('foo')
)
