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
    extend Windows::Functions

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
      @closed = false

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

      ObjectSpace.define_finalizer(self, self.class.finalize(@job_handle, @closed))
    end

    # Add process +pid+ to the job object. Process ID's added to the
    # job are tracked via the Job#process_list accessor.
    #
    def add_process(pid)
      if @process_list.size > 99
        raise ArgumentError, "maximum number of processes reached"
      end

      phandle = OpenProcess(PROCESS_ALL_ACCESS, false, pid)

      if phandle == 0
        raise SystemCallError.new('OpenProcess', FFI.errno)
      end

      pbool = FFI::MemoryPointer.new(:int)

      IsProcessInJob(phandle, 0, pbool)

      if pbool.read_int == 0
        unless AssignProcessToJobObject(@job_handle, phandle)
          raise SystemCallError.new('AssignProcessToJobObject', FFI.errno)
        end
        @process_list << pid
      else
        raise ArgumentError, "pid #{pid} is already part of a job"
      end

      pid
    end

    # Close the job object.
    #
    def close
      CloseHandle(@job_handle) if @job_handle
      @closed = true
    end

    def self.finalize(handle, closed)
      proc{ CloseHandle(handle) unless closed }
    end

    # Kill all processes associated with the job object that are
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

    # Return a list of process ids that are part of the job.
    #
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
        raise SystemCallError.new('QueryInformationJobObject', FFI.errno)
      end

      info[:ProcessIdList].to_a.select{ |n| n != 0 }
    end

    # Returns
    def account_info
      info = JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION.new

      bool = QueryInformationJobObject(
        @job_handle,
        JobObjectBasicAndIoAccountingInformation,
        info,
        info.size,
        nil
      )

      unless bool
        raise SystemCallError.new('QueryInformationJobObject', FFI.errno)
      end

      struct = AccountInfo.new(
        info[:BasicInfo][:TotalUserTime][:QuadPart],
        info[:BasicInfo][:TotalKernelTime][:QuadPart],
        info[:BasicInfo][:ThisPeriodTotalUserTime][:QuadPart],
        info[:BasicInfo][:ThisPeriodTotalKernelTime][:QuadPart],
        info[:BasicInfo][:TotalPageFaultCount],
        info[:BasicInfo][:TotalProcesses],
        info[:BasicInfo][:ActiveProcesses],
        info[:BasicInfo][:TotalTerminatedProcesses],
        info[:IoInfo][:ReadOperationCount],
        info[:IoInfo][:WriteOperationCount],
        info[:IoInfo][:OtherOperationCount],
        info[:IoInfo][:ReadTransferCount],
        info[:IoInfo][:WriteTransferCount],
        info[:IoInfo][:OtherTransferCount]
      )

      struct
    end

    # Return limit information for the process group.
    #
    def limit_info
      info = JOBOBJECT_EXTENDED_LIMIT_INFORMATION.new

      bool = QueryInformationJobObject(
        @job_handle,
        JobObjectExtendedLimitInformation,
        info,
        info.size,
        nil
      )

      unless bool
        raise SystemCallError.new('QueryInformationJobObject', FFI.errno)
      end

      struct = LimitInfo.new(
        info[:BasicLimitInformation][:PerProcessUserTimeLimit][:QuadPart],
        info[:BasicLimitInformation][:PerJobUserTimeLimit][:QuadPart],
        info[:BasicLimitInformation][:LimitFlags],
        info[:BasicLimitInformation][:MinimumWorkingSetSize],
        info[:BasicLimitInformation][:MaximumWorkingSetSize],
        info[:BasicLimitInformation][:ActiveProcessLimit],
        info[:BasicLimitInformation][:Affinity],
        info[:BasicLimitInformation][:PriorityClass],
        info[:BasicLimitInformation][:SchedulingClass],
        info[:IoInfo][:ReadOperationCount],
        info[:IoInfo][:WriteOperationCount],
        info[:IoInfo][:OtherOperationCount],
        info[:IoInfo][:ReadTransferCount],
        info[:IoInfo][:WriteTransferCount],
        info[:IoInfo][:OtherTransferCount],
        info[:ProcessMemoryLimit],
        info[:JobMemoryLimit],
        info[:PeakProcessMemoryUsed],
        info[:PeakJobMemoryUsed]
      )

      struct
    end
  end
end

if $0 == __FILE__
  include Win32
  j = Job.new('test')
  j.process_list
  pid1 = Process.spawn("notepad.exe")
  pid2 = Process.spawn("notepad.exe")
  #p pid1
  #p pid2
  j.add_process(pid1)
  j.add_process(pid2)
  p j.process_list
  sleep 10
  p j.account_info
  sleep 10
  p j.account_info
  p j.limit_info
  sleep 5
  j.close
end
