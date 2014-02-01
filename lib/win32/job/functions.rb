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
    attach_function :IsProcessInJob, [:handle, :handle, :pointer], :bool
    attach_function :OpenProcess, [:dword, :bool, :dword], :handle
    attach_function :QueryInformationJobObject, [:handle, :int, :pointer, :dword, :pointer], :bool
    attach_function :SetInformationJobObject, [:handle, :int, :pointer, :dword], :bool
    attach_function :TerminateJobObject, [:handle, :uint], :bool
  end
end
