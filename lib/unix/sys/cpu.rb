require 'ffi'
require 'rbconfig'

module Sys
  class CPU
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    CTL_HW = 6 # Generic hardware/cpu

    HW_MACHINE      = 1  # Machine class
    HW_MODEL        = 2  # Specific machine model
    HW_NCPU         = 3  # Number of CPU's
    HW_MACHINE_ARCH = 12 # CPU frequency
    HW_CPU_FREQ     = 15 # CPU frequency

    SI_MACHINE          = 5
    SI_ARCHITECTURE     = 6
    SC_NPROCESSORS_ONLN = 15

    begin
      attach_function :sysctl, [:pointer, :uint, :pointer, :pointer, :pointer, :size_t], :int
      private_class_method :sysctl
    rescue FFI::NotFoundError
      # Do nothing, not supported on this platform.
    end

    # Solaris
    begin
      attach_function :getloadavg, [:pointer, :int], :int
      attach_function :processor_info, [:int, :pointer], :int
      attach_function :sysconf, [:int], :long
      attach_function :sysinfo, [:int, :pointer, :long], :int

      private_class_method :getloadavg
      private_class_method :processor_info
      private_class_method :sysconf
      private_class_method :sysinfo
    rescue FFI::NotFoundError
      # Do nothing, not supported on this platform.
    end

    class ProcInfo < FFI::Struct
      layout(
        :pi_state, :int,
        :pi_processor_type, [:char, 16],
        :pi_fputypes, [:char, 32],
        :pi_clock, :int
      )
    end

    def self.architecture
      if self.respond_to?(:sysctl, true)
        buf  = 0.chr * 64
        mib  = FFI::MemoryPointer.new(:int, 2).write_array_of_int([CTL_HW, HW_MACHINE_ARCH])
        size = FFI::MemoryPointer.new(:long, 1).write_int(buf.size)

        sysctl(mib, 2, buf, size, nil, 0)

        buf.strip
      else
        buf = 0.chr * 257

        if sysinfo(SI_ARCHITECTURE, buf, buf.size) < 0
          raise Error, "sysinfo function failed"
        end

        buf.strip
      end
    end

    def self.num_cpu
      if self.respond_to?(:sysctl, true)
        buf  = 0.chr * 4
        mib  = FFI::MemoryPointer.new(:int, 2).write_array_of_int([CTL_HW, HW_NCPU])
        size = FFI::MemoryPointer.new(:long, 1).write_int(buf.size)

        sysctl(mib, 2, buf, size, nil, 0)

        buf.strip.unpack("C").first
      else
        num = sysconf(SC_NPROCESSORS_ONLN)

        if num < 0
          raise Error, "sysconf function failed"
        end

        num
      end
    end

    def self.machine
      if respond_to?(:sysctl, true)
        buf  = 0.chr * 32
        mib  = FFI::MemoryPointer.new(:int, 2).write_array_of_int([CTL_HW, HW_MACHINE])
        size = FFI::MemoryPointer.new(:long, 1).write_int(buf.size)

        sysctl(mib, 2, buf, size, nil, 0)

        buf.strip
      else
        buf = 0.chr * 257

        if sysinfo(SI_MACHINE, buf, buf.size) < 0
          raise Error, "sysinfo function failed"
        end

        buf.strip
      end
    end

    def self.model
      if respond_to?(:sysctl, true)
        buf  = 0.chr * 64
        mib  = FFI::MemoryPointer.new(:int, 2).write_array_of_int([CTL_HW, HW_MODEL])
        size = FFI::MemoryPointer.new(:long, 1).write_int(buf.size)

        sysctl(mib, 2, buf, size, nil, 0)

        buf.strip
      else
        pinfo = ProcInfo.new

        # Some systems start at 0, some at 1
        if processor_info(0, pinfo) < 0
          if processor_info(1, pinfo) < 0
            raise Error, "process_info function failed"
          end
        end

        pinfo[:pi_processor_type].to_s
      end
    end

    def self.freq
      if respond_to?(:sysctl, true)
        buf  = 0.chr * 16
        mib  = FFI::MemoryPointer.new(:int, 2).write_array_of_int([CTL_HW, HW_CPU_FREQ])
        size = FFI::MemoryPointer.new(:long, 1).write_int(buf.size)

        sysctl(mib, 2, buf, size, nil, 0)

        buf.unpack("I*").first / 1000000
      else
        pinfo = ProcInfo.new

        # Some systems start at 0, some at 1
        if processor_info(0, pinfo) < 0
          if processor_info(1, pinfo) < 0
            raise Error, "process_info function failed"
          end
        end

        pinfo[:pi_clock].to_i
      end
    end

    def self.load_avg
      if respond_to?(:getloadavg, true)
        loadavg = FFI::MemoryPointer.new(:double, 3)

        if getloadavg(loadavg, loadavg.size) < 0
          raise Error, "getloadavg function failed"
        end

        loadavg.get_array_of_double(0, 3)
      end
    end
  end
end
