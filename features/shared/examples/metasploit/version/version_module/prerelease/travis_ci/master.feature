Feature: 'Metasploit::Version Version Module' shared example in master build on Travis-CI

  The 'Metasploit::Version Version Module' shared example will check that the described_class for an RSpec *_spec.rb
  file does not define PRERELEASE.

  Background:
    Given a file named "lib/my_namespace/my_gem.rb" with:
    """ruby
    require 'my_namespace/my_gem/version'

    module MyNamespace
      module MyGem
      end
    end
    """
    Given a file named "spec/spec_helper.rb" with:
    """ruby
    require 'metasploit/version'
    require 'my_namespace/my_gem'

    Dir[Metasploit::Version.root.join('spec', 'support', '**', '*.rb')].each do |f|
      require f
    end
    """
    Given a file named "spec/lib/my_namespace/my_gem/version_spec.rb" with:
    """ruby
    require 'spec_helper'

    RSpec.describe MyNamespace::MyGem::Version do
      it_should_behave_like 'Metasploit::Version Version Module'
    end
    """
    Given I set the environment variables to:
      | variable      | value   |
      | TRAVIS_BRANCH | master  |
  Scenario: PRERELEASE defined
    Given a file named "lib/my_namespace/my_gem/version.rb" with:
    """ruby
    module MyNamespace
      module MyGem
        module Version
          #
          # CONSTANTS
          #

          # The major version number
          MAJOR = 1

          # The minor version number, scoped to the {MAJOR} version number.
          MINOR = 2

          # The patch number, scoped to the {MINOR} version number
          PATCH = 3

          # The prerelease name of the given {MAJOR}.{MINOR}.{PATCH} version number.  Will not be defined on master.
          PRERELEASE = 'source-branch-relative-name'
        end
      end
    end
    """
    When I run `rspec spec/lib/my_namespace/my_gem/version_spec.rb --format documentation`
    Then the output should contain "expected MyNamespace::MyGem::Version::PRERELEASE not to be defined on master"
  Scenario: PRERELEASE undefined
    Given a file named "lib/my_namespace/my_gem/version.rb" with:
    """ruby
    module MyNamespace
      module MyGem
        module Version
          #
          # CONSTANTS
          #

          # The major version number
          MAJOR = 1

          # The minor version number, scoped to the {MAJOR} version number.
          MINOR = 2

          # The patch number, scoped to the {MINOR} version number
          PATCH = 3
        end
      end
    end
    """
    When I run `rspec spec/lib/my_namespace/my_gem/version_spec.rb --format documentation`
    Then the output should not contain "expected MyNamespace::MyGem::Version::PRERELEASE not to be defined on master"