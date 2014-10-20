require_relative 'job/constants'
require_relative 'job/functions'
require_relative 'job/structs'
require_relative 'job/helper'

# The Win32 module serves as a namespace only.
module Win32

  # The Job class encapsulates a Windows Job object.
  class Job
    include Windows::Constants
    include Windows::Functions
    include Windows::Structs
    extend Windows::Functions

    # The version of the win32-job library
    VERSION = '0.1.3'

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
      limit_job_time
      limit_affinity
      minimum_working_set
      maximum_working_set
      preserve_job_time
      priority_class
      process_memory
      process_time
      scheduling_class
      silent_breakaway_ok
    ]

    public

    # The name of the job, if specified.
    attr_reader :job_name

    alias :name :job_name

    # Create a new Job object identified by +name+. If no name is provided
    # then an anonymous job is created.
    #
    # If the job already exists then the existing job is opened instead, unless
    # the +open_existing+ method is false. In that case an error is
    # raised.
    #
    # The +security+ argument accepts a raw SECURITY_ATTRIBUTES struct that is
    # passed to the CreateJobObject function internally.
    #
    def initialize(name = nil, open_existing = true, security = nil)
      raise TypeError unless name.is_a?(String) if name

      @job_name = name
      @process_list = []
      @closed = false

      @job_handle = CreateJobObject(security, name)

      if @job_handle == 0
        FFI.raise_windows_error('CreateJobObject', FFI.errno)
      end

      if FFI.errno == ERROR_ALREADY_EXISTS && !open_existing
        raise ArgumentError, "job '#{name}' already exists"
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
    # Note that once a process is added to a job, the association cannot be
    # broken. A process can be associated with more than one job in a
    # hierarchy of nested jobs, however.
    #
    # You may add a maximum of 100 processes per job.
    #
    def add_process(pid)
      if @process_list.size > 99
        raise ArgumentError, "maximum number of processes reached"
      end

      phandle = OpenProcess(PROCESS_ALL_ACCESS, false, pid)

      if phandle == 0
        FFI.raise_windows_error('OpenProcess', FFI.errno)
      end

      pbool = FFI::MemoryPointer.new(:int)

      IsProcessInJob(phandle, 0, pbool)

      if pbool.read_int == 0
        unless AssignProcessToJobObject(@job_handle, phandle)
          FFI.raise_windows_error('AssignProcessToJobObject', FFI.errno)
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

    # Kill all processes associated with the job object that are
    # associated with the current process.
    #
    # Note that killing a process does not dissociate it from the job.
    #
    def kill
      unless TerminateJobObject(@job_handle, Process.pid)
        FFI.raise_windows_error('TerminateJobObject', FFI.errno)
      end

      @process_list = []
    end

    alias terminate kill

    # Set various job limits. Possible options are:
    #
    # * active_process => Numeric
    #     Establishes a maximum number of simultaneously active processes
    #     associated with the job.
    #
    # * affinity => Numeric
    #     Causes all processes associated with the job to use the same
    #     processor affinity.
    #
    # * breakaway_ok => Boolean
    #     If any process associated with the job creates a child process using
    #     the CREATE_BREAKAWAY_FROM_JOB flag while this limit is in effect, the
    #     child process is not associated with the job.
    #
    # * die_on_unhandled_exception => Boolean
    #     Forces a call to the SetErrorMode function with the SEM_NOGPFAULTERRORBOX
    #     flag for each process associated with the job. If an exception occurs
    #     and the system calls the UnhandledExceptionFilter function, the debugger
    #     will be given a chance to act. If there is no debugger, the functions
    #     returns EXCEPTION_EXECUTE_HANDLER. Normally, this will cause termination
    #     of the process with the exception code as the exit status.
    #
    # * job_memory => Numeric
    #     Causes all processes associated with the job to limit the job-wide
    #     sum of their committed memory. When a process attempts to commit
    #     memory that would exceed the job-wide limit, it fails. If the job
    #     object is associated with a completion port, a
    #     JOB_OBJECT_MSG_JOB_MEMORY_LIMIT message is sent to the completion
    #     port.
    #
    # * job_time => Numeric
    #     Establishes a user-mode execution time limit for the job.
    #
    # * kill_on_job_close => Boolean
    #     Causes all processes associated with the job to terminate when the
    #     last handle to the job is closed.
    #
    # * minimum_working_set_size => Numeric
    #     Causes all processes associated with the job to use the same minimum
    #     set size. If the job is nested, the effective working set size is the
    #     smallest working set size in the job chain.
    #
    # * maximum_working_set_size => Numeric
    #     Causes all processes associated with the job to use the same maximum
    #     set size. If the job is nested, the effective working set size is the
    #     smallest working set size in the job chain.
    #
    # * per_job_user_time_limit
    #     The per-job user-mode execution time limit, in 100-nanosecond ticks.
    #     The system adds the current time of the processes associated with the
    #     job to this limit.
    #
    #     For example, if you set this limit to 1 minute, and the job has a
    #     process that has accumulated 5 minutes of user-mode time, the limit
    #     actually enforced is 6 minutes.
    #
    #     The system periodically checks to determine whether the sum of the
    #     user-mode execution time for all processes is greater than this
    #     end-of-job limit. If so all processes are terminated.
    #
    # * per_process_user_time_limit
    #     The per-process user-mode execution time limit, in 100-nanosecond
    #     ticks. The system periodically checks to determine whether each
    #     process associated with the job has accumulated more user-mode time
    #     than the set limit. If it has, the process is terminated.
    #     If the job is nested, the effective limit is the most restrictive
    #     limit in the job chain.
    #
    # * preserve_job_time => Boolean
    #     Preserves any job time limits you previously set. As long as this flag
    #     is set, you can establish a per-job time limit once, then alter other
    #     limits in subsequent calls. This flag cannot be used with job_time.
    #
    # * priority_class => Numeric
    #     Causes all processes associated with the job to use the same priority
    #     class, e.g. ABOVE_NORMAL_PRIORITY_CLASS.
    #
    # * process_memory => Numeric
    #     Causes all processes associated with the job to limit their committed
    #     memory. When a process attempts to commit memory that would exceed
    #     the per-process limit, it fails. If the job object is associated with
    #     a completion port, a JOB_OBJECT_MSG_PROCESS_MEMORY_LIMIT message is
    #     sent to the completion port. If the job is nested, the effective
    #     memory limit is the most restrictive memory limit in the job chain.
    #
    # * process_time => Numeric
    #     Establishes a user-mode execution time limit for each currently
    #     active process and for all future processes associated with the job.
    #
    # * scheduling_class => Numeric
    #     Causes all processes in the job to use the same scheduling class. If
    #     the job is nested, the effective scheduling class is the lowest
    #     scheduling class in the job chain.
    #
    # * silent_breakaway_ok => Boolean
    #     Allows any process associated with the job to create child processes
    #     that are not associated with the job. If the job is nested and its
    #     immediate job object allows breakaway, the child process breaks away
    #     from the immediate job object and from each job in the parent job chain,
    #     moving up the hierarchy until it reaches a job that does not permit
    #     breakaway. If the immediate job object does not allow breakaway, the
    #     child process does not break away even if jobs in its parent job
    #     chain allow it.
    #
    # * subset_affinity => Numeric
    #     Allows processes to use a subset of the processor affinity for all
    #     processes associated with the job.
    #--
    # The options are based on the LimitFlags of the
    # JOBOBJECT_BASIC_LIMIT_INFORMATION struct.
    #
    def configure_limit(options = {})
      unless options.is_a?(Hash)
        raise TypeError, "argument to configure must be a hash"
      end

      # Validate options
      options.each{ |key,value|
        unless VALID_OPTIONS.include?(key.to_s.downcase)
          raise ArgumentError, "invalid option '#{key}'"
        end
      }

      flags  = 0
      struct = JOBOBJECT_EXTENDED_LIMIT_INFORMATION.new

      if options[:active_process]
        flags |= JOB_OBJECT_LIMIT_ACTIVE_PROCESS
        struct[:BasicInformatin][:ActiveProcessLimit] = options[:active_process]
      end

      if options[:affinity]
        flags |= JOB_OBJECT_LIMIT_AFFINITY
        struct[:BasicLimitInformation][:Affinity] = options[:affinity]
      end

      if options[:breakaway_ok]
        flags |= JOB_OBJECT_LIMIT_BREAKAWAY_OK
      end

      if options[:die_on_unhandled_exception]
        flags |= JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION
      end

      if options[:job_memory]
        flags |= JOB_OBJECT_LIMIT_JOB_MEMORY
        struct[:JobMemoryLimit] = options[:job_memory]
      end

      if options[:per_job_user_time_limit]
        flags |= JOB_OBJECT_LIMIT_JOB_TIME
        struct[:BasicLimitInformation][:PerJobUserTimeLimit][:QuadPart] = options[:per_job_user_time_limit]
      end

      if options[:kill_on_job_close]
        flags |= JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
      end

      if options[:preserve_job_time]
        flags |= JOB_OBJECT_LIMIT_PRESERVE_JOB_TIME
      end

      if options[:priority_class]
        flags |= JOB_OBJECT_LIMIT_PRIORITY_CLASS
        struct[:BasicLimitInformation][:PriorityClass] = options[:priority_class]
      end

      if options[:process_memory]
        flags |= JOB_OBJECT_LIMIT_PROCESS_MEMORY
        struct[:ProcessMemoryLimit] = options[:process_memory]
      end

      if options[:process_time]
        flags |= JOB_OBJECT_LIMIT_PROCESS_TIME
        struct[:BasicLimitInformation][:PerProcessUserTimeLimit][:QuadPart] = options[:process_time]
      end

      if options[:scheduling_class]
        flags |= JOB_OBJECT_LIMIT_SCHEDULING_CLASS
        struct[:BasicLimitInformation][:SchedulingClass] = options[:scheduling_class]
      end

      if options[:silent_breakaway_ok]
        flags |= JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK
      end

      if options[:subset_affinity]
        flags |= JOB_OBJECT_LIMIT_SUBSET_AFFINITY | JOB_OBJECT_LIMIT_AFFINITY
      end

      if options[:minimum_working_set_size]
        flags |= JOB_OBJECT_LIMIT_WORKINGSET
        struct[:BasicLimitInformation][:MinimumWorkingSetSize] = options[:minimum_working_set_size]
      end

      if options[:maximum_working_set_size]
        flags |= JOB_OBJECT_LIMIT_WORKINGSET
        struct[:BasicLimitInformation][:MaximumWorkingSetSize] = options[:maximum_working_set_size]
      end

      struct[:BasicLimitInformation][:LimitFlags] = flags

      bool = SetInformationJobObject(
        @job_handle,
        JobObjectExtendedLimitInformation,
        struct,
        struct.size
      )

      unless bool
        FFI.raise_windows_error('SetInformationJobObject', FFI.errno)
      end

      options
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
        FFI.raise_windows_error('QueryInformationJobObject', FFI.errno)
      end

      info[:ProcessIdList].to_a[0...info[:NumberOfProcessIdsInList]]
    end

    # Returns an AccountInfoStruct that shows various job accounting
    # information, such as total user time, total kernel time, the
    # total number of processes, and so on.
    #
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
        FFI.raise_windows_error('QueryInformationJobObject', FFI.errno)
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
        FFI.raise_windows_error('QueryInformationJobObject', FFI.errno)
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

    # Waits for the processes in the job to terminate.
    #--
    # See http://blogs.msdn.com/b/oldnewthing/archive/2013/04/05/10407778.aspx
    #
    def wait
      io_port = CreateIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 1)

      if io_port == 0
        FFI.raise_windows_error('CreateIoCompletionPort', FFI.errno)
      end

      port = JOBOBJECT_ASSOCIATE_COMPLETION_PORT.new
      port[:CompletionKey] = @job_handle
      port[:CompletionPort] = io_port

      bool = SetInformationJobObject(
        @job_handle,
        JobObjectAssociateCompletionPortInformation,
        port,
        port.size
      )

      FFI.raise_windows_error('SetInformationJobObject', FFI.errno) unless bool

      olap  = FFI::MemoryPointer.new(Overlapped)
      bytes = FFI::MemoryPointer.new(:ulong)
      ckey  = FFI::MemoryPointer.new(:uintptr_t)

      while GetQueuedCompletionStatus(io_port, bytes, ckey, olap, INFINITE) &&
          !(ckey.read_pointer.to_i == @job_handle && bytes.read_ulong == JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO)
        sleep 0.1
      end
    end

    private

    # Automatically close job object when it goes out of scope.
    #
    def self.finalize(handle, closed)
      proc{ CloseHandle(handle) unless closed }
    end
  end
end
