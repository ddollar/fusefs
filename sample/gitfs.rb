require File.join(File.dirname(__FILE__), '..', 'lib', 'fusefs')
include FuseFS

require 'pp'

# if (ARGV.size != 1)
#   puts "Usage: #{$0} <directory>"
#   exit
# end

dirname = ARGV.shift

unless dirname && File.directory?(dirname)
  puts "Usage: #{$0} <directory>"
  exit
end

class GitDir < MetaDir
  def initialize(repo)
    @repo = repo
    super()
  end
  def current_commit
    head = read_commit_file(File.join(git_dir, 'HEAD'))
    head = read_commit_file(File.join(git_dir, $1)) if head =~ /^ref\: (.*)$/
    head
  end
  def branches
    Dir[File.join(git_dir, 'refs', 'heads', '*')].inject({}) do |hash, file|
      puts file
      branch = File.split(file).last
      commit = read_commit_file(file)
      hash.update({ branch => commit })
    end
  end
  def tags
    {}
  end
  def git(command)
    command = "cd \"#{@repo}\" && git #{command}"
    puts command
    exec(command)
  end
  def git_dir
    File.join(@repo, '.git')
  end
  def work_dir
    @repo
  end
  def read_commit_file(file)
    IO.read(file).chomp.strip
  end
  def switch_to(head)
    puts "switching to #{head}"
    self.git("switch #{head}")
  end
end

class HeadCollectionDir < MetaDir
  def initialize(git, heads)
    super()
    @subdirs = heads.inject({}) do |hash, name_commit|
      hash.update({ name_commit.first => HeadDir.new(git, name_commit.last) })
    end
  end
end

class HeadDir < FuseDir
  def initialize(git, head)
    @git  = git
    @head = head
  end
  def directory?(path)
    #puts "directory?(#{path})"
    File.directory?(full_path(path))
  end
  def file?(path)
    #puts "file?(#{path})"
    File.file?(full_path(path))
  end
  def size(path)
    #puts 'size'
    File.size(full_path(path))
  end
  def contents(path)
    #puts "contents(#{path})"
    ensure_switched!
    Dir[File.join(full_path(path), '*')].map do |dir|
      dir[full_path(path).length..-1]
    end.map do |dir|
      dir[0..0] == '/' ? dir[1..-1] : dir
    end
  end
  def read_file(path)
    IO.read(full_path(path))
  end
  def can_write?(path)
    File.writable?(full_path(path))
  end
  def can_delete?(path)
    can_write?(path)
  end
  def write_to(path, contents)
    File.open(full_path(path), 'w') do |file|
      file.write contents
    end
  end
  def full_path(path)
    File.join(@git.work_dir, path)
  end
  def ensure_switched!
    @git.switch_to(@head) unless @git.current_commit == @head
  end
end

root = GitDir.new("/Users/ddollar/Code/LookingForRaid")

root.mkdir("/branches", HeadCollectionDir.new(root, root.branches))

# Set the root FuseFS
FuseFS.set_root(root)
FuseFS.mount_under(dirname, 'nolocalcaches', *ARGV)
FuseFS.run