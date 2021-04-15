Gem::Specification.new do |s|
  s.name = 'ruby_waveshare_epd'
  s.version = '0.1.0'
  s.summary = 'Provides an interface for Waveshare e-paper displays.'
  s.authors = ['Mui Kai En']
  s.email = 'muikaien1@gmail.com'
  s.files = Dir["{lib}/**/*.rb"]
  s.homepage = 'https://kaine119.github.io'
  s.license = 'MIT'
  s.add_dependency 'spi', '~>0.1.1'
  s.add_dependency 'rpi_gpio', '~>0.5.0'

  # dependencies for example
  s.add_development_dependency 'rmagick', '~>4.2.2'
end
