## Examples

* [Amazon Book Search](aaws.rb)
    * Httparty included into poro class
    * Uses `get` requests
    * Transforms query params to uppercased params

* [Google Search](google.rb)
  * Httparty included into poro class
  * Uses `get` requests

* [Crack Custom Parser](crack.rb)
    * Creates a custom parser for XML using crack gem
    * Uses `get` request

* [Create HTML Nokogiri parser](nokogiri_html_parser.rb)
    * Adds Html as a format
    * passed the body of request to Nokogiri

* [More Custom Parsers](custom_parsers.rb)
  * Create an additional parser for atom or make it the ONLY parser

* [Basic Auth, Delicious](delicious.rb)
  * Basic Auth, shows how to merge those into options
  * Uses `get` requests

* [Passing Headers, User Agent](headers_and_user_agents.rb)
  * Use the class method of Httparty
  * Pass the User-Agent in the headers
  * Uses `get` requests

* [Basic Post Request](basic.rb)
    * Httparty included into poro class
    * Uses `post` requests

* [Access Rubyurl Shortener](rubyurl.rb)
  * Httparty included into poro class
  * Uses `post` requests

* [Add a custom log file](logging.rb)
  * create a log file and have httparty log requests

* [Accessing StackExchange](stackexchange.rb)
  * Httparty included into poro class
  * Creates methods for different endpoints
  * Uses `get` requests

* [Accessing Tripit](tripit_sign_in.rb)
  * Httparty included into poro class
  * Example of using `debug_output` to see headers/urls passed
  * Getting and using Cookies
  * Uses `get` requests

* [Accessing Twitter](twitter.rb)
  * Httparty included into poro class
  * Basic Auth
  * Loads settings from a config file
  * Uses `get` requests
  * Uses `post` requests

* [Accessing WhoIsMyRep](whoismyrep.rb)
  * Httparty included into poro class
  * Uses `get` requests
  * Two ways to pass params to get, inline on the url or in query hash

* [Rescue Json Error](rescue_json.rb)
  * Rescue errors due to parsing response

* [Download file using stream mode](stream_download.rb)
  * Uses `get` requests
  * Uses `stream_body` mode
  * Download file without using the memory

* [Microsoft graph](microsoft_graph.rb)
  * Basic Auth
  * Uses `post` requests
  * Uses multipart

* [Multipart](multipart.rb)
  * Multipart data upload _(with and without file)_

* [Uploading File](body_stream.rb)
  * Uses `body_stream` to upload file

* [Accessing x509 Peer Certificate](peer_cert.rb)
  * Provides access to the server's TLS certificate

* [Accessing IDNs](idn.rb)
  * Uses a `get` request with an International domain names, which are Urls with emojis and non-ASCII characters such as accented letters.