require 'ffi'

module PandocRB
  class String < FFI::Struct
    layout :str_ptr, :pointer,
           :length,  :long

    def self.from_str(string)
      new_hs_string = self.new
      new_hs_string[:str_ptr] = FFI::MemoryPointer.from_string string
      new_hs_string[:length]  = string.bytesize
      new_hs_string
    end

    def to_s
      self[:str_ptr]
        .read_string_length(self[:length])
        .force_encoding("utf-8")
    end
  end
end

