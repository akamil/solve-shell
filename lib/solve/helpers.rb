require 'readline'

module Solve
 module Helpers

    def history_file
        "#{home_dir}/.solve/history"
    end

    def save_history(array)
                write_file(history_file, array.join("\n") + "\n")
    end

    def load_history
               if !history=read_file(history_file)
                        history =""
               else
		 history 
    		end
	end

    def readline_with_hist_management(prompt)
  		line = Readline.readline(prompt, true)
  		return nil if line.nil?
  		if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
    			Readline::HISTORY.pop
  		end
  	line
    end


    def read_file(filename)
              File.exists?(filename) and File.read(filename).split("\n")
    end

    def write_file(filename, data)
	      FileUtils.mkdir_p(File.dirname(filename))
      	      f = File.open(filename, 'w')
      	      f.puts data
              f.close
    end

    def set_permissions(filename,fmode,drmode)
     	      FileUtils.chmod drmode, File.dirname(filename)
      	      FileUtils.chmod fmode, filename
   end

   def delete_file(filename)
                FileUtils.rm_f(filename)
   end

    def home_dir
       ENV['HOME']
    end

    def ask
      STDIN.gets.strip
    end

   def echo_off
      system "stty -echo"
    end
  
    def echo_on
      system "stty echo"
    end

   def display(msg="", newline=true)
      if newline
        puts(msg)
      else
        print(msg)
        STDOUT.flush
      end
    end

   def ask_for_password
      echo_off
      password = ask
      puts
      echo_on
      return password
    end

 end
end
