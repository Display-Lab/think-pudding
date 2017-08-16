# Think Pudding
A minimal proof of concept reasoner example.

## Description
The minimal.owl ontology is rdf/xml formatted, and contains a single SWRL rule/
That rule specifies that a Candidate that hasColor(Red) is an acceptable Candidate.
There is a named individual Color "Red".
The named individual candidate "Foo". 
Foo hasColor Red in this ontology, and reasoners should infer that Foo is an AcceptableCandidate.

## Use

### OwlTools Command Line

```
owltools minimal.owl --reasoner hermit --run-reasoner --assert-implied
```

### StarDog Command Line

Start up & demonstrate
```
# Start server and create database
stardog-admin server start
stardog-admin db create -n 'mydb' minimal.owl

# Query without reasoning
stardog query mydb "select distinct * where { ?s ?p ?o } limit 10"

# Query with reasoning
stardog query mydb "select distinct * where { ?s ?p ?o } limit 10"
```

Cleanup & shutdown
```
stardog-admin db drop mydb
stardog-admin server stop
```

## Requirements
- owltools
- StarDog Community

## License

Creative Commons 3.0
