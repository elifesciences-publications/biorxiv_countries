This code is associated with the paper from  ABDILL RA et al., "International authorship and
collaboration across bioRxiv
preprints". eLife, 2020. http://doi.org/10.7554/eLife.58496

# rxivist spider

## Running the spider for real
The web crawler runs in a lightly customized Docker container and can be launched from any server (or workstation) that has access to the database.

```sh
# start ROR API:
git clone https://github.com/ror-community/ror-api.git
cd ror-api
docker-compose up -d
docker-compose exec web python manage.py setup

# start database:
cd ..
git clone https://github.com/blekhmanlab/biorxiv_countries.git
cd biorxiv_countries/code/db
docker build . -t local_rxdbthing:latest
docker-compose up

# connect ROR API and the database:
cd ..
docker network connect ror-api_default authordb

# launch spider:
cd biorxiv_countries/code
docker build . -t countryspider:latest
docker run -it --rm --name localspider -v "$(pwd)":/app --entrypoint "bash" --env RX_DBHOST --env RX_DBPASSWORD --env RX_DBUSER --net ror-api_default countryspider:latest
```
