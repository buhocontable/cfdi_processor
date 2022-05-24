require 'nokogiri'

module CfdiProcessor
  class DataExtractorBase
    attr_accessor :xml, :nokogiri_xml

    def initialize(xml)
      @base_hash = {}
      @xml = xml
      @nokogiri_xml = ::Nokogiri::XML(xml)
      @nokogiri_xml.remove_namespaces!
      I18n.load_path << File.expand_path("locale/en.yml", __dir__)
      I18n.locale = :en

      # => Hook methods:
      #
      # * Execute data extraction
      # * Translate data extracted
      #
      extract_data_from_xml
      translate_data
    end

    def extract_data_from_xml
      raise 'Undefined abstract method: #extract_data_from_xml'
    end

    def translate_data
      @base_hash.keys.each do |key|
        value = @base_hash[key]
        translated = translate(key, value)
        instance_variable_set("@#{key}", translated)
      end
      self
    end

    def translate(translation_key, object)
      return object.map{|obj| translate(translation_key, obj) } if object.is_a? Array

      translated = {}
      if object.is_a? Hash
        object.keys.each do |key|
          val = object[key]
          if val.is_a?(Array) || val.is_a?(Hash)
            val = translate(key, val)
          end
          translation = I18n.t("cfdi.#{translation_key}.#{key}")
          translated.merge!(translation => val)
        end
      end
      translated
    end

  end
end