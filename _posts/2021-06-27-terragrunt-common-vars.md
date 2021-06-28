---
title: DRY common variables with Terragrunt
---

I was looking for a way to define common variables with [Terragrunt](https://terragrunt.gruntwork.io) as DRY-ly as possible and just couldn't wrap my head around it. Then, I found [gruntwork-io/terragrunt-infrastructure-live-example](https://github.com/gruntwork-io/terragrunt-infrastructure-live-example), which got me a little closer to the solution!

## The example repo
First, the root `terragrunt.hcl` is called by the stack's (e.g. `non-prod/us-east-1/qa/mysql/terragrunt.hcl`) via an include. From there, it looks through the parent folders to find the different levels of variable definitions:
```terraform
locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract the variables we need for easy access
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.aws_account_id
  aws_region   = local.region_vars.locals.aws_region
}
```

Okay, so we're bringing in variables from HCL files through the use of the `read_terragrunt_config()` function. Those other HCL files only contain a locals block with some variables defined. The "Extract the variables" part is just assigning a shorter name to some of the variables we've brought in since they're used further down in the root `terragrunt.hcl` file.

Then, at the bottom of the file, we have this:
```
  inputs = merge(
    local.account_vars.locals,
    local.region_vars.locals,
    local.environment_vars.locals,
  )
```

Terragrunt's `inputs` configuration attribute exports the key/value pairs of a map as `TF_VAR_*` environment variables. The `merge()` function is squishing all of our imported variables into a single map.

## But wait!
At this point, you would think that our common variables are ready to be accessed anywhere because they're being exported as environment variables. But no! You can't just start referencing `var.aws_region` even though it's defined as an environment variable. If you try, you'll get the error "Reference to undeclared input variable".

**Defining a variable is not the same as _declaring_ a variable**.

Also note that this locals block is only for Terragrunt and not shared with any `*.tf` files you might be using in your stack.

Let's fix this up so that our stacks only have to include the root `terragrunt.hcl` file and automatically have access to the variables exported in the inputs attribute.

## DRY common variables
First, let's do the merge in the locals block:
```terraform
locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Merge them all into one map
  common_vars = merge(
    local.account_vars.locals,
    local.region_vars.locals,
    local.environment_vars.locals,
  )

  # Extract the variables we need for easy access
  account_name = local.common_vars.account_name
  account_id   = local.common_vars.aws_account_id
  aws_region   = local.common_vars.aws_region
}

```

Export the merged vars as `TF_VAR_*` environment variables:
```
inputs = local.common_vars
```

Finally, use a `generate` block to automatically create a `common.tf` file that declares our variables when we run Terragrunt in each stack:
```terraform
generate "common" {
  path      = "common.tf"
  if_exists = "overwrite_terragrunt"
  contents  = join(
    "\n",
    [for key, _ in local.common_vars : "variable \"${key}\" {}"]
  )
}
```

And that's it! Our common variables are declared and any new additions to `account.hcl`, `region.hcl`, or `env.hcl` will automatically populate when we run Terragrunt again.
