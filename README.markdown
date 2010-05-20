Lunar: full text searching on top of Redis
==========================================

But why?
--------
We have been using Redis as our datastore exclusively for a lot of projects.
But searching is still something that is required by most projects. Given
those requirements and what we have, we could:

1. Use SOLR and install it / manage it on every application we build.
2. Use Sphinx (mind you we don't have MySQL running in our server too).
3. Build our own (this appears to be something prevalent nowadays :D)

Sphinx vs Lunar vs SOLR
-----------------------
SOLR is definitely the way to go if you have heavyweight searching requirements.
Sphinx on the other hand, is probably an even match against Lunar.

Features
--------

1. Full text search matching using metaphones.
2. Ability to search by a specific field.
3. Range matching for `number`s.
4. Fuzzy matching for address book style autocompletion needs.

Probably the most unique thing about Lunar is its Fuzzy matching
capability. SOLR and Sphinx don't do this out of the box.

Example
-------
Given you want to index a document with a `namespace` Gadget.

    Lunar.index Gadget do |i|
      i.text  :name, 'iphone 3gs'
      i.text  :tags, 'mobile apple smartphone'

      i.number :price, 200
      i.number :rating, 25.5

      i.sortable :votes, 50
    end

    #  with this declaration, you can now search:
    Lunar.search Gadget, :q => 'iphone'
    Lunar.search Gadget, :name => 'iphone', :tags => 'mobile'
    Lunar.search Gadget, :price => 150..250

    # If you need fuzzy matching you can also do that:
    Lunar.index Customer do |i|
      i.id 1001
      i.fuzzy :name, "Abraham Lincoln"
    end

    Lunar.index Customer do |i|
      i.id 1002
      i.fuzzy :name, "Barack Obama"
    end

    Lunar.search Customer, :fuzzy => { :name => "A" }
    # returns [Customer[1001]]

    Lunar.search Customer, :fuzzy => { :name => "B" }
    # returns [Customer[1002]]

    # for sorting, you can do it on the `ResultSet` returned:
    results = Lunar.search Gadget :q => 'iphone', :tags => 'mobile'
    results.sort(:by => :votes, :order => "ASC")
    results.sort(:by => :votes, :order => "DESC")

    # this is also compatible with the pagination gem of course:
    # let's say in our sinatra handler we do something like:

    get '/gadget/search' do
      @gadgets = paginate(Lunar.search(Gadget, :q => params[:q]),
        :per_page => 10, :page => params[:page],
        :sort_by => :votes, :order => 'DESC'
      )
    end

    # see http://github.com/sinefunc/pagination for more info.

Under the Hood?
---------------
A quick rundown of what happens when we do fulltext indexing:

    Lunar.index :Gadget do |i|
      i.id 1001
      i.text :title, "apple apple apple macbook macbook pro"
    end

    # Executes the ff: in redis:
    #
    # ZADD Lunar:Gadget:title:APL  3 1001
    # ZADD Lunar:Gadget:title:MKBK 2 1001
    # ZADD Lunar:Gadget:title:PR   1 1001
    #
    # In addition a reference of all the words are stored
    # SMEMBERS Lunar:Gadget:Metaphones:1001:title
    # => (APL, MKBK, PR)

Note on Patches/Pull Requests
-----------------------------

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a
  commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

### Copyright

Copyright (c) 2010 Cyril David. See LICENSE for details.