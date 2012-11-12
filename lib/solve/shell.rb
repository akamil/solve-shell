require 'fileutils'
require 'etc'

# Solve::Shell is used to create an interactive shell.  It is invoked by the solve binary.
module Solve
	class Shell
		attr_accessor :suppress_output,  :solve_dir, :local, :home

		# Set up the user's environment, including a pure binding into which
		# env.rb and commands.rb are mixed.
		def initialize
			root = Solve::Dir.new('/')
			@home = Solve::Dir.new(ENV['HOME']) if ENV['HOME']
			pwd = Solve::Dir.new(ENV['PWD']) if ENV['PWD']

			@config = Solve::Config.new

			@config.load_history.each do |item|
				Readline::HISTORY.push(item)
			end

			@local = Solve::Box.new('localhost')
                        @solve_dir = @home['.solve']
			@solve_dir.create
                        #remote = Solve::Box.new('solve@50.18.157.135')
                        #remote_dir = remote['/home/solve/']


#Readline.completion_append_character = " "
			Readline.completion_proc = Proc.new do |str|
  				Object::Dir[str+'*'].grep( /^#{Regexp.escape(str)}/ )
			end

			Readline.basic_word_break_characters = " "
			Readline.completion_append_character = "" 
			#Readline.completion_proc = completion_proc
                       
			comp = proc {|str| Object::Dir['*'].grep( /^#{Regexp.escape(str)}/ )}
			#Readline.completion_proc = lambda do |str|
				    #start_dir=%x[pwd]
			#	    start_dir=""
			#	    files = Object::Dir["#{start_dir}#{str}*"]
    			#	    files.
      			#	    map { |f| Object::File.expand_path(f) }.
      			#	    map { |f| Object::File.directory?(f) ? f + "/" : f }
  			#end

			Readline.completion_proc =comp
	
			@box = Solve::Box.new
			@pure_binding = @box.instance_eval "binding"
			$last_res = nil

			eval @config.load_env, @pure_binding

			commands = @config.load_commands
			Solve::Dir.class_eval commands
			Array.class_eval commands

		end

def  execute (cmd)
	     cmd=cmd.strip
	     cmd=cmd.gsub( /\'/, "" )
             cmd=cmd.gsub( /\.param/, "" )
             cmd=cmd.gsub( /\.workflw/, "" )
             cmd=cmd.gsub( /^solve/, "" )
	     basedir = '.'
	     param_files=Object::Dir.glob("*.param")
	     workflow_files=Object::Dir.glob("*.workflw")
	     param_filenames= (param_files.collect{|u| u = u.chomp(Object::File.extname(u) ) }).join('|')
             workflow_filenames= (workflow_files.collect{|u| u = u.chomp(Object::File.extname(u) ) }).join('|')
             case cmd
                when "help\s"
                        puts "Available commands:"
                        puts "create"
                        puts "upload"
                        puts "download"
                        puts "wget"
                        puts "view"
                        puts "list"
                        puts "mkdir"
                        puts "rmdir"
                        puts "mv"
                        puts "rm"
                        puts "cp"
                        puts "tophat"
                        puts "bowtie"
                        puts "samtools"
                        puts "cufflinks"
                        puts "reset"
		when (/^cancel/)
			name = cmd.split(' ').last	
			base=Object::Process.pid
			env=Etc.getpwnam(Etc.getlogin)
			descendants = Hash.new{|ht,k| ht[k]=[k]}
  			orig=Hash[*`ps -eo pid,ppid`.scan(/\d+/).map{|x|x.to_i}]
  			orig.each{|pid,ppid|
    				puts "#{pid}=>#{ppid}"
    				descendants[ppid] = descendants[ppid]," ",[pid]
  			}
  			puts "base"
  		        puts base,"=>",descendants[base]
			puts "---------desc--------"
		        descendants.each {|ppid,pids|
                                puts "#{ppid}=>#{pids}"
			}	
			#puts %x[ps -ef|grep #{env.uid}|grep #{name}|grep -v grep]
			#puts Process.pid 
			 
		when (/^list/)
                        dirname = cmd.split(' ').last
                        if dirname.casecmp("list")==0
				dirname='.'	
			end
                        puts green('Files')
 			if !Object::Dir.glob("#{dirname}/*").empty?
                                        puts %x[ls -xp  --hide=*.param --hide=*.workflw "#{dirname}"]
                        end
			puts green('Parameters')
			if !Object::Dir.glob("#{dirname}/*.param").empty? 
                                	puts %x[ls #{dirname}/*.param |awk -F'/' '{print $NF}'|cut -f1 -d'.'|tr '\n' ' ']
			end
			puts green('Workflows')
			if !Object::Dir.glob("#{dirname}/*.workflw").empty? 
                                	puts %x[ls #{dirname}/*.workflw |awk -F'/' '{print $NF}'|cut -f1 -d'.'|tr '\n' ' ']
			end
	       when (/^view/)
                        filename = cmd.split(' ').last
                        cmd=cmd.gsub(/view/,'cat')
                        if Object::File.exists?("#{filename}.param")
                	        cmd="#{cmd}.param"
			elsif Object::File.exists?("#{filename}.workflw")
                		cmd="#{cmd}.workflw"
                        #elsif !Object::File.exists?("#{filename}")
                        #        puts "file does not exist: #{filename}"
			end
			#rcmd="local.bash('#{cmd}')"
			#local_execute(rcmd)
			cmd=cmd+";echo"
			system (cmd)
	       when (/^cd/)
			dirname = cmd.split(' ').last
			Object::Dir.chdir(dirname)		
	       when (/^create/)
			dirname = cmd.split(' ').last
			if dirname.casecmp("create")==0
                                rcmd= "home.create_dir('myproject')"
                        else
				rcmd= "home.create_dir('#{dirname}')"
			end
			local_execute(rcmd)
	
               when (/^output/)
                      str=cmd.split(' ')
                      out= ["-o",str[1]]
                      str.slice!(0,2)
                      str.insert(1, out)
                      cmd_new = str.join(' ')
		      #rcmd ="local.bash('#{cmd_new}')"
		      #local_execute(rcmd)
	      	      system(cmd_new)
	       when (/^params/)
			name = cmd.split(' ').last
			params_file(name+'.param').create
	     when (/^workflow/)
                        name = cmd.split(' ').last
                        params_file(name+'.workflw').create 
              when (/^run/)
			name = cmd.split(' ').last
                        if !Object::File.exists?(name+'.workflw')
                                 puts "#{name}: No such file "
				 return
                        end
			 cmd= params_file( name+'.workflw').contents
			 puts cmd
			 execute (cmd) 
			
	      when (/^tophat/)
                if param_filenames!="" and cmd =~ /#{param_filenames}/
			#if cmd =~ /#{param_filenames}/
                           cmd.sub!(/#{param_filenames}/){|f| params_file(f+'.param').contents}
		        #end
                end
                system(cmd)
	   when (/^cufflinks/)
		 if param_filenames!="" and cmd =~ /#{param_filenames}/
                	cmd.sub!(/#{param_filenames}/){|f| params_file(f+'.param').contents}  
         		system(cmd)
		end
	    when (/^bowtie/)
		 if param_filenames!="" and cmd =~ /#{param_filenames}/
                	cmd.sub!(/#{param_filenames}/){|f| params_file(f+'.param').contents} 
          		system(cmd)
		end
	   when (/^samtools/)
		 if param_filenames!="" and cmd =~ /#{param_filenames}/
			cmd.sub!(/#{param_filenames}/){|f| params_file(f+'.param').contents}
                	system(cmd)	
		end
   	   when (/^cuffdiff/)
		 if param_filenames!="" and cmd =~ /#{param_filenames}/
                	cmd.sub!(/#{param_filenames}/){|f| params_file(f+'.param').contents}
                	system(cmd)
		end
 	    when (/^add/)
			str=cmd.split(' ')
			 
			params_name=str[1]
			str.slice!(0,2)
			str_new = str.join(' ')
		#	puts str_new
		if Object::File.exists?(params_name+'.param')
                                #puts params_name
				params_file(params_name+'.param').append(' '+ str_new )
      		elsif Object::File.exists?(params_name+'.workflw')	
			       #substitute params
			       #puts param_filenames
     			       str_new.sub!(/#{param_filenames}/){|f| params_file(f+'.param').contents}
			       
                               params_file(params_name+'.workflw').append("\n"+ str_new )
	        else
			puts "#{params_name}: No such file "
		end
               # when (/^run/)
               #         name = cmd.split(' ').last
	       #		if Object::File.exists?(name+'.workflw')
               #         	params_file(name+'.workflw').contents
               #         else
	       #		 puts "#{name}: No such file "
  		#	end
		when (/^sub/)
			str=cmd.split(' ')
                        params_name=str[1]
			if !params_name
				puts "Missing params name"
				return
			end
			tosub=str[2]
			if !tosub
				puts "Missing params name"
                                return
                        end

			params=params_file(params_name+'.param').contents
			params.gsub!("#{tosub}","")
			params_file(params_name+'.param').write(params)

		when (/^del/)
                        str=cmd.split(' ')
			params_name=str[1]
                        params_file(params_name).destroy
	
	        when (/^upload/)
                        filename = cmd.split(' ').last
                        if filename.casecmp("upload")==0
                                puts "missing input file"
                        else
                                upload(filename)
                        end
               
	#	when (/^download/)
        #                filename = cmd.split(' ').last
        #                if filename.casecmp("download")==0
        #                        puts "missing input file"
        #                else
        #                        download(filename)
        #                end
           
		else
			#params = Hash.new
			#params['myparams'] = 'koo'
			#str=cmd.split(' ')
			#possible_params_name=str[1]
       			#if params.has_key?(possible_params_name)	
			#	puts "paraarams"	
			#end 
			#rcmd ="local.bash('#{cmd}')"
			#local_execute(rcmd)
			system(cmd)
               end
	#puts rcmd	
	#remote_execute(rcmd)
end
		def pexecute (cmd)
			master="50.18.157.135"
			slave="ec2-204-236-173-102.us-west-1.compute.amazonaws.com"
			pcmd="ssh #{slave} hostname;cd test_data;#{cmd}; scp -r ~/test_data/tophat_out #{master}:~/test_data"
		puts pcmd
	
		end
		# Run a single command.
		def local_execute (cmd)
			res = eval(cmd, @pure_binding)
			$last_res = res
			eval("_ = $last_res", @pure_binding)
			print_result res
		rescue Solve::Exception => e
			puts "Exception #{e.class} -> #{e.message}"
		rescue ::Exception => e
			puts "Exception #{e.class} -> #{e.message}"
			e.backtrace.each do |t|
				puts "   #{::File.expand_path(t)}"
			end
		end

		# Run the interactive shell using readline.
		def run
			loop do
				cmd = Readline.readline('solve$ ')

				finish if cmd.nil? or cmd == 'exit'
				next if cmd == ""
				Readline::HISTORY.push(cmd)

				execute(cmd)
			end
		end

		# Save history to ~/.solve/history when the shell exists.
		def finish
			@config.save_history(Readline::HISTORY.to_a)
			puts
			exit
		end

		# Nice printing of different return types, particularly Solve::SearchResults.
		def print_result(res)
			return if self.suppress_output
			if res.kind_of? String
				puts res
			elsif res.kind_of? Solve::SearchResults
				widest = res.entries.map { |k| k.full_path.length }.max
				res.entries_with_lines.each do |entry, lines|
					print entry.full_path
					print ' ' * (widest - entry.full_path.length + 2)
					print "=> "
					print res.colorize(lines.first.strip.head(30))
					print "..." if lines.first.strip.length > 30
					if lines.size > 1
						print " (plus #{lines.size - 1} more matches)"
					end
					print "\n"
				end
				puts "#{res.entries.size} matching files with #{res.lines.size} matching lines"
			elsif res.respond_to? :each
				counts = {}
				res.each do |item|
					puts item
					counts[item.class] ||= 0
					counts[item.class] += 1
				end
				if counts == {}
					puts "=> (empty set)"
				else
					count_s = counts.map do |klass, count|
						"#{count} x #{klass}"
					end.join(', ')
					puts "=> #{count_s}"
				end
			else
				puts "=> #{res.inspect}"
			end
		end

#     def upload (filename)
#	   remote = Solve::Box.new('solve@50.18.157.135')
#           upload_dir = remote['/home/solve/']
#	   file = local['/Users/alex/hg18.2bit']
#	   file.copy_to upload_dir
#     end


		def path_parts(input)		# :nodoc:
			case input
			
			when /((?:@{1,2}|\$|)\w+(?:\[[^\]]+\])*)([\[\/])(['"])([^\3]*)$/
				$~.to_a.slice(1, 4).push($~.pre_match)
			when /((?:@{1,2}|\$|)\w+(?:\[[^\]]+\])*)(\.)(\w*)$/
				$~.to_a.slice(1, 3).push($~.pre_match)
			when /((?:@{1,2}|\$|)\w+)$/
				$~.to_a.slice(1, 1).push(nil).push($~.pre_match)
			else
				[ nil, nil, nil ]
			end
		end

		def complete_method(receiver, dot, partial_name, pre)
			path = eval("#{receiver}.full_path", @pure_binding) rescue nil
			box = eval("#{receiver}.box", @pure_binding) rescue nil
			if path and box
				(box[path].methods - Object.methods).select do |e|
					e.match(/^#{Regexp.escape(partial_name)}/)
				end.map do |e|
					(pre || '') + receiver + dot + e
				end
			end
		end

		def complete_path(possible_var, accessor, quote, partial_path, pre)             # :nodoc:
                        original_var, fixed_path = possible_var, ''

                        if /^(.+\/)([^\/]*)$/ === partial_path
                                fixed_path, partial_path = $~.captures
                                possible_var += "['#{fixed_path}']"
                        end
			puts "possible_var #{possible_var}"

                        full_path = eval("#{possible_var}.full_path", @pure_binding) rescue nil
                        box = eval("#{possible_var}.box", @pure_binding) rescue nil

                        if full_path and box
                                Solve::Dir.new(full_path, box).entries.select do |e|
                                        e.name.match(/^#{Regexp.escape(partial_path)}/)

                                end.map do |e|
                                   (pre || '') + original_var + accessor + quote + fixed_path + e.name + (e.dir? ? "/" : "")
                                end
                        end
                end

		def fancy2_complete_path(possible_var, accessor, quote, partial_path, pre)		# :nodoc:
			original_var, fixed_path = possible_var, ''
			if /^(.+\/)([^\/]*)$/ === partial_path
				fixed_path, partial_path = $~.captures
				possible_var += "['#{fixed_path}']"
			end

			full_path = eval("#{possible_var}.full_path", @pure_binding) rescue nil
			box = eval("#{possible_var}.box", @pure_binding) rescue nil
			if full_path and box
				Solve::Dir.new(full_path, box).entries.select do |e|
					e.name.match(/^#{Regexp.escape(partial_path)}/)
					#puts e.name
				end.map do |e|
					(pre || '') + original_var + accessor + quote + fixed_path + e.name + (e.dir? ? "/" : "")
				end
			end
		end

		def complete_variable(partial_name, pre)
			lvars = eval('local_variables', @pure_binding)
			gvars = eval('global_variables', @pure_binding)
			ivars = eval('instance_variables', @pure_binding)
			(lvars + gvars + ivars).select do |e|
				e.match(/^#{Regexp.escape(partial_name)}/)
			end.map do |e|
				(pre || '') + e
			end
		end

		# Try to do tab completion on dir square brackets and slash accessors.
		#
		# Example:
		#
		# dir['subd    # presing tab here will produce dir['subdir/ if subdir exists
		# dir/'subd    # presing tab here will produce dir/'subdir/ if subdir exists
		#
		# This isn't that cool yet, because it can't do multiple levels of subdirs.
		# It does work remotely, though, which is pretty sweet.
		def completion_proc
			proc do |input|
			e	receiver, accessor, *rest = path_parts(input)
			#	puts "input: #{input}"
			#	puts "receiver: #{receiver}"
			#	puts "accessor: #{accessor}"
			#	puts "rest: #{rest}"
				if receiver
					case accessor
					when /^[\[\/]$/
						complete_path(receiver, accessor, *rest)
				#	when /^\.$/
				#		complete_method(receiver, accessor, *rest)
				#	when nil
				#		complete_variable(receiver, *rest)
					end
				end
			end
		end
	
	def colorize(text, color_code)
  		"\e[#{color_code}m#{text}\e[0m"
	end

	def red(text); colorize(text, 31); end
	def green(text); colorize(text, 32); end
	def blue(text); colorize(text, 33); end

	
	def params_file(name)
                path=@local.bash('pwd').chomp
                local_dir=@local[path]
                file=local_dir["#{name}"]
        end


        def load_params
                params_file.contents
        end
   end
end
