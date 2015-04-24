# encoding: utf-8
require 'spec_helper'
require 'stringio'
require 'rexml/document'

module RuboCop
  module Formatter
    describe CheckstyleFormatter do
      let(:severities) { [:refactor, :convention, :warning, :error, :fatal] }
      let(:cop) do
        Cop::Cop.new.tap do |c|
          source_buffer = Parser::Source::Buffer.new('sample.rb', 1).tap { |b| b.source = '' }
          severities.each_with_index do |severity, index|
            if c.respond_to?(:add_offense)
              c.add_offense(nil, Parser::Source::Range.new(source_buffer, 0, index), severity.to_s, severity)
            else
              begin
                c.add_offence(severity, nil, Parser::Source::Range.new(source_buffer, 0, index), severity.to_s)
              rescue
                c.add_offence(nil, Parser::Source::Range.new(source_buffer, 0, index), severity.to_s, severity)
              end
            end
          end
        end
      end
      let(:output) { StringIO.new }
      let(:file) { File.join(Dir.pwd, 'sample.rb') }

      before do
        formatter = described_class.new(output)
        formatter.started(file)
        formatter.file_finished(file, cop.respond_to?(:offenses) ? cop.offenses : cop.offences)
        formatter.finished([file])
      end

      it 'should convert rubocop severity to checkstyle severity' do
        doc = REXML::Document.new(output.string)
        REXML::XPath.match(doc, '/checkstyle/file').each do |file|
          if defined?(PathUtil)
            expect(file.attribute('name').value).to eq('sample.rb')
          end
          REXML::XPath.match(file, '/error').each do |error|
            message = error.attribute('message').value
            severity = error.attribute('severity').value
            case message
            when 'refactor', 'convention'; expect(severity).to eq('info')
            when 'warning'; expect(severity).to eq('warning')
            when 'error', 'fatal'; expect(severity).to eq('error')
            end
          end
        end
      end
    end
  end
end
