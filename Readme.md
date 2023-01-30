

# running the container

        docker pull phaustin/libradtran_image:jan23
        cd ~/repos/libradtran-docker
        docker-compose up -d
        docker ps  (see if the process has started)
        docker exec -it libradtran_image /bin/bash

to exchange data between host and container

         mkdir -p ~/repos/libradtran-docker/shared

and then start the container

inside the container the same folder appears as /opt/libRadtran/shared


