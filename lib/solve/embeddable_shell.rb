require 'solve/shell'

module Solve
	# This is a class that can be embedded in other applications 
	# rake tasks, utility scripts, etc
	# 
	# Delegates unknown method calls to a Solve::Shell instance
	class EmbeddableShell
		attr_accessor :shell
		def initialize(suppress_output = true)
			self.shell = Solve::Shell.new
			shell.suppress_output = suppress_output
		end
		
		# evalutes and unkown method call agains the solve shell
		def method_missing(sym, *args, &block)
			shell.execute sym.to_s
			$last_res
		end
		
		# take a whole block and execute it as if it were inside a shell
		def execute_in_shell(&block)
			self.instance_eval(&block)
		end
	end
end
