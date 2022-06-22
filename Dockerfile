FROM ubuntu:latest
LABEL org="iNeuron Intelligence Private Limited"
LABEL author="avnish"
LABEL email="avnish@ineuron.ai"
LABEL twitter="https://twitter.com/avn_yadav"
LABEL linkedin="https://www.linkedin.com/in/avnish-yadav-3ab447188/"

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root
ENV YARN_PROXYSERVER_USER=root
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_YARN_HOME=${HADOOP_HOME}
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV HADOOP_LOG_DIR=${HADOOP_YARN_HOME}/logs
ENV HADOOP_IDENT_STRING=root
ENV HADOOP_MAPRED_IDENT_STRING=root
ENV HADOOP_MAPRED_HOME=${HADOOP_HOME}
ENV SPARK_HOME=/usr/local/spark
ENV CONDA_HOME=/usr/local/conda
ENV PYSPARK_MASTER=yarn
ENV PATH=${CONDA_HOME}/bin:${SPARK_HOME}/bin:${HADOOP_HOME}/bin:${PATH}
ENV NOTEBOOK_PASSWORD=""
ENV AIRFLOW_PORT=8085
ENV AIRFLOW_USER_NAME=admin
ENV AIRFLOW_USER_PASSWORD=airflow
ENV AIRFLOW_USER_ROLE=Admin
ENV AIRFLOW_EMAIL_ID=yadav.tara.avnish@gmail.com
ENV AIRFLOW_HOME=/home/airflow

RUN apt-get update && \
    apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

ENV TZ="Asia/Kolkata"
# setup ubuntu
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get -y install openjdk-8-jdk wget openssh-server sshpass supervisor \
    && apt-get -y install nano net-tools lynx \
    && apt-get clean

# setup ssh
RUN ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa \
    && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys \
    && chmod 0600 /root/.ssh/authorized_keys
COPY ubuntu/root/.ssh/config /root/.ssh/config

# setup conda
COPY ubuntu/root/.jupyter /root/.jupyter/
COPY ubuntu/root/ipynb/environment.yml /tmp/environment.yml
RUN wget -q https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh -O /tmp/anaconda.sh \
    && /bin/bash /tmp/anaconda.sh -b -p $CONDA_HOME \
    && $CONDA_HOME/bin/conda env update -n base --file /tmp/environment.yml \
    && $CONDA_HOME/bin/conda update -n root conda -y \
    && $CONDA_HOME/bin/conda update --all -y \
    && $CONDA_HOME/bin/pip install --upgrade pip
RUN mkdir -p /home/airflow/dags 
COPY ./dags /home/airflow/dags 
RUN mkdir -p /home/airflow/library/
RUN mkdir -p config
COPY ./config /config
COPY ./dist  /home/airflow/library/
COPY ./home/airflow /home/airflow
# setup volumes
RUN mkdir /root/ipynb
VOLUME [ "/root/ipynb","/home/airflow" ]
WORKDIR /
RUN pip install --upgrade pip
RUN pip install /home/airflow/library/Housing_price_prediction-0.0.0-py3-none-any.whl
RUN python -m pip install  virtualenv
COPY ./requirements.txt .
RUN pip install -r requirements.txt
COPY ./airflow-start.sh .
COPY ./schema.yaml .
RUN chmod 777 ./airflow-start.sh
CMD ["./airflow-start.sh"]