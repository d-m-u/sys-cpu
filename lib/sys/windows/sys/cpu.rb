require 'win32ole'
require 'socket'

# See Ruby bugs #2618 and #7681. This is a workaround.
BEGIN{
  require 'win32ole'
  if RUBY_VERSION.to_f < 2.0
    WIN32OLE.ole_initialize
    at_exit { WIN32OLE.ole_uninitialize }
  end
}

# The Sys module serves only as a namespace
module Sys
  # Encapsulates system CPU information
  class CPU
    # Error raised if any of the Sys::CPU methods fail.
    class Error < StandardError; end

    # Base connect string
    BASE_CS = 'winmgmts:{impersonationLevel=impersonate}' # :nodoc:

    private_constant :BASE_CS

    # Fields used in the CPUStruct
    fields = %w[
      address_width
      architecture
      availability
      caption
      config_manager_error_code
      config_manager_user_config
      cpu_status
      creation_class_name
      freq
      voltage
      data_width
      description
      device_id
      error_cleared?
      error_description
      ext_clock
      family
      install_date
      l2_cache_size
      l2_cache_speed
      last_error_code
      level
      load_avg
      manufacturer
      max_clock_speed
      name
      other_family_description
      pnp_device_id
      power_management_supported?
      power_management_capabilities
      processor_id
      processor_type
      revision
      role
      socket_designation
      status
      status_info
      stepping
      system_creation_class_name
      system_name
      unique_id
      upgrade_method
      version
      voltage_caps
    ]

    # The struct returned by the CPU.processors method
    CPUStruct = Struct.new('CPUStruct', *fields) # :nodoc:

    private_constant :CPUStruct

    # Returns the +host+ CPU's architecture, or nil if it cannot be
    # determined.
    #
    def self.architecture(host=Socket.gethostname)
      cs = BASE_CS + "//#{host}/root/cimv2:Win32_Processor='cpu0'"
      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => e
        raise Error, e
      else
        get_cpu_arch(wmi.Architecture)
      end
    end

    # Returns an integer indicating the speed (i.e. frequency in Mhz) of
    # +cpu_num+ on +host+, or the localhost if no +host+ is specified.
    # If +cpu_num+ +1 is greater than the number of cpu's on your system
    # or this call fails for any other reason, a Error is raised.
    #
    def self.freq(cpu_num = 0, host = Socket.gethostname)
      cs = BASE_CS + "//#{host}/root/cimv2:Win32_Processor='cpu#{cpu_num}'"
      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => e
        raise Error, e
      else
        wmi.CurrentClockSpeed
      end
    end

    # Returns the load capacity for +cpu_num+ on +host+, or the localhost
    # if no host is specified, averaged to the last second. Processor
    # loading refers to the total computing burden for each processor at
    # one time.
    #
    # Note that this attribute is actually the LoadPercentage.  I may use
    # one of the Win32_Perf* classes in the future.
    #
    def self.load_avg(cpu_num = 0, host = Socket.gethostname)
      cs = BASE_CS + "//#{host}/root/cimv2:Win32_Processor='cpu#{cpu_num}'"
      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => e
        raise Error, e
      else
        wmi.LoadPercentage
      end
    end

    # Returns a string indicating the cpu model, e.g. Intel Pentium 4.
    #
    def self.model(host = Socket.gethostname)
      cs = BASE_CS + "//#{host}/root/cimv2:Win32_Processor='cpu0'"
      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => e
        raise Error, e
      else
        wmi.Name
      end
    end

    # Returns an integer indicating the number of cpu's on the system.
    #--
    # This (oddly) requires a different class.
    #
    def self.num_cpu(host = Socket.gethostname)
      cs = BASE_CS + "//#{host}/root/cimv2:Win32_ComputerSystem='#{host}'"
      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => e
        raise Error, e
      else
        wmi.NumberOfProcessors
      end
    end

    # Returns a CPUStruct for each CPU on +host+, or the localhost if no
    # +host+ is specified.  A CPUStruct contains the following members:
    #
    # * address_width
    # * architecture
    # * availability
    # * caption
    # * config_manager_error_code
    # * config_manager_user_config
    # * cpu_status
    # * creation_class_name
    # * freq
    # * voltage
    # * data_width
    # * description
    # * device_id
    # * error_cleared?
    # * error_description
    # * ext_clock
    # * family
    # * install_date
    # * l2_cache_size
    # * l2_cache_speed
    # * last_error_code
    # * level
    # * load_avg
    # * manufacturer
    # * max_clock_speed
    # * name
    # * other_family_description
    # * pnp_device_id
    # * power_management_supported?
    # * power_management_capabilities
    # * processor_id
    # * processor_type
    # * revision
    # * role
    # * socket_designation
    # * status
    # * status_info
    # * stepping
    # * system_creation_class_name
    # * system_name
    # * unique_id
    # * upgrade_method
    # * version
    # * voltage_caps
    #
    # Note that not all of these members will necessarily be defined.
    #
    def self.processors(host = Socket.gethostname) # :yields: CPUStruct
      begin
        wmi = WIN32OLE.connect(BASE_CS + "//#{host}/root/cimv2")
      rescue WIN32OLERuntimeError => e
        raise Error, e
      else
        wmi.InstancesOf('Win32_Processor').each{ |cpu|
          yield CPUStruct.new(
            cpu.AddressWidth,
            get_cpu_arch(cpu.Architecture),
            get_availability(cpu.Availability),
            cpu.Caption,
            get_cmec(cpu.ConfigManagerErrorCode),
            cpu.ConfigManagerUserConfig,
            get_status(cpu.CpuStatus),
            cpu.CreationClassName,
            cpu.CurrentClockSpeed,
            cpu.CurrentVoltage,
            cpu.DataWidth,
            cpu.Description,
            cpu.DeviceId,
            cpu.ErrorCleared,
            cpu.ErrorDescription,
            cpu.ExtClock,
            get_family(cpu.Family),
            cpu.InstallDate,
            cpu.L2CacheSize,
            cpu.L2CacheSpeed,
            cpu.LastErrorCode,
            cpu.Level,
            cpu.LoadPercentage,
            cpu.Manufacturer,
            cpu.MaxClockSpeed,
            cpu.Name,
            cpu.OtherFamilyDescription,
            cpu.PNPDeviceID,
            cpu.PowerManagementSupported,
            cpu.PowerManagementCapabilities,
            cpu.ProcessorId,
            self.get_processor_type(cpu.ProcessorType),
            cpu.Revision,
            cpu.Role,
            cpu.SocketDesignation,
            cpu.Status,
            cpu.StatusInfo,
            cpu.Stepping,
            cpu.SystemCreationClassName,
            cpu.SystemName,
            cpu.UniqueId,
            self.get_upgrade_method(cpu.UpgradeMethod),
            cpu.Version,
            self.get_voltage_caps(cpu.VoltageCaps)
          )
        }
      end
    end

    # Returns a string indicating the type of processor, e.g. GenuineIntel.
    #
    def self.cpu_type(host = Socket.gethostname)
      cs = BASE_CS + "//#{host}/root/cimv2:Win32_Processor='cpu0'"
      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => e
        raise Error, e
      else
        wmi.Manufacturer
      end
    end

    private

    # Convert the ConfigManagerErrorCode number to its corresponding string
    # Note that this value returns nil on my system.
    #
    def self.get_cmec(num)
      case num
        when 0
          str = 'The device is working properly.'
          str
        when 1
          str = 'The device is not configured correctly.'
          str
        when 2
          str = 'Windows cannot load the driver for the device.'
          str
        when 3
          str = 'The driver for the device might be corrupted, or the'
          str << ' system may be running low on memory or other'
          str << ' resources.'
          str
        when 4
          str = 'The device is not working properly. One of the drivers'
          str << ' or the registry might be corrupted.'
          str
        when 5
          str = 'The driver for this device needs a resource that'
          str << ' Windows cannot manage.'
          str
        when 6
          str = 'The boot configuration for this device conflicts with'
          str << ' other devices.'
          str
        when 7
          str = 'Cannot filter.'
          str
        when 8
          str = 'The driver loader for the device is missing.'
          str
        when 9
          str = 'This device is not working properly because the'
          str << ' controlling firmware is reporting the resources'
          str << ' for the device incorrectly.'
          str
        when 10
          str = 'This device cannot start.'
          str
        when 11
          str = 'This device failed.'
          str
        when 12
          str = 'This device cannot find enough free resources that'
          str << ' it can use.'
          str
        when 13
          str = "Windows cannot verify this device's resources."
          str
        when 14
          str = 'This device cannot work properly until you restart'
          str << ' your computer.'
          str
        when 15
          str = 'This device is not working properly because there is'
          str << ' probably a re-enumeration problem.'
          str
        when 16
           str = 'Windows cannot identify all the resources this device '
           str << ' uses.'
           str
        when 17
          str = 'This device is asking for an unknown resource type.'
          str
        when 18
          str = 'Reinstall the drivers for this device.'
          str
        when 19
          str = 'Failure using the VXD loader.'
          str
        when 20
          str = 'Your registry might be corrupted.'
          str
        when 21
          str = 'System failure: try changing the driver for this device.'
          str << ' If that does not work, see your hardware documentation.'
          str << ' Windows is removing this device.'
          str
        when 22
          str = 'This device is disabled.'
          str
        when 23
          str = 'System failure: try changing the driver for this device.'
          str << "If that doesn't work, see your hardware documentation."
          str
        when 24
          str = 'This device is not present, not working properly, or'
          str << ' does not have all its drivers installed.'
          str
        when 25
          str = 'Windows is still setting up this device.'
          str
        when 26
          str = 'Windows is still setting up this device.'
          str
        when 27
          str = 'This device does not have valid log configuration.'
          str
        when 28
          str = 'The drivers for this device are not installed.'
          str
        when 29
          str = 'This device is disabled because the firmware of the'
          str << ' device did not give it the required resources.'
          str
        when 30
          str = 'This device is using an Interrupt Request (IRQ)'
          str << ' resource that another device is using.'
          str
        when 31
          str = 'This device is not working properly because Windows'
          str << ' cannot load the drivers required for this device'
          str
        else
          nil
      end
    end

    private_class_method :get_cmec

    # Convert an cpu architecture number to a string
    def self.get_cpu_arch(num)
      case num
        when 0
          'x86'
        when 1
          'MIPS'
        when 2
          'Alpha'
        when 3
          'PowerPC'
        when 6
          'IA64'
        when 9
          'x64'
        else
          nil
      end
    end

    private_class_method :get_cpu_arch

    # convert an Availability number into a string
    def self.get_availability(num)
      case num
        when 1
          'Other'
        when 2
          'Unknown'
        when 3
          'Running'
        when 4
          'Warning'
        when 5
          'In Test'
        when 6
          'Not Applicable'
        when 7
          'Power Off'
        when 8
          'Off Line'
        when 9
          'Off Duty'
        when 10
          'Degraded'
        when 11
          'Not Installed'
        when 12
          'Install Error'
        when 13
          'Power Save - Unknown'
        when 14
          'Power Save - Low Power Mode'
        when 15
          'Power Save - Standby'
        when 16
          'Power Cycle'
        when 17
          'Power Save - Warning'
        when 18
          'Paused'
        when 19
          'Not Ready'
        when 20
          'Not Configured'
        when 21
          'Quiesced'
        else
          nil
      end
    end

    private_class_method :get_availability

    # convert CpuStatus to a string form.  Note that values 5 and 6 are
    # skipped because they're reserved.
    def self.get_status(num)
      case num
        when 0
          'Unknown'
        when 1
          'Enabled'
        when 2
          'Disabled by User via BIOS Setup'
        when 3
          'Disabled By BIOS (POST Error)'
        when 4
          'Idle'
        when 7
          'Other'
        else
          nil
      end
    end

    private_class_method :get_status

    # Convert a family number into the equivalent string
    def self.get_family(num)
      case num
        when 1
          'Other'
        when 2
          'Unknown'
        when 3
          '8086'
        when 4
          '80286'
        when 5
          '80386'
        when 6
          '80486'
        when 7
          '8087'
        when 8
          '80287'
        when 9
          '80387'
        when 10
          '80487'
        when 11
          'Pentium?'
        when 12
          'Pentium?'
        when 13
          'Pentium?'
        when 14
          'Pentium?'
        when 15
          'Celeron?'
        when 16
          'Pentium?'
        when 17
          'Pentium?'
        when 18
          'M1'
        when 19
          'M2'
        when 24
          'K5'
        when 25
          'K6'
        when 26
          'K6-2'
        when 27
          'K6-3'
        when 28
          'AMD'
        when 29
          'AMD?'
        when 30
          'AMD2900'
        when 31
          'K6-2+'
        when 32
          'Power'
        when 33
          'Power'
        when 34
          'Power'
        when 35
          'Power'
        when 36
          'Power'
        when 37
          'Power'
        when 38
          'Power'
        when 39
          'Power'
        when 48
          'Alpha'
        when 49
          'Alpha'
        when 50
          'Alpha'
        when 51
          'Alpha'
        when 52
          'Alpha'
        when 53
          'Alpha'
        when 54
          'Alpha'
        when 55
          'Alpha'
        when 64
          'MIPS'
        when 65
          'MIPS'
        when 66
          'MIPS'
        when 67
          'MIPS'
        when 68
          'MIPS'
        when 69
          'MIPS'
        when 80
          'SPARC'
        when 81
          'SuperSPARC'
        when 82
          'microSPARC'
        when 83
          'microSPARC'
        when 84
          'UltraSPARC'
        when 85
          'UltraSPARC'
        when 86
          'UltraSPARC'
        when 87
          'UltraSPARC'
        when 88
          'UltraSPARC'
        when 96
          '68040'
        when 97
          '68xxx'
        when 98
          '68000'
        when 99
          '68010'
        when 100
          '68020'
        when 101
          '68030'
        when 112
          'Hobbit'
        when 120
          'Crusoe?'
        when 121
          'Crusoe?'
        when 128
          'Weitek'
        when 130
          'Itanium?'
        when 144
          'PA-RISC'
        when 145
          'PA-RISC'
        when 146
          'PA-RISC'
        when 147
          'PA-RISC'
        when 148
          'PA-RISC'
        when 149
          'PA-RISC'
        when 150
          'PA-RISC'
        when 160
          'V30'
        when 176
          'Pentium?'
        when 177
          'Pentium?'
        when 178
          'Pentium?'
        when 179
          'Intel?'
        when 180
          'AS400'
        when 181
          'Intel?'
        when 182
          'AMD'
        when 183
          'AMD'
        when 184
          'Intel?'
        when 185
          'AMD'
        when 190
          'K7'
        when 200
          'IBM390'
        when 201
          'G4'
        when 202
          'G5'
        when 250
          'i860'
        when 251
          'i960'
        when 260
          'SH-3'
        when 261
          'SH-4'
        when 280
          'ARM'
        when 281
          'StrongARM'
        when 300
          '6x86'
        when 301
          'MediaGX'
        when 302
          'MII'
        when 320
          'WinChip'
        when 350
          'DSP'
        when 500
          'Video'
        else
          nil
      end
    end

    private_class_method :get_family

    # Convert power management capabilities number to its equivalent string
    def self.get_pmc(num)
      case num
        when 0
          'Unknown'
        when 1
          'Not Supported'
        when 2
          'Disabled'
        when 3
          'Enabled'
        when 4
          'Power Saving Modes Entered Automatically'
        when 5
          'Power State Settable'
        when 6
          'Power Cycling Supported'
        when 7
          'Timed Power On Supported'
        else
          nil
      end
    end

    private_class_method :get_pmc

    # Convert a processor type into its equivalent string
    def self.get_processor_type(num)
      case num
        when 1
          'Other'
        when 2
          'Unknown'
        when 3
          'Central Processor'
        when 4
          'Math Processor'
        when 5
          'DSP Processor'
        when 6
          'Video Processor'
        else
          nil
      end
    end

    private_class_method :get_processor_type

    # Convert an upgrade method into its equivalent string
    def self.get_upgrade_method(num)
      case num
        when 1
          'Other'
        when 2
          'Unknown'
        when 3
          'Daughter Board'
        when 4
          'ZIF Socket'
        when 5
          'Replacement/Piggy Back'
        when 6
          'None'
        when 7
          'LIF Socket'
        when 8
          'Slot 1'
        when 9
          'Slot 2'
        when 10
          '370 Pin Socket'
        when 11
          'Slot A'
        when 12
          'Slot M'
        else
          nil
      end
    end

    private_class_method :get_upgrade_method

    # Convert return values to voltage cap values (floats)
    def self.get_voltage_caps(num)
      case num
        when 1
          5.0
        when 2
          3.3
        when 4
          2.9
        else
          nil
      end
    end

    private_class_method :get_voltage_caps
  end
end
