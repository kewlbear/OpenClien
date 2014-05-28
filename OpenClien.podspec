Pod::Spec.new do |s|
  s.name             = "OpenClien"
  s.version          = "0.1.1"
  s.summary          = "Clien.net 비공식 iOS 라이브러리"
  s.homepage         = "https://github.com/kewlbear/OpenClien"
  s.license          = 'Apache 2.0'
  s.author           = { "Changbeom Ahn" => "kewlbear@gmail.com" }
  s.source           = { :git => "https://github.com/kewlbear/OpenClien.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'OpenClien'
  s.private_header_files = 'Vendor/*'
  s.compiler_flags = '-I/usr/include/libxml2'

  s.dependency 'GDataXML-HTML'

  s.subspec 'GTM' do |gtm|
    gtm.source_files = 'Vendor/GTM'
    gtm.requires_arc = false
  end
end
