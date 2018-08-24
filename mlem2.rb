require_relative './rule_common'
require 'optparse'

attr_file = 'a.attr'
data_file = 'a.data'
cond_file = 'a.cond'
rule_file = 'a.rule'
seed = 0

opt = OptionParser.new
opt.on('-a ATTRIBUTE_FILE',String){|v| attr_file = v}
opt.on('-i INPUT_FILE',String){|v| data_file = v}
opt.on('-c CONDITION_FILE',String){|v| cond_file = v}
opt.on('-r OUTPUT_RULE_FILE',String){|v| rule_file = v}
opt.on('-s SEED',Integer){|v| seed = v}

opt.parse!(ARGV)

srand(seed)

print 'induce rules from ', data_file, " by MLEM2.\n\n"

# read attr
attributes = read_attr(attr_file)

# read data
header,pre_objects = read_data(data_file)

# read cond
cond_names,dec_name,ord_names = read_cond(cond_file)

# covert numerical table
h_attributes = to_h_attributes(attributes,header)
objects = to_numeric(h_attributes,pre_objects)

decision = attributes.find{|a| a.attr_name == dec_name}
if decision == nil then p 'there is no decision class: ' + dec_name.to_s + ".\n"; exit(1) end

if cond_names.empty?
  cond_names = header - [dec_name]
end
conditions = attributes.find_all{|a| cond_names.include?(a.attr_name)}

values = h_attributes.map{|h| [h,(objects.map{|o| o[h]} - [nil]).uniq.sort]}.to_h

labels = values[decision].map{|v| NominalFeature.new(decision,v)}

features = conditions.inject([]){|ary,c|
  if ord_names.include?(c.attr_name) && c.instance_of?(RealAttribute)
    f = (0...values[c].size-1).map{|i| AtMostFeature.new(c,(values[c][i]+values[c][i+1])/2)} + (0...values[c].size-1).map{|i| AtLeastFeature.new(c,(values[c][i]+values[c][i+1])/2)}    
  elsif ord_names.include?(c.attr_name)
    f = (0...values[c].size-1).map{|i| AtMostFeature.new(c,values[c][i])} + (0...values[c].size-1).map{|i| AtLeastFeature.new(c,values[c][i+1])} 
  else
    f = values[c].map{|v| NominalFeature.new(c,v)}
  end
  ary + f
}

feature_table = objects.map{|o| features.map{|f| f.match?(o)}}

print objects.size, ' objects, ', cond_names.size, ' attributes including ', ord_names.size, ' ordinals, ', \
features.size, ' features, ', labels.size, ' labels.', "\n\n"

#####
### generate rules
#####

rules = []

labels.each{|label|
  print 'label ',label.to_s,"\n"
  class_set = (0...objects.size).select{|i| label.match?(objects[i])}
  class_bar_set = (0...objects.size).to_a - class_set

  pos = class_set.clone
  pos.reject!{|i| class_bar_set.any?{|ii| conditions.all?{|c| objects[i][c] == nil || objects[i][c] == objects[ii][c]}}}
  neg = (0...objects.size).to_a - pos

  print pos.size, ' positives and ', neg.size, ' negatives.', "\n"

  all_feas = (0...features.size).to_a
  (0...features.size).each{|j|
    if all_feas.any?{|jj| 
      jj != j \
      && pos.all?{|i| !feature_table[i][j] || feature_table[i][jj]} && neg.all?{|i| feature_table[i][j] || !feature_table[i][jj]} \
    }
      all_feas.delete(j)
    end
  }
  all_feas_partiton = all_feas.map{|j| 
    (0...features.size).select{|jj| 
      pos.all?{|i| feature_table[i][j] == feature_table[i][jj]} && neg.all?{|i| feature_table[i][j] == feature_table[i][jj]}
    }
  }
  all_feas = all_feas_partiton.map{|e| e.sample}

  print all_feas.size, ' non-dominated features.', "\n"

  left_pos = pos.clone

  class_rules = []

  while(!left_pos.empty?) do
    cov_pos = pos.clone
    cov_neg = neg.clone
    cov_left = left_pos.clone

    rule_body = []

    cur_feas = all_feas
    cur_feas.reject!{|j| left_pos.none?{|i| feature_table[i][j]}}

    while !cov_neg.empty? do
      # p all_cands.sort

      sel_feas = cur_feas.clone

      evals = sel_feas.map{|j| cov_left.count{|i| feature_table[i][j]}}
      best_eval = evals.max
      sel_feas = (0...cur_feas.size).select{|k| evals[k] == best_eval}.map{|k| sel_feas[k]}

      # evals = sel_feas.map{|j| cov_pos.count{|i| feature_table[i][j]}}
      # best_eval = evals.max
      # sel_feas = (0...cur_feas.size).select{|k| evals[k] == best_eval}.map{|k| sel_feas[k]}

      # evals = sel_feas.map{|j| cov_neg.count{|i| feature_table[i][j]}}
      # best_eval = evals.min
      # sel_feas = (0...cur_feas.size).select{|k| evals[k] == best_eval}.map{|k| sel_feas[k]}

      evals = sel_feas.map{|j| pos.count{|i| feature_table[i][j]} + neg.count{|i| feature_table[i][j]}}
      best_eval = evals.min
      sel_feas = (0...cur_feas.size).select{|k| evals[k] == best_eval}.map{|k| sel_feas[k]}

      if sel_feas.empty?
        p 'error: no current features.'
        exit(1)
      end

      sel_fea = sel_feas[0]

      cov_pos = cov_pos.select{|i| feature_table[i][sel_fea]}
      cov_neg = cov_neg.select{|i| feature_table[i][sel_fea]}
      cov_left = cov_left.select{|i| feature_table[i][sel_fea]}
      cur_feas -= [sel_fea]
      cur_feas.reject!{|j| cov_left.none?{|i| feature_table[i][j]}}

      # p cov_pos.size,cov_neg.size

      rule_body << sel_fea
    end

    tmp = rule_body.clone.reverse
    tmp.each{|j|
      if neg.none?{|i| rule_body.all?{|jj| jj == j || feature_table[i][jj]}}
        rule_body.delete(j)
      end
    }

    cov_pos = pos.select{|i| rule_body.all?{|j| feature_table[i][j]}}
    left_pos -= cov_pos

    rule_body = rule_body.map{|j| features[j]}

    # p rule_body.map{|b| b.to_s}

    coverage = [labels,labels.map{|l| objects.count{|o| l.match?(o) && rule_body.all?{|f| f.match?(o)}}}].transpose.to_h
    rule_body = attributes.inject([]){|r,a| r + rule_body.select{|f| f.attri == a}.sort_by{|f| f.value}}
    rule = Rule.new(label,rule_body,coverage)
    class_rules << rule
  end

  tmp = class_rules.clone.reverse
  tmp.each{|r|
    if pos.all?{|i| class_rules.any?{|rr| rr != r && rr.match?(objects[i])}}
      class_rules.delete(r)
    end
  }
  
  print class_rules.size, ' rules including ', class_rules.map{|r| r.body.size}.reduce(:+), ' features.', "\n"
  (0...[3,class_rules.size].min).each{|i| print class_rules[i].to_s, "\n"}
  if class_rules.size > 3 then print "...\n" end
  print "\n"

  rules += class_rules
}

dist = labels.map{|l| objects.count{|o| l.match?(o)}}
k = (0...labels.size).max_by{|kk| dist[kk]}
default_rule = Rule.new(labels[k],[],[labels,dist].transpose.to_h)
rules << default_rule

#####
### output rules
#####

print 'save rules to ', rule_file, ".\n\n"

file = File.open(rule_file,'w')
rules.each{|r|
  file.print r.to_s, "\n\n"
}
file.close

