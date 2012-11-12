# Internal class for managing an ssh tunnel, across which relatively insecure
# HTTP commands can be sent by Solve::Connection::Remote.
require 'solve/helpers'
require 'fileutils.rb'

class Solve::SshTunnel
 attr_reader :solve_dir, :ssh_dir, :port

 include Solve::Helpers

	def initialize(real_host)
		#@real_host = real_host
		@real_host="50.18.157.135"
		@user=""
                @solve_dir = Solve::Dir.new("#{ENV['HOME']}/.solve")
                @solve_dir.create
		@ssh_dir=Solve::Dir.new("#{ENV['HOME']}/.ssh")
                @ssh_dir.create
		get_credentials
	end
		
    def keyfile
                ssh_dir['id_dsa_solve']
    end

    def save_key(key)
    	keyfile.write(key+"\n")
    end 
    
    def pubkey
              ssh_dir['id_dsa_solve.pub']
    end

    def ask_for_credentials
      user = ""
      print "User: "
      user = ask
      if user.empty?
         puts "Username cannot be empty"
         exit
      end
      return user
    end

    def user_file
           solve_dir['user']
    end

    def save_user
           user_file.write("#{user}")
    end

    def host
	   'localhost'
    end

    def port
	@port
    end

    def user
	@user	
    end

    def ensure_tunnel(options={})
		return if @port and tunnel_alive?
		
		@port = config.tunnels[@real_host]
		if !@port or !tunnel_alive?
			setup_everything(options)
		end
    end

    def setup_everything(options={})
		display "Connecting..."
		push_credentials
		launch_solved
		establish_tunnel(options)
    end

    def get_credentials
     		if user_file.exists?
     			@user=user_file.contents
     		else
			@user = ask_for_credentials
        		generate_keys
        		upload_pubkey
       			# if !status=chk_auth
       			#          #delete_file(keyfile)
       			#          #delete_file(pubkey)
       			#           delete_file("~/.ssh/*solve*")
       			#           delete_file("~/.solve/*")
       			#          exit
       			# end
        		save_user
     		 end
     end

     def generate_keys
      		#puts "generating keys..."
      		if !ssh_dir.exists?
        		FileUtils.mkdir_p ssh_dir
       			 File.chmod(0700, ssh_dir)
      		end
      		%x[ssh-keygen -t rsa -N "" -f #{keyfile} 2>&1]
      		#puts "ssh-keygen -t rsa -N "" -f #{keyfile} 2>&1"
    	end



	def upload_pubkey
 		#puts "uploading keys.."
  		%x[ssh -o "IdentityFile #{keyfile}" -o "StrictHostKeyChecking no" #{user}@#{@real_host} "umask 077; chmod 700 ~/.ssh/; cat >> ~/.ssh/authorized_keys" < #{pubkey} 2>&1;echo "uploaded keys"]
  		#puts "ssh -o \"IdentityFile #{keyfile}\" -o \"StrictHostKeyChecking no\" #{user}@#{@real_host} \"umask 077; cat >> ~/.ssh/authorized_keys\" < #{pubkey} 2>&1;echo \"uploaded keys"
        end

	def push_credentials
		#display "Pushing credentials"
		config.ensure_credentials_exist
		ssh_append_to_credentials(config.credentials_file.contents.strip)
	end

	def ssh_append_to_credentials(string)
		passwords_file = "~/.solve/passwords"
		string = "'#{string}'"
		#ssh "M=`grep #{string} #{passwords_file} 2>/dev/null | wc -l`; if [ $M = 0 ]; then mkdir -p .solve; chmod 700 .solve; echo #{string} >> #{passwords_file}; chmod 600 #{passwords_file}; fi"
		cmd="M=`grep #{string} #{passwords_file} 2>/dev/null | wc -l`; if [ $M = 0 ]; then mkdir -p .solve; chmod 700 .solve; echo #{string} >> #{passwords_file}; chmod 600 #{passwords_file}; fi"
		#puts cmd
		ssh cmd
	end

	def launch_solved
		#display "Launching solved"
		cmd ="if [ `ps aux | grep solved | grep -v grep | wc -l` -ge 1 ]; then exit; fi; solved > /dev/null 2>&1 &"
		#puts cmd
		ssh cmd
	end

	def establish_tunnel(options={})
		#display "Establishing ssh tunnel"
		@port = next_available_port

		make_ssh_tunnel(options)

		tunnels = config.tunnels
		tunnels[@real_host] = @port
		config.save_tunnels tunnels

		sleep 0.5
	end

	def tunnel_options
		{            
			:local_port => @port,
			:remote_port => Solve::Config::DefaultPort,
			:ssh_host => @real_host,
			:ssh_user => @user,
			:ssh_key => keyfile.quoted_path
		}
	end

	def tunnel_alive?
		#puts tunnel_count_command
		`#{tunnel_count_command}`.to_i > 0
	end

	def tunnel_count_command
		"ps x | grep '#{ssh_tunnel_command_without_stall}' | grep -v grep | wc -l"
	end

	class SshFailed < Exception; end
	class NoPortSelectedYet < Exception; end

	def ssh(command)
	cmd ="ssh -i #{keyfile.quoted_path}  #{@user}@#{@real_host} '#{command}'"
	#puts cmd
		raise SshFailed unless system(cmd)
	
	end

	def scp(command)
        cmd ="scp -i #{keyfile.quoted_path}  #{@user}@#{@real_host} '#{command}'"
        #puts cmd
                raise SshFailed unless system(cmd)

        end

	def make_ssh_tunnel(options={})
		#puts ssh_tunnel_command(options)
		raise SshFailed unless system(ssh_tunnel_command(options))
	end

	def ssh_tunnel_command_without_stall
		options = tunnel_options
		raise NoPortSelectedYet unless options[:local_port]
		"ssh -f -L #{options[:local_port]}:127.0.0.1:#{options[:remote_port]} -i #{options[:ssh_key]} #{options[:ssh_user]}@#{options[:ssh_host]}"
	end

	def ssh_stall_command(options={})
		if options[:timeout] == :infinite
			"while [ 1 ]; do sleep 1000; done"
		elsif options[:timeout].to_i > 10
			"sleep #{options[:timeout].to_i}"
		else
			"sleep 9000"
		end
	end

	def ssh_tunnel_command(options={})		
		#ssh_tunnel_command_without_stall + ' "' + ssh_stall_command(options) + '"'
		ssh_tunnel_command_without_stall + ' "' + ssh_stall_command(options) + '"'
	end

	def next_available_port
		(config.tunnels.values.max || Solve::Config::DefaultPort) + 1
	end

	def config
		@config ||= Solve::Config.new
	end

	def display(msg)
		puts msg
	end
end
