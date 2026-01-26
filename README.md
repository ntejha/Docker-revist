# Docker-revist

We are going to use codespaces. After going inside codespaces, check if there is python and docker installed.

If we don't want to have the whole file address everytime, we use the CLI. We can do: `echo "PS1="> " > ~/.bashrc`

### What is Docker ?

Docker uses something called containers, which basically isolates application and their dependencies from the host machine to work consistent across systems but still shares the OS kernel.

To see how intially how docker works try using this command : `docker run hello-world`

Incase, you want to run CLI commands inside the docker. Use this command : `docker run -it <dockername>` - it means interactive terminal.

We are going to use ubuntu inside docker for this : 
-  `apt update`
-  `apt install python3`

When we do docker run, each time it takes the docker image and creates a new container. It is stateless, so after working inside the container. it is lost if run again.

Incase, we want to see the list of images we have executed. We can use this command : `docker ps -a`

Incase, we want all the id of images. We can use this command : `docker ps -aq`

Mass removal, we can use docker rm `docker ps -aq`

Lets, say i want to access folder in my system inside docker.We have to use **volumes** to do this. We can use this command : 

```
docker run -it --entrypoint=bash -v $(pwd)/test:/app/test python:3.13.11-slim
```





