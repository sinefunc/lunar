require 'helper'

class LunarFuzzyTest < Test::Unit::TestCase
  context "when setting fuzzy name, 'Yukihiro Matsumoto'" do
    setup do
      @index = Lunar.index 'Item' do |i|
        i.id 1001
        i.fuzzy :name, 'Yukihiro Matsumoto'
      end
    end

    should "store Lunar:Item:Fuzzies:name:Y up to o and M up to o" do
      fname, lname = 'yukihiro', 'matsumoto'
      nest = Lunar.nest[:Item][:Fuzzies][:name]

      (1..fname.length).each do |length|
        key = nest[encode(fname[0, length])]
        assert_equal '1', key.zscore(1001)
      end

      (1..lname.length).each do |length|
        key = nest[encode(lname[0, length])]
        assert_equal '1', key.zscore(1001)
      end

      assert_equal %w{matsumoto yukihiro},
        Lunar.nest[:Item][:Fuzzies][1001][:name].smembers.sort
    end
  end

  context "when creating an index that already exists" do
    setup do
      @index = Lunar.index 'Item' do |i|
        i.id  1001
        i.fuzzy :name, 'Yukihiro Matsumoto'
      end

      @index = Lunar.index 'Item' do |i|
        i.id  1001
        i.fuzzy :name, 'Martin Fowler Yuki'
      end
    end

    should "remove all fuzzy entries for Yukihiro Matsumoto" do
      fname, lname = 'yukihiro', 'matsumoto'
      nest = Lunar.nest[:Item][:Fuzzies][:name]

      (5..fname.length).each do |length|
        key = nest[encode(fname[0, length])]
        assert_nil key.zscore('1001')
      end

      (3..lname.length).each do |length|
        key = nest[encode(lname[0, length])]
        assert_nil key.zscore('1001')
      end

      assert_equal %w{fowler martin yuki},
        Lunar.nest[:Item][:Fuzzies][1001][:name].smembers.sort
    end

    should "store Lunar:Item:name:M up to n and F up to r etc..." do
      fname, lname, triple = 'martin', 'fowler', 'yuki'
      nest = Lunar.nest[:Item][:Fuzzies][:name]

      %w{martin fowler yuki}.each do |word|
        (1..word.length).each do |length|
          key = nest[encode(word[0, length])]
          assert_equal '1', key.zscore(1001)
        end
      end
    end
  end

  context "on delete" do
    setup do
      @index1 = Lunar.index 'Item' do |i|
        i.id 1001
        i.fuzzy :name, 'Yukihiro Matsumoto'
      end

      @index2 = Lunar.index 'Item' do |i|
        i.id 1002
        i.fuzzy :name, 'Linus Torvalds'
      end

      Lunar.delete('Item', 1001)
      Lunar.delete('Item', 1002)
    end

    should "remove all fuzzy entries for Yukihiro Matsumoto" do
      nest = Lunar.nest[:Item][:Fuzzies][:name]

      %w{yukihiro matsumoto}.each do |word|
        (1..word.length).each do |length|
          key = nest[encode(word[0, length])]
          assert_nil key.zscore(1001)
        end
      end
    end

    should "remove all fuzzy entries for Linus Torvalds" do
      nest = Lunar.nest[:Item][:Fuzzies][:name]

      %w{linus torvalds}.each do |word|
        (1..word.length).each do |length|
          key = nest[encode(word[0, length])]
          assert_nil key.zscore(1001)
        end
      end
    end

    should "also remove the key Lunar:Item:Fuzzies:*:name" do
      assert ! Lunar.redis.exists("Lunar:Item:Fuzzies:1001:name")
      assert ! Lunar.redis.exists("Lunar:Item:Fuzzies:1002:name")
    end
  end

protected
  def encode(str)
    Lunar.encode(str)
  end
end
