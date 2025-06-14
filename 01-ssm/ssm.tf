resource "aws_ssm_document" "install_iis_custom" {
  name            = "InstallIIS"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Install IIS and write a plain message",
    mainSteps = [
      {
        action = "aws:runPowerShellScript",
        name   = "installAndConfigureIIS",
        inputs = {
          runCommand = [
            "Write-Host \"Installing IIS...\"",
            "Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart",
            "Start-Service W3SVC",
            "$webRoot = \"C:\\\\inetpub\\\\wwwroot\"",
            "$indexPath = Join-Path $webRoot \"index.html\"",
            "$html = @\"\nWelcome from IIS\n\"@",
            "Set-Content -Path $indexPath -Value $html -Encoding UTF8",
            "Write-Host \"`nIIS is running. Visit: http://localhost`n\""
          ]
        }
      }
    ]
  })
}

resource "aws_ssm_document" "install_apache_ubuntu" {
  name            = "InstallApacheOnUbuntu"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Install and configure Apache2 on Ubuntu",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "installApache",
        inputs = {
          runCommand = [
            "sudo apt update",
            "sudo apt install -y apache2",
            "sudo systemctl enable apache2",
            "sudo systemctl start apache2",
            "echo \"Welcome from Apache\" | sudo tee /var/www/html/index.html > /dev/null"
          ]
        }
      }
    ]
  })
}
