require_relative './rule_common'
require 'optparse'

attr_file = 'a.attr'
data_file = 'a.data'
rule_file = 'a.rule'
out_file = 'a.out'

opt = OptionParser.new
opt.on('-a ATTRIBUTE_FILE',String){|v| attr_file = v}
opt.on('-i INPUT_FILE',String){|v| data_file = v}
opt.on('-r RULE_FILE',String){|v| rule_file = v}
opt.on('-o OUTPUT_FILE',String){|v| out_file = v}

opt.parse!(ARGV)

print 'classify objects in ', data_file, ' by rules in ', rule_file, ".\n\n"

# read attr
attributes = read_attr(attr_file)

# read data
header,pre_objects = read_data(data_file)

# covert numerical table
h_attributes = to_h_attributes(attributes,header)
objects = to_numeric(h_attributes,pre_objects)

# read rules
rules,labels = read_rule(rule_file,attributes)

default_rule = rules.find{|r| r.body.empty?}
rules.delete_if{|r| r.body.empty?}

decision = default_rule.head.attri

pred = []
objects.each{|o|
  matched = rules.select{|r| r.match?(o)}
  label_eval = labels.map{|l| matched.select{|r| r.head == l}.inject(0){|t,r| t + r.body.size*r.coverage[l]}}
  if label_eval.all?{|e| e==0}
    pred << default_rule.head.value
  else
    k = (0...labels.size).max_by{|kk| label_eval[kk]}
    pred << labels[k].value
  end
}

if attributes.include?(decision)
  cont_tab = Array.new(labels.size){Array.new(labels.size)}
  (0...labels.size).each{|k|
    (0...labels.size).each{|l|
      cont_tab[k][l] = (0...objects.size).count{|i| labels[k].match?(objects[i]) && labels[l].match?({decision=>pred[i]})}
    }
  }

  acc = (0...labels.size).inject(0){|t,k| t + cont_tab[k][k]} / objects.size.to_f

  print 'Accuracy',"\n"
  printf("%f\n\n",acc)

  print 'Contingency table',"\n"
  cont_tab.each{|ct|
    ct.each{|e| printf("%#{(Math.log10(objects.size)).ceil}d ",e)}
    print "\n"
  }
  print "\n"
end

##########
### output
##########

print 'save the result to ', out_file, ".\n\n"

file = File.open(out_file,'w')

if attributes.include?(decision)
  file.print 'Accuracy',"\n"
  file.printf("%f\n\n",acc)

  file.print 'Contingency table',"\n"
  cont_tab.each{|ct|
    ct.each{|e| file.printf("%#{(Math.log10(objects.size)).ceil}d ",e)}
    file.print "\n"
  }
  file.print "\n"
end

(0...objects.size).each{|i|
  file.print h_attributes.map{|a| '(' + a.attr_name.to_s + ',' + a.to_s(objects[i][a]) + ')'}.inject(''){|str,v| str + v + ' '}, "\n"
  matched = rules.select{|r| r.match?(objects[i])}
  file.print NominalFeature.new(decision,pred[i]).to_s, "\n"
  matched.each{|r|
    file.print r.to_s, "\n"    
  }
  file.print "\n"
}

file.close
