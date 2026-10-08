run "setup" {
  command = apply

  module {
    source = "./tests/integration/setup"
  }
}

run "sandbox_group" {
  command = apply

  variables {
    location  = "newzealandnorth"
    name      = run.setup.name
    parent_id = run.setup.resource_group_id
  }

  assert {
    condition     = output.name == var.name
    error_message = "The name output must match the sandbox group name."
  }

  assert {
    condition     = startswith(output.management_endpoint, "https://management.")
    error_message = "The module must return the sandbox data plane endpoint."
  }
}
