# Docker-revist

We are going to use codespaces. After going inside codespaces, check if there is python and docker installed.

If we don't want to have the whole file address everytime, we use the CLI. We can do: `echo "PS1="> " > ~/.bashrc`

### What is Docker ?

Docker uses something called containers, which basically isolates application and their dependencies from the host machine to work consistent across systems but still shares the OS kernel.

### Practical Usage of Docker ?

To see how intially how docker works try using this command : `docker run hello-world`

Incase, you want to run CLI commands inside the docker. Use this command : `docker run -it <dockername>` - it means interactive terminal.

We are going to use ubuntu inside docker for this : 
-  `apt update`
-  `apt install python3`

When we do docker run, each time it takes the docker image and creates a new container. It is stateless, so after working inside the container. it is lost if run again.

Incase, we want to see the list of images we have executed. We can use this command : `docker ps -a`

Incase, we want all the id of images. We can use this command : `docker ps -aq`

Mass removal, we can use docker rm `docker ps -aq`

Add this in your cli : 
```
mkdir test
cd test
touch file1.txt file2.txt file3.txt
echo "Hello from host" > file1.txt
cd ..
```
Create a script file inside the test : 
```
from pathlib import Path

current_dir = Path.cwd()
current_file = Path(__file__).name

print(f"Files in {current_dir}:")

for filepath in current_dir.iterdir():
    if filepath.name == current_file:
        continue

    print(f"  - {filepath.name}")

    if filepath.is_file():
        content = filepath.read_text(encoding='utf-8')
        print(f"    Content: {content}")
```
Lets, say i want to access folder in my system inside docker.We have to use **volumes** to do this. We can use this command : 

```
docker run -it --entrypoint=bash -v $(pwd)/test:/app/test python:3.13.11-slim
```

Before running this command make sure your in root folder than something else.

In order to make sure, we are running the pipeline code in a virtual environment. we are going to use uv package for this.

First, we go inside pipeline folder and do `uv init --python 3.13`. then we are going to add dependencies `uv add pandas pyarrow`. then we try to check if the code works in virtual environment `uv run python pipeline.py 12`

Create a dockerfile inside the pipeline folder, I did it this way `touch Dockerfile`. Add the necessary things.

We have to build the Docker image, `docker build -t test:python .` (t is used to give a name tag)

We know how to access the image, `docker run -it --entrypoint=bash --rm test:pandas` (rm is added to clear the image once the session is over)

Lets understand the Dockerfile : 

```
FROM python:3.13.11-slim 
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /code
ENV PATH="/code/.venv/bin:$PATH"
COPY pyproject.toml .python-version uv.lock ./
RUN uv sync --locked


COPY pipeline.py .

ENTRYPOINT ["python","pipeline.py", "12"]
```

- We are using python:3.13.11-slim for image of the docker file
- COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/ , this basically importing uv. it is given here [Link](https://docs.astral.sh/uv/guides/integration/docker/#available-images)
- WORKDIR /code is basically for default working directory
- ENV PATH="/code/.venv/bin:$PATH", it points to a venv
- COPY pyproject.toml .python-version uv.lock ./ , this is basically taking all the  files into the dockerfile
- RUN uv sync --locked, for intalling dependices using uv
- COPY pipeline.py . , for saving the file into /code
- ENTRYPOINT ["python","pipeline.py", "12"], when u do docker run this will implement

### PostGreSQL with Docker

We are going to use PostgreSQL wit docker, 

```
docker run -it --rm \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \     # volumemapping
  -p 5432:5432 \                                     # portmapping
  postgres:18
```

In order to access the PostgreSQL, we going to use pgcli. Do `uv add --dev pgcli` inside the pipeline folder.

To connect to the postgres, use this `uv run pgcli -h localhost -p 5432 -u root -d ny_taxi` (h: host, p: port, u: username, d: database name)

Commands in postgres : 
- `\dt` : display all tables in the database
- `\dt+` : display extra info like table size and description


### Data Ingestion

For this we have add another dependency in pipeline folder uv, `uv add --dev jupyter` to have interactive session. Then we have to do `uv run jupyter notebook` and click the forwarded link. The token would be in the terminal, when you run the uv run command with token=.

Inside the jupyter notebook, create a ipynb notebook called notebook. Check notebook.ipynb for the adding of data from pandas into the postgresql.

if you want to convert ipynb into py, do `uv run jupyter nbconvert --to=script notebook,ipynb`

We have renamed the .py to ingest_data.py file and we have refactored to keep it clean and also added cli support to give custom parameters.

Now, we can run it using `uv run ingest_data.py` or using custom parameter's also.

Now, we are going to try to edit the dockerfile to run the ingestion script.

```
# Start with slim Python 3.13 image for smaller size
FROM python:3.13.11-slim

# Copy uv binary from official uv image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

# Set working directory inside container
WORKDIR /app

# Add virtual environment to PATH
ENV PATH="/app/.venv/bin:$PATH"

# Copy dependency files first (better caching)
COPY "pyproject.toml" "uv.lock" ".python-version" ./
# Install all dependencies (pandas, sqlalchemy, psycopg2)
RUN uv sync --locked

# Copy ingestion script
COPY ingest_data.py ingest_data.py 

# Set entry point to run the ingestion script
ENTRYPOINT [ "python", "ingest_data.py" ]
```

then we can build the docker image by `docker build -t taxi_ingest:v001 .`

When we run it we face an error, because the docker cannot access the postgres localhost as each docker has it's own local host. so we do

First, `docker network create pg-network`. we do this so that container to container communication can happen.

We name the postgresql as pgdatabase and then in ingest docker we give the instead of localhost we put pgdatabase.

For Visual GUI for postgres, we are going to put inside the network and be able to access the pddatabase. first,

this is for postgres database
```
docker run -it --rm\
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  --network=pg-network \
  --name pgdatabase \
  postgres:18
```

this is for pgadmin in a different terminal
```
docker run -it --rm \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -v pgadmin_data:/var/lib/pgadmin \
  -p 8085:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4
```

then the ingestion in a different terminal
```
docker run -it \
  --network=pg-network \
  taxi_ingest:v001 \
    --pg-user=root \
    --pg-pass=root \
    --pg-host=pgdatabase \
    --pg-port=5432 \
    --pg-db=ny_taxi \
    --target-table=yellow_taxi_trips_2021_2 \
    --year=2021 \
    --month=2 \
    --chunksize=100000
```


Now, above is working inorder to make it easier. we are going to do docker compose to two containers pgdatabase and pgadmin.

```
services:
  pgdatabase:
    image: postgres:18
    environment:
      - POSTGRES_USER=root
      - POSTGRES_PASSWORD=root
      - POSTGRES_DB=ny_taxi
    volumes:
      - "ny_taxi_postgres_data:/var/lib/postgresql:rw"
    ports:
      - "5432:5432"
  pgadmin:
    image: dpage/pgadmin4
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=root
    volumes:
      - "pgadmin_data:/var/lib/pgadmin"
    ports:
      - "8085:80"

volumes:
  ny_taxi_postgres_data:
  pgadmin_data:
```

We don't have to specify the network because compose in default works in a seperate network.

We can find out the network name which it makes by `docker network ls`

then in ingestion script we can put like this 

```
docker run -it   --network=pipeline_default   taxi_ingest:v001     --pg-user=root     --pg-pass=root     --pg-host=pgdatabase     --pg-port=5432     --pg-db=ny_taxi     
--target-table=yellow_taxi_trips_2021_2     --year=2021     --month=2     --chunksize=100000
```

