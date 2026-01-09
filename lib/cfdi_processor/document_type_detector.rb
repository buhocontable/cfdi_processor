# frozen_string_literal: true

module CfdiProcessor
  # Detects CFDI document type and version from XML.
  # Works with StampedExtractor or raw XML string.
  class DocumentTypeDetector
    # SAT namespace patterns for version detection
    VERSION_PATTERNS = {
      cfdi: {
        '4.0' => 'http://www.sat.gob.mx/cfd/4',
        '3.3' => 'http://www.sat.gob.mx/cfd/3',
        '3.2' => 'http://www.sat.gob.mx/cfd/3'
      },
      nomina: {
        '1.2' => 'http://www.sat.gob.mx/nomina12',
        '1.1' => 'http://www.sat.gob.mx/nomina'
      },
      pagos: {
        '2.0' => 'http://www.sat.gob.mx/Pagos20',
        '1.0' => 'http://www.sat.gob.mx/Pagos'
      },
      carta_porte: {
        '3.1' => 'http://www.sat.gob.mx/CartaPorte31',
        '3.0' => 'http://www.sat.gob.mx/CartaPorte30',
        '2.0' => 'http://www.sat.gob.mx/CartaPorte20'
      },
      combustibles: {
        '1.2' => 'http://www.sat.gob.mx/EstadoDeCuentaCombustible12',
        '1.1' => 'http://www.sat.gob.mx/ConsumoDeCombustibles11',
        '1.0' => 'http://www.sat.gob.mx/consumodecombustibles'
      },
      retenciones: {
        '2.0' => 'http://www.sat.gob.mx/esquemas/retencionpago/2',
        '1.0' => 'http://www.sat.gob.mx/esquemas/retencionpago/1'
      },
      comercio_exterior: {
        '2.0' => 'http://www.sat.gob.mx/ComercioExterior20',
        '1.1' => 'http://www.sat.gob.mx/ComercioExterior11',
        '1.0' => 'http://www.sat.gob.mx/ComercioExterior'
      },
      donatarias: {
        '1.1' => 'http://www.sat.gob.mx/donat'
      },
      impuestos_locales: {
        '1.0' => 'http://www.sat.gob.mx/implocal'
      },
      dividendos: {
        '1.0' => 'http://www.sat.gob.mx/esquemas/retencionpago/1/dividendos'
      }
    }.freeze

    # Complement node names to check for
    COMPLEMENT_NODES = {
      nomina: 'Nomina',
      pagos: 'Pagos',
      carta_porte: 'CartaPorte',
      combustibles: %w[EstadoDeCuentaCombustible ConsumoDeCombustibles],
      comercio_exterior: 'ComercioExterior',
      donatarias: 'Donatarias',
      impuestos_locales: 'ImpuestosLocales'
    }.freeze

    attr_reader :xml_string, :nokogiri_xml

    def initialize(input)
      if input.is_a?(String)
        @xml_string = input
        @nokogiri_xml = Nokogiri::XML(input)
        @nokogiri_xml.remove_namespaces!
      elsif input.respond_to?(:nokogiri_xml)
        @nokogiri_xml = input.nokogiri_xml
        @xml_string = input.respond_to?(:xml) ? input.xml : @nokogiri_xml.to_s
      else
        raise ArgumentError, 'Input must be XML string or extractor object'
      end
    end

    # Detect document type
    # @return [Symbol] :nomina, :pagos, :carta_porte, :combustibles, :retenciones,
    #                  :comercio_exterior, :donatarias, :impuestos_locales,
    #                  :ingreso, :egreso, :traslado, :unknown
    def document_type
      return :retenciones if retenciones_document?

      # Check complements in priority order
      COMPLEMENT_NODES.each do |type, nodes|
        return type if has_complement?(nodes)
      end

      # Fall back to TipoDeComprobante
      detect_by_receipt_type
    end

    # Detect all version info
    # @return [Hash] { cfdi_version:, complement_type:, complement_version: }
    def versions
      {
        cfdi_version: cfdi_version,
        complement_type: complement_type,
        complement_version: complement_version
      }
    end

    # Get CFDI version (4.0, 3.3, 3.2)
    def cfdi_version
      comprobante = @nokogiri_xml.at('Comprobante')
      comprobante&.[]('Version') || comprobante&.[]('version') || '4.0'
    end

    # Get complement type if present
    def complement_type
      COMPLEMENT_NODES.each_key do |type|
        return type if has_complement?(COMPLEMENT_NODES[type])
      end
      nil
    end

    # Get complement version based on namespace
    def complement_version
      VERSION_PATTERNS.each do |type, versions|
        next if type == :cfdi

        versions.each do |version, namespace|
          return { type: type, version: version } if @xml_string.include?(namespace)
        end
      end
      nil
    end

    private

    def retenciones_document?
      root = @nokogiri_xml.root
      return false unless root

      root.name == 'Retenciones'
    end

    def has_complement?(node_names)
      complement = @nokogiri_xml.at('Complemento')
      return false unless complement

      Array(node_names).any? { |name| complement.at(name) }
    end

    def detect_by_receipt_type
      comprobante = @nokogiri_xml.at('Comprobante')
      type = comprobante&.[]('TipoDeComprobante')

      case type
      when 'E' then :egreso
      when 'N' then :nomina
      when 'P' then :pagos
      when 'T' then :traslado
      when 'I' then :ingreso
      else :ingreso
      end
    end
  end
end
