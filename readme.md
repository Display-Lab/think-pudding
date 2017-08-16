# Think Pudding
A minimal proof of concept reasoner and ontology example.

## Description
The minimal.owl ontology is rdf/xml formatted, and contains a single SWRL rule.
That rule specifies that a Candidate that hasColor(Red) is an AcceptableCandidate.
```
Candidate(?c) ^ hasColor(?c, Red) -> AcceptableCandidate(?c)
```
There is a named individual Color "Red".
The named individual candidate "Foo". 
Foo hasColor Red in this ontology, and reasoners should infer that Foo is an AcceptableCandidate.

## Use

### StarDog Command Line
Start up & demonstrate
```
# Start server and create database
stardog-admin server start
stardog-admin db create -n 'mydb' minimal.owl

# Query without reasoning will return no results
stardog query mydb acceptable.sparql

# +---------+
# | subject |
# +---------+
# +---------+

# Query with reasoning will return single result, :Foo
stardog query --reasoning acceptable.sparql

# +---------+
# | subject |
# +---------+
# | :Foo    |
# +---------+
```

Cleanup & shutdown
```
stardog-admin db drop mydb
stardog-admin server stop
```

### OwlTools Command Line
The owltools does not make the inference that Foo is an AcceptableCandidate.

```
owltools minimal.owl --reasoner hermit --run-reasoner --assert-implied
```


## Requirements
- owltools
- StarDog Community

## License

Creative Commons 3.0
