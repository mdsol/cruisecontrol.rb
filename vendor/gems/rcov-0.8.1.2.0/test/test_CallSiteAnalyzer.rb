

require 'test/unit'
require 'rcov'

class Test_CallSiteAnalyzer < Test::Unit::TestCase

  sample_file = File.join(File.dirname(__FILE__), "sample_03.rb")
  load sample_file

  def setup
    @a = Rcov::CallSiteAnalyzer.new
    @o = Rcov::Test::Temporary::Sample03.new
  end

  def verify_callsites_equal(expected, actual)
    callsites = expected.inject({}) do |s,(backtrace, count)| 
      unless $".any?{|x| %r{\brcovrt\b} =~ x}
        backtrace = backtrace.map{|_, mid, file, line| [nil, mid, file, line] }
      end
      s[Rcov::CallSiteAnalyzer::CallSite.new(backtrace)] = count
      s
    end
    assert_equal(callsites, actual)
  end

  def verify_defsite_equal(expected, actual)
    assert_equal(Rcov::CallSiteAnalyzer::DefSite.new(*expected), actual)
  end

  def test_callsite_compute_raw_difference
    src = [ 
            { ["Foo", "foo"] => {"bar" => 1},
              ["Foo", "bar"] => {"baz" => 10} }, 
            { ["Foo", "foo"] => ["foo.rb", 10] } 
          ]
    dst = [ 
            { ["Foo", "foo"] => {"bar" => 1, "fubar" => 10},
              ["Foo", "baz"] => {"baz" => 10} },
            { ["Foo", "foo"] => ["fooredef.rb", 10],
              ["Foo", "baz"] => ["foo.rb", 20]}
          ]
    expected = [ 
                 { ["Foo", "foo"] => {"fubar" => 10},
                   ["Foo", "baz"] => {"baz"   => 10} },
                 { ["Foo", "foo"] => ["fooredef.rb", 10],
                   ["Foo", "baz"] => ["foo.rb", 20] } 
    ]
               
    assert_equal(expected, 
                 @a.instance_eval{ compute_raw_data_difference(src, dst) } )
  end

  def test_return_values_when_no_match
    @a.run_hooked{ @o.f1 }
    assert_equal(nil, @a.defsite("Foobar#bogus"))
    assert_equal(nil, @a.defsite("Foobar", "bogus"))
    assert_equal(nil, @a.callsites("Foobar", "bogus"))
    assert_equal(nil, @a.callsites("Foobar.bogus"))
    assert_equal(nil, @a.callsites("<Class:Foobar>", "bogus"))
  end

  def test_basic_defsite_recording
    @a.run_hooked{ @o.f1 }
    verify_defsite_equal(["./test/sample_03.rb", 3], 
                 @a.defsite("Rcov::Test::Temporary::Sample03", "f1"))
    verify_defsite_equal(["./test/sample_03.rb", 7], 
                 @a.defsite("Rcov::Test::Temporary::Sample03", "f2"))
    verify_defsite_equal(["./test/sample_03.rb", 7], 
                 @a.defsite("Rcov::Test::Temporary::Sample03#f2"))
  end

  def test_basic_callsite_recording
    @a.run_hooked{ @o.f1 }
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1, "./test/sample_03.rb", 4]] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1, "./test/sample_03.rb", 4]] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03#f2"))
    #verify_callsites_equal({["./test/sample_03.rb:4:in `f1'"] => 10}, 
    #             @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
    #verify_callsites_equal({["./test/sample_03.rb:4:in `f1'"] => 10}, 
    #             @a.callsites("Rcov::Test::Temporary::Sample03#f2"))
  end

  def test_basic_callsite_recording_API
    @a.run_hooked{ @o.f1 }
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1, 
                              "./test/sample_03.rb", 4]] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1, "./test/sample_03.rb", 4]] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
    callsites = @a.callsites("Rcov::Test::Temporary::Sample03", "f2")
    callsite = callsites.keys[0]
    assert_equal("./test/sample_03.rb", callsite.file)
    assert_equal(4, callsite.line)
    assert_equal(:f1, callsite.calling_method)
  end
  
  
  def test_basic_callsite_recording_with_singleton_classes
    @a.run_hooked{ @o.class.g1 }
    assert(@a.analyzed_classes.include?("#<Class:Rcov::Test::Temporary::Sample03>"))
    assert_equal(%w[g1 g2], @a.analyzed_methods("#<Class:Rcov::Test::Temporary::Sample03>"))
    verify_callsites_equal({[[class << Rcov::Test::Temporary::Sample03; self end, 
                             :g1, "./test/sample_03.rb", 15]] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03.g2"))
    verify_callsites_equal({[[class << Rcov::Test::Temporary::Sample03; self end,
                              :g1, "./test/sample_03.rb", 15]] => 10}, 
                 @a.callsites("#<Class:Rcov::Test::Temporary::Sample03>","g2"))
  end


  def test_differential_callsite_recording
    @a.run_hooked{ @o.f1 }
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1,
                              "./test/sample_03.rb", 4]] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))

    @a.run_hooked{ @o.f1 }
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1,
                              "./test/sample_03.rb", 4]] => 20}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
    
    @a.run_hooked{ @o.f3 }
    assert_equal(%w[f1 f2 f3], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1, 
                              "./test/sample_03.rb", 4]] => 120,
                  [[Rcov::Test::Temporary::Sample03, :f3, 
                    "./test/sample_03.rb", 11]]=>100 },
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
  end

  def test_reset
    @a.run_hooked do
      10.times{ @o.f1 }
      @a.reset
      @o.f1
    end
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1, 
                              "./test/sample_03.rb", 4]] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))

  end

  def test_nested_callsite_recording
    a = Rcov::CallSiteAnalyzer.new
    b = Rcov::CallSiteAnalyzer.new
    a.run_hooked do 
      b.run_hooked { @o.f1 }
      assert(b.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
      assert_equal(%w[f1 f2], b.analyzed_methods("Rcov::Test::Temporary::Sample03"))
      verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1,
                                "./test/sample_03.rb", 4]] => 10}, 
                   b.callsites("Rcov::Test::Temporary::Sample03", "f2"))

      @o.f1
      assert_equal(%w[f1 f2], b.analyzed_methods("Rcov::Test::Temporary::Sample03"))
      verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1,
                                "./test/sample_03.rb", 4]] => 10}, 
                   b.callsites("Rcov::Test::Temporary::Sample03", "f2"))
      
      assert(a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
      assert_equal(%w[f1 f2], a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
      verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1,
                                "./test/sample_03.rb", 4]] => 20}, 
                   a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
    end
    b.run_hooked{ @o.f3 }
    assert_equal(%w[f1 f2 f3], b.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    verify_callsites_equal({[[Rcov::Test::Temporary::Sample03, :f1, 
                              "./test/sample_03.rb", 4]] => 110,
                  [[Rcov::Test::Temporary::Sample03, :f3,
                    "./test/sample_03.rb", 11]]=>100 },
                 b.callsites("Rcov::Test::Temporary::Sample03", "f2"))
  end

  def test_expand_name
    assert_equal(["Foo", "foo"], @a.instance_eval{ expand_name("Foo#foo") })
    assert_equal(["Foo", "foo"], @a.instance_eval{ expand_name("Foo", "foo") })
    assert_equal(["#<Class:Foo>", "foo"], 
                 @a.instance_eval{ expand_name("Foo.foo") })
    assert_equal(["#<Class:Foo>", "foo"], 
                 @a.instance_eval{ expand_name("#<Class:Foo>", "foo") })
  end
end
