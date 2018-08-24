$missing_value = :'?'

class AbstractAttribute
  attr_reader :attr_name, :values
  def initialize(attr_name)
    @attr_name, @values = attr_name, ['abstract']
  end
  def to_n(v)
    return nil if v.to_sym == $missing_value
    v
  end
  def to_s(n)
    return $missing_value.to_s if n == nil
    n
  end
  def hash
    @attr_name.hash
  end
  def eql?(o)
    return nil unless o.kind_of?(AbstractAttribute)
    @attr_name == o.attr_name
  end
  def ==(o)
    return nil unless o.kind_of?(AbstractAttribute)
    @attr_name == o.attr_name
  end
  def <=>(o)
    return nil unless o.kind_of?(AbstractAttribute)
    @attr_name <=> o.attr_name
  end  
end

class RealAttribute < AbstractAttribute
  def initialize(attr_name)
    @attr_name, @values = attr_name, ['real']
  end
  def to_n(v)
    return nil if v.to_sym == $missing_value
    v.to_f
  end
  def to_s(n)
    return $missing_value.to_s if n == nil
    n.to_s
  end
end

class IntegerAttribute < AbstractAttribute
  def initialize(attr_name)
    @attr_name, @values = attr_name, ['integer']
  end
  def to_n(v)
    return nil if v.to_sym == $missing_value
    v.to_i
  end
  def to_s(n)
    return $missing_value.to_s if n == nil
    n.to_s
  end
end

class StringAttribute < AbstractAttribute
  def initialize(attr_name)
    @attr_name, @values = attr_name, ['string']
  end
  def to_n(v)
    return nil if v.to_sym == $missing_value
    v.to_sym
  end
  def to_s(n)
    return $missing_value.to_s if n == nil
    n.to_s
  end
end

class DiscreteAttribute < AbstractAttribute
  def initialize(attr_name,values)
    @attr_name, @values = attr_name, values
  end
  def to_n(v)
    return nil if v.to_sym == $missing_value
    (0...@values.size).find{|i| values[i] == v.to_sym}
  end
  def to_s(n)
    return $missing_value.to_s if n == nil
    values[n].to_s
  end
end

class NominalFeature
  include Comparable
  attr_reader :attri, :value
  def initialize(attri,value)
    @attri, @value = attri, value
  end
  def match?(o)
    o[attri] == @value
  end
  def hash
    @attri.hash + @value.hash
  end
  def eql?(o)
    return false unless o.instance_of?(NominalFeature)
    @attri == o.attri && @value == o.value    
  end
  def ==(o)
    return false unless o.instance_of?(NominalFeature)
    @attri == o.attri && @value == o.value    
  end
  def <=>(o)
    return nil unless o.instance_of?(NominalFeature)
    if @attri == o.attri
      return @value <=> o.value
    else
      return @attri <=> o.attri
    end
  end
  def to_s
    '[' + attri.attr_name.to_s + ' = ' + attri.to_s(value) + ']'
  end
  def is_compatible?(o)
    return true unless @attri == o.attri
    @value == o.value
  end
end

class AtMostFeature
  include Comparable
  attr_reader :attri, :value
  def initialize(attri,value)
    @attri, @value = attri, value
  end
  def match?(o)
    if o[attri] == nil then return false end
    o[attri] <= @value
  end
  def hash
    @attri.hash + @value.hash
  end
  def eql?(o)
    return false unless o.instance_of?(AtMostFeature) 
    @attri == o.attri && @value == o.value  
  end
  def ==(o)
    return false unless o.instance_of?(AtMostFeature)
    @attri == o.attri && @value == o.value  
  end
  def <=>(o)
    return nil unless o.instance_of?(AtMostFeature)
    if @attri == o.attri
      return @value <=> o.value
    else
      return @attri <=> o.attri
    end
  end
  def to_s
    '[' + attri.attr_name.to_s + ' <= ' + attri.to_s(value) + ']'
  end
  def is_compatible?(o)
    return true unless @attri == o.attri && o.instance_of?(AtLeastFeature)
    @value >= o.value
  end
end

class AtLeastFeature
  include Comparable
  attr_reader :attri, :value
  def initialize(attri,value)
    @attri, @value = attri, value
  end
  def match?(o)
    if o[attri] == nil then return false end
    o[attri] >= @value
  end
  def hash
    @attri.hash + @value.hash
  end
  def eql?(o)
    return false unless o.instance_of?(AtLeastFeature)
    @attri == o.attri && @value == o.value 
  end
  def ==(o)
    return false unless o.instance_of?(AtLeastFeature)
    @attri == o.attri && @value == o.value 
  end
  def <=>(o)
    return nil unless o.instance_of?(AtLeastFeature)
    if @attri == o.attri
      return @value <=> o.value
    else
      return @attri <=> o.attri
    end
  end
  def to_s
    '[' + attri.attr_name.to_s + ' >= ' + attri.to_s(value) + ']'
  end
  def is_compatible?(o)
    return true unless @attri == o.attri && o.instance_of?(AtMostFeature)
    @value <= o.value
  end
end

class Rule
  attr_reader :body, :head, :coverage
  def initialize(head,body,coverage)
    @head, @body, @coverage = head, body, coverage
  end
  def match?(o)
    body.all?{|f| f.match?(o)}
  end
  def hash
    @head.hash + @body.hash
  end
  def eql?(o)
    @head == o.head && @body == o.body
  end
  def ==(o)
    @head == o.head && @body == o.body
  end
  def to_s
    dec = head.attri
    head.to_s + ' <-' + body.inject(''){|str,f| str + ' ' + f.to_s} + "\n\t" + coverage.to_a.inject("[ "){|str,c| str + dec.to_s(c[0].value) + '(' + c[1].to_s + ') '} + ']'
  end
end

def read_attr(file_name)
  file = File.open(file_name)

  attributes = []
  file.each{|l|
    l.strip!
    if l == '' then next end
    items = l.split(':').map{|s| s.strip}
    if items[1] == nil then p 'error in attr file: ' + l; exit(1) end
    if items[1] == 'real'
      a = RealAttribute.new(items[0].to_sym)
    elsif items[1] == 'integer'
      a = IntegerAttribute.new(items[0].to_sym)
    elsif items[1] == 'string'
      a = StringAttribute.new(items[0].to_sym)
    else
      values = items[1].split(/\s+/).map{|s| s.to_sym}
      a = DiscreteAttribute.new(items[0].to_sym,values)
    end
    attributes << a
  }

  return attributes
end

def read_data(file_name)
  file = File.open(file_name)

  header = []
  file.each{|l|
    l.strip!
    if l != '' 
      header = l.split(/\s+/).map{|s| s.to_sym}
      break
    end
  }

  if file.eof? then p 'error in the data file: EOF.'; exit(1) end

  objects = []
  file.each{|l|
    l.strip!
    if l == '' then next end
      items = l.split(/\s+/)
      if items.size == header.size
        objects << items
      else
        p 'error in the data file: row.size != header.size: ' + l; exit(1)
      end
  }
  file.close

  if objects.size == 0 then p 'error in the data file: no objects.'; exit(1) end

  return header,objects
end

def read_cond(file_name)
  ordinals = []
  conditions = []
  decision = ''

  file = File.open(file_name)
  file.each{|l|
    l.strip!
    if l == '' then next end
    item = l.split(/\s+/)
    if item[0].downcase == 'ordinal'
      ordinals += item[1..-1].map{|s| s.to_sym}
    elsif item[0].downcase == 'condition'
      conditions += item[1..-1].map{|s| s.to_sym}
    elsif item[0].downcase == 'decision'
      if decision != ''
        p 'errro in the info file: multiple decision.'; exit(1)
      else
        decision = item[1].to_sym
      end
    end
  }
  file.close

  if decision == '' then p 'error in the info file: decision is not specified.'; exti(1) end

  return conditions,decision,ordinals
end

def to_h_attributes(attributes,header)
  h_attributes = header.map{|h| attributes.find{|a| a.attr_name == h}}
  if h_attributes.include?(nil) then p 'there are unknown attributes in data.' + "\n"; exit(1) end
  return h_attributes
end

def to_numeric(h_attributes,objects)
  return objects.map{|o| (0...o.size).map{|i| [h_attributes[i],h_attributes[i].to_n(o[i])]}.to_h}
end

def read_rule(file_name,attributes)
  heads = []
  bodys = []
  covs = []
  file = File.open(file_name)
  while !file.eof?
    l = file.readline
    l.strip!
    if l == '' then next end
    item = l.split('<-')

    head_str = item[0].strip
    f = head_str.slice!(/\[[^\[^\]]+\]/)
    f = f.gsub(/[\[\]]/,'').strip.split('=').map{|s| s.strip}
    h_attr = attributes.find{|a| a.attr_name == f[0].to_sym}
    head = NominalFeature.new(h_attr,h_attr.to_n(f[1]))

    body = []
    if item[1] != nil
      body_str = item[1].strip
      while body_str != ''
        f = body_str.slice!(/\[[^\[^\]]+\]/)
        f = f.gsub(/[\[\]]/,'')
        if f.include?('<=')
          f = f.strip.split('<=').map{|s| s.strip}
          h_attr = attributes.find{|a| a.attr_name == f[0].to_sym}
          body << AtMostFeature.new(h_attr,h_attr.to_n(f[1]))
        elsif f.include?('>=')
          f = f.strip.split('>=').map{|s| s.strip}
          h_attr = attributes.find{|a| a.attr_name == f[0].to_sym}
          body << AtLeastFeature.new(h_attr,h_attr.to_n(f[1]))
        else
          f = f.strip.split('=').map{|s| s.strip}
          h_attr = attributes.find{|a| a.attr_name == f[0].to_sym}
          body << NominalFeature.new(h_attr,h_attr.to_n(f[1]))
        end
        body_str.strip!
      end
    end

    l = file.readline
    str = l.strip!
    cov = str.slice!(/\[[^\[^\]]+\]/)
    cov = cov.gsub(/[\[\]]/,'').strip.split(/\s+/).map{|s| s.strip}

    heads << head
    bodys << body
    covs << cov
  end
  file.close

  labels = heads.uniq.sort

  coverages = []
  (0...bodys.size).each{|i|
    cov = covs[i]
    coverage = Hash.new(0)
    cov.each{|c|
      c =~ /([\w\-]+)\((\d+)\)/
      lm = Regexp.last_match
      l = labels.find{|ll| ll.value == ll.attri.to_n(lm[1])}
      if l != nil then coverage[l] = lm[2].to_i end
    }
    coverages << coverage
  }

  rules = []
  (0...bodys.size).each{|i| rules << Rule.new(heads[i],bodys[i],coverages[i])}

  return rules,labels
end