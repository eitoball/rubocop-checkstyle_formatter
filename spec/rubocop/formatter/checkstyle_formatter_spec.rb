# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'rexml/document'

module RuboCop
  module Formatter
    RSpec.describe CheckstyleFormatter do
      let(:output) { StringIO.new }
      let(:file) { File.expand_path('sample.rb', Dir.pwd) }
      let(:formatter) { described_class.new(output) }

      def build_offense(severity, line: 1, column: 0, message: nil)
        source = (Array.new(line - 1, 'x') + ['x' * (column + 1)]).join("\n")
        buffer = Parser::Source::Buffer.new('sample.rb', 1)
        buffer.source = source
        line_start = source.rindex("\n") ? source.rindex("\n") + 1 : 0
        range = Parser::Source::Range.new(buffer, line_start + column, line_start + column + 1)
        Cop::Offense.new(severity, range, message || severity.to_s, 'TestCop')
      end

      def format_file(offenses)
        formatter.started(file)
        formatter.file_finished(file, offenses)
        formatter.finished([file])
        REXML::Document.new(output.string)
      end

      def errors_from(doc)
        REXML::XPath.match(doc, '//checkstyle/file/error')
      end

      describe 'severity mapping' do
        let(:severities) { %i[refactor convention warning error fatal] }
        let(:doc) { format_file(severities.map { |severity| build_offense(severity) }) }

        it 'maps RuboCop severities to Checkstyle severities' do
          errors = errors_from(doc)

          expect(errors.size).to eq(5)

          errors.each do |error|
            message = error.attribute('message').value
            severity = error.attribute('severity').value

            expected = case message
                       when 'refactor', 'convention' then 'info'
                       when 'warning' then 'warning'
                       when 'error', 'fatal' then 'error'
                       end

            expect(severity).to eq(expected)
          end
        end

        it 'uses a relative path by default' do
          original = ENV.delete('RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH')

          begin
            file_element = REXML::XPath.first(doc, '//checkstyle/file')
            expect(file_element.attribute('name').value).to eq('sample.rb')
          ensure
            ENV['RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH'] = original if original
          end
        end
      end

      context 'when RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH is set' do
        around do |example|
          ENV['RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH'] = 'true'
          example.run
          ENV.delete('RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH')
        end

        it 'uses an absolute path in the file name attribute' do
          doc = format_file([build_offense(:warning)])
          file_element = REXML::XPath.first(doc, '//checkstyle/file')

          expect(Pathname.new(file_element.attribute('name').value)).to be_absolute
        end
      end

      describe 'offense attributes' do
        let(:offense) { build_offense(:warning, line: 3, column: 4, message: 'unused variable') }
        let(:error) { REXML::XPath.first(format_file([offense]), '//checkstyle/file/error') }

        it 'includes line, column, message, and source' do
          expect(error.attribute('line').value).to eq('3')
          expect(error.attribute('column').value).to eq('5')
          expect(error.attribute('message').value).to eq('unused variable')
          expect(error.attribute('source').value).to eq('com.puppycrawl.tools.checkstyle.TestCop')
        end
      end

      describe 'empty offenses' do
        it 'outputs a file element without errors' do
          doc = format_file([])

          expect(REXML::XPath.first(doc, '//checkstyle/file')).not_to be_nil
          expect(errors_from(doc)).to be_empty
        end
      end
    end
  end
end
