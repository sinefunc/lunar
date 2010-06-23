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
      i.number :category_ids, %w(100 101 102)
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

  test "searching for a multi-id individually" do
    search100 = Lunar.search Gadget, numbers: { category_ids: 100 }
    search101 = Lunar.search Gadget, numbers: { category_ids: 101 }
    search102 = Lunar.search Gadget, numbers: { category_ids: 102 }

    assert_equal ["1001"], search100.map(&:id)
    assert_equal ["1001"], search101.map(&:id)
    assert_equal ["1001"], search102.map(&:id)
  end

  test "searching for a valid multi-id at the same time" do
    search = Lunar.search Gadget, numbers: { category_ids: %w(100 101 102) }

    assert_equal ["1001"], search.map(&:id)
  end

  test "searching with one invalid multi-id at the same time" do
    search = Lunar.search Gadget, numbers: { category_ids: %w(100 101 102 103) }

    assert_equal ["1001"], search.map(&:id)
  end
  
  test "searching with all invalid multi-id" do
    search = Lunar.search Gadget, numbers: { category_ids: %w(103 104 105) }
    assert_equal 0, search.size
  end
end
