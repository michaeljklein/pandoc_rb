[![Build Status](https://travis-ci.org/michaeljklein/pandoc_rb.svg?branch=master)](https://travis-ci.org/michaeljklein/pandoc_rb)


# PandocRb

Like [PandocRuby](https://github.com/alphabetum/pandoc-ruby), but its interface is more limited:

```ruby
module PandocRb
  def self.raise_exception(result)
  ..

  def self.convert(in_format_str, out_format_str, input_str, extract_media_path='')
  ..

  def self.reader_from_ext(extension)
  ..
end
```

The primary benefit is that instead of using `system` calls,
`pandoc_rb` directly uses the memory allocated for Ruby [String](https://ruby-doc.org/core-2.2.1/String.html)s
through the FFI.

The benchmark results indicate that both significant constant (from initialization) and linear (from streaming through bash pipes)
overhead for `PandocRuby` is eliminated in `pandoc_rb`.

## Installation

Requires Haskell-[`stack`](https://docs.haskellstack.org/en/stable/README/)

Add this line to your application's Gemfile:

```ruby
gem 'pandoc_rb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pandoc_rb

## Usage

`pandoc_rb`'s main interface is contained in the `PandocRb` module.

The public interface consists of constants and a main conversion function

The constants include:
```ruby
PandocRb::Version # The current version
PandocRb::Readers # A list of allowed readers
PandocRb::Writers # A list of allowed writers
```

And the main conversion function is:
```ruby
# General conversion function
PandocRb.convert input_format, output_format, input_string, (optional) extract_media_path

# Convert `markdown` to `latex`
PandocRb.convert 'markdown', 'latex', '_italic text_'

# Convert `docx` to `latex` from file
PandocRb.convert 'docx', 'latex', File.binread('some_doc.docx'), `extract/figures/dir`

# Convert `markdown` to `docx`, writing to a `docx` file
File.open 'some_doc.docx', 'wb' do |file|
  file.write PandocRb.convert('markdown', 'docx', '_italic text_')
end
```

## Contributing

1. Fork it ( https://github.com/michaeljklein/pandoc_rb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

