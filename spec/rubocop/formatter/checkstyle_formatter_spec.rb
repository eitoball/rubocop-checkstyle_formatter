# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'rexml/document'

module RuboCop
  module Formatter
    RSpec.describe CheckstyleFormatter do
      let(:output_io) { StringIO.new }
      let(:file) { File.expand_path('sample.rb', Dir.pwd) }
      let(:formatter) { described_class.new(output_io) }

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
        REXML::Document.new(output_io.string)
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
        let(:empty_file_output_warning) do
          'RUBOCOP_CHECKSTYLE_FORMATTER_OUTPUT_EMPTY_RESULT will default to false in a future version.'
        end

        around do |example|
          original = ENV.delete('RUBOCOP_CHECKSTYLE_FORMATTER_OUTPUT_EMPTY_RESULT')
          example.run
        ensure
          if original
            ENV['RUBOCOP_CHECKSTYLE_FORMATTER_OUTPUT_EMPTY_RESULT'] = original
          else
            ENV.delete('RUBOCOP_CHECKSTYLE_FORMATTER_OUTPUT_EMPTY_RESULT')
          end
        end

        it 'outputs a file element without errors and warns about the future default' do
          doc = nil

          expect { doc = format_file([]) }
            .to output("#{empty_file_output_warning}\n").to_stderr

          expect(REXML::XPath.first(doc, '//checkstyle/file')).not_to be_nil
          expect(errors_from(doc)).to be_empty
        end

        %w[false FALSE].each do |value|
          it "omits the file element when output-empty-result is #{value}" do
            ENV['RUBOCOP_CHECKSTYLE_FORMATTER_OUTPUT_EMPTY_RESULT'] = value

            expect(REXML::XPath.first(format_file([]), '//checkstyle/file')).to be_nil
          end
        end

        it 'does not warn when output-empty-result is false' do
          ENV['RUBOCOP_CHECKSTYLE_FORMATTER_OUTPUT_EMPTY_RESULT'] = 'false'

          expect { format_file([]) }.not_to output.to_stderr
        end

        it 'outputs a file element for a value other than false' do
          ENV['RUBOCOP_CHECKSTYLE_FORMATTER_OUTPUT_EMPTY_RESULT'] = 'true'

          expect { expect(REXML::XPath.first(format_file([]), '//checkstyle/file')).not_to be_nil }
            .to output("#{empty_file_output_warning}\n").to_stderr
        end

        it 'warns once per formatter run when several files have no offenses' do
          formatter.started(file)

          expect do
            formatter.file_finished(file, [])
            formatter.file_finished(file, [])
            formatter.finished([file])
          end.to output("#{empty_file_output_warning}\n").to_stderr
        end

        it 'warns again after a new formatter run starts' do
          2.times do
            formatter.started(file)

            expect { formatter.file_finished(file, []) }
              .to output("#{empty_file_output_warning}\n").to_stderr
          end
        end
      end

      describe 'XML escaping of offense messages' do
        def message_attribute(doc)
          REXML::XPath.first(doc, '//checkstyle/file/error').attribute('message').value
        end

        it 'escapes ampersands' do
          message = 'Use "&" instead of "and"'
          doc = format_file([build_offense(:warning, message: message)])

          expect(output_io.string).to include('&amp;')
          expect(message_attribute(doc)).to eq(message)
        end

        it 'escapes angle brackets' do
          message = 'Avoid <class> syntax'
          doc = format_file([build_offense(:warning, message: message)])

          expect(output_io.string).to include('&lt;class&gt;')
          expect(message_attribute(doc)).to eq(message)
        end

        it 'escapes single and double quotes' do
          message = %q(Check 'single' and "double" quotes)
          doc = format_file([build_offense(:warning, message: message)])

          expect(output_io.string).to include('&apos;single&apos;')
          expect(output_io.string).to include('&quot;double&quot;')
          expect(message_attribute(doc)).to eq(message)
        end

        it 'produces well-formed, parseable XML when a message mixes all special characters' do
          message = %q(Use "&" instead of "and", avoid <class> syntax, check 'single' quotes)

          doc = nil
          expect { doc = format_file([build_offense(:warning, message: message)]) }.not_to raise_error

          expect(message_attribute(doc)).to eq(message)
        end
      end

      describe 'known limitations of XML escaping' do
        it 'cannot encode raw control characters, which are illegal in XML 1.0' do
          message = "unterminated string\x01literal"
          offense = build_offense(:warning, message: message)

          # REXML raises a bare RuntimeError with this wording as an implementation
          # detail (not a documented API), so we only match on the message here.
          expect { format_file([offense]) }.to raise_error(/Illegal character/)
        end
      end
    end
  end
end
