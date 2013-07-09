# Rubocop Checkstyle Formatter

A formatter for rubocop that outputs in checkstyle format.
It requires rubocop version 0.9.0 or above.

## Installation

Add this line to your application's Gemfile:

    gem 'rubocop-checkstyle_formatter', require: false

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rubocop-checkstyle_formatter

## Usage

    $ rubocop --require rubocop/formatter/checkstyle_formatter --format Rubocop::Formatter::CheckstyleFormatter
    
I use this formatter in Jenkins with [Violations plugin](https://wiki.jenkins-ci.org/display/JENKINS/Violations).
As a part of build, I execute rubocop as shell script like:

    bundle exec rubocop --require rubocop/formatter/checkstyle_formatter --format Rubocop::Formatter::CheckstyleFormatter --no-color --silent --rails --out tmp/checkstyle.xml

Then, after build, I add 'Report Violations' and configure xml filename pattern of checkstyle to "xml/checkstyle.xml".

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
