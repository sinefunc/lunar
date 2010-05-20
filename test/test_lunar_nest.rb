require "helper"

class LunarNestTest < Test::Unit::TestCase
  test "retrieving keys for a pattern" do
    Lunar.redis.set("Foo:1:Bar", 1)
    Lunar.redis.set("Foo:2:Bar", 2)

    nest = Lunar::LunarNest.new("Foo", Lunar.redis)['*']["Bar"]

    assert_equal ['Foo:1:Bar', 'Foo:2:Bar'], nest.keys.sort
  end

  test "retrieving keys and their matches" do
    Lunar.redis.set("Foo:1:Bar", 1)
    Lunar.redis.set("Foo:2:Bar", 2)

    nest = Lunar::LunarNest.new("Foo", Lunar.redis)['*']["Bar"]

    matches = []

    nest.matches.each do |key, m|
      matches << m
    end

    assert_equal ['1', '2'], matches.sort
  end

  test "retrieving keys and their matches when more than one *" do
    Lunar.redis.set("Foo:1:Bar:3:Baz", 1)
    Lunar.redis.set("Foo:2:Bar:4:Baz", 2)

    nest = Lunar::LunarNest.new("Foo", Lunar.redis)['*']["Bar"]["*"]["Baz"]

    matches1 = []
    matches2 = []

    nest.matches.each do |key, m1, m2|
      matches1 << m1
      matches2 << m2
    end

    assert_equal ['1', '2'], matches1.sort
    assert_equal ['3', '4'], matches2.sort
  end

end