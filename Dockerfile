# spark.dockerfile
FROM debian:stretch
MAINTAINER Getty Images "https://github.com/gettyimages"

RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Users with other locales should set this in their derivative image
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update \
 && apt-get install -y curl unzip \
    python3-pip python3-setuptools \
    libpostgresql-jdbc-java \ 
    libpostgresql-jdbc-java-doc \
    libmysql-java \
 && ln -s /usr/bin/python3 /usr/bin/python \
 && pip3 install --upgrade pip   \
 && pip3 install py4j \
 && pip3 install numpy \
 && pip3 install pandas \
 && pip3 install psycopg2 \
 && pip3 install mysql-connector-python \
 && pip3 install pymssql \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
RUN curl  https://github.com/stjack/SparkHadoopV0/tree/main/oracle/ojdbc8.jar -o /usr/share/java/ojdbc8.jar
RUN curl  https://github.com/stjack/SparkHadoopV0/tree/main/oracle/ojdbc.policy -o /usr/share/java/ojdbc.policy
RUN curl  https://github.com/stjack/SparkHadoopV0/tree/main/oracle/ucp.jar -o /usr/share/java/ucp.jar
RUN curl  https://github.com/stjack/SparkHadoopV0/tree/main/oracle/xdb6.jar -o /usr/share/java/xdb6.jar
RUN curl  https://github.com/stjack/SparkHadoopV0/tree/main/oracle/oraclepki.jar -o /usr/share/java/oraclepki.jar
## Adding support for Azure-hadoop drivers
RUN curl  https://github.com/stjack/SparkHadoopV0/tree/main/drivers/azure-storage-8.6.6.jar -o /usr/share/java/azure-storage-8.6.6.jar
RUN curl  https://github.com/stjack/SparkHadoopV0/tree/main/drivers/hadoop-azure-3.3.0.jar -o /usr/share/java/hadoop-azure-3.3.0.jar
# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# JAVA
RUN apt-get update \
 && apt-get install -y openjdk-8-jre \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# HADOOP
ENV HADOOP_VERSION 3.0.0
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# SPARK
ENV SPARK_VERSION 2.4.4
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -sL --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

WORKDIR $SPARK_HOME
CMD ["bin/spark-class", "org.apache.spark.deploy.master.Master"]

