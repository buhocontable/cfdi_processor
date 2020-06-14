# CfdiProcessor

Extracts the information from the CFDI (Mexico) and converts it into a hash.

[![Build Status](https://travis-ci.com/armando1339/cfdi_processor.svg?branch=master)](https://travis-ci.com/armando1339/cfdi_processor) [![Coverage Status](https://coveralls.io/repos/github/armando1339/cfdi_processor/badge.svg?branch=master)](https://coveralls.io/github/armando1339/cfdi_processor?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cfdi_processor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cfdi_processor

## Usage

### CFDI Data

Create an instance of `CfdiProcessor::StampedExtractor` and pass to it the params.

```ruby
xml_data = CfdiProcessor::StampedExtractor.new(xml_string)
```

Access to the data extracted

```ruby

# => Execute the instance methods
xml_data.receipt
xml_data.issuer
xml_data.receiver
xml_data.concepts
xml_data.taxes

```

To access to the XML string and Nokogiri document.

```ruby

# =>
xml_data.xml

# =>
xml_data.nokogiri_xml

```

## Contributing

Bug report or pull request are welcome. Make a pull request:

- Clone the repo
- Create a new feature branch
- Commit your changes
- Push the new branch
- Create new pull-request

Please write tests if necessary.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
