# PowerShell script to create a simple web server on port 80

# Create the HTTP listener object
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:80/")

try {
    # Start the listener
    $listener.Start()
    Write-Host "Web server started on port 80. Press Ctrl+C to stop..."

    while ($listener.IsListening) {
        try {
            # Wait for an incoming request
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            # Log incoming request details
            Write-Host "Received request: $($request.HttpMethod) $($request.Url)"

            # Create a simple HTML response
            $htmlContent = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>PowerShell Web Server</title>
</head>
<body>
    <h1>Welcome to the PowerShell Web Server!</h1>
    <p>You've successfully accessed the server on port 80.</p>
</body>
</html>
"@

            # Convert the HTML content to bytes
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($htmlContent)

            # Set the content type and status code
            $response.ContentType = "text/html"
            $response.ContentLength64 = $buffer.Length
            $response.StatusCode = 200

            # Send the response to the client
            $response.OutputStream.Write($buffer, 0, $buffer.Length)

            # Close the output stream and response
            $response.OutputStream.Close()

        } catch {
            Write-Host "Error processing request: $($_.Exception.Message)"
        }
    }

} catch {
    Write-Host "Failed to start web server: $($_.Exception.Message)"
} finally {
    # Ensure listener stops gracefully
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
    Write-Host "Web server stopped."
}
