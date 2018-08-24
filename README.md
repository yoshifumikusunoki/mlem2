# MLEM2

An implementation of MLEM2 rule induction algorithm [1].

## How to use
First, obtain a training data set `a.train` and a validation data set `a.test` by 10-fold cross validation.
```
ruby cv10eqcls.rb -a <attribute file> -i <data file> -d <class name> -p <test position> -s <seed>
```
`<test position>` is 0,1,...,9.

Compute a rule set `a.rule` by the MLEM2 algorithm.
```
ruby mlem2.rb -a <attribute file> -i <training data file (a.train)> -c <attribute setting file>
```

Classify the validation data set `a.test` by the obtained rule set `a.rule`.
```
ruby rule_classifier.rb -a <attribute file> -i <validation data file (a.test)> -r <rule file (a.rule)>
```

For `zoo dataset`, we set as follows.
```
<attribute file> := datasets/zoo.attr
<data file> := datasets/zoo.data
<class name> := type
<attribute setting file> := datasets/zoo.cond
```


## Reference
[1] J. W. Grzymala-Busse. Rule Induction from Rough Approximations. In: J. Kacprzyk, W. Pedrycz (eds) Springer Handbook of Computational Intelligence. Springer, Berlin, Heidelberg, 2015

  
