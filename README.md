# RuboCop Checkstyle Formatter

A formatter for [RuboCop](https://github.com/rubocop/rubocop) that outputs in checkstyle format.
It requires RuboCop version 1.20.0 or above.

![Build Status](https://github.com/eitoball/rubocop-checkstyle_formatter/actions/workflows/build.yml/badge.svg?branch=main)

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

## Known limitations

Offense messages are written into the `message` attribute via REXML, which escapes
`&`, `<`, `>`, `'`, and `"` automatically, so these characters are safe to include in
cop messages. Raw control characters (e.g. `\x01`), however, are illegal in XML 1.0
and will cause REXML to raise an error while writing the report.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
