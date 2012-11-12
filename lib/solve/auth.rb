#!/usr/bin/ruby

require 'fileutils.rb' 
require "solve/helpers"

 class Solve::Auth
   class<<self
     attr_accessor :credentials

include Solve::Helpers

    def default_host
      "50.18.157.135"
    end

    def host
      ENV['SOLVE_HOST'] || default_host
    end

    def credentials_file
        "#{home_dir}/.solve/credentials"
    end

    def user
        @credentials
    end

    def ssh_dir
	File.join(home_dir, ".ssh")
    end

    def keyfile
      File.join(ssh_dir,"id_dsa_solve")
    end

    def pubkey
      keyfile + ".pub"
    end

    def remote_home_dir
       "/home/#{user}"
    end

    def remote_ssh_dir
        File.join(remote_home_dir, ".ssh")
    end

    def upload_pubkey
  %x[ssh -o "IdentityFile #{keyfile}" -o "StrictHostKeyChecking no" #{user}@#{host} "umask 077; cat >> ~/.ssh/authorized_keys" < #{pubkey} 2>&1;echo "uploaded keys"]
  
   #puts "ssh -o \"IdentityFile #{keyfile}\" -o \"StrictHostKeyChecking no\" #{user}@#{host} \"umask 077; cat >> ~/.ssh/authorized_keys\" < #{pubkey} 2>&1"
        end

  def create_ssh_master
		u= %x[ssh -t -q -f -N -o "ControlMaster auto" -o "ControlPath ~/.ssh/solve-%r@%h:%p"  #{user}@#{host} "uname" >/dev/null 2>&1]
  end
	
  def chk_auth
        u= %x[ssh -t -q -i #{keyfile} #{user}@#{host} "uname"]
        #u= %x[ssh -t -q  -o "ControlMaster auto" -o "ControlPath ~/.ssh/solve-%r@%h:%p"  #{user}@#{host} "uname"]
        if u.chomp=="Linux"
                puts "connection alright"
                return true
        else
                puts "cannot access remote"
                return false
        end
    end

def  delete_file(filename)
       begin
    	FileUtils.rm(filename, :noop => false, :verbose => false)
       rescue
      end
 end

    def generate_keys
      if !File.exists?(ssh_dir)
        FileUtils.mkdir_p ssh_dir
        File.chmod(0700, ssh_dir)
      end
      %x[ssh-keygen -t rsa -N "" -f #{keyfile} 2>&1]
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

    def save_credentials
        begin
                 	write_file(credentials_file, @credentials)
                 	set_permissions(credentials_file,0600,0700)
	rescue  
		 puts "Unable to save credentials."
                 exit 
        end
    end

def get_credentials
      if !@credentials=read_file(credentials_file)
	@credentials = ask_for_credentials
  	generate_keys
        upload_pubkey
       # create_ssh_master
        if !status=chk_auth
                 #delete_file(keyfile)
                 #delete_file(pubkey)
                  delete_file("~/.ssh/*solve*")
                  delete_file("~/.solve/*")
                 exit
        end
	save_credentials
      end
end

   def clear 
      #delete_file(credentials_file)
      @credentials =nil
      #delete_file(keyfile)
      #delete_file(pubkey)
      
      delete_file("~/.ssh/solve*")
      delete_file("~/.ssh/*solve*")
      delete_file("~/.solve/*")
       
    end

    def login
        clear
     	begin 
	      get_credentials
     	rescue
                puts "Unable to get credentials."
                exit
     	end
     end
  end
end
