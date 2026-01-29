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





