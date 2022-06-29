import logging
import pytest
from rdflib import Graph
from rdflib.query import Result

@pytest.fixture
def big_graph() -> Graph:
    g = Graph()
    g.parse("../vignettes/alice/outputs/spek_cs.json")
    return g


def test_load(big_graph):
    assert 4596 == len(big_graph)

    qres: Result = big_graph.query("""
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX obo: <http://purl.obolibrary.org/obo/>
      PREFIX slowmo: <http://example.com/slowmo#>
      construct { ?candidate ?p ?o }
      where {
        ?candidate a obo:cpo_0000053 .
        ?candidate ?p ?o
      }
    """)

    logging.critical(qres.graph.serialize(format="n3"))


def test_query(big_graph: Graph):

    # qres = big_graph.update(cp_insert_query)
    big_graph.update("""
    INSERT DATA { <z:> a <c:> . <a:> a <b:> }"""
    )

    qres: Result = big_graph.update("""
    insert { ?s <booty:> ?o }
    where {
      ?s a <c:> .
      ?s ?p ?o
      }
    """)

    big_graph.update("""
    insert { 
      ?s <rooty:> ?o .
      <who:> <rooty:> <c:> }
    where {
      ?s a <c:> .
      ?s ?p ?o
      }
    """)

    # logging.critical(qres.graph.serialize())
    logging.critical(len(big_graph))

    qres = big_graph.query("""
    construct { ?s ?p <c:> }
    where {
      ?s ?p <c:> .
      filter not exists {
        ?s <booty:> ?o .
      }
    }
    """)

    # logging.critical(qres.graph.serialize())
    # assert False
    # assert 2 == len(big_graph)

    # for row in qres:
    #     print(row.s, row.p, row.o)

def test_cp(big_graph: Graph):

  big_graph.parse("../vignettes/alice/causal_pathways.json")
  logging.critical("n triples (big_graph): %d", len(big_graph))

  qres: Result = big_graph.query("""
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX obo: <http://purl.obolibrary.org/obo/>
  PREFIX slowmo: <http://example.com/slowmo#>
  PREFIX feeb: <http://feedbacktailor.org/ftkb#>
  construct { 
    ?candidate slowmo:acceptable_by ?path .
  }
  where {
    ?path a obo:cpo_0000029 .
    ?candidate a obo:cpo_0000053 . 
    FILTER NOT EXISTS {
      ?path slowmo:HasPrecondition ?attr .
      ?attr a ?atype .
      FILTER NOT EXISTS {
        ?candidate obo:RO_0000091 ?disp .
        ?disp a ?atype .
      }
    }
  }
  """)

  for row in qres:
        print(row)
  print(len(qres))
  # logging.critical(qres.graph.serialize(
  #   # format="json-ld"
  #   ))
  # logging.critical("n triples: %d", len(qres.graph))