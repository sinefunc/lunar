require "helper"

class NumberSearchTest < Test::Unit::TestCase
  class Gadget < Struct.new(:id)
    def self.[](id)
      new(id)
    end
  end

  setup do
    Lunar.index Gadget do |i|
      i.id 1001
      i.number :price, 200
    end
  end

  test "doing straight searches for numbers" do
    search = Lunar.search Gadget, numbers: { price: 200 }
    
    assert_equal ["1001"], search.map(&:id)
  end

  test "also doing range searches" do
    search = Lunar.search Gadget, price: 150..200
    
    assert_equal ["1001"], search.map(&:id)
  end

  test "searching both" do
    search = Lunar.search Gadget, price: 150..200, numbers: { price: 200 }
    
    assert_equal ["1001"], search.map(&:id)
  end
end
