# RuboCop Checkstyle Formatter

A formatter for [RuboCop](https://github.com/rubocop/rubocop) that outputs in checkstyle format.
It requires RuboCop version 1.14.0 or above.

![Build Status](https://github.com/eitoball/rubocop-checkstyle_formatter/actions/workflows/build.yml/badge.svg?branch=master)

## Installation

Add this line to your application's Gemfile:

    gem 'rubocop-checkstyle_formatter', require: false

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rubocop-checkstyle_formatter

## Usage

    $ rubocop --require rubocop/formatter/checkstyle_formatter --format RuboCop::Formatter::CheckstyleFormatter

I use this formatter in Jenkins with [Checkstyle plugin](https://wiki.jenkins-ci.org/display/JENKINS/Checkstyle+Plugin).
As a part of build, I execute rubocop as shell script like:

    bundle exec rubocop --require rubocop/formatter/checkstyle_formatter --format RuboCop::Formatter::CheckstyleFormatter --no-color --rails --out tmp/checkstyle.xml

Then, after build, I add post-build action 'Publish Checkstyle analysis results' and configure Checkstyle results to "tmp/checkstyle.xml".

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
