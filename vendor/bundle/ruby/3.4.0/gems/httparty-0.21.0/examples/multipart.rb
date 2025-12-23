# If you are uploading file in params, multipart will used as content-type automatically

HTTParty.post(
  'http://localhost:3000/user',
  body: {
    name: 'Foo Bar',
    email: 'example@email.com',
    avatar: File.open('/full/path/to/avatar.jpg')
  }
)


# However, you can force it yourself

HTTParty.post(
  'http://localhost:3000/user',
  multipart: true,
  body: {
    name: 'Foo Bar',
    email: 'example@email.com'
  }
)
