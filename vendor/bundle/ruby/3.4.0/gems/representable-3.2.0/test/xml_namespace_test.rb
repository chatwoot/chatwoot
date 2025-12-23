require "test_helper"

# <lib:library
#    xmlns:lib="http://eric.van-der-vlist.com/ns/library"
#    xmlns:hr="http://eric.van-der-vlist.com/ns/person">
#   <lib:book id="b0836217462" available="true">
#    <lib:isbn>0836217462</lib:isbn>
#    <lib:title xml:lang="en">Being a Dog Is a Full-Time Job</lib:title>
#    <hr:author id="CMS">
#     <hr:name>Charles M Schulz</hr:name>
#     <hr:born>1922-11-26</hr:born>
#     <hr:dead>2000-02-12</hr:dead>
#    </hr:author>
#    <lib:character id="PP">
#     <hr:name>Peppermint Patty</hr:name>
#     <hr:born>1966-08-22</hr:born>
#     <lib:qualification>bold, brash and tomboyish</lib:qualification>
#     </lib:character>
#    <lib:character id="Snoopy">
#     <hr:name>Snoopy</hr:name>
#     <hr:born>1950-10-04</hr:born>
#     <lib:qualification>extroverted beagle</lib:qualification>
#    </lib:character>
#    <lib:character id="Schroeder">
#     <hr:name>Schroeder</hr:name>
#     <hr:born>1951-05-30</hr:born>
#     <lib:qualification>brought classical music to the Peanuts strip
#                   </lib:qualification>
#    </lib:character>
#    <lib:character id="Lucy">
#     <hr:name>Lucy</hr:name>
#     <hr:born>1952-03-03</hr:born>
#     <lib:qualification>bossy, crabby and selfish</lib:qualification>
#    </lib:character>
#   </lib:book>
#  </lib:library>

  # Theoretically, every property (scalar) needs/should have a namespace.
  # property :name, namespace: "http://eric.van-der-vlist.com/ns/person"
  # # This is implicit if contained:
  # class Person < Decorator
  #   namespace: "http://eric.van-der-vlist.com/ns/person"
  #   property :name #, namespace: "http://eric.van-der-vlist.com/ns/person"
  # end
  # class Library
  #   namespace "http://eric.van-der-vlist.com/ns/library"

  #   namespace_def lib:    "http://eric.van-der-vlist.com/ns/library"
  #   namespace_def person: "http://eric.van-der-vlist.com/ns/person"
  #   # namespace_def person: Person

  #   property :person, decorator: Person
  # end
class NamespaceXMLTest < Minitest::Spec
  module Model
    Library = Struct.new(:book)
    Book = Struct.new(:id, :isbn)
  end

  let (:book) { Model::Book.new(1, 666) }

  #:simple-class
  class Library < Representable::Decorator
    feature Representable::XML
    feature Representable::XML::Namespace

    namespace "http://eric.van-der-vlist.com/ns/library"

    property :book do
      namespace "http://eric.van-der-vlist.com/ns/library"

      property :id,  attribute: true
      property :isbn
    end
  end
  #:simple-class end


  # default namespace for library
  it "what" do
    Library.new(Model::Library.new(book)).to_xml.must_xml(

    #:simple-xml
    %{<library xmlns="http://eric.van-der-vlist.com/ns/library">
      <book id="1">
        <isbn>666</isbn>
      </book>
    </library>}
    #:simple-xml end
    )
  end
end

class Namespace2XMLTest < Minitest::Spec
  module Model
    Library   = Struct.new(:book)
    Book      = Struct.new(:id, :isbn, :author, :character)
    Character = Struct.new(:name, :born, :qualification)
  end

  let (:book) { Model::Book.new(1, 666, Model::Character.new("Fowler"), [Model::Character.new("Frau Java", 1991, "typed")]) }

  #:map-class
  class Library < Representable::Decorator
    feature Representable::XML
    feature Representable::XML::Namespace

    namespace "http://eric.van-der-vlist.com/ns/library"
    namespace_def lib: "http://eric.van-der-vlist.com/ns/library"
    namespace_def hr: "http://eric.van-der-vlist.com/ns/person"

    property :book, class: Model::Book do
      namespace "http://eric.van-der-vlist.com/ns/library"

      property :id,  attribute: true
      property :isbn

      property :author, class: Model::Character do
        namespace "http://eric.van-der-vlist.com/ns/person"

        property :name
        property :born
      end

      collection :character, class: Model::Character do
        namespace "http://eric.van-der-vlist.com/ns/library"

        property :qualification

        property :name, namespace: "http://eric.van-der-vlist.com/ns/person"
        property :born, namespace: "http://eric.van-der-vlist.com/ns/person"
      end
    end
  end
  #:map-class end

  it "renders" do
    Library.new(Model::Library.new(book)).to_xml.must_xml(
#:map-xml
%{<lib:library xmlns:lib=\"http://eric.van-der-vlist.com/ns/library\" xmlns:hr=\"http://eric.van-der-vlist.com/ns/person\">
  <lib:book id=\"1\">
    <lib:isbn>666</lib:isbn>
    <hr:author>
      <hr:name>Fowler</hr:name>
    </hr:author>
    <lib:character>
      <lib:qualification>typed</lib:qualification>
      <hr:name>Frau Java</hr:name>
      <hr:born>1991</hr:born>
    </lib:character>
  </lib:book>
</lib:library>}
#:map-xml end
    )
  end

  it "parses" do
    lib  = Model::Library.new
    #:parse-call
    Library.new(lib).from_xml(%{<lib:library
  xmlns:lib="http://eric.van-der-vlist.com/ns/library"
  xmlns:hr="http://eric.van-der-vlist.com/ns/person">
  <lib:book id="1">
    <lib:isbn>666</lib:isbn>
    <hr:author>
      <hr:name>Fowler</hr:name>
    </hr:author>
    <lib:character>
      <lib:qualification>typed</lib:qualification>
      <hr:name>Frau Java</hr:name>
      <bogus:name>Mr. Ruby</hr:name>
      <name>Dr. Elixir</hr:name>
      <hr:born>1991</hr:born>
    </lib:character>
  </lib:book>
</lib:library>}
    #:parse-call end
    )

    _(lib.book.inspect).must_equal %{#<struct Namespace2XMLTest::Model::Book id=\"1\", isbn=\"666\", author=#<struct Namespace2XMLTest::Model::Character name=\"Fowler\", born=nil, qualification=nil>, character=[#<struct Namespace2XMLTest::Model::Character name=\"Frau Java\", born=\"1991\", qualification=\"typed\">]>}

    #:parse-res
    lib.book.character[0].name #=> "Frau Java"
    #:parse-res end
  end
end
