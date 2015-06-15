# This file is a rake build file. The purpose of this file is to simplify
# setting up and using Awestruct. It's not required to use Awestruct, though it
# does save you time (hopefully). If you don't want to use rake, just ignore or
# delete this file.
#
# If you're just getting started, execute this command to install Awestruct and
# the libraries on which it depends:
#
#  rake setup
#
# The setup task installs the necessary libraries inside the project in the .bin
# directory.
#
# There are also tasks for running Awestruct. The build will auto-detect
# whether you are using Bundler and, if you are, wrap calls to awestruct in
# `bundle exec`.
#
# To run in Awestruct in editor mode, execute:
#
#  rake
#
# To clean the generated site before you build, execute:
#
#  rake clean preview
#
# To get a list of all tasks, execute:
#
#  rake -T
#
# Now you're Awestruct with rake!

task :default => :preview

#####################################################################################
# Bundler and environment related tasks
#####################################################################################
# Perform initialization steps, such as setting up the PATH
task :init do
  # Detect using gems local to project
  if File.exist? '.bin'
    ENV['PATH'] = ".bin#{File::PATH_SEPARATOR}#{ENV['PATH']}"
    ENV['GEM_HOME'] = '.bundle'
  else
    msg "No local bundle installation. Run 'rake setup' first", :warn
    exit 0
  end
end

desc 'Setup the environment to run Awestruct using Bundler'
task :setup do |task, args|
  bundle_command = 'bundle install --binstubs=.bin --path=.bundle'
  msg bundle_command
  system bundle_command
  msg 'Bundle installed'
  # Don't execute any more tasks, need to reset env
  exit 0
end

desc 'Update gems ignoring the previously installed gems specified in Gemfile.lock'
task :update => :init do
  system 'bundle update'
  # Don't execute any more tasks, need to reset env
  exit 0
end

#####################################################################################
# Awestruct related tasks
#####################################################################################
desc 'Build and preview the site locally in development mode. preview[<options>] can be used to pass awestruct options, eg \'preview[--no-generate]\''
task :preview, [:profile, :options] => :init do |task, args|
  profile = get_profile args
  options = args[:options]
  run_awestruct "-P #{profile} --server --auto #{options}"
end

desc 'Generate the site using the specified profile, default is \'development\'. Additional options can also be specified, eg \'gen[development, \'-w\']'
task :gen, [:profile, :options] => :init do |task, args|
  profile = get_profile args
  options = args[:options]
  run_awestruct "-P #{profile} -g --force #{options}"
end

desc 'Clean out generated site and temporary files, using [all] will also delete local gem files'
task :clean, :option do |task, args|
  require 'fileutils'
  dirs = ['.awestruct', '.sass-cache', '_site']
  if args[:option] == 'all-keep-deps'
    dirs << '_tmp'
    dirs << '.wget-cache'
  end
  if args[:option] == 'all'
    dirs << '_tmp'
    dirs << '.wget-cache'
    dirs << '.bin'
    dirs << '.bundle'
  end
  dirs.each do |dir|
    FileUtils.remove_dir dir unless !File.directory? dir
  end
end

#####################################################################################
# Helper methods
#####################################################################################
# Execute Awestruct
def run_awestruct(args)
  cmd = "bundle exec awestruct #{args}"
  msg cmd
  system cmd or raise "ERROR: Running Awestruct failed."
end

def get_profile(args)
  if args[:profile].nil?
    profile = "editor"
  else
    profile = args[:profile]
  end
end

# Print a message to STDOUT
def msg(text, level = :info)
  case level
  when :warn
    puts "\e[31m#{text}\e[0m"
  else
    puts "\e[33m#{text}\e[0m"
  end
end

