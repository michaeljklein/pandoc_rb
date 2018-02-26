# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'
require 'pry'
require 'open3'


module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
   (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end


def system_indent(command)
  puts "running #{command}"
  exit_status = system command
  if exit_status
    puts "ran #{command}"
  else
    puts ["failed:", "<command>", command.split(' '), "</command>"].flatten
    raise "#{command} failed"
  end
  exit_status
end


def stack_path
  @stack_path ||= begin
    Dir.chdir(__dir__) do
      temp_stack_path = `stack path`.lines.map do |line|
        /^(?<var>[^:]+): (?<val>.*)$/ =~ line.chomp
        [var, File.absolute_path(val)]
      end.to_h
      temp_stack_path['compiler-lib'] = temp_stack_path['compiler-bin'].sub(/bin$/, 'lib')
      temp_stack_path['compiler'] = temp_stack_path['compiler-bin'].sub(/^.*\/([^\/]+)\/bin$/, '\1')
      temp_stack_path
    end
  end
end


unless system('which stack')
  raise "Error: stack not installed"
end


Dir.chdir(__dir__){ system_indent 'stack setup' }

Dir.chdir(__dir__){ system_indent 'stack build' }


# Give it a name
extension_name = 'pandoc_rb/pandoc_rb'

LIBDIR      = ::CONFIG['libdir']
INCLUDEDIR  = ::CONFIG['includedir']

HEADER_DIRS = [
  File.join(stack_path['compiler-lib'], stack_path['compiler'], "rts"),
  File.join(stack_path['local-install-root'], "bin"),

  # /home/hsolo/.stack/programs/x86_64-linux/ghc-8.0.2/lib/ghc-8.0.2/include/
  File.join(stack_path['compiler-lib'], stack_path['compiler'], "include"),

  # .stack-work/dist/x86_64-osx/Cabal-1.24.2.0/build/PandocRb.dylib/PandocRb.dylib-tmp/
  File.join(stack_path['dist-dir'], "build/PandocRb.dylib/PandocRb.dylib-tmp"),

  # Then search /usr/local for people that installed from source
  '/usr/local/include',

  # Check the ruby install locations
  INCLUDEDIR,

  # Finally fall back to /usr
  '/usr/include',
]

LIB_DIRS = [
  # /home/hsolo/.stack/programs/x86_64-linux/ghc-8.0.2/lib/ghc-8.0.2/rts/
  File.join(stack_path['compiler-lib'], stack_path['compiler'], "rts"),
  File.join(stack_path['local-install-root'], "bin"),
  File.join(stack_path['dist-dir'], "build/PandocRb.dylib/PandocRb.dylib-tmp"), # PandocRb_stub.h
  File.join(stack_path['compiler-lib'], stack_path['compiler'], "include"),

  # First search /opt/local for macports
  '/opt/local/lib',

  # Then search /usr/local for people that installed from source
  '/usr/local/lib',

  # Check the ruby install locations
  LIBDIR,

  # Finally fall back to /usr
  '/usr/lib',
]

dir_config extension_name, HEADER_DIRS, LIB_DIRS


# Example:
# stack_path['compiler'] == "ghc-8.0.2"
# abbrev_compiler = "ghc8.0.2
abbrev_compiler = stack_path['compiler'].sub('-', '')

have_header 'stdio.h'
have_header 'ruby.h'
have_header 'HsFFI.h'
have_header 'PandocRb_stub.h', 'HsFFI.h'

find_library "HSrts-#{abbrev_compiler}", nil
find_library 'PandocRb', nil

$INCFLAGS  = File.join(stack_path['local-install-root'], "bin/PandocRb.dylib") + ' ' + $INCFLAGS
$INCFLAGS += " -I#{File.join(stack_path['compiler-lib'], stack_path['compiler'], "include")}" # HsFFI.h
$INCFLAGS += " -I#{File.join(stack_path['dist-dir'], "build/PandocRb.dylib/PandocRb.dylib-tmp")}" # PandocRb_stub.h
$INCFLAGS += " -L#{File.join(stack_path['compiler-lib'], stack_path['compiler'], "rts")}"
$INCFLAGS += " -lHSrts-#{abbrev_compiler}"

$LDFLAGS  = File.join(stack_path['local-install-root'], "bin/PandocRb.dylib") + ' ' + $LDFLAGS
$LDFLAGS += " -I#{File.join(stack_path['compiler-lib'], stack_path['compiler'], "include")}" # HsFFI.h
$LDFLAGS += " -I#{File.join(stack_path['dist-dir'], "build/PandocRb.dylib/PandocRb.dylib-tmp")}" # PandocRb_stub.h
$LDFLAGS += " -L#{File.join(stack_path['compiler-lib'], stack_path['compiler'], "rts")}"
$LDFLAGS += " -Wl,-rpath,'#{File.join(stack_path['compiler-lib'], stack_path['compiler'], "rts")}'"
$LDFLAGS += " -Wl,-R'#{File.join(stack_path['local-install-root'], "bin")}'" unless OS.mac?
$LDFLAGS += " -Wl,-rpath,'#{File.join(stack_path['local-install-root'], "bin")}'"
$LDFLAGS += " -lHSrts-#{abbrev_compiler}"

create_makefile extension_name

system_indent 'make'

