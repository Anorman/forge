require 'sprockets'
require 'sass'
require 'zip/zip'

module Forge
  class Builder
    def initialize(project)
      @project = project
      @templates_path = File.join(@project.source_path, 'templates')
      @assets_path = @project.assets_path
      @functions_path = File.join(@project.source_path, 'functions')

      init_sprockets
    end

    # Runs all the methods necessary to build a completed project
    def build
      copy_templates
      copy_functions
      build_assets
    end

    # Use the rubyzip library to build a zip from the generated source
    def zip
      basename = File.basename(@project.root)

      Zip::ZipFile.open(get_output_filename(basename), Zip::ZipFile::CREATE) do |zip|
        # Get all filenames in the build directory recursively
        filenames = Dir[File.join(@project.build_path, '**', '*')]

        # Remove the build directory path from the filename
        filenames.collect! {|path| path.gsub(/#{@project.build_path}\//, '')}

        # Add each file in the build directory to the zip file
        filenames.each do |filename|
          zip.add File.join(basename, filename), File.join(@project.build_path, filename)
        end
      end
    end

    def copy_templates
      template_paths.each do |template_path|
        FileUtils.cp_r template_path, @project.build_path
      end
    end

    def copy_functions
      FileUtils.cp_r @functions_path, @project.build_path
    end

    def build_assets
      [['style.css'], ['js', 'theme.js']].each do |asset|
        destination = File.join(@project.build_path, asset)

        asset = @sprockets.find_asset(asset.last)

        asset.write_to(destination) unless asset.nil?
      end
    end

    private

    def init_sprockets
      @sprockets = Sprockets::Environment.new

      ['javascripts', 'stylesheets'].each do |dir|
        @sprockets.append_path File.join(@assets_path, dir)
      end
    end

    def template_paths
      @template_paths ||= [
        ['core', '.'],
        ['custom', 'pages', '.'],
        ['custom', 'partials', '.']
      ].collect { |path| File.join(@templates_path, path) }
    end

    # Generate a unique filename for the zip output
    def get_output_filename(basename)
      filename = "#{basename}.zip"

      i = 1
      while File.exists?(filename)
        filename = "#{basename}(#{i}).zip"
        i += 1
      end

      filename
    end
  end
end