RSpec.describe CfdiProcessor::StampedExtractor do
  subject{ CfdiProcessor::StampedExtractor.new(xml_string) }

  it { should respond_to(:xml) }
  it { should respond_to(:nokogiri_xml) }
  it { should respond_to(:receipt) }
  it { should respond_to(:issuer) }
  it { should respond_to(:receiver) }
  it { should respond_to(:concepts) }
  it { should respond_to(:taxes) }
  it { should respond_to(:global_info) }

  describe '#xml' do
    it "is expected that return a kind of String" do
      expect(subject.xml).to be_kind_of String
    end
  end

  describe '#nokogiri_xml' do
    it "is expected that return a kind of Nokogiri::XML::Document" do
      expect(subject.nokogiri_xml).to be_kind_of Nokogiri::XML::Document
    end
  end

  describe '#extract_data_from_xml' do
    it "is expected that return CfdiProcessor::StampedExtractor" do
      expect(subject.extract_data_from_xml).to be_kind_of CfdiProcessor::StampedExtractor
    end
  end

  describe '#translate_data' do
    before do
      subject.extract_data_from_xml
    end

    it "is expected that return CfdiProcessor::StampedExtractor" do
      expect(subject.translate_data).to be_kind_of CfdiProcessor::StampedExtractor
    end

    before do
      subject.translate_data
    end

    it "is expected that return @receipt translated" do
      expect(subject.receipt.include?('date_issued')).to be_truthy
    end
  end

  context 'when it has global_info' do
    subject{ CfdiProcessor::StampedExtractor.new(xml_with_global_info) }

    describe '#extract_data_from_xml' do
      it "contains global_info data" do
        expect(subject.global_info).to be_present
        expect(subject.global_info['periodicity']).to eql('04')
        expect(subject.global_info['month']).to eql('02')
        expect(subject.global_info['year']).to eql('2023')
      end
    end
  end
end 