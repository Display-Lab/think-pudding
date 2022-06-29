import timeit

import pytest
import rdflib.plugins.sparql
from rdflib import ConjunctiveGraph, Graph, URIRef
from rdflib.query import Result

# Doesn't work against rdflib to to problem with the  https://github.com/RDFLib/rdflib/issues/709
TP_QUERY = """
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX obo: <http://purl.obolibrary.org/obo/>
  PREFIX slowmo: <http://example.com/slowmo#>
  # INSERT {
  #   GRAPH <urn:spek> {
  #     ?candidate slowmo:acceptable_by ?path .
  #   }
  # }
  # USING <Urn:spek>
  # USING <urn:paths>
  construct { 
    ?candidate slowmo:acceptable_by ?path .
  }
  from <urn:spek>
  from <urn:pathways>  
  where {
    ?path a obo:cpo_0000029 .
    ?candidate a obo:cpo_0000053 . 
    # ?candidate slowmo:AncestorTemplate ?template .
    FILTER NOT EXISTS {
      ?path slowmo:HasPrecondition ?attr .
      ?attr a ?atype .
      FILTER NOT EXISTS {
        ?candidate obo:RO_0000091 ?disp .
        ?disp a ?atype .
      }
    }
  }
  """

@pytest.fixture
def big_graph() -> ConjunctiveGraph:
  rdflib.plugins.sparql.SPARQL_LOAD_GRAPHS = False
  rdflib.plugins.sparql.SPARQL_DEFAULT_GRAPH_UNION = False
  g = ConjunctiveGraph()
  return g


# pytest -rP tests/test_cg.py::test_load
def test_load(big_graph: ConjunctiveGraph):
  spek = URIRef("urn:spek")
  g_spek = Graph(store=big_graph.store, identifier=spek)
  g_spek.parse("../vignettes/alice/outputs/spek_cs.json")

  assert 165 == len(big_graph)

  pathways = URIRef("urn:pathways")
  g_pathways = Graph(store=big_graph.store, identifier=pathways)
  g_pathways.parse("../vignettes/alice/causal_pathways.json")

  assert 192 == len(big_graph)

  # print(big_graph.serialize(format="nquads"))

  t = timeit.timeit(
    stmt='big_graph.query("select * from <urn:pathways> {?s ?p ?o .}")',
    globals={'big_graph': big_graph},
    number=10
  )

  qres = big_graph.query("select * from <urn:pathways> {?s ?p ?o .}")

  print(len(qres))
  print('time: {}'.format(t))


def test_simple_query(big_graph: ConjunctiveGraph):

    data = """
    <urn:a> <urn:a> <urn:a> <urn:a> .
    <urn:b> <urn:b> <urn:b> <urn:b> .
    <urn:c> <urn:c> <urn:c> <urn:c> .
    """

    big_graph.parse(data=data, format="nquads")

    assert len(big_graph) == 3
    assert len(big_graph.query("SELECT * {?s ?p ?o .}")) == 0


# pytest -rP tests/test_cg.py::test_thinkpudding_query
def test_thinkpudding_query(big_graph: ConjunctiveGraph):

  # spek
  spek = URIRef("urn:spek")
  g_spek = Graph(store=big_graph.store, identifier=spek)
  g_spek.parse("../vignettes/alice/outputs/spek_cs.json")

  assert 165 == len(big_graph)
  print('spek has {} candidates'.format(len(
    big_graph.query(
      "SELECT * from <urn:spek> WHERE {?s a <http://purl.obolibrary.org/obo/cpo_0000053> .}")
  )))

  # pathways
  pathways = URIRef("urn:pathways")
  g_pathways = Graph(store=big_graph.store, identifier=pathways)
  g_pathways.parse("../vignettes/alice/causal_pathways.json")

  assert 192 == len(big_graph)

  print('pathways has {} causal pathways'.format(len(
    big_graph.query(
      "SELECT * from <urn:pathways> WHERE {?s a <http://purl.obolibrary.org/obo/cpo_0000029> .}")
  )))

  # graphs in the store
  for c in big_graph.contexts():
    print(f"-- {c.identifier} ")

# thinkpudding query (as a construct)
  qres: Result = big_graph.query(TP_QUERY)

  print(qres.graph.serialize()) 

  # logging.critical(qres.graph.serialize(format="json-ld"))
