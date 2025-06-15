# --------------------------------------------------------------------------------------------------
# SSM DOCUMENT: INSTALL IIS ON WINDOWS
# --------------------------------------------------------------------------------------------------
resource "aws_ssm_document" "install_iis_custom" {
  # The name of the SSM document to be created
  name = "InstallIIS"

  # Specifies that this is a Command document (not a Policy or Automation)
  document_type = "Command"

  # Indicates that the document content will be in JSON format
  document_format = "JSON"

  # The actual SSM document content, encoded as a JSON structure
  content = jsonencode({
    schemaVersion = "2.2",                             # Specifies the schema version for the SSM document
    description   = "Install IIS and write a plain message",  # Short description of what this document does
    mainSteps = [
      {
        action = "aws:runPowerShellScript",           # The action to execute: run a PowerShell script
        name   = "installAndConfigureIIS",            # Step name; must be unique within the document
        inputs = {
          runCommand = [
            # Output message indicating that IIS installation is starting
            "Write-Host \"Installing IIS...\"",

            # Enable the IIS Web Server Role with all dependencies, do not reboot after install
            "Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart",

            # Start the IIS service
            "Start-Service W3SVC",

            # Define the path to the IIS web root directory
            "$webRoot = \"C:\\\\inetpub\\\\wwwroot\"",

            # Create the full path to the index.html file
            "$indexPath = Join-Path $webRoot \"index.html\"",

            # Define the HTML content to be written to the index file
            "$html = @\"\nWelcome from IIS\n\"@",

            # Write the HTML content to the index.html file using UTF-8 encoding
            "Set-Content -Path $indexPath -Value $html -Encoding UTF8",

            # Display a success message with the access URL
            "Write-Host \"`nIIS is running. Visit: http://localhost`n\""
          ]
        }
      }
    ]
  })
}

# --------------------------------------------------------------------------------------------------
# SSM DOCUMENT: INSTALL APACHE ON UBUNTU
# --------------------------------------------------------------------------------------------------
resource "aws_ssm_document" "install_apache_ubuntu" {
  # The name of the SSM document to be created
  name = "InstallApacheOnUbuntu"

  # Specifies that this is a Command document
  document_type = "Command"

  # Specifies that the document will be written in JSON format
  document_format = "JSON"

  # The actual content of the SSM document encoded as JSON
  content = jsonencode({
    schemaVersion = "2.2",                          # Defines the SSM schema version
    description   = "Install and configure Apache2 on Ubuntu",  # Summary of what the document performs
    mainSteps = [
      {
        action = "aws:runShellScript",             # Run a shell script (Linux/Unix systems)
        name   = "installApache",                  # Unique step name
        inputs = {
          runCommand = [
            # Refresh the local package index
            "sudo apt update",

            # Install the Apache2 package without user prompts
            "sudo apt install -y apache2",

            # Enable the Apache2 service to start at boot
            "sudo systemctl enable apache2",

            # Start the Apache2 service immediately
            "sudo systemctl start apache2",

            # Create a basic HTML file to confirm web server is working
            "echo \"Welcome from Apache\" | sudo tee /var/www/html/index.html > /dev/null"
          ]
        }
      }
    ]
  })
}
