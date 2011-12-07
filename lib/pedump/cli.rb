require 'pedump'
require 'optparse'

unless Object.instance_methods.include?(:try)
  class Object
    def try(method)
      send method if respond_to? method
    end
  end
end

class PEdump::CLI
  attr_accessor :data, :argv

  KNOWN_ACTIONS = %w'mz dos_stub rich pe data_directory sections strings resources resource_directory'.map(&:to_sym)
  DEFAULT_ALL_ACTIONS = KNOWN_ACTIONS - %w'resource_directory'.map(&:to_sym)

  def initialize argv = ARGV
    @argv = argv
  end

  def run
    @actions = []
    @options = { :format => :table }
    optparser = OptionParser.new do |opts|
      opts.banner = "Usage: pedump [options]"

      opts.on "-v", "--[no-]verbose", "Run verbosely" do |v|
        @options[:verbose] ||= 0
        @options[:verbose] += 1
      end
      opts.on "-f", "--format FORMAT", [:binary, :c, :dump, :hex, :inspect, :table],
        "Output format: bin,c,dump,hex,inspect,table (default)" do |v|
        @options[:format] = v
      end
      # TODO: imports, exports
      KNOWN_ACTIONS.each do |t|
        opts.on "--#{t.to_s.tr('_','-')}", eval("lambda{ |_| @actions << :#{t.to_s.tr('-','_')} }")
      end
      opts.on "--all", "Dump all but #{(KNOWN_ACTIONS-DEFAULT_ALL_ACTIONS).join(',')} (default)" do
        @actions = DEFAULT_ALL_ACTIONS
      end
    end

    if (@argv = optparser.parse(@argv)).empty?
      puts optparser.help
      return
    end

    if (@actions-KNOWN_ACTIONS).any?
      puts "[?] unknown actions: #{@actions-KNOWN_ACTIONS}"
      @actions.delete_if{ |x| !KNOWN_ACTIONS.include?(x) }
    end
    @actions = DEFAULT_ALL_ACTIONS if @actions.empty?

    argv.each_with_index do |fname,idx|
      if argv.size > 1
        puts if idx > 0
        puts "# -----------------------------------------------"
        puts "# #{fname}"
        puts "# -----------------------------------------------"
        puts
      end
      @pedump = PEdump.new fname
      if @options[:verbose]
        @pedump.logger.level = @options[:verbose] > 1 ? Logger::INFO : Logger::DEBUG
      end
      @pedump = @pedump.dump

      @actions.each do |action|
        dump_action action
      end
    end
  rescue Errno::EPIPE
    # output interrupt, f.ex. when piping output to a 'head' command
    # prevents a 'Broken pipe - <STDOUT> (Errno::EPIPE)' message
  end

  def action_title action
    s = action.to_s.upcase.tr('_',' ')
    s += " Header" if [:mz, :pe, :rich].include?(action)
    "=== %s ===\n\n" % s
  end

  def dump_action action
    data = @pedump.send(action)
    return if !data || (data.respond_to?(:empty?) && data.empty?)

    puts action_title(action)

    return dump(data) if [:inspect, :table].include?(@options[:format])

    dump_opts = {:name => action}
    case action
      when :pe
        @pedump.pe.ifh.TimeDateStamp = @pedump.pe.ifh.TimeDateStamp.to_i
        data = @pedump.pe.signature + (@pedump.pe.ifh.try(:pack)||'') + (@pedump.pe.ioh.try(:pack)||'')
        @pedump.pe.ifh.TimeDateStamp = Time.at(@pedump.pe.ifh.TimeDateStamp)
      when :resources
        return dump_resources(data)
      when :strings
        return dump_strings(data)
      else
        if data.is_a?(Struct) && data.respond_to?(:pack)
          data = data.pack
        elsif data.is_a?(Array) && data.all?{ |x| x.is_a?(Struct) && x.respond_to?(:pack)}
          data = data.map(&:pack).join
        end
    end
    dump data, dump_opts
  ensure
    puts
  end

  def dump data, opts = {}
    case opts[:format] || @options[:format] || :dump
    when :dump, :hexdump
      puts hexdump(data)
    when :hex
      puts data.each_byte.map{ |x| "%02x" % x }.join(' ')
    when :binary
      print data
    when :c
      name = opts[:name] || "foo"
      puts "// #{data.size} bytes total"
      puts "unsigned char #{name}[] = {"
      data.unpack('C*').each_slice(12) do |row|
        puts "  " + row.map{ |c| "0x%02x," % c}.join(" ")
      end
      puts "};"
    when :inspect
      require 'pp'
      pp data
    when :table
      dump_table data
    end
  end

  COMMENTS = {
    :Machine => {
      0x014c => 'x86',
      0x0200 => 'Intel Itanium',
      0x8664 => 'x64',
      'default' => '???'
    },
    :Magic => {
      0x010b => '32-bit executable',
      0x020b => '64-bit executable',
      0x0107 => 'ROM image',
      'default' => '???'
    },
    :Subsystem => PEdump::IMAGE_SUBSYSTEMS
  }

  def dump_table data
    if data.is_a?(Struct)
      return dump_res_dir(data) if data.is_a?(PEdump::IMAGE_RESOURCE_DIRECTORY)
      data.each_pair do |k,v|
        case v
        when Numeric
          case k
          when /\AMajor.*Version\Z/
            printf "%30s: %24s\n", k.to_s.sub('Major',''), "#{v}.#{data[k.to_s.sub('Major','Minor')]}"
          when /\AMinor.*Version\Z/
          else
            if COMMENTS[k]
              printf "%30s: %10d  %12s  %s\n", k, v, v<10 ? v : ("0x"+v.to_s(16)),
                COMMENTS[k][v] || COMMENTS[k]['default'] || ''
            else
              printf "%30s: %10d  %12s\n", k, v, v<10 ? v : ("0x"+v.to_s(16))
            end
          end
        when Struct
          printf "\n# %s:\n", v.class.to_s.split('::').last
          dump_table v
        when Time
          printf "%30s: %24s\n", k, v.strftime('"%Y-%m-%d %H:%M:%S"')
        when Array
          next if %w'DataDirectory section_table'.include?(k)
        else
          printf "%30s: %24s\n", k, v.to_s.inspect
        end
      end
    elsif data.is_a?(Enumerable) && data.map(&:class).uniq.size == 1
      case data.first
      when PEdump::IMAGE_DATA_DIRECTORY
        dump_data_dir data
      when PEdump::IMAGE_SECTION_HEADER
        dump_sections data
      when PEdump::Resource
        dump_resources data
      when PEdump::STRING
        dump_strings data
      else
        puts "[?] don't know how to dump: #{data.inspect[0,50]}" unless data.empty?
      end
    elsif data.is_a?(PEdump::DOSStub)
      puts hexdump(data)
    elsif data.is_a?(PEdump::RichHdr)
      dump_rich_hdr data
    else
      puts "[?] Don't know how to display #{data.inspect[0,50]}... as a table"
    end
  end

  def dump_strings data
    printf "%5s %5s  %4s  %s\n", "ID", "ID", "LANG", "STRING"
    prev_lang = nil
    data.sort_by{|s| [s.lang, s.id] }.each do |s|
      #puts if prev_lang && prev_lang != s.lang
      printf "%5d %5x  %4x  %s\n", s.id, s.id, s.lang, s.value.inspect
      prev_lang = s.lang
    end
  end

  def dump_res_dir entry, level = 0
    if entry.is_a?(PEdump::IMAGE_RESOURCE_DIRECTORY)
      # root entry
      printf "dir? %8s %8s %5s %5s",    "FLAGS", "TIMESTMP", "VERS", 'nEnt'
      printf " | %-15s %8s | ",         "NAME", "OFFSET"
      printf "data? %8s %8s %5s %8s\n", 'DATA_OFS', 'DATA_SZ', 'CP', 'RESERVED'
    end

    dir =
      case entry
      when PEdump::IMAGE_RESOURCE_DIRECTORY
        entry
      when PEdump::IMAGE_RESOURCE_DIRECTORY_ENTRY
        entry.data
      end

    fmt1  = "DIR: %8x %8x %5s %5d"
    fmt1s = fmt1.tr("xd\nDIR:","ss ") % ['','','','']

    if dir.is_a?(PEdump::IMAGE_RESOURCE_DIRECTORY)
      printf fmt1,
        dir.Characteristics, dir.TimeDateStamp,
        [dir.MajorVersion,dir.MinorVersion].join('.'),
        dir.NumberOfNamedEntries + dir.NumberOfIdEntries
    else
      print fmt1s
    end

    name =
      case level
      when 0 then "ROOT"
      when 1 then PEdump::ROOT_RES_NAMES[entry.Name] || entry.name
      else entry.name
      end

    printf " | %-15s", name
    printf("\n%s   %15s",fmt1s,'') if name.size > 15
    printf " %8x | ", entry.respond_to?(:OffsetToData) ? entry.OffsetToData : 0

    if dir.is_a?(PEdump::IMAGE_RESOURCE_DIRECTORY)
      puts
      dir.entries.each do |child|
        dump_res_dir child, level+1
      end
    else
      printf "DATA: %8x %8x %5s %8x\n", dir.OffsetToData, dir.Size, dir.CodePage, dir.Reserved
    end
  end

#  def dump_res_dir0 dir, level=0, dir_entry = nil
#    dir_entry ||= PEdump::IMAGE_RESOURCE_DIRECTORY_ENTRY.new
#    printf "%-10s %8x %8x %8x %5s %5d\n", dir_entry.name || "ROOT", dir_entry.OffsetToData.to_i,
#      dir.Characteristics, dir.TimeDateStamp,
#      [dir.MajorVersion,dir.MinorVersion].join('.'),
#      dir.NumberOfNamedEntries + dir.NumberOfIdEntries
#    dir.entries.each do |child|
#      if child.data.is_a?(PEdump::IMAGE_RESOURCE_DIRECTORY)
#        dump_res_dir child.data, level+1, child
#      else
#        print "  "*(level+1) + "CHILD"
#        child.data.each_pair do |k,v|
#          print " #{k[0,2]}=#{v}"
#        end
#        puts
#        #p child
#      end
#    end
#  end

  def dump_resources data
    keys = []; fmt = []
    fmt << "%11x " ; keys << :file_offset
    fmt << "%5d "  ; keys << :cp
    fmt << "%5x "  ; keys << :lang
    fmt << "%8d  " ; keys << :size
    fmt << "%-13s "; keys << :type
    fmt << "%s\n"  ; keys << :name
    printf fmt.join.tr('dx','s'), *keys.map(&:to_s).map(&:upcase)
    data.each do |res|
      fmt.each_with_index do |f,i|
        v = res.send(keys[i])
        if f['x']
          printf f.tr('x','s'), v < 10 ? v.to_s : "0x#{v.to_s(16)}"
        else
          printf f, v
        end
      end
    end
  end

  def dump_sections data
    printf "  %-8s %8s %8s %8s %8s %5s %8s %5s %8s  %8s\n",
      'NAME', 'RVA', 'VSZ','RAW_SZ','RAW_PTR','nREL','REL_PTR','nLINE','LINE_PTR','FLAGS'
    data.each do |s|
      name = s.Name[/[^a-z0-9_.]/i] ? s.Name.inspect : s.Name
      name = "#{name}\n          " if name.size > 8
      printf "  %-8s %8x %8x %8x %8x %5x %8x %5x %8x  %8x  %s\n", name,
        s.VirtualAddress,      s.VirtualSize,
        s.SizeOfRawData,       s.PointerToRawData,
        s.NumberOfRelocations, s.PointerToRelocations,
        s.NumberOfLinenumbers, s.PointerToLinenumbers,
        s.flags,               s.flags_desc
    end
  end

  def dump_data_dir data
    data.each do |row|
      printf "  %-12s  rva:0x%8x   size:0x %8x\n", row.type, row.va, row.size
    end
  end

  def dump_rich_hdr data
    puts "    LIB_ID        VERSION        TIMES_USED   "
    data.decode.each do |row|
      printf " %5d  %2x    %7d  %4x   %7d %3x\n",
        row.id, row.id, row.version, row.version, row.times, row.times
    end
  end

  def hexdump data, h = {}
    offset = h[:offset] || 0
    add    = h[:add]    || 0
    size   = h[:size]   || (data.size-offset)
    tail   = h[:tail]   || "\n"
    width  = h[:width]  || 0x10                 # row width, in bytes

    size = data.size-offset if size+offset > data.size

    r = ''; s = ''
    r << "%08x: " % (offset + add)
    ascii = ''
    size.times do |i|
      if i%width==0 && i>0
        r << "%s |%s|\n%08x: " % [s, ascii, offset + add + i]
        ascii = ''; s = ''
      end
      s << " " if i%width%8==0
      c = data[offset+i].ord
      s << "%02x " % c
      ascii << ((32..126).include?(c) ? c.chr : '.')
    end
    r << "%-*s |%-*s|%s" % [width*3+width/8+(width%8==0?0:1), s, width, ascii, tail]
  end
end