require_relative './rule_common'
require 'optparse'

attr_file = 'a.attr'
data_file = 'a.data'
train_file = 'a.train'
test_file = 'a.test'
dec_name = :class
position = 0
seed = 0

opt = OptionParser.new
opt.on('-a ATTRIBUTE_FILE',String){|v| attr_file = v}
opt.on('-i INPUT_FILE',String){|v| data_file = v}
opt.on('-d DECISION',String){|v| dec_name = v.to_sym}
opt.on('-t TRAIN_FILE',String){|v| train_file = v}
opt.on('-e TEST_FILE',String){|v| test_file = v}
opt.on('-p POSITION',Integer){|v| position = v}
opt.on('-s SEED',Integer){|v| seed = v}

opt.parse!(ARGV)

if position < 0 || position > 9
  p 'error: position = ' + position.to_s
  exit(1)
end

srand(seed)

# read attr
attributes = read_attr(attr_file)

# read data
header,pre_objects = read_data(data_file)

# covert numerical table
h_attributes = to_h_attributes(attributes,header)
objects = to_numeric(h_attributes,pre_objects)

decision = attributes.find{|a| a.attr_name == dec_name}
if decision == nil then p 'there is no decision class: ' + dec_name.to_s + ".\n"; exit(1) end

labels = objects.map{|o| o[decision]}.uniq.sort.map{|v| NominalFeature.new(decision,v)}

class_set = labels.map{|l| objects.select{|o| l.match?(o)}.shuffle}

tefile = File.open(test_file, "w")
tefile << h_attributes.inject(''){|str,a| str + a.attr_name.to_s + ' '} + "\n"
trfile = File.open(train_file, "w")
trfile << h_attributes.inject(''){|str,a| str + a.attr_name.to_s + ' '} + "\n"

class_set.each{|c|
  left = ((c.size()*position)/10.0).to_i
  right = ((c.size()*(position+1))/10.0).to_i
  (left...right).each{|i| tefile << h_attributes.inject(''){|str,a| str + a.to_s(c[i][a]) + ' '} + "\n"}
  (0...left).each{|i| trfile << h_attributes.inject(''){|str,a| str + a.to_s(c[i][a]) + ' '} + "\n"}
  (right...c.size()).each{|i| trfile << h_attributes.inject(''){|str,a| str + a.to_s(c[i][a]) + ' '} + "\n"}  
}

tefile.close
trfile.close
