require 'ffi'

module FFI
  extend FFI::Library

  ffi_lib :kernel32

  attach_function :FormatMessage, :FormatMessageA,
    [:ulong, :pointer, :ulong, :ulong, :pointer, :ulong, :pointer], :ulong

  def win_error(function, err=FFI.errno)
    flags = 0x00001000 | 0x00000200
    buf = FFI::MemoryPointer.new(:char, 1024)

    FormatMessage(flags, nil, err , 0x0409, buf, 1024, nil)

    function + ': ' + buf.read_string.strip
  end

  def raise_windows_error(function, err=FFI.errno)
    raise SystemCallError.new(win_error(function, err), err)
  end

  module_function :win_error
  module_function :raise_windows_error
end
