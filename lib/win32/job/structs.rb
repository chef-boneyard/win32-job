require 'ffi'

module Windows
  module Structs
    class JOBOBJECT_BASIC_PROCESS_ID_LIST < FFI::Struct
      layout(
        :NumberOfAssignedProcesses, :ulong,
        :NumberOfProcessIdsInList, :ulong,
        :ProcessIdList, [:uintptr_t, 100]
      )
    end
  end
end
