require 'nokogiri'

module CfdiProcessor
  class DataExtractorBase
    attr_accessor :xml, :nokogiri_xml

    def initialize(xml)
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
      raise 'Undefined abstract method: #translate_data'
    end

    # => Search for the _translate_ pattern at the beginning of the method,
    # if it is found, look for the translation based on the end of the
    # method name and the argument that is passed to it.
    #
    def method_missing(name, *args, &block)
      if name.to_s.start_with?('_translate_')
        resource_name = name.to_s.sub('_translate_', '')
        instance_var  = instance_variable_get("@#{resource_name}")
        if  instance_var.kind_of?(Array)
          translated = instance_var.map do |object|
            next if object.blank?
            translate_instance_variable(resource_name,object,args)
          end
        else 
          translated = translate_instance_variable(resource_name,instance_var,args) unless instance_var.blank?
        end

        instance_variable_set("@#{resource_name}", translated)  
      else 
        super
      end
    end

    private

    def translate_instance_variable(resource_name,object,args) 
      item = {}
      object.inject({}) do |translated, (key,value)|
        if value.kind_of?(Array)
          next if value.blank?
          items = value.each do |item|
            item.transform_keys!{ |k| I18n.t("#{args.first}.#{key}.#{k}") }
          end

          translated.merge!(I18n.t("#{args.first}.#{resource_name}.#{key}") => items)
        else
          translated.merge!(I18n.t("#{args.first}.#{resource_name}.#{key}") => value)
        end
        item = translated       
      end
      item 
    end
  end
end