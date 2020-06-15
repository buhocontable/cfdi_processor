RSpec.describe CfdiProcessor::StampedExtractor do
  subject{ CfdiProcessor::StampedExtractor.new(xml_string) }

  it { should respond_to(:xml) }
  it { should respond_to(:nokogiri_xml) }
  it { should respond_to(:receipt) }
  it { should respond_to(:issuer) }
  it { should respond_to(:receiver) }
  it { should respond_to(:concepts) }
  it { should respond_to(:taxes) }

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
end 