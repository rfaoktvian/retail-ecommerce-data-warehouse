from dotenv import load_dotenv
import os
from google.cloud import bigquery

load_dotenv()
client = bigquery.Client()
query = "SELECT order_purchase_timestamp FROM `qwiklabs-gcp-03-018d48a9d681.bronze.postgres_orders` LIMIT 3"
job = client.query(query)
for row in job.result():
    print(row.order_purchase_timestamp)
