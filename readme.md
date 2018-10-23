[![DOI](https://zenodo.org/badge/100519665.svg)](https://zenodo.org/badge/latestdoi/100519665)


# Think Pudding
A minimal proof of concept reasoner and ontology example.

## Description
Using triple store (fuseki) to store and query spek output from candidate smasher,
determine which candidates are acceptable using ISRs.

## Use

### Fuseki

1. Start in memory fuseki that allows for updates
    ```sh
    FUSEKI_DIR=/opt/fuseki/apache-jena-fuseki-3.8.0
    ${FUSEKI_DIR}/fuseki-server --mem --update /ds 1> fuseki.out 2>&1 &
    ```

2. Input example spek
    ```sh
    ./insert_spek.sh
    ```

3. Run ISR update to identify acceptable candidates
    ```sh
    ./update_isr.sh
    ```

4. Run query to get results
    ```sh
    ./query_isr.sh
    ```

## Requirements
- fuseki

## License

Creative Commons 3.0
