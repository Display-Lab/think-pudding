import rdflib.plugins.sparql
from rdflib import ConjunctiveGraph


def test_issue811():

    data = """
    <urn:a> <urn:a> <urn:a> <urn:a> .
    <urn:b> <urn:b> <urn:b> <urn:b> .
    <urn:c> <urn:c> <urn:c> <urn:c> .
    """

    rdflib.plugins.sparql.SPARQL_DEFAULT_GRAPH_UNION = False
    rdflib.plugins.sparql.SPARQL_LOAD_GRAPHS = False

    graph = ConjunctiveGraph()
    graph.parse(data=data, format="nquads")
    assert len(graph) == 3

    assert len(graph.query("SELECT * {?s ?p ?o .}")) == 0

    # Set default graph as UNION, CORRECT result
    rdflib.plugins.sparql.SPARQL_DEFAULT_GRAPH_UNION = True
    assert len(graph.query("SELECT * {?s ?p ?o .}")) == 3

    # Use FROM to specify <urn:b> as the default graph

    # Set default graph as UNION, INCORRECT result
    rdflib.plugins.sparql.SPARQL_DEFAULT_GRAPH_UNION = True
    assert (
        len(graph.query("SELECT * FROM <urn:b> {?s ?p ?o}")) == 3
    ), "should be 1 triple"

    # Set default graph as NON-UNION, CORRECT result
    rdflib.plugins.sparql.SPARQL_DEFAULT_GRAPH_UNION = False
    assert (
        len(graph.query("SELECT * FROM <urn:b> {?s ?p ?o}")) == 1
    ), "should be 1 triple"

    # Use FROM NAMED to specify <urn:b> as target graph

    # Set default graph as UNION, INCORRECT result
    rdflib.plugins.sparql.SPARQL_DEFAULT_GRAPH_UNION = True
    assert (
        len(graph.query("SELECT * FROM NAMED <urn:b> {?s ?p ?o}")) == 3
    ), "should be 1 triple"

    # Set default graph as NON-UNION, CORRECT result
    rdflib.plugins.sparql.SPARQL_DEFAULT_GRAPH_UNION = False
    assert (
        len(graph.query("SELECT * FROM NAMED <urn:b> {?s ?p ?o}")) == 1
    ), "should be 1 triple"