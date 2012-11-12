Gem::Specification.new do |s|
  s.name        = "solve"
  s.version     = "1.0" 
  s.authors     = ["Alex Kamil]
  s.email       = ["ak2834@columbia.edu"]
  s.homepage    = "http://solvebio.com"
  s.summary     = "Solve Shell"
  s.description = "Command-line tool to create and manage bioinformatics projects"
  s.executables ="solve","solved"
  s.rubyforge_project = "solve"
  s.files = Dir.glob("{bin,lib}/**/*")
end
