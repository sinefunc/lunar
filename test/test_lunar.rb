require 'helper'

class TestLunar < Test::Unit::TestCase
  class Gadget < Struct.new(:id)
    def self.[](id)
      new(id)
    end
  end

  context "an index of some gadgets" do
    setup do
      Lunar.index Gadget do |i|
        i.id 1001
        i.text   :title, 'apple iphone 3GS smartphone'
        i.text   :tags, 'mobile smartphone apple'
        i.number :price, 200
        i.number :score, 35.5
        i.fuzzy  :code, 'apple iphone mobile tmobile'

        i.sortable :price, 200
        i.sortable :score, 35.5
        i.sortable :title, 'apple iphone 3GS'
      end

      Lunar.index Gadget do |i|
        i.id 1002
        i.text   :title, 'nokia N95 Symbian smartphone'
        i.text   :tags,  'mobile smartphone nokia'
        i.number :price, 150
        i.number :score, 20.5
        i.fuzzy  :code,  'nokia n95 mobile'

        i.sortable :price, 150
        i.sortable :score, 20.5
        i.sortable :title, 'nokia N95 Symbian smartphone'
      end

      Lunar.index Gadget do |i|
        i.id 1003
        i.text   :title, 'blackberry bold 9000 smartphone'
        i.text   :tags, 'mobile smartphone blackberry'
        i.number :price, 170
        i.number :score, 25.5
        i.fuzzy  :code,  'blackberry bold mobile'

        i.sortable :price, 170
        i.sortable :score, 25.5
        i.sortable :title, 'blackberry bold 9000 smartphone'
      end
    end

    def q(options)
      Lunar.search(Gadget, options).map(&:id)
    end

    test "all kinds of fulltext searching" do
      assert_equal %w{1001}, q(:q => 'apple')
      assert_equal %w{1001}, q(:q => 'iphone')
      assert_equal %w{1001}, q(:q => '3gs')
      assert_equal %w{1001 1002 1003}, q(:q => 'smartphone')
      assert_equal %w{1001 1002 1003}, q(:q => 'mobile')
      assert_equal %w{1002}, q(:q => 'nokia')
      assert_equal %w{1002}, q(:q => 'n95')
      assert_equal %w{1002}, q(:q => 'symbian')
      assert_equal %w{1003}, q(:q => 'blackberry')
      assert_equal %w{1003}, q(:q => 'bold')
      assert_equal %w{1003}, q(:q => '9000')
    end

    test "fulltext searching with an except" do
      assert_equal [], q(:q => 'apple', :except => { :numbers => { :price => 200 }})
      assert_equal [], q(:q => 'iphone', :except => { :numbers => { :price => 200 }})
      assert_equal [], q(:q => '3gs', :except => { :numbers => { :price => 200 }})
      assert_equal %w{1001 1002}, q(:q => 'smartphone', :except => { :numbers => { :price => 170 }})
      assert_equal %w{1001 1002}, q(:q => 'mobile', :except => { :numbers => { :price => 170 }})
      assert_equal [], q(:q => 'nokia', :except => { :fuzzy => { :code => 'nokia' }})
      assert_equal [], q(:q => 'n95', :except => { :fuzzy => { :code => 'nokia'}})
      assert_equal [], q(:q => 'symbian', :except => { :fuzzy => { :code => 'nokia'}})
      assert_equal %w{1003}, q(:q => 'blackberry', :except => { :fuzzy => { :code => 'nokia'}})
      assert_equal %w{1003}, q(:q => 'bold', :except => { :fuzzy => { :code => 'nokia'}})
      assert_equal %w{1003}, q(:q => '9000', :except => { :fuzzy => { :code => 'nokia'}})
    end

    test "searching non-existent words" do
      assert_equal [], q(:q => "ericson")
      assert_equal [], q(:q => "ericson", :title => "apple")
      assert_equal [], q(:q => "ericson", :description => "nokia")
      assert_equal [], q(:q => "ericson", :description => "FooBar")
      assert_equal [], q(:q => "ericson", :fuzzy => { :code => "a" })
      assert_equal [], q(:q => "ericson", :price => 150..200)
    end

    test "searching combinations of empty strings" do
      assert_equal %w{1001}, q(:q => 'apple', :tags => 'mobile', :title => "")
      assert_equal %w{1001}, q(:q => 'apple', :tags => 'smartphone', :title => "")
      assert_equal %w{1001}, q(:q => 'apple', :tags => 'apple', :title => "")

      assert_equal %w{1001 1002 1003}, q(:q => 'mobile', :tags => 'smartphone', :title => "")
    end

    test "sorting empty result sets" do
      assert_equal [], Lunar.search(Gadget, :q => "ericson").sort(:by => :price)
    end

    test "fulltext searching with key value pairs" do
      assert_equal %w{1001}, q(:q => 'apple', :tags => 'mobile')
      assert_equal %w{1001}, q(:q => 'apple', :tags => 'smartphone')
      assert_equal %w{1001}, q(:q => 'apple', :tags => 'apple')

      assert_equal %w{1001 1002 1003}, q(:q => 'mobile', :tags => 'smartphone')
    end

    test "fulltext + keyword searching with range matching" do
      assert_equal %w{1001}, q(:q => 'mobile', :tags => 'smartphone', :price => 200..200)
      assert_equal %w{1002}, q(:q => 'mobile', :tags => 'smartphone', :price => 150..150)
      assert_equal %w{1003}, q(:q => 'mobile', :tags => 'smartphone', :price => 170..170)

      assert_equal %w{1001 1002 1003}, q(:price => 150..200)
    end

    test "searching one key => value pair" do
      assert_equal %w{1001}, q(:title => 'apple')
      assert_equal %w{1001}, q(:title => 'iphone')
      assert_equal %w{1001}, q(:title => '3GS')
      assert_equal %w{1001 1002 1003}, q(:title => 'smartphone')
    end

    test "searching multiple key => value pairs" do
      assert_equal %w{1001}, q(:title => 'apple', :tags => 'mobile')
      assert_equal %w{1001}, q(:title => 'apple', :tags => 'smartphone')
      assert_equal %w{1001}, q(:title => 'apple', :tags => 'apple')

      assert_equal %w{1001 1002 1003}, q(:title => 'smartphone', :tags => 'mobile')
      assert_equal %w{1001 1002 1003}, q(:title => 'smartphone', :tags => 'smartphone')
      assert_equal %w{1001}, q(:title => 'smartphone', :tags => 'apple')
    end

    test "sorting by price" do
      r = Lunar.search(Gadget, :q => 'smartphone').sort_by(:price, :order => 'ASC')
      assert_equal %w{1002 1003 1001}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort_by(:price, :order => 'DESC')
      assert_equal %w{1001 1003 1002}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort(:by => :price, :order => 'ASC')
      assert_equal %w{1002 1003 1001}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort(:by => :price, :order => 'DESC')
      assert_equal %w{1001 1003 1002}, r.map(&:id)
    end

    test "sorting by score" do
      r = Lunar.search(Gadget, :q => 'smartphone').sort_by(:score, :order => 'ASC')
      assert_equal %w{1002 1003 1001}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort_by(:score, :order => 'DESC')
      assert_equal %w{1001 1003 1002}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort(:by => :score, :order => 'ASC')
      assert_equal %w{1002 1003 1001}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort(:by => :score, :order => 'DESC')
      assert_equal %w{1001 1003 1002}, r.map(&:id)
    end

    test "sorting by title" do
      r = Lunar.search(Gadget, :q => 'smartphone').sort_by(:title, :order => 'ALPHA ASC')
      assert_equal %w{1001 1003 1002}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort_by(:title, :order => 'ALPHA DESC')
      assert_equal %w{1002 1003 1001}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort(:by => :title, :order => 'ALPHA ASC')
      assert_equal %w{1001 1003 1002}, r.map(&:id)

      r = Lunar.search(Gadget, :q => 'smartphone').sort(:by => :title, :order => 'ALPHA DESC')
      assert_equal %w{1002 1003 1001}, r.map(&:id)
    end

    test "fuzzy matching on code apple iphone" do
      assert_equal %w{1001}, q(:fuzzy => { :code => 'T' })

      assert_equal %w{1001}, q(:fuzzy => { :code => 'a' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'ap' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'app' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'appl' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'apple' })

      assert_equal %w{1001}, q(:fuzzy => { :code => 'i' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'ip' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'iph' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'ipho' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'iphon' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'iphone' })

      assert_equal %w{1001}, q(:fuzzy => { :code => 'a i' })
      assert_equal %w{1001}, q(:fuzzy => { :code => 'app iph' })
    end

    test "fuzzy matching on code mobile" do
      assert_equal %w{1001 1002 1003}, q(:fuzzy => { :code => 'm' })
      assert_equal %w{1001 1002 1003}, q(:fuzzy => { :code => 'mo' })
      assert_equal %w{1001 1002 1003}, q(:fuzzy => { :code => 'mob' })
      assert_equal %w{1001 1002 1003}, q(:fuzzy => { :code => 'mobi' })
      assert_equal %w{1001 1002 1003}, q(:fuzzy => { :code => 'mobil' })
      assert_equal %w{1001 1002 1003}, q(:fuzzy => { :code => 'mobile' })
    end

    test "fuzzy matching on code mobile with keywords: apple" do
      assert_equal %w{1001}, q(:q => 'apple', :fuzzy => { :code => 'm' })
      assert_equal %w{1001}, q(:q => 'apple', :fuzzy => { :code => 'mo' })
      assert_equal %w{1001}, q(:q => 'apple', :fuzzy => { :code => 'mob' })
      assert_equal %w{1001}, q(:q => 'apple', :fuzzy => { :code => 'mobi' })
      assert_equal %w{1001}, q(:q => 'apple', :fuzzy => { :code => 'mobil' })
      assert_equal %w{1001}, q(:q => 'apple', :fuzzy => { :code => 'mobile' })
    end
  end

  context "searching multiple fuzzy fields at the same time" do
    setup do
      Lunar.index Gadget do |i|
        i.id 1001
        i.fuzzy :first, "The First"
        i.fuzzy :last,  "The Last"
      end

      Lunar.index Gadget do |i|
        i.id 1002
        i.fuzzy :first, "La Primera"
        i.fuzzy :last,  "El Ultimo"
      end
    end 

    test "fails to find non-intersecting sets" do
      res = Lunar.search Gadget, :fuzzy => { :first => "First", :last => "Primera" }

      assert_equal 0, res.size
    end

    test "is able to find First and Last" do
      res = Lunar.search Gadget, :fuzzy => { :first => "First", :last => "Last" }
  
      assert_equal %w{1001}, res.map(&:id)
    end
  end
end
