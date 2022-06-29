### Characterization tests
There are some examples of loading an rdflib graph and querying in the test_cg.py file.

try this
```
poetry install
```

and then
```
pytest -rP tests/test_cg.py::test_cp
```

You should see the some output from the creation and querying of the graphs. See the code for more info.