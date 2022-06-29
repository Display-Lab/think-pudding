# Notes while creating Alice example

peer comparison requires peers.
needed to create peers data with expected average.
does template specified in spek get merged with external templates?
try ruby gem csvlint to validate structure of data files
csvlint current version doesn't work with current ruby.
try python frictionless describe and validate.
suggest using miniconda for python installation and package management, but might be bridge too far.

calculation of peer average should exclude the recipient.
 - this was discussed before, but the straight average everyone was decided upon.
 - i don't recall the reasons, but it's computationally easier anyway.
 - means the peer data is going to be wierd in order to get a .93 mean rate.
 - calculating a synthetic data set for coming up with a given mean is a bit of a pain.
 - 97,94,91,90 gives mean of 93.

aspire annotations don't generalize without modification to rate data.
should write a general rate data annotation set.

bitstomach does not like when performace data does not have a measure column.
 -  write test case for data set cases: mapt, map, mpt, apt, pt, ap
 -  provide assumption for missing dimensions
should try to sort out generic function for calc peer average to avoid having it in every annotation.r
 - going to be problematic to handle numerator only, numer & denominator, and rate data in one function.
 - consider splitting to three and attempting to detect the case for each measure.
 - numerator only is going to be the hard one here.

bitstomach reads in rate as character data.
  - should read in a double as per the spek. This is a problem with `spekex::cols_for_readr`.
  - this is done: spekex updated.

candidates smasher cli (cansmash) parameter flags differ from bitstomach and thinkpudding.
 - `-s` should point to spek

fucked up the `@context` element of the json-ld docs.
 - the spec does not like having a ':' in the keys:

    >  Strings that have the form of an IRI (e.g., containing a ":") should not be used as terms.

 - consider dropping the prefix for the context entries that are convenient lookups.
 - using "psdo:term" should still work as the psdo prefix is define in the context.
 - see templates.json in alice example for corrected version.

should rewrite run annotation script as a makefile.
  Also need message to check for installed components.

ruby's rdf + json/ld doesn't think spek is valid RDF format.
  - needs `format: :jsonld` specified in options hash.
  - obsolete currently as cansmash does dumb json parsing.

in cansmash, if no spek templates are found, use all from external source? no.
need to sort out mode of operation for spek templates:
 - spek templates select which templates to use? yes.
 - spek templates provide additional templates? yes.
 - spek templates provide additional annotations? yes.
 - spek templates override external templates? yes.

Do selection.
 - If no spek templates, use all external. no.
 - If no spek templates & no external templates, die. no.
 - If no spek templates & no external templates, emit no candidates. yes.

Double check on template attributes, e.g. psdo:45 (social comparator element)
  The template should have a set of marks to display social comparator
  but the performer actually has the annotation of if a social comparator was calc'd for the performance.
  This is fine.  It is the display side corresponding to psdo_0000095.

why is template type "http://example.com/slowmo#EmailTemplate"?
 - why not psdo:2 
 - is email template being handled differently than psdo:2?
 - template not handled differently, but is conceptually differently
 - **Known shoehorning.** keep machinery the same and refactor ontology later. 

candidate smasher merging graphs of external templates was only superficially implemented.
 - need to fully subset graphs, or you just end up with bnode references.
 - this got resolved as falling back to straight json parsing.
 - need to do internallys fully in RDF.  Mix & match JSON and RDF doesn't work nicely.

Template issues:
 - psdo_0000003 is the wrong predicate for pointing to code that generates the corresponding artifacts
 - pointing to code should be URL to file directly (E.g. raw.github.com)
 - pictoralist should get the filename, and assume it's in a templates_lib directory.
      Maybe do URL, then filename, then env name (for a compiled & loaded template package)

 - psdo_0000002 does not include things that are not themselves a performance summary dispaly or do not include one.
     -  emails might not include performance summary displays.
     -  redesigning to accomodate non-displays might require a lot of ontology work.
     -  probably do ontology work before getting to the coding.
  
Spek needs to indicate template ids to consider.  This will change per vignette.
  Run `vimdiff alice/spek.json bob/spek.json to see difference.

Debugging unexpected annotation result.
1. Check bitstomach (and spekex) package has lookup for annotate_X
    1. Look in bitstomach/R/package_constants.R for `DEFAULT_URI_LOOKUP` list.
    2. Ensure the X of `annotate_X` function name is present in list.
    3. Check that value of right hand side is expected IRI.  (value likely in spekex)
    4. Check the spekex/R/package_constants.R for literal value of IRI constant.
    5. Run command to check value in local library version of bitstomach where X is X of `annotate_X` function.
       ```sh 
       # E.g. lookup IRI for annotate_positive_trend
       Rscript --default-packages=bitstomach -e 'bitstomach:::BS$DEFAULT_URI_LOOKUP$positive_trend'
       ```
2. Check `annotations.r` for function with name `annotate_X` e.g. annotate_positive_gap
3. Use BitStomach annotation [testing harness](https://github.com/Display-Lab/bit-stomach/blob/master/testing_annotations.md) to run the annotation function and examine resulting table. If issue persists, step through the annotation function line by line to find issue.

Checking that the Vignette is working.
1. Run `../scripts/run_vignette.sh` to generate outputs
2. Open `causal_pathways.json` to view list of preconditions of causal pathways.
3. Open `outputs/spek_tp.json` to get list of dispositions of named candidate.
  I use the `less` program and pattern searching to do this: `less outputs/spek_tp.json`
  1. Use `/Bob` (less' search navigation) to find candidate with Bob the performer listed as AncestorPerformer
  2. Lookup each of the RO_0000091 blank nodes to get the list of dispositions
    1. Use `/"@id" : "\_b:X"` to find blank node X 
    2. Note the `@type` of the node
4. Compare list of preconditions and dispositions for precond that isn't in the disps list.
5. Missing precondition is result of:
  - Wrong IRI listed for precondition.
  - Wrong IRI listed for disposition.
  - Disposition that should be supplied by template
  - Disposition that should be supplied by performer
  - Precondition might be a mistake

If the candidate is missing attributes from the template, check that the `@id` of the templates.json matches the `slowmo:IsAboutTemplate` values.
