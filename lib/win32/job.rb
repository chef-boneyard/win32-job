require File.join(File.dirname(__FILE__), 'job', 'constants')
require File.join(File.dirname(__FILE__), 'job', 'functions')
require File.join(File.dirname(__FILE__), 'job', 'structs')

# The Win32 module serves as a namespace only.
module Win32

  # The Job class encapsulates a Windows Job object.
  class Job
    include Windows::Constants
    include Windows::Functions
    include Windows::Structs

    # The version of the win32-job library
    VERSION = '0.1.0'

    private

    # Valid options for the configure method
    VALID_OPTIONS = %w[
      active_process
      affinity
      breakaway_ok
      die_on_unhandled_exception
      job_memory
      job_time
      kill_on_job_close
      preserve_job_time
      priority_class
      process_memory
      process_time
      scheduling_class
      silent_breakaway_ok
      workingset
    ]

    public

    #attr_reader :process_list
    attr_reader :job_name

    alias :name :job_name

    # Create a new Job object identified by +name+. If no name is provided
    # then an anonymous job is created.
    #
    # If the +kill_on_close+ argument is true, all associated processes are
    # terminated and the job object then destroys itself. Otherwise, the job
    # object will not be destroyed until all associated processes have exited.
    #
    def initialize(name = nil, security = nil)
      raise TypeError unless name.is_a?(String) if name

      @job_name = name
      @process_list = []

      @job_handle = CreateJobObject(security, name)

      if @job_handle == 0
        raise SystemCallError.new('CreateJobObject', FFI.errno)
      end

      if block_given?
        begin
          yield self
        ensure
          close
        end
      end
    end

    # Add process +pid+ to the job object. Process ID's added to the
    # job are tracked via the Job#process_list accessor.
    #
    def add_process(pid)
      phandle = OpenProcess(PROCESS_ALL_ACCESS, false, pid)

      if phandle == 0
        raise SystemCallError.new('OpenProcess', FFI.errno)
      end

      pbool = FFI::MemoryPointer.new(:int)

      IsProcessInJob(phandle, 0, pbool)

      if pbool.read_int == 0
        unless AssignProcessToJobObject(@job_handle, phandle)
          error = FFI.errno
          close
          raise SystemCallError.new('AssignProcessToJobObject', error)
        end
        @process_list << pid
      else
        close
        raise ArgumentError, "pid #{pid} is already part of a job"
      end

      pid
    end

    # Close the job object.
    #
    def close
      CloseHandle(@job_handle) if @job_handle
    end

    # Kill all processes associated with the job object that is
    # associated with the current process.
    #
    def kill
      if TerminateJobObject(@job_handle, Process.pid) == 0
        raise SystemCallError.new('TerminateJobObject', FFI.errno)
      end
    end

    # Set various job limits. Possible options are:
    #
    # * active_process
    # * affinity
    # * breakaway_ok
    # * die_on_unhandled_exception
    # * job_memory
    # * job_time
    # * kill_on_job_close
    # * preserve_job_time
    # * priority_class
    # * process_memory
    # * process_time
    # * scheduling_class
    # * silent_breakaway_ok
    # * workingset
    #--
    # The options are based on the LimitFlags of the
    # JOBOBJECT_BASIC_LIMIT_INFORMATION struct.
    #
    def configure(options = {})
      unless options.is_a?(Hash)
        raise TypeError, "argument to configure must be a hash"
      end

      options.each{ |key, value|
        key = key.to_s.downcase
        unless VALID_OPTIONS.include?(key)
          raise ArgumentError, "invalid option '#{key}'"
        end
        options[key.to_sym] = value
      }

      job_struct = 0.chr * 44

      if options[:process_time]
        job_struct[0, 8] = [options[:process_time]].pack('L')
      end

      if options[:job_time]
        job_struct[0, 8] = [options[:process_time]].pack('L')
      end
    end

    def process_list
      info = JOBOBJECT_BASIC_PROCESS_ID_LIST.new

      bool = QueryInformationJobObject(
        @job_handle,
        JobObjectBasicProcessIdList,
        info,
        info.size,
        nil
      )

      unless bool
        error = FFI.errno
        close
        raise SystemCallError.new('QueryInformationJobObject', error)
      end

      p info[:NumberOfAssignedProcesses]
      #p info[:ProcessIdList]
    end
  end
end

if $0 == __FILE__
  include Win32
  j = Job.new('test')
  j.process_list
  pid1 = Process.spawn("notepad.exe")
  pid2 = Process.spawn("notepad.exe")
  p pid1
  p pid2
  j.add_process(pid1)
  j.add_process(pid2)
  j.process_list
  j.close
end
