#######################################################################
# test_win32_job.rb
#
# Test suite for the win32-job library. You should run these tests
# via the "rake test" command.
#######################################################################
require 'test-unit'
require 'win32/job'

class TC_Win32_Job < Test::Unit::TestCase
  def setup
    @name = 'ruby_xxxxxx'
    @job = Win32::Job.new(@name)
    @pid = Process.spawn('notepad')
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

  test "close method does not accept any arguments" do
    assert_raise(ArgumentError){ @job.close(1) }
  end

  test "add_process basic functionality" do
    assert_respond_to(@job, :add_process)
  end

  test "add_process works as expected" do
    assert_nothing_raised{ @job.add_process(@pid) }
  end

  test "add process requires a single argument" do
    assert_raise(ArgumentError){ @job.add_process }
  end

  test "configure_limit basic functionality" do
    assert_nothing_raised{ @job.configure_limit }
  end

  test "configure_limit works as expected" do
    assert_nothing_raised{
      @job.configure_limit(
        :breakaway_ok      => true,
        :kill_on_job_close => true,
        :process_memory    => 1024 * 8,
        :process_time      => 1000
      )
    }
  end

  test "configure_limit raises an error if it detects an invalid option" do
    assert_raise(ArgumentError){ @job.configure_limit(:bogus => 1) }
  end

  test "priority constants are defined" do
    assert_not_nil(Win32::Job::ABOVE_NORMAL_PRIORITY_CLASS)
    assert_not_nil(Win32::Job::BELOW_NORMAL_PRIORITY_CLASS)
    assert_not_nil(Win32::Job::HIGH_PRIORITY_CLASS)
    assert_not_nil(Win32::Job::IDLE_PRIORITY_CLASS)
    assert_not_nil(Win32::Job::NORMAL_PRIORITY_CLASS)
    assert_not_nil(Win32::Job::REALTIME_PRIORITY_CLASS)
  end

  def teardown
    @name = nil

    @job.close
    @job = nil

    Process.kill(9, @pid)
    @pid = nil
  end
end
