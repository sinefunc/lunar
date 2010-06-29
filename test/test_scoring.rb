require 'helper'

class LunarScoringTest < Test::Unit::TestCase
  describe "scores of 'the quick brown fox jumps over the lazy dog'" do
    should "return a hash of the words with score 1 except the, with score 2" do
      scoring = Lunar::Scoring.new("the quick brown fox jumps over the lazy dog")
      assert_equal 0, scoring.scores["the"]
      assert_equal 1, scoring.scores["quick"]
      assert_equal 1, scoring.scores["brown"]
      assert_equal 1, scoring.scores["fox"]
      assert_equal 1, scoring.scores["jumps"]
      assert_equal 1, scoring.scores["over"]
      assert_equal 1, scoring.scores["lazy"]
      assert_equal 1, scoring.scores["dog"]
    end
  end

  describe "scores of 'tHe qUick bRowN the quick brown THE QUICK BROWN'" do
    should "return a hash of each of the words the quick brown with score 3" do
      scoring = Lunar::Scoring.new('tHe qUick bRowN the quick brown THE QUICK BROWN')
      assert_equal 0, scoring.scores['the']
      assert_equal 3, scoring.scores['quick']
      assert_equal 3, scoring.scores['brown']
    end
  end

  describe 'scores of apple macbook pro 17"' do
    should "return a hash of apple macbook pro 17" do
      scoring = Lunar::Scoring.new('apple macbook pro 17"')
      assert_equal 1, scoring.scores['apple']
      assert_equal 1, scoring.scores['macbook']
      assert_equal 1, scoring.scores['pro']
      assert_equal 1, scoring.scores['17']
    end
  end
end
