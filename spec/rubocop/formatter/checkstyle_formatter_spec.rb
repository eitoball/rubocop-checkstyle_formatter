# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'rexml/document'

RSpec.describe RuboCop::Formatter::CheckstyleFormatter do
  let(:severities) { %i[refactor convention warning error fatal] }
  let(:cop) do
    config = RuboCop::Config.new({}, "#{Dir.pwd}/.rubocop.yml")
    cop = RuboCop::Cop::Cop.new(config, {})
    processed_source = RuboCop::ProcessedSource.new('', 2.4, nil)
    if cop.respond_to?(:begin_investigation, true)
      cop.send(:begin_investigation, processed_source)
    end
    source_buffer = Parser::Source::Buffer.new('sample.rb', 1).tap { |b| b.source = '' }
    severities.each_with_index do |severity, index|
      cop.add_offense(nil, location: Parser::Source::Range.new(source_buffer, 0, index), message: severity.to_s)
    end
    cop
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
        when 'refactor', 'convention' then expect(severity).to eq('info')
        when 'warning' then expect(severity).to eq('warning')
        when 'error', 'fatal' then expect(severity).to eq('error')
        end
      end
    end
  end

  context 'RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH is defined' do
    around do |example|
      ENV['RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH'] = 'true'
      example.run
      ENV.delete('RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH')
    end

    it 'should use absolute path in name attribute of file tag' do
      output = StringIO.new
      formatter = described_class.new(output)
      formatter.started(file)
      formatter.file_finished(file, cop.respond_to?(:offenses) ? cop.offenses : cop.offences)
      formatter.finished([file])
      doc = REXML::Document.new(output.string)
      file = REXML::XPath.first(doc, '/checkstyle/file')
      expect(Pathname.new(file.attributes['name'])).to be_absolute
    end
  end
end
