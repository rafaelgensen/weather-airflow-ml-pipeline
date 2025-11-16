FROM apache/airflow:2.9.1-python3.10

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ curl && \
    apt-get clean

USER airflow

COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

COPY dags/ /opt/airflow/dags/
