require 'thor'
require 'yaml'
require 'guard/forge/assets'
require 'guard/forge/config'
require 'guard/forge/templates'
require 'guard/forge/functions'

module Forge
  class CLI < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'layouts'))
    end

    desc "create DIRECTORY", "Creates a Forge project"
    def create(dir)
      theme = {}
      theme[:name] = dir

      Forge::Project.create(dir, theme, self)
    end

    desc "link PATH", "Create a symbolic link to the compilation directory"
    long_desc "This command will symlink the compiled version of the theme to the specified path.\n\n"+
      "To compile the theme use the `forge watch` command"
    def link(path)
      project = Forge::Project.new('.', self)

      FileUtils.mkdir_p project.build_path unless File.directory?(project.build_path)

      do_link(project, path)
    end

    desc "watch", "Start watch process"
    long_desc "Watches the source directory in your project for changes, and reflects those changes in a compile folder"
    def watch
      project = Forge::Project.new('.', self)

      # Empty the build directory before starting up to clean out old files
      FileUtils.rm_rf project.build_path
      FileUtils.mkdir_p project.build_path

      Forge::Guard.start(project, self)
    end

    desc "build DIRECTORY", "Build your theme into specified directory"
    def build(dir = 'build')
      project = Forge::Project.new('.', self)

      builder = Builder.new(project)
      builder.build

      Dir.glob(File.join(dir, '**', '*')).each do |file|
        shell.mute { remove_file(file) }
      end

      directory(project.build_path, dir)
    end

    protected
    def do_link(project, path)
      begin
        project.link(path)
      rescue LinkSourceDirNotFound
        say_status :error, "The path #{File.dirname(path)} does not exist", :red
        exit 2
      rescue Errno::EEXIST
        say_status :error, "The path #{path} already exsts", :red
        exit 2
      end
    end
  end
end
