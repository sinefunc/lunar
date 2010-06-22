require "helper"

class IndexTest < Test::Unit::TestCase
  class Gadget < Struct.new(:id)
  end

  describe "indexing texts" do
    def nest(word)
      Lunar.nest[:Gadget][:title][Lunar.metaphone(word)]
    end

    test "with non-repeating words" do
      ret = Lunar.index :Gadget do |i|
        i.id 1001
        i.text :title, 'apple iphone 3GS smartphone'
      end

      assert_equal ['1001'], nest('apple').zrangebyscore(1, 1)
      assert_equal ['1001'], nest('iphone').zrangebyscore(1, 1)
      assert_equal ['1001'], nest('3gs').zrangebyscore(1, 1)
      assert_equal ['1001'], nest('smartphone').zrangebyscore(1, 1)

      assert_equal %w{APL IFN KS SMRTFN},
        Lunar.nest[:Gadget][:Metaphones][1001][:title].smembers.sort
    end

    test "deleting non-repeating words scenario" do
      ret = Lunar.index :Gadget do |i|
        i.id 1001
        i.text :title, 'apple iphone 3GS smartphone'
      end

      Lunar.delete(:Gadget, 1001)

      assert_equal 0, nest('apple').zcard
      assert_equal 0, nest('iphone').zcard
      assert_equal 0, nest('3gs').zcard
      assert_equal 0, nest('smartphone').zcard

      assert_equal 0, Lunar.nest[:Gadget][1001][:title].scard
    end

    test "with multiple word instances and stopwords" do
      Lunar.index :Gadget do |i|
        i.id 1001
        i.text :title, 'count of monte cristo will count to 100'
      end

      assert_equal ['1001'], nest('count').zrangebyscore(2, 2)
      assert_equal ['1001'], nest('monte').zrangebyscore(1, 1)
      assert_equal ['1001'], nest('cristo').zrangebyscore(1, 1)
      assert_equal ['1001'], nest('100').zrangebyscore(1, 1)

      assert nest('of').zrange(0, -1).empty?
      assert nest('to').zrange(0, -1).empty?
      assert nest('will').zrange(0, -1).empty?
    end

    test "deleting multiple word instances scenario" do
      Lunar.index :Gadget do |i|
        i.id 1001
        i.text :title, 'count of monte cristo will count to 100'
      end

      Lunar.delete(:Gadget, 1001)

      assert_equal 0, nest('count').zcard
      assert_equal 0, nest('monte').zcard
      assert_equal 0, nest('cristo').zcard
      assert_equal 0, nest('100').zcard

      assert_nil Lunar.nest[:Gadget][1001][:title].get
    end

    test "re-indexing" do
      Lunar.index :Gadget do |i|
        i.id 1001
        i.text :title, 'apple iphone 3GS smartphone'
      end

      Lunar.index :Gadget do |i|
        i.id 1001
        i.text :title, 'apple iphone 3G'
      end

      assert_equal ['1001'], nest('apple').zrangebyscore(1, 1)
      assert_equal ['1001'], nest('iphone').zrangebyscore(1, 1)
      assert_equal ['1001'], nest('3g').zrangebyscore(1, 1)

      assert nest('3gs').zrange(0, -1).empty?
      assert nest('smartphone').zrange(0, -1).empty?
    end
  end

  describe "indexing numbers" do
    def numbers
      Lunar.nest[:Gadget][:Numbers]
    end

    test "works for integers and floats" do
      Lunar.index :Gadget do |i|
        i.id 1001
        i.number :price, 200
        i.number :score, 25.5
      end

      assert_equal '200',  numbers[:price].zscore(1001)
      assert_equal '25.5', numbers[:score].zscore(1001)

      assert_equal '1', numbers[:price]["200"].zscore(1001)
    end
    
    test "reindexing" do
      Lunar.index :Gadget do |i|
        i.id 1001
        i.number :price, 200
      end

      Lunar.index :Gadget do |i|
        i.id 1001
        i.number :price, 150
      end

      assert_nil numbers[:price]["200"].zrank(1001)
      assert_equal '1', numbers[:price]["150"].zscore(1001)
    end

    test "allows deletion" do
      Lunar.index :Gadget do |i|
        i.id 1001
        i.number :price, 200
        i.number :score, 25.5
      end

      Lunar.delete :Gadget, 1001

      assert_nil numbers[:price].zrank(1001)
      assert_nil numbers[:score].zrank(1001)
      assert_nil numbers[:price]["200"].zrank(1001)
    end
  end

  describe "sortable fields" do
    test "works for integers, floats, strings" do
      Lunar.index :Gadget do |i|
        i.id 1001
        i.sortable :name, 'iphone'
        i.sortable :price, 200
        i.sortable :score, 25.5
      end

      assert_equal 'iphone', Lunar.nest[:Gadget][:Sortables][1001][:name].get
      assert_equal '200',    Lunar.nest[:Gadget][:Sortables][1001][:price].get
      assert_equal '25.5',   Lunar.nest[:Gadget][:Sortables][1001][:score].get
    end

    test "deletes sortable fields" do
      Lunar.index :Gadget do |i|
        i.id 1001
        i.sortable :name, 'iphone'
        i.sortable :price, 200
        i.sortable :score, 25.5
      end

      Lunar.delete :Gadget, 1001

      assert_nil Lunar.nest[:Gadget][1001][:name].get
      assert_nil Lunar.nest[:Gadget][1001][:price].get
      assert_nil Lunar.nest[:Gadget][1001][:score].get
    end
  end
end
