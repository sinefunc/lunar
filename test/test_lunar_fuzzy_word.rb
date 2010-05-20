require "helper"

class LunarFuzzyWordTest < Test::Unit::TestCase
  context "the word 'dictionary'" do
    setup do
      @w = Lunar::FuzzyWord.new('dictionary')
    end

    should "have d, di, ... dictionary as it's partials" do
      assert_equal ['d', 'di', 'dic', 'dict', 'dicti', 'dictio',
        'diction', 'dictiona', 'dictionar', 'dictionary'], @w.partials
    end
  end
end