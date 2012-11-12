require 'rubygems'

# The top-level Solve module has some convenience methods for accessing the
# local box.
module Solve
	# Access the root filesystem of the local box.  Example:
	#
	#   Solve['/etc/hosts'].contents
	#
	def self.[](key)
		box[key]
	end

	# Create a dir object from the path of a provided file.  Example:
	#
	#   Solve.dir(__FILE__).files
	#
	def self.dir(filename)
		box[::File.expand_path(::File.dirname(filename)) + '/']
	end

	# Create a dir object based on the shell's current working directory at the
	# time the program was run.  Example:
	#
	#   Solve.launch_dir.files
	#
	def self.launch_dir
		box[::Dir.pwd + '/']
	end

	# Run a bash command in the root of the local machine.  Equivalent to
	# Solve::Box.new.bash.
	def self.bash(command, options={})
		box.bash(command, options)
	end

	# Pull the process list for the local machine.  Example:
   #
   #   Solve.processes.filter(:cmdline => /ruby/)
	#
	def self.processes
		box.processes
	end

	# Get the process object for this program's PID.  Example:
   #
   #   puts "I'm using #{Solve.my_process.mem} blocks of memory"
	#
	def self.my_process
		box.processes.filter(:pid => ::Process.pid).first
	end

	# Create a box object for localhost.
	def self.box
		@@box = Solve::Box.new
	end

	# Quote a path for use in backticks, say.
	def self.quote(path)
		path.gsub(/(?=[^a-zA-Z0-9_.\/\-\x7F-\xFF\n])/n, '\\').gsub(/\n/, "'\n'").sub(/^$/, "''")
	end
end

module Solve::Connection; end

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'solve/exceptions'
require 'solve/config'
require 'solve/commands'
require 'solve/access'
require 'solve/entry'
require 'solve/file'
require 'solve/dir'
require 'solve/search_results'
require 'solve/head_tail'
require 'solve/find_by'
require 'solve/string_ext'
require 'solve/fixnum_ext'
require 'solve/array_ext'
require 'solve/process'
require 'solve/process_set'
require 'solve/local'
require 'solve/remote'
require 'solve/ssh_tunnel'
require 'solve/box'
require 'solve/embeddable_shell'
require 'solve/auth' 
