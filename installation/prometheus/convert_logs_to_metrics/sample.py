import re
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
import threading
import time

# Sample function to read the log file (you can specify the log file path)
log_file_path = './ANZ_Bank.log'

# Regular expression to parse the log
log_pattern = re.compile(r'(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) Bank: (?P<bank>.*?) \| Scraped Data: (?P<scraped_data>\d+) records')

# Function to read the log file and convert it to Prometheus metrics format
def convert_logs_to_metrics(logs):
    metrics = []
    for line in logs.strip().split('\n'):
        match = log_pattern.match(line)
        if match:
            timestamp = match.group('timestamp')
            bank = match.group('bank').replace(" ", "_")  # Replace spaces with underscores
            scraped_data = int(match.group('scraped_data'))
            
            # Convert timestamp to ISO 8601 format without the date for simplicity
            timestamp = datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S").isoformat()

            # Construct the metric line
            metric = f'scraped_data_total{{bank="{bank}", timestamp="{timestamp}"}} {scraped_data}'
            metrics.append(metric)
    
    return metrics

# Function to read the log file and get live data
def read_log_file():
    with open(log_file_path, 'r') as file:
        logs = file.readlines()
    return logs

# HTTP server handler to expose Prometheus metrics
class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics":
            logs = read_log_file()
            metrics = convert_logs_to_metrics("".join(logs))
            response = "\n".join(metrics)
            
            # Send response headers
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            
            # Send the metrics response
            self.wfile.write(response.encode())
        else:
            self.send_response(404)
            self.end_headers()

# Function to start the HTTP server
def start_server():
    server_address = ('', 8000)
    httpd = HTTPServer(server_address, MetricsHandler)
    print("Starting server on port 8000...")
    httpd.serve_forever()

# Start the server in a separate thread
def start_metrics_server():
    server_thread = threading.Thread(target=start_server)
    server_thread.daemon = True
    server_thread.start()

# Run the server
if __name__ == "__main__":
    start_metrics_server()
    
    # Keep the script running to serve the data
    while True:
        time.sleep(1)