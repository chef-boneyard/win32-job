require 'ffi'

module Windows
  module Structs
    class JOBOBJECT_BASIC_PROCESS_ID_LIST < FFI::Struct
      layout(
        :NumberOfAssignedProcesses, :ulong,
        :NumberOfProcessIdsInList, :ulong,
        :ProcessIdList, [:uintptr_t, 100] # Limit 100 processes per job (?)
      )
    end

    class JOBOBJECT_BASIC_ACCOUNTING_INFORMATION < FFI::Struct
      layout(
        :TotalUserTime, :uintptr_t,
        :TotalKernelTime, :uintptr_t,
        :ThisPeriodTotalUserTime, :uintptr_t,
        :ThisPeriodTotalKernelTime, :uintptr_t,
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
      layout(:BasicInfo, JOBOBJECT_BASIC_ACCOUNTING_INFORMATION, :IoInfo, IO_COUNTERS)
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
  end
end
