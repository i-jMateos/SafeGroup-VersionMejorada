platform :ios, '12.0'

target 'SafeGroup' do
  use_frameworks!

  pod 'Kingfisher'
  pod 'ForceDirectedScene'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/Firestore'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end

    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag.start_with?('-G') || flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
  end

  ['Pods/gRPC-Core/src/core/lib/promise/detail/basic_seq.h',
   'Pods/gRPC-C++/src/core/lib/promise/detail/basic_seq.h'].each do |basic_seq|
    if File.exist?(basic_seq)
      File.chmod(0644, basic_seq)
      text = File.read(basic_seq)
      text.gsub!('Traits::template CallSeqFactory', 'Traits::CallSeqFactory')
      File.write(basic_seq, text)
    end
  end
end
