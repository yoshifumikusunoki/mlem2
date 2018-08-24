# MLEM2

An implementation of MLEM2 rule induction algorithm [1].

## How to use
First, we obtain a training data set `a.train` and a validation data set `a.test` by 10-fold cross validation.
```
ruby cv10eqcls.rb -a <attribute file> -i <data file> -d <class name> -p <test position> -s <seed>
```
`<test position>` is 0,1,...,9.

We compute a rule set `a.rule` by the MLEM2 algorithm.
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

## Example 

Run, 
```
ruby mlem2.rb -a datasets/zoo.attr -c datasets/zoo.cond -i datasets/zoo.data
```
Then, we obtain the following rules.
The last is a default rule.
```
[type = mammal] <- [milk = true]
	[ mammal(41) bird(0) reptile(0) fish(0) amphibian(0) insect(0) invertebrate(0) ]

[type = bird] <- [feathers = true]
	[ mammal(0) bird(20) reptile(0) fish(0) amphibian(0) insect(0) invertebrate(0) ]

[type = reptile] <- [fins = false] [legs = 0] [tail = true]
	[ mammal(0) bird(0) reptile(3) fish(0) amphibian(0) insect(0) invertebrate(0) ]

[type = reptile] <- [hair = false] [aquatic = false] [legs = 4]
	[ mammal(0) bird(0) reptile(2) fish(0) amphibian(0) insect(0) invertebrate(0) ]

[type = fish] <- [breathes = false] [fins = true]
	[ mammal(0) bird(0) reptile(0) fish(13) amphibian(0) insect(0) invertebrate(0) ]

[type = amphibian] <- [aquatic = true] [toothed = true] [legs = 4] [catsize = false]
	[ mammal(0) bird(0) reptile(0) fish(0) amphibian(4) insect(0) invertebrate(0) ]

[type = insect] <- [aquatic = false] [legs = 6]
	[ mammal(0) bird(0) reptile(0) fish(0) amphibian(0) insect(8) invertebrate(0) ]

[type = invertebrate] <- [airborne = false] [predator = true] [backbone = false]
	[ mammal(0) bird(0) reptile(0) fish(0) amphibian(0) insect(0) invertebrate(8) ]

[type = invertebrate] <- [backbone = false] [legs = 0]
	[ mammal(0) bird(0) reptile(0) fish(0) amphibian(0) insect(0) invertebrate(4) ]

[type = mammal] <-
	[ mammal(41) bird(20) reptile(5) fish(13) amphibian(4) insect(8) invertebrate(10) ]
```

## Reference
[1] J. W. Grzymala-Busse. Rule Induction from Rough Approximations. In: J. Kacprzyk, W. Pedrycz (eds) Springer Handbook of Computational Intelligence. Springer, Berlin, Heidelberg, 2015

  
