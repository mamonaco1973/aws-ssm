resource "aws_ssm_document" "install_iis_custom" {
  name            = "InstallIISHelloWorld"
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
            "$webRoot = \\\"C:\\\\inetpub\\\\wwwroot\\\"",
            "$indexPath = Join-Path $webRoot \\\"index.html\\\"",
            "$html = @\"\nWelcome from IIS\n\"@",
            "Set-Content -Path $indexPath -Value $html -Encoding UTF8",
            "Write-Host \"`nIIS is running. Visit: http://localhost`n\""
          ]
        }
      }
    ]
  })
}
