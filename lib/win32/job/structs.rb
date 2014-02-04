require 'ffi'

module Windows
  module Structs
    extend FFI::Library

    typedef :uintptr_t, :handle
    typedef :ulong, :dword
    typedef :ushort, :word

    class LARGE_INTEGER < FFI::Union
      layout(:QuadPart, :long_long)
    end

    class JOBOBJECT_BASIC_PROCESS_ID_LIST < FFI::Struct
      layout(
        :NumberOfAssignedProcesses, :ulong,
        :NumberOfProcessIdsInList, :ulong,
        :ProcessIdList, [:uintptr_t, 100] # Limit 100 processes per job (?)
      )
    end

    class JOBOBJECT_BASIC_ACCOUNTING_INFORMATION < FFI::Struct
      layout(
        :TotalUserTime, LARGE_INTEGER,
        :TotalKernelTime, LARGE_INTEGER,
        :ThisPeriodTotalUserTime, LARGE_INTEGER,
        :ThisPeriodTotalKernelTime, LARGE_INTEGER,
        :TotalPageFaultCount, :ulong,
        :TotalProcesses, :ulong,
        :ActiveProcesses, :ulong,
        :TotalTerminatedProcesses, :ulong
      )
    end

    class IO_COUNTERS < FFI::Struct
      layout(
        :ReadOperationCount, :ulong_long,
        :WriteOperationCount, :ulong_long,
        :OtherOperationCount, :ulong_long,
        :ReadTransferCount, :ulong_long,
        :WriteTransferCount, :ulong_long,
        :OtherTransferCount, :ulong_long
      )
    end

    class JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION < FFI::Struct
      layout(
        :BasicInfo, JOBOBJECT_BASIC_ACCOUNTING_INFORMATION,
        :IoInfo, IO_COUNTERS
      )
    end

    class JOBOBJECT_BASIC_LIMIT_INFORMATION < FFI::Struct
      layout(
        :PerProcessUserTimeLimit, LARGE_INTEGER,
        :PerJobUserTimeLimit, LARGE_INTEGER,
        :LimitFlags, :ulong,
        :MinimumWorkingSetSize, :size_t,
        :MaximumWorkingSetSize, :size_t,
        :ActiveProcessLimit, :ulong,
        :Affinity, :uintptr_t,
        :PriorityClass, :ulong,
        :SchedulingClass, :ulong
      )
    end

    class JOBOBJECT_EXTENDED_LIMIT_INFORMATION < FFI::Struct
      layout(
        :BasicLimitInformation, JOBOBJECT_BASIC_LIMIT_INFORMATION,
        :IoInfo, IO_COUNTERS,
        :ProcessMemoryLimit, :size_t,
        :JobMemoryLimit, :size_t,
        :PeakProcessMemoryUsed, :size_t,
        :PeakJobMemoryUsed, :size_t
      )
    end

    class JOBOBJECT_ASSOCIATE_COMPLETION_PORT < FFI::Struct
      layout(:CompletionKey, :uintptr_t, :CompletionPort, :handle)
    end

    class SECURITY_ATTRIBUTES < FFI::Struct
      layout(
        :nLength, :ulong,
        :lpSecurityDescriptor, :pointer,
        :bInheritHandle, :bool
      )
    end

    class PROCESS_INFORMATION < FFI::Struct
      layout(
        :hProcess, :handle,
        :hThread, :handle,
        :dwProcessId, :dword,
        :dwThreadId, :dword
      )
    end

    class STARTUPINFO < FFI::Struct
      layout(
        :cb, :ulong,
        :lpReserved, :string,
        :lpDesktop, :string,
        :lpTitle, :string,
        :dwX, :dword,
        :dwY, :dword,
        :dwXSize, :dword,
        :dwYSize, :dword,
        :dwXCountChars, :dword,
        :dwYCountChars, :dword,
        :dwFillAttribute, :dword,
        :dwFlags, :dword,
        :wShowWindow, :word,
        :cbReserved2, :word,
        :lpReserved2, :pointer,
        :hStdInput, :handle,
        :hStdOutput, :handle,
        :hStdError, :handle
      )
    end

    # I'm assuming the anonymous struct for the internal union here.
    class Overlapped < FFI::Struct
      layout(
        :Internal, :ulong,
        :InternalHigh, :ulong,
        :Offset, :ulong,
        :OffsetHigh, :ulong,
        :hEvent, :ulong
      )
    end

    # Ruby Structs

    AccountInfo = Struct.new('AccountInfo',
      :total_user_time,
      :total_kernel_time,
      :this_period_total_user_time,
      :this_period_total_kernel_time,
      :total_page_fault_count,
      :total_processes,
      :active_processes,
      :total_terminated_processes,
      :read_operation_count,
      :write_operation_count,
      :other_operation_count,
      :read_transfer_count,
      :write_transfer_count,
      :other_transfer_count
    )

    LimitInfo = Struct.new('LimitInfo',
      :per_process_user_time_limit,
      :per_job_user_time_limit,
      :limit_flags,
      :minimum_working_set_size,
      :maximum_working_set_size,
      :active_process_limit,
      :affinity,
      :priority_class,
      :scheduling_class,
      :read_operation_count,
      :write_operation_count,
      :other_operation_count,
      :read_transfer_count,
      :write_transfer_count,
      :other_transfer_count,
      :process_memory_limit,
      :job_memory_limit,
      :peak_process_memory_used,
      :peek_job_memory_used
    )
  end
end
