require 'rubygems'
gem 'test-unit'

require 'test/unit'
require 'win32/job'

class TC_Win32_Job < Test::Unit::TestCase
  def setup
    @name = 'ruby_xxxxxx'
    @job  = Win32::Job.new(@name)
  end

  test "version number is what we expect" do
    assert_equal('0.1.0', Win32::Job::VERSION)
  end
  
  test "constructor argument may be omitted" do
    assert_nothing_raised{ Win32::Job.new }
  end

  test "constructor accepts a name for the job" do
    assert_nothing_raised{ Win32::Job.new(@name) }
  end

  test "argument to constructor must be a string" do
    assert_raise(TypeError){ Win32::Job.new(1) }
  end

  test "job_name basic functionality" do
    assert_respond_to(@job, :job_name)
    assert_nothing_raised{ @job.job_name }
    assert_kind_of(String, @job.job_name)
  end

  test "job_name is read-only" do
    assert_raise(NoMethodError){ @job.job_name = 'foo' }
  end

  test "name is an alias for job_name" do
    assert_alias_method(@job, :name, :job_name)
  end

  test "close basic functionality" do
    assert_respond_to(@job, :close)
    assert_nothing_raised{ @job.close }
  end

  test "calling close multiple times has no effect" do
    assert_nothing_raised{ @job.close }
    assert_nothing_raised{ @job.close }
    assert_nothing_raised{ @job.close }
  end

  def teardown
    @name = nil
    @job  = nil
  end
end
