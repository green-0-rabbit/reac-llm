data "archive_file" "docker_context" {
  type        = "zip"
  source_dir  = "${path.module}/../docker"
  output_path = "${path.module}/docker_context.zip"
}
