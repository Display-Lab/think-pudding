[![DOI](https://zenodo.org/badge/100519665.svg)](https://zenodo.org/badge/latestdoi/100519665)

# Think Pudding

## Description
Using a triple store to store and query spek output from candidate smasher.
Determine which candidates are acceptable using causal pathways.

## Use

### Nebula Tripple Store

1. Upload data to S3 Bucket

2. Spin up Nebula cluster stack with bastion host
    ```sh
    aws cloudformation create-stack --stack-name $STACK_NAME\
      --capabilities "CAPABILITY_IAM" \
      --template-body file://nept_stack_cf.yaml \
      --parameters '[{"ParameterKey":"Env","ParameterValue":"test"},'\
      '{"ParameterKey":"DbInstanceType","ParameterValue":"db.r4.xlarge"},'\
      '{"ParameterKey":"KeyName","ParameterValue":"aws-growls-useast-1"}]'
    ```

3. Assign IAM ROLE to cluster
    ```sh
    aws neptune add-role-to-db-cluster \
      --role-arn ${NeptuneLoadFromS3IAMRoleArn} \
      --db-cluster-identifier ${DBClusterId}
    ```

4. Configure Bastion Host
    ```sh
    ansible-playbook -i ${BastionIp}, -u ec2-user bastion_play.yml
    ```

4. Login to Bastion Host and Load Data
    ```sh
    ssh ec2-user@${BastionIp} scripts/neptune_load.sh
    ```

### Fuseki Tripple Store

1. Start in memory fuseki that allows for updates
    ```sh
    ${FUSEKI_HOME}/fuseki-server --mem --update /ds 1> fuseki.out 2>&1 &
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
