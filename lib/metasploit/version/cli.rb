#
# Standard library
#

require 'pathname'

#
# Gems
#

require 'thor'

#
# Project
#

require 'metasploit/version'
require 'metasploit/version/version'

# Command-line interface for `metasploit-version`.  Used to run commands for managing the semantic version of a project.
class Metasploit::Version::CLI < Thor
  include Thor::Actions

  #
  # CONSTANTS
  #

  # Name of this gem, for use in other projects that call `metasploit-version install`.
  GEM_NAME = 'metasploit-version'
  # Line added to a project's gemspec to add `metasploit-version` as a development dependency.
  #
  # @todo Change to '~> #{Metasploit::Version::Version::MAJOR}.#{Metasploit::Version::Version::MINOR}' once metasploit-version is 1.0.0
  DEVELOPMENT_DEPENDENCY_LINE = "  spec.add_development_dependency '#{GEM_NAME}', '~> #{Metasploit::Version::Version::MAJOR}.#{Metasploit::Version::Version::MINOR}.#{Metasploit::Version::Version::PATCH}'\n"
  # Matches pre-existing development dependency on metasploit-version for updating.
  DEVELOPMENT_DEPENDENCY_REGEXP = /spec\.add_development_dependency\s+(?<quote>"|')#{GEM_NAME}\k<quote>/

  #
  # Class options
  #

  class_option :force,
               default: false,
               desc: 'Force overwriting conflicting files',
               type: :boolean
  class_option :skip,
               default: false,
               desc: 'Skip conflicting files',
               type: :boolean

  #
  # Configuration
  #

  root = Pathname.new(__FILE__).parent.parent.parent.parent
  source_root root.join('app', 'templates')

  #
  # Commands
  #

  desc 'install',
       "Install metasploit-version and sets up files"
  long_desc(
      "Adds 'metasploit-version' as a development dependency in this project's gemspec OR updates the semantic version requirement; " \
      "adds semantic versioning version.rb file."
  )
  option :major,
         banner: 'MAJOR',
         default: 0,
         desc: 'Major version number',
         type: :numeric
  option :minor,
         banner: 'MINOR',
         default: 0,
         desc: 'Minor version number, scoped to MAJOR version number.',
         type: :numeric
  option :patch,
         banner: 'PATCH',
         default: 0,
         desc: 'Patch version number, scoped to MAJOR and MINOR version numbers.',
         type: :numeric
  # Adds 'metasploit-version' as a development dependency in this project's gemspec.
  #
  # @return [void]
  def install
    ensure_development_dependency
    template('lib/versioned/version.rb.tt', "lib/#{namespaced_path}/version.rb")
    system('bundle', 'install')
  end

  private

  # Capitalizes words by converting the first character of `word` to upper case.
  #
  # @param word [String] a lower case string
  # @return [String]
  def capitalize(word)
    word[0, 1].upcase + word[1 .. -1]
  end

  # Ensures that the {#gemspec_path} contains a development dependency on {GEM_NAME}.
  #
  # Adds `spec.add_development_dependency 'metasploit_version', '~> <semantic version requirement>'` if {#gemspec_path}
  # does not have such an entry.  Otherwise, updates the `<semantic version requirement>` to match this version of
  # `metasploit-version`.
  #
  # @return [void]
  # @raise (see #gemspec_path)
  def ensure_development_dependency
    path = gemspec_path
    gem_specification = Gem::Specification.load(path)

    metasploit_version = gem_specification.dependencies.find { |dependency|
      dependency.name == GEM_NAME
    }

    lines = []

    if metasploit_version
      if metasploit_version.requirements_list.include? '>= 0'
        shell.say "Adding #{GEM_NAME} as a development dependency to "
      else
        shell.say "Updating #{GEM_NAME} requirements in "
      end

      shell.say path

      File.open(path) do |f|
        f.each_line do |line|
          match = line.match(DEVELOPMENT_DEPENDENCY_REGEXP)

          if match
            lines << DEVELOPMENT_DEPENDENCY_LINE
          else
            lines << line
          end
        end
      end
    else
      end_index = nil
      lines = []

      open(path) do |f|
        line_index = 0

        f.each_line do |line|
          lines << line

          if line =~ /^\s*end\s*$/
            end_index = line_index
          end

          line_index += 1
        end
      end

      lines.insert(end_index, DEVELOPMENT_DEPENDENCY_LINE)
    end

    File.open(path, 'w') do |f|
      lines.each do |line|
        f.write(line)
      end
    end
  end

  # The name of the gemspec in the current working directory.
  #
  # @return [String] relative path to the current working directory's gemspec.
  # @raise [SystemExit] if no gemspec is found
  def gemspec_path
    unless instance_variable_defined? :@gemspec
      path = "#{name}.gemspec"

      unless File.exist?(path)
        shell.say 'No gemspec found'
        exit 1
      end

      @gemspec_path = path
    end

    @gemspec_path
  end

  # The name of the gem.
  #
  # @return [String] name of the gem.  Assumed to be the name of the pwd as it should match the repository name.
  def name
    @name ||= File.basename(Dir.pwd)
  end

  # The fully-qualified namespace for the gem.
  #
  # @param [String]
  def namespace_name
    @namespace_name ||= namespaces.join('::')
  end

  # List of `Module#name`s making up the {#namespace_name the fully-qualifed namespace for the gem}.
  #
  # @return [Array<String>]
  def namespaces
    unless instance_variable_defined? :@namespaces
      underscored_words = name.split('_')
      capitalized_underscored_words = underscored_words.map { |underscored_word|
        capitalize(underscored_word)
      }
      capitalized_hyphenated_name = capitalized_underscored_words.join
      hyphenated_words = capitalized_hyphenated_name.split('-')

      @namespaces = hyphenated_words.map { |hyphenated_word|
        capitalize(hyphenated_word)
      }
    end

    @namespaces
  end

  # The relative path of the gem under `lib`.
  #
  # @return [String] Format of `[<parent>/]*<child>`
  def namespaced_path
    @namespaced_path ||= name.tr('-', '/')
  end

  # The prerelease version.
  #
  # @return [nil] if on master or HEAD
  # @return [String] if on a branch
  def prerelease
    unless instance_variable_defined? :@prerelease
      branch = Metasploit::Version::Branch.current
      parsed = Metasploit::Version::Branch.parse(branch)

      if parsed.is_a? Hash
        prerelease = parsed[:prerelease]

        if prerelease
          @prerelease = prerelease
        end
      end
    end

    @prerelease
  end
end