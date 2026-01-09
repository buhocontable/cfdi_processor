# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CfdiProcessor::DocumentTypeDetector do
  describe '#document_type' do
    context 'with standard CFDI Ingreso' do
      it 'returns :ingreso for TipoDeComprobante I' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="I"><cfdi:Emisor/><cfdi:Receptor/></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:ingreso)
      end
    end

    context 'with CFDI Egreso' do
      it 'returns :egreso for TipoDeComprobante E' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="E"><cfdi:Emisor/><cfdi:Receptor/></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:egreso)
      end
    end

    context 'with CFDI Traslado' do
      it 'returns :traslado for TipoDeComprobante T' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="T"><cfdi:Emisor/><cfdi:Receptor/></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:traslado)
      end
    end

    context 'with Nómina complement' do
      it 'returns :nomina when Nomina node is present' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="N"><cfdi:Complemento><nomina12:Nomina xmlns:nomina12="http://www.sat.gob.mx/nomina12"/></cfdi:Complemento></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:nomina)
      end
    end

    context 'with Pagos complement' do
      it 'returns :pagos when Pagos node is present' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="P"><cfdi:Complemento><pago20:Pagos xmlns:pago20="http://www.sat.gob.mx/Pagos20"/></cfdi:Complemento></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:pagos)
      end
    end

    context 'with Carta Porte complement' do
      it 'returns :carta_porte when CartaPorte node is present' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="T"><cfdi:Complemento><cartaporte31:CartaPorte xmlns:cartaporte31="http://www.sat.gob.mx/CartaPorte31"/></cfdi:Complemento></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:carta_porte)
      end
    end

    context 'with Combustibles complement' do
      it 'returns :combustibles when EstadoDeCuentaCombustible node is present' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/3" Version="3.3" TipoDeComprobante="I"><cfdi:Complemento><ecc12:EstadoDeCuentaCombustible xmlns:ecc12="http://www.sat.gob.mx/EstadoDeCuentaCombustible12"/></cfdi:Complemento></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:combustibles)
      end
    end

    context 'with Retenciones document' do
      it 'returns :retenciones when root is Retenciones' do
        xml = '<retenciones:Retenciones xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/2" Version="2.0"><retenciones:Emisor/></retenciones:Retenciones>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:retenciones)
      end
    end

    context 'with Comercio Exterior complement' do
      it 'returns :comercio_exterior when ComercioExterior node is present' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="I"><cfdi:Complemento><cce20:ComercioExterior xmlns:cce20="http://www.sat.gob.mx/ComercioExterior20"/></cfdi:Complemento></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:comercio_exterior)
      end
    end

    context 'with Donatarias complement' do
      it 'returns :donatarias when Donatarias node is present' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="I"><cfdi:Complemento><donat:Donatarias xmlns:donat="http://www.sat.gob.mx/donat"/></cfdi:Complemento></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:donatarias)
      end
    end

    context 'with Impuestos Locales complement' do
      it 'returns :impuestos_locales when ImpuestosLocales node is present' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="I"><cfdi:Complemento><implocal:ImpuestosLocales xmlns:implocal="http://www.sat.gob.mx/implocal"/></cfdi:Complemento></cfdi:Comprobante>'
        detector = described_class.new(xml)
        expect(detector.document_type).to eq(:impuestos_locales)
      end
    end
  end

  describe '#cfdi_version' do
    it 'returns 4.0 for CFDI 4.0' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0"><cfdi:Emisor/></cfdi:Comprobante>'
      expect(described_class.new(xml).cfdi_version).to eq('4.0')
    end

    it 'returns 3.3 for CFDI 3.3' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/3" Version="3.3"><cfdi:Emisor/></cfdi:Comprobante>'
      expect(described_class.new(xml).cfdi_version).to eq('3.3')
    end

    it 'returns 3.2 for CFDI 3.2' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/3" version="3.2"><cfdi:Emisor/></cfdi:Comprobante>'
      expect(described_class.new(xml).cfdi_version).to eq('3.2')
    end
  end

  describe '#complement_type' do
    it 'returns :nomina for Nómina complement' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4"><cfdi:Complemento><Nomina/></cfdi:Complemento></cfdi:Comprobante>'
      expect(described_class.new(xml).complement_type).to eq(:nomina)
    end

    it 'returns :pagos for Pagos complement' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4"><cfdi:Complemento><Pagos/></cfdi:Complemento></cfdi:Comprobante>'
      expect(described_class.new(xml).complement_type).to eq(:pagos)
    end

    it 'returns nil when no complement' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4"><cfdi:Emisor/></cfdi:Comprobante>'
      expect(described_class.new(xml).complement_type).to be_nil
    end
  end

  describe '#complement_version' do
    it 'detects Nomina 1.2' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns:nomina12="http://www.sat.gob.mx/nomina12"><cfdi:Complemento><nomina12:Nomina/></cfdi:Complemento></cfdi:Comprobante>'
      result = described_class.new(xml).complement_version
      expect(result).to eq({ type: :nomina, version: '1.2' })
    end

    it 'detects Pagos 2.0' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns:pago20="http://www.sat.gob.mx/Pagos20"><cfdi:Complemento><pago20:Pagos/></cfdi:Complemento></cfdi:Comprobante>'
      result = described_class.new(xml).complement_version
      expect(result).to eq({ type: :pagos, version: '2.0' })
    end

    it 'detects Carta Porte 3.1' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns:cartaporte31="http://www.sat.gob.mx/CartaPorte31"><cfdi:Complemento><cartaporte31:CartaPorte/></cfdi:Complemento></cfdi:Comprobante>'
      result = described_class.new(xml).complement_version
      expect(result).to eq({ type: :carta_porte, version: '3.1' })
    end
  end

  describe '#versions' do
    it 'returns all version info' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns:nomina12="http://www.sat.gob.mx/nomina12" Version="4.0"><cfdi:Complemento><nomina12:Nomina/></cfdi:Complemento></cfdi:Comprobante>'
      result = described_class.new(xml).versions

      expect(result[:cfdi_version]).to eq('4.0')
      expect(result[:complement_type]).to eq(:nomina)
      expect(result[:complement_version]).to eq({ type: :nomina, version: '1.2' })
    end
  end

  describe 'with StampedExtractor input' do
    it 'accepts StampedExtractor object' do
      xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" TipoDeComprobante="I"><cfdi:Emisor/><cfdi:Receptor/><cfdi:Conceptos><cfdi:Concepto/></cfdi:Conceptos></cfdi:Comprobante>'
      extractor = CfdiProcessor::StampedExtractor.new(xml)
      detector = described_class.new(extractor)

      expect(detector.document_type).to eq(:ingreso)
    end
  end
end
