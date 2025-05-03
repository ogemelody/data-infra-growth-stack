FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    ssh-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/dbt

# Install dbt and required packages directly
RUN pip install --no-cache-dir dbt-core dbt-postgres dbt-bigquery

# Copy the dbt project
COPY ./kasi_datainfra_data_modelling /usr/src/dbt/kasi_datainfra_data_modelling

# Copy the profiles.yml to the dbt directory
COPY ./profiles.yml /root/.dbt/profiles.yml

# Set environment variables for dbt
ENV DBT_PROFILES_DIR=/root/.dbt
ENV DBT_PROJECT_DIR=/usr/src/dbt/kasi_datainfra_data_modelling

# Set the working directory to the dbt project
WORKDIR /usr/src/dbt/kasi_datainfra_data_modelling

# Default command to run when starting the container
CMD ["dbt", "compile"]
