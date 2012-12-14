# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "pedump"
  s.version = "0.4.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrey \"Zed\" Zaikin"]
  s.date = "2012-12-14"
  s.description = "dump headers, sections, extract resources of win32 PE exe,dll,etc"
  s.email = "zed.0xff@gmail.com"
  s.executables = ["pedump"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/pedump",
    "data/fs.txt",
    "data/sig.bin",
    "data/signatures.txt",
    "data/userdb.txt",
    "lib/pedump.rb",
    "lib/pedump/cli.rb",
    "lib/pedump/comparer.rb",
    "lib/pedump/composite_io.rb",
    "lib/pedump/core.rb",
    "lib/pedump/loader.rb",
    "lib/pedump/loader/section.rb",
    "lib/pedump/logger.rb",
    "lib/pedump/ne.rb",
    "lib/pedump/ne/version_info.rb",
    "lib/pedump/packer.rb",
    "lib/pedump/pe.rb",
    "lib/pedump/resources.rb",
    "lib/pedump/security.rb",
    "lib/pedump/sig_parser.rb",
    "lib/pedump/tls.rb",
    "lib/pedump/unpacker.rb",
    "lib/pedump/unpacker/aspack.rb",
    "lib/pedump/unpacker/upx.rb",
    "lib/pedump/version.rb",
    "lib/pedump/version_info.rb",
    "misc/aspack/Makefile",
    "misc/aspack/aspack_unlzx.c",
    "misc/aspack/lzxdec.c",
    "misc/aspack/lzxdec.h",
    "misc/nedump.c",
    "pedump.gemspec",
    "samples/bad/68.exe",
    "samples/bad/data_dir_15_entries.exe",
    "spec/65535sects_spec.rb",
    "spec/bad_imports_spec.rb",
    "spec/bad_samples_spec.rb",
    "spec/composite_io_spec.rb",
    "spec/data/calc.exe_sections.yml",
    "spec/data/data_dir_15_entries.exe_sections.yml",
    "spec/dllord_spec.rb",
    "spec/foldedhdr_spec.rb",
    "spec/imports_badterm_spec.rb",
    "spec/imports_vterm_spec.rb",
    "spec/manyimportsW7_spec.rb",
    "spec/ne_spec.rb",
    "spec/packer_spec.rb",
    "spec/pe_spec.rb",
    "spec/pedump_spec.rb",
    "spec/resource_spec.rb",
    "spec/sections_spec.rb",
    "spec/sig_all_packers_spec.rb",
    "spec/sig_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/samples.rb",
    "spec/unpackers/aspack_spec.rb",
    "spec/unpackers/find_spec.rb",
    "spec/virtsectblXP_spec.rb",
    "tmp/.keep"
  ]
  s.homepage = "http://github.com/zed-0xff/pedump"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "dump win32 PE executable files with a pure ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<multipart-post>, ["~> 1.1.4"])
      s.add_runtime_dependency(%q<progressbar>, [">= 0"])
      s.add_runtime_dependency(%q<awesome_print>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<what_methods>, [">= 0"])
      s.add_development_dependency(%q<looksee>, [">= 0"])
    else
      s.add_dependency(%q<multipart-post>, ["~> 1.1.4"])
      s.add_dependency(%q<progressbar>, [">= 0"])
      s.add_dependency(%q<awesome_print>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<what_methods>, [">= 0"])
      s.add_dependency(%q<looksee>, [">= 0"])
    end
  else
    s.add_dependency(%q<multipart-post>, ["~> 1.1.4"])
    s.add_dependency(%q<progressbar>, [">= 0"])
    s.add_dependency(%q<awesome_print>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<what_methods>, [">= 0"])
    s.add_dependency(%q<looksee>, [">= 0"])
  end
end

