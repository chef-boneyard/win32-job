require 'ffi'

module Windows
  module Functions
    extend FFI::Library
    ffi_lib :kernel32

    typedef :uintptr_t, :handle
    typedef :ulong, :dword

    attach_function :AssignProcessToJobObject, [:handle, :handle], :bool
    attach_function :CloseHandle, [:handle], :bool
    attach_function :CreateJobObject, :CreateJobObjectA, [:pointer, :string], :handle
    attach_function :CreateIoCompletionPort, [:handle, :handle, :uintptr_t, :dword], :handle
    attach_function :GetQueuedCompletionStatus, [:handle, :pointer, :pointer, :pointer, :dword], :bool
    attach_function :IsProcessInJob, [:handle, :handle, :pointer], :bool
    attach_function :OpenProcess, [:dword, :bool, :dword], :handle
    attach_function :OpenJobObject, :OpenJobObjectA, [:dword, :bool, :string], :handle
    attach_function :QueryInformationJobObject, [:handle, :int, :pointer, :dword, :pointer], :bool
    attach_function :ResumeThread, [:handle], :dword
    attach_function :SetInformationJobObject, [:handle, :int, :pointer, :dword], :bool
    attach_function :TerminateJobObject, [:handle, :uint], :bool
    attach_function :WaitForSingleObjectEx, [:handle, :dword, :bool], :dword
  end
end
